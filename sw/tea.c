#include <stdio.h>
#include <stdint.h>
#define ROUND 5
void tinyenc (uint16_t* dat, uint16_t* key) {
  uint16_t x = dat[0];
  uint16_t y = dat[1];
  uint16_t delta = 0x9E37;
  uint16_t sum = 0;
  uint8_t i;
  for(i=0;i<ROUND;i++){
    sum += delta;
    x += ((y << 4) + key[0]) ^ (y + sum) ^ ((y >> 5) + key[1]);
    y += ((x << 4) + key[2]) ^ (x + sum) ^ ((x >> 5) + key[3]);
    printf("sum = %x\n", sum);
  }
  dat[0] = x;
  dat[1] = y;
}
void tinydec (uint16_t* dat, uint16_t* key) {
  uint16_t x = dat[0];
  uint16_t y = dat[1];
  uint16_t delta = 0x9E37;
  uint16_t sum = delta * ROUND;
  uint8_t i;
  for(i=0;i<ROUND;i++){
    y -= ((x << 4) + key[2]) ^ (x + sum) ^ ((x >> 5) + key[3]);
    x -= ((y << 4) + key[0]) ^ (y + sum) ^ ((y >> 5) + key[1]);
    sum -= delta;
    printf("sum = %x\n", sum);
  }
  dat[0] = x;
  dat[1] = y;
}
int main () {
  uint16_t dat[3] = {0x4443,0x4241,0x0};
  uint16_t key[4] = {0x1234,0x5678,0x9ABC,0xDEF1};
  printf("plain = %s\n", (char*)dat);
  tinyenc(dat,key);
  printf("ciper = %lx , %s\n", *(uint64_t*)dat, (char*)dat);
  tinydec(dat,key);
  printf("plain = %s\n", (char*)dat);
  return 0;
}
