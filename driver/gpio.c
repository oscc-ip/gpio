#include <am.h>
#include <klib.h>
#include <klib-macros.h>

#define GPIO_BASE_ADDR    0x10004000
#define GPIO_REG_PADDIR   *((volatile uint32_t *)(GPIO_BASE_ADDR))
#define GPIO_REG_PADIN    *((volatile uint32_t *)(GPIO_BASE_ADDR + 4))
#define GPIO_REG_PADOUT   *((volatile uint32_t *)(GPIO_BASE_ADDR + 8))
#define GPIO_REG_INTEN    *((volatile uint32_t *)(GPIO_BASE_ADDR + 12))
#define GPIO_REG_INTTYPE0 *((volatile uint32_t *)(GPIO_BASE_ADDR + 16))
#define GPIO_REG_INTTYPE1 *((volatile uint32_t *)(GPIO_BASE_ADDR + 20))
#define GPIO_REG_INTSTAT  *((volatile uint32_t *)(GPIO_BASE_ADDR + 24))
#define GPIO_REG_IOFCFG   *((volatile uint32_t *)(GPIO_BASE_ADDR + 28))

#define TIMER_BASE_ADDR   0x10005000
#define TIMER_REG_CTRL    *((volatile uint32_t *)(TIMER_BASE_ADDR + 0))
#define TIMER_REG_PSCR    *((volatile uint32_t *)(TIMER_BASE_ADDR + 4))
#define TIMER_REG_CNT     *((volatile uint32_t *)(TIMER_BASE_ADDR + 8))
#define TIMER_REG_CMP     *((volatile uint32_t *)(TIMER_BASE_ADDR + 12))
#define TIMER_REG_STAT    *((volatile uint32_t *)(TIMER_BASE_ADDR + 16))

// gpio[0] for ouput, gpio[1] for input
void gpio_init() {
    GPIO_REG_PADDIR = (uint32_t)0b10;
    GPIO_REG_PADOUT = (uint32_t)0b01;
}

void timer_init() {
    TIMER_REG_CTRL = (uint32_t)0x0;
    while(TIMER_REG_STAT == 1);           // clear irq
    TIMER_REG_CMP  = (uint32_t)(50000-1); // 50MHz for 1ms
}

void delay_ms(uint32_t val) {
    TIMER_REG_CTRL = (uint32_t)0xD;
    for(int i = 1; i <= val; ++i) {
        while(TIMER_REG_STAT == 0);
    }
    TIMER_REG_CTRL = (uint32_t)0x0;
}

int main(){
    putstr("gpio test\n");
    putstr("led output test\n");

    gpio_init();
    timer_init();
    for(int i = 0; i < 20; ++i) {
        delay_ms(300);
        if(GPIO_REG_PADOUT == 0b00) GPIO_REG_PADOUT = (uint32_t)0b01;
        else GPIO_REG_PADOUT = (uint32_t)0b00;
    }

    putstr("key input test\n"); // need extn board
    while(1) {
        if(((GPIO_REG_PADIN & 0b10) >> 1) == 0b0) {
            delay_ms(100);  // debouncing
            if(((GPIO_REG_PADIN & 0b10) >> 1) == 0b0) {
                putstr("key detect\n");
                if(GPIO_REG_PADOUT == 0b00) GPIO_REG_PADOUT = (uint32_t)0b01;
                else GPIO_REG_PADOUT = (uint32_t)0b00;
            }
        }
    }

    return 0;
}
