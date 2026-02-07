#define K2_DEBUG_WARN
// #define K2_DEBUG_INFO

/*
 * The mailbox driver (& framebuffer, display) for rpi3.
 * Uses mailbox "property" interface.
 * Reference: https://github.com/raspberrypi/firmware/wiki/Mailbox-property-interface
 *
 * QEMU code (buggy, see docs/notes-qemu-fb.md):
 * hw/display/bcm2835_fb.c
 * https://github.com/Xilinx/qemu/blob/master/hw/display/bcm2835_fb.c
 *
 * CREDITS, more references: see the end of this file.
 */

#include "plat.h"
#include "utils.h"
#include "spinlock.h"

struct spinlock mboxlock = {.locked = 0, .cpu = 0, .name = "mbox_lock"};

/* mailbox message buffer */
volatile unsigned int __attribute__((aligned(16))) mbox[36];

#define MMIO_BASE       0x3F000000UL
#define VIDEOCORE_MBOX  (MMIO_BASE + 0x0000B880)
#define MBOX_READ       ((volatile unsigned int*)((VIDEOCORE_MBOX) + 0x0))
#define MBOX_POLL       ((volatile unsigned int*)((VIDEOCORE_MBOX) + 0x10))
#define MBOX_SENDER     ((volatile unsigned int*)((VIDEOCORE_MBOX) + 0x14))
#define MBOX_STATUS     ((volatile unsigned int*)((VIDEOCORE_MBOX) + 0x18))
#define MBOX_CONFIG     ((volatile unsigned int*)((VIDEOCORE_MBOX) + 0x1C))
#define MBOX_WRITE      ((volatile unsigned int*)((VIDEOCORE_MBOX) + 0x20))
#define MBOX_RESPONSE   0x80000000
#define MBOX_FULL       0x80000000
#define MBOX_EMPTY      0x40000000

/**
 * Make a mailbox call. Use the "mbox" buffer for both request and response.
 * Response overwrites request.
 * Spin wait for mailbox hardware.
 * Returns 0 on failure, non-zero on success.
 *
 * Caller must hold mboxlock.
 */
int mbox_call(unsigned char ch) {
    // the buf addr (pa) w/ ch (chan id) in LSB 
    unsigned int r = (((unsigned int)((unsigned long)&mbox) & ~0xF) | (ch & 0xF));
    r = BUS_ADDRESS(r); 
    /* wait until we can write to the mailbox */
    do { asm volatile("nop"); } while (*MBOX_STATUS & MBOX_FULL);
    __asm__ volatile ("dmb sy" ::: "memory");    // mem barrier, ensuring msg in mem

    /* write the address of our message to the mailbox with channel identifier */
    *MBOX_WRITE = r; 
    /* now wait for the response */
    while (1) {
        /* is there a response? */
        do { asm volatile("nop"); } while (*MBOX_STATUS & MBOX_EMPTY);
        /* is it a response to our message? */
        if (r == *MBOX_READ) {
            V("r is 0x%x", r); 
            /* is it a valid successful response? (strange it's benign) */
            if (mbox[1] != MBOX_RESPONSE) I("mbox[1] is %08x", mbox[1]);            
            return mbox[1] == MBOX_RESPONSE;
        } else {
            W("got an irrelevant msg. bug?"); 
        }
    }
    return 0;
}

///////////////////////////////////////////////////
// property interfaces via mbox
#define MBOX_REQUEST    0
#define CODE_RESPONSE_SUCCESS    0x80000000
#define CODE_RESPONSE_FAILURE    0x80000001

/* channels */
#define MBOX_CH_POWER   0
#define MBOX_CH_FB      1
#define MBOX_CH_VUART   2
#define MBOX_CH_VCHIQ   3
#define MBOX_CH_LEDS    4
#define MBOX_CH_BTNS    5
#define MBOX_CH_TOUCH   6
#define MBOX_CH_COUNT   7
#define MBOX_CH_PROP    8
/* tags */
#define MBOX_TAG_LAST           0
// in a successful resp, b31 is set; b30-0 is "value length in bytes"
#define VALUE_LENGTH_RESPONSE	(1 << 31)

///////////////////////////////////////////////////
//  framebuffer driver (via mbox)
#include "fb.h"

/* PC Screen Font as used by Linux Console */
typedef struct {
    unsigned int magic;
    unsigned int version;
    unsigned int headersize;
    unsigned int flags;
    unsigned int numglyph;
    unsigned int bytesperglyph;
    unsigned int height;
    unsigned int width;
    unsigned char glyphs;
} __attribute__((packed)) psf_t;
// cf: Makefile font build rules
extern volatile unsigned char _binary_font_psf_start;  

// default (upon boot): 1024x768, phys WH = virt WH, offset (0,0)
// said to support up to 1920x1080
struct fb_struct the_fb = {
    .fb = 0,
#ifdef PLAT_RPI3QEMU
    /* these are just initial fb sizes; app will ask for diff
    sizes based on their logic. so we keep them small for qemu
    to avoid a big blank screen upon boot */
    // .width = 640,
    // .height = 480, 
    // .vwidth = 640, 
    // .vheight = 480,
    .width = 320,
    .height = 240, 
    .vwidth = 320, 
    .vheight = 240,
#else // rpi3 hw
    // =0 same as the detected scr dim, see below
    .width  = 0, // 1024,  
    .height = 0, // 768, 
    .vwidth = 0, // 1024, 
    .vheight = 0, // 768,
#endif
    .scr_width = 0,
    .scr_height = 0, 
    .depth = 32, 
    .isrgb = 0,     // see below 
    .offsetx = 0,
    .offsety = 0,
    .size = 0, 
}; 
/* Note on "isrgb": whatever the doc says, 0 seems rgb; 1 seems bgr (per my
test) rpi3 hw will return "0" even if we asks for "1" qemu will do whatever we
ask ("0" or "1"); if "1", channel order is bgr */

/*
 * Detect physical display optimal x/y, if unconfigured.
 * Caller must hold mboxlock.
 * Return: 0 on success.
 *
 * FXL's 720p monitor: 1360x768
 * QEMU: 640x480 (initial; subject to reconfig for larger fb)
 */
int fb_detect_scr_dim(uint *w, uint *h) {
    mbox[0] = 8*4;     // size of the whole buf that follows
    mbox[1] = MBOX_REQUEST; // cpu->gpu request
        mbox[2] = 0x40003;     // rls framebuffer
        mbox[3] = 8;           // total buf size
        mbox[4] = 0;           // req para size
        mbox[5] = 0;           // resp: width
        mbox[6] = 0;           // resp: height
    mbox[7] = MBOX_TAG_LAST;

    if(!mbox_call(MBOX_CH_PROP)) {
        E("failed to get screen dim");
        return -1;
    } 

    *w=mbox[5];*h=mbox[6]; I("detected screen dim %d %d", *w, *h);    
    return 0; 
}

/* 
 * Set virt offset
 * Caller must hold mboxlock
 * Return 0 on success 
 */
int fb_set_voffsets(int offsetx, int offsety) {

    mbox[0] = 8*4;
    mbox[1] = MBOX_REQUEST;
    
    mbox[2] = 0x48009; 
    mbox[3] = 8;
    mbox[4] = 8;
    mbox[5] =  offsetx;           //FrameBufferInfo.x_offset
    mbox[6] =  offsety;           //FrameBufferInfo.y.offset    

    mbox[7] = MBOX_TAG_LAST;

    if(!mbox_call(MBOX_CH_PROP)) {
        E("failed to set virt offsets, requested x=%d y=%d", offsetx, offsety);
        return -1;
    }     
     if (mbox[5] != offsetx || mbox[6] != offsety) {
        E("failed set: offsetx %u offsety %u res: offsetx %u offsety %u", 
            offsetx, offsety, mbox[5], mbox[6]);
        return -1;     
     }
     V("set OK: offsetx %u offsety %u res: offsetx %u offsety %u", 
            offsetx, offsety, mbox[5], mbox[6]);
     return 0; 
}

/*
 * Initialize the actual framebuffer hardware by invoking the mailbox interface.
 * Return 0 if successful.
 */
static int do_fb_init(struct fb_struct *fbs) {
    if (!fbs)
        return -1;

    acquire(&mboxlock);

#ifdef PLAT_RPI3
    // If vwidth/vheight are 0, set them to the screen size
    if (fb_detect_scr_dim(&fbs->scr_width, &fbs->scr_height) == 0) {
        fbs->vwidth  = fbs->vwidth  ? fbs->vwidth  : fbs->scr_width;
        fbs->vheight = fbs->vheight ? fbs->vheight : fbs->scr_height;
        fbs->width   = fbs->width   ? fbs->width   : fbs->scr_width;
        fbs->height  = fbs->height  ? fbs->height  : fbs->scr_height;
    }
#endif

    // Prepare mailbox message
    mbox[0]  = 35 * 4;       // total size of buffer
    mbox[1]  = MBOX_REQUEST;

    mbox[2]  = 0x48003;      // set physical width & height
    mbox[3]  = 8;            
    mbox[4]  = 8;            
    mbox[5]  = fbs->width;   
    mbox[6]  = fbs->height;  

    mbox[7]  = 0x48004;      // set virtual width & height
    mbox[8]  = 8;
    mbox[9]  = 8;
    mbox[10] = fbs->vwidth;  
    mbox[11] = fbs->vheight; 

    mbox[12] = 0x48009;      // set virtual offset
    mbox[13] = 8;
    mbox[14] = 8;
    mbox[15] = fbs->offsetx;
    mbox[16] = fbs->offsety;

    mbox[17] = 0x48005;      // set depth
    mbox[18] = 4;
    mbox[19] = 4;
    mbox[20] = fbs->depth;

    mbox[21] = 0x48006;      // set pixel order
    mbox[22] = 4;
    mbox[23] = 4;
    mbox[24] = fbs->isrgb;

    mbox[25] = 0x40001;      // get framebuffer
    mbox[26] = 8;
    mbox[27] = 8;            
    mbox[28] = 4096;         // alignment
    mbox[29] = 0;            

    mbox[30] = 0x40008;      // get pitch
    mbox[31] = 4;
    mbox[32] = 4;
    mbox[33] = 0;            

    mbox[34] = MBOX_TAG_LAST;

    if (mbox_call(MBOX_CH_PROP) && mbox[20]==fbs->depth && mbox[28]!=0) {
        // extract framebuffer info
        mbox[28] &= 0x3FFFFFFF;              
        fbs->fb = (unsigned char *)((uint64_t)mbox[28] & 0x3FFFFFFF);              // framebuffer pointer
        fbs->pitch  = mbox[33];              // bytes per row
        fbs->width  = mbox[5];               
        fbs->height = mbox[6];               
        fbs->vwidth  = mbox[10];             
        fbs->vheight = mbox[11];             
        fbs->depth   = mbox[20];             
        fbs->isrgb   = mbox[24];             

        // clear framebuffer memory
        memset((void*)fbs->fb, 0, fbs->pitch * fbs->vheight);

        fbs->size = PGROUNDUP(fbs->pitch * fbs->vheight);

        I("OK. fb pa: %p w %u h %u vw %u vh %u pitch %u isrgb %u",
  fbs->fb,
  fbs->width,
  fbs->height,
  fbs->vwidth,
  fbs->vheight,
  fbs->pitch,
  fbs->isrgb);
    } else {
        E("Unable to set scr res to %d x %d\n", fbs->width, fbs->height);
        release(&mboxlock);
        return -2;
    }

    release(&mboxlock);
    return 0;
}


void fb_showpicture();

/* Initialize the framebuffer and display a picture (OS logo).
    Return 0 on success (display will go black). */
int fb_init(void) {
    static int once = 1; 
    int ret = do_fb_init(&the_fb); 
    if (ret==0 && once)
        {fb_showpicture(); once=0;}
    return ret; 
}

/* Finalize the framebuffer and clean up.
    Return 0 on success (display will go blank). */
int fb_fini(void) {
    int ret = 0;

    acquire(&mboxlock);
    if (!the_fb.fb || !the_fb.size) {
        ret = -1;
        goto out;
    }

#ifdef PLAT_RPI3QEMU // avoid artifacts: qemu does not clear old fb
    memset(the_fb.fb, 0, the_fb.size);
#endif

    mbox[0] = 6 * 4;        // size of the whole buf that follows
    mbox[1] = MBOX_REQUEST; // cpu->gpu request

    mbox[2] = 0x48001; // rls framebuffer
    mbox[3] = 0;       // total buf size
    mbox[4] = 0;       // req para size

    mbox[5] = MBOX_TAG_LAST;

    if (!mbox_call(MBOX_CH_PROP))
        I("failed to rls fb with GPU.");
    // response code always 0x80000001 (failure). couldn't figure out why

    // wont need this until flavor simple/rich user
    // if (free_phys_region(VA2PA(the_fb.fb), the_fb.size)) {
    //     E("failed to free fb memory. bug?");
    //     ret = -2;
    // }
    the_fb.fb = 0;
out:
    release(&mboxlock);
    return ret;
}

///////////////////////////////////////////////////
//  draw: picture/text on the fb display 

/*
 * Display a string using fixed size PSF update x,y screen coordinates
 * x/y (IN|OUT): the position before/after the screen output
 * NB these are pixel coordinates (not character locations)
 */
void fb_print(int *x, int *y, char *s) {
    unsigned pitch = the_fb.pitch;
    unsigned char *fb = the_fb.fb;

    // get our font
    psf_t *font = (psf_t *)&_binary_font_psf_start;
    // draw next character if it's not zero
    while (*s) {
        /* get offset of the glyph. Need to adjust this to support unicode table */
        unsigned char *glyph = (unsigned char *)&_binary_font_psf_start +
                               font->headersize + (*((unsigned char *)s) < font->numglyph ? *s : 0) * font->bytesperglyph;
        // calculate the offset on screen
        int offs = (*y * pitch) + (*x * 4);
        // variables
        int i, j, line, mask, bytesperline = (font->width + 7) / 8;
        // handle carrige return
        if (*s == '\r') {
            *x = 0;
        } else
            // new line
            if (*s == '\n') {
                *x = 0;
                *y += font->height;
            } else {
                // display a character
                for (j = 0; j < font->height; j++) {
                    // display one row
                    line = offs;
                    mask = 1 << (font->width - 1);
                    for (i = 0; i < font->width; i++) {
                        // if bit set, we use white color, otherwise black
                        *((unsigned int *)(fb + line)) = ((int)*glyph) & mask ? 0xFFFFFF : 0;
                        mask >>= 1;
                        line += 4;
                    }
                    // adjust to next line
                    glyph += bytesperline;
                    offs += pitch;
                }
                *x += (font->width + 1);
            }
        // next character
        s++;
    }
}

#include "uvalogo.h"    // stored pixel data
#define IMG_DATA header_data      
#define IMG_HEIGHT height
#define IMG_WIDTH width

void fb_showpicture()
{
    int x, y;
    unsigned char *ptr = the_fb.fb;       // pointer to framebuffer memory
    char *data = IMG_DATA, pixel[4];      // source image data (RGB)
    char res[16];

    // crop image to fit framebuffer
    unsigned int img_fb_height = the_fb.vheight < IMG_HEIGHT ? the_fb.vheight : IMG_HEIGHT; 
    unsigned int img_fb_width  = the_fb.vwidth  < IMG_WIDTH  ? the_fb.vwidth  : IMG_WIDTH; 

    // top-center starting point in framebuffer
    ptr += ((the_fb.vwidth - img_fb_width)/2) * PIXELSIZE;  
    ptr += ((the_fb.vheight - img_fb_height)/2) * the_fb.pitch;

    // copy pixels from image data into framebuffer
    for(y = 0; y < img_fb_height; y++) {
        unsigned char *line_ptr = ptr;  // start of current framebuffer line
        for(x = 0; x < img_fb_width; x++) {
            HEADER_PIXEL(data, pixel);  // read next pixel from IMG_DATA into pixel[3]

            if(the_fb.isrgb) {
                // framebuffer expects RGB, copy as-is
                line_ptr[0] = pixel[0];  // R
                line_ptr[1] = pixel[1];  // G
                line_ptr[2] = pixel[2];  // B
            } else {
                // framebuffer expects BGR, swap R and B
                line_ptr[0] = pixel[2];  // B
                line_ptr[1] = pixel[1];  // G
                line_ptr[2] = pixel[0];  // R
            }
            line_ptr[3] = 0;           // alpha / padding
            line_ptr += PIXELSIZE;
        }
        // move framebuffer pointer to start of next line
        ptr += the_fb.pitch;
    }

    // show text strings below the image
    x = (the_fb.vwidth - img_fb_width)/2;           // start x below the image
    y = (the_fb.vheight - img_fb_height)/2 + img_fb_height + 4; // some padding
    fb_print(&x, &y, "TAHSIN OS");    
    sprintf(res, " %dx%d", the_fb.width, the_fb.height); // debug info 
    fb_print(&x, &y, res);
}


/*
 * Copyright (C) 2018 bzt (bztsrc@github)
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use, copy,
 * modify, merge, publish, distribute, sublicense, and/or sell copies
 * of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 *
 */


/*
    References:
    1. Raspberry Pi Mailboxes: 
    https://github.com/raspberrypi/firmware/wiki/Mailboxes
    2. RT-Thread driver for Raspberry Pi:
    https://github.com/RT-Thread/rt-thread/blob/master/bsp/raspberry-pi/raspi3-64/driver/mbox.c
    3. Bare-metal programming for Raspberry Pi:
    https://www.valvers.com/open-software/raspberry-pi/bare-metal-programming-in-c-part-5/#part-5armc-016
    4. U-Boot mailbox implementation:
    uboot arch/arm/mach-bcm283x/msg.c

    For `do_fb_init()`:

    - Additional undocumented details:
    https://github.com/raspberrypi/firmware/issues/719

    - This implementation uses the mailbox "property channel." 
    Alternatively, the "fb" channel can be used directly:
    https://github.com/rsta2/circle/blob/master/lib/bcmframebuffer.cpp

    - Example code:
    https://github.com/RT-Thread/rt-thread/blob/master/bsp/raspberry-pi/raspi3-64/driver/mbox.c
*/
