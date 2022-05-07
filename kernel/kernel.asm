
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8f013103          	ld	sp,-1808(sp) # 800088f0 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	5dc78793          	addi	a5,a5,1500 # 80006640 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	de078793          	addi	a5,a5,-544 # 80000e8e <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00003097          	auipc	ra,0x3
    80000130:	9f0080e7          	jalr	-1552(ra) # 80002b1c <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	78e080e7          	jalr	1934(ra) # 800008ca <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	ff450513          	addi	a0,a0,-12 # 80011180 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	fe448493          	addi	s1,s1,-28 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      //printf("enter sleep console\n");
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	07290913          	addi	s2,s2,114 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405863          	blez	s4,80000224 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71463          	bne	a4,a5,800001e8 <consoleread+0x84>
      if(myproc()->killed){
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	c9a080e7          	jalr	-870(ra) # 80001e5e <myproc>
    800001cc:	413c                	lw	a5,64(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	3a6080e7          	jalr	934(ra) # 8000257a <sleep>
    while(cons.r == cons.w){
    800001dc:	0984a783          	lw	a5,152(s1)
    800001e0:	09c4a703          	lw	a4,156(s1)
    800001e4:	fef700e3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e8:	0017871b          	addiw	a4,a5,1
    800001ec:	08e4ac23          	sw	a4,152(s1)
    800001f0:	07f7f713          	andi	a4,a5,127
    800001f4:	9726                	add	a4,a4,s1
    800001f6:	01874703          	lbu	a4,24(a4)
    800001fa:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    800001fe:	079c0663          	beq	s8,s9,8000026a <consoleread+0x106>
    cbuf = c;
    80000202:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	f8f40613          	addi	a2,s0,-113
    8000020c:	85d6                	mv	a1,s5
    8000020e:	855a                	mv	a0,s6
    80000210:	00003097          	auipc	ra,0x3
    80000214:	8b6080e7          	jalr	-1866(ra) # 80002ac6 <either_copyout>
    80000218:	01a50663          	beq	a0,s10,80000224 <consoleread+0xc0>
    dst++;
    8000021c:	0a85                	addi	s5,s5,1
    --n;
    8000021e:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000220:	f9bc1ae3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000224:	00011517          	auipc	a0,0x11
    80000228:	f5c50513          	addi	a0,a0,-164 # 80011180 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00011517          	auipc	a0,0x11
    8000023e:	f4650513          	addi	a0,a0,-186 # 80011180 <cons>
    80000242:	00001097          	auipc	ra,0x1
    80000246:	a56080e7          	jalr	-1450(ra) # 80000c98 <release>
        return -1;
    8000024a:	557d                	li	a0,-1
}
    8000024c:	70e6                	ld	ra,120(sp)
    8000024e:	7446                	ld	s0,112(sp)
    80000250:	74a6                	ld	s1,104(sp)
    80000252:	7906                	ld	s2,96(sp)
    80000254:	69e6                	ld	s3,88(sp)
    80000256:	6a46                	ld	s4,80(sp)
    80000258:	6aa6                	ld	s5,72(sp)
    8000025a:	6b06                	ld	s6,64(sp)
    8000025c:	7be2                	ld	s7,56(sp)
    8000025e:	7c42                	ld	s8,48(sp)
    80000260:	7ca2                	ld	s9,40(sp)
    80000262:	7d02                	ld	s10,32(sp)
    80000264:	6de2                	ld	s11,24(sp)
    80000266:	6109                	addi	sp,sp,128
    80000268:	8082                	ret
      if(n < target){
    8000026a:	000a071b          	sext.w	a4,s4
    8000026e:	fb777be3          	bgeu	a4,s7,80000224 <consoleread+0xc0>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	faf72323          	sw	a5,-90(a4) # 80011218 <cons+0x98>
    8000027a:	b76d                	j	80000224 <consoleread+0xc0>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	564080e7          	jalr	1380(ra) # 800007f0 <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	552080e7          	jalr	1362(ra) # 800007f0 <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	546080e7          	jalr	1350(ra) # 800007f0 <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	53c080e7          	jalr	1340(ra) # 800007f0 <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	eb450513          	addi	a0,a0,-332 # 80011180 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	910080e7          	jalr	-1776(ra) # 80000be4 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00003097          	auipc	ra,0x3
    800002f6:	880080e7          	jalr	-1920(ra) # 80002b72 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	e8650513          	addi	a0,a0,-378 # 80011180 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	996080e7          	jalr	-1642(ra) # 80000c98 <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	e6270713          	addi	a4,a4,-414 # 80011180 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	e3878793          	addi	a5,a5,-456 # 80011180 <cons>
    80000350:	0a07a703          	lw	a4,160(a5)
    80000354:	0017069b          	addiw	a3,a4,1
    80000358:	0006861b          	sext.w	a2,a3
    8000035c:	0ad7a023          	sw	a3,160(a5)
    80000360:	07f77713          	andi	a4,a4,127
    80000364:	97ba                	add	a5,a5,a4
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	ea27a783          	lw	a5,-350(a5) # 80011218 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	df670713          	addi	a4,a4,-522 # 80011180 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	de648493          	addi	s1,s1,-538 # 80011180 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	daa70713          	addi	a4,a4,-598 # 80011180 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	e2f72a23          	sw	a5,-460(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000412:	00011797          	auipc	a5,0x11
    80000416:	d6e78793          	addi	a5,a5,-658 # 80011180 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	dec7a323          	sw	a2,-538(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	dda50513          	addi	a0,a0,-550 # 80011218 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	2d6080e7          	jalr	726(ra) # 8000271c <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <current_cpu_number+0x8>
    80000460:	00011517          	auipc	a0,0x11
    80000464:	d2050513          	addi	a0,a0,-736 # 80011180 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00022797          	auipc	a5,0x22
    8000047c:	99078793          	addi	a5,a5,-1648 # 80021e08 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00011797          	auipc	a5,0x11
    8000054e:	ce07ab23          	sw	zero,-778(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <current_cpu_number+0x10>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	d8450513          	addi	a0,a0,-636 # 800082f0 <digits+0x2b0>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00009717          	auipc	a4,0x9
    80000582:	a8f72123          	sw	a5,-1406(a4) # 80009000 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00011d97          	auipc	s11,0x11
    800005be:	c86dad83          	lw	s11,-890(s11) # 80011240 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	16050263          	beqz	a0,8000073a <printf+0x1b2>
    800005da:	4481                	li	s1,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b13          	li	s6,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b97          	auipc	s7,0x8
    800005ea:	a5ab8b93          	addi	s7,s7,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00011517          	auipc	a0,0x11
    800005fc:	c3050513          	addi	a0,a0,-976 # 80011228 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5e4080e7          	jalr	1508(ra) # 80000be4 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <current_cpu_number+0x20>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2485                	addiw	s1,s1,1
    80000624:	009a07b3          	add	a5,s4,s1
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050763          	beqz	a0,8000073a <printf+0x1b2>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2485                	addiw	s1,s1,1
    80000636:	009a07b3          	add	a5,s4,s1
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000642:	cfe5                	beqz	a5,8000073a <printf+0x1b2>
    switch(c){
    80000644:	05678a63          	beq	a5,s6,80000698 <printf+0x110>
    80000648:	02fb7663          	bgeu	s6,a5,80000674 <printf+0xec>
    8000064c:	09978963          	beq	a5,s9,800006de <printf+0x156>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79863          	bne	a5,a4,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	0b578263          	beq	a5,s5,80000718 <printf+0x190>
    80000678:	0b879663          	bne	a5,s8,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c9d793          	srli	a5,s3,0x3c
    800006c6:	97de                	add	a5,a5,s7
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0992                	slli	s3,s3,0x4
    800006d6:	397d                	addiw	s2,s2,-1
    800006d8:	fe0915e3          	bnez	s2,800006c2 <printf+0x13a>
    800006dc:	b799                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	0007b903          	ld	s2,0(a5)
    800006ee:	00090e63          	beqz	s2,8000070a <printf+0x182>
      for(; *s; s++)
    800006f2:	00094503          	lbu	a0,0(s2)
    800006f6:	d515                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f8:	00000097          	auipc	ra,0x0
    800006fc:	b84080e7          	jalr	-1148(ra) # 8000027c <consputc>
      for(; *s; s++)
    80000700:	0905                	addi	s2,s2,1
    80000702:	00094503          	lbu	a0,0(s2)
    80000706:	f96d                	bnez	a0,800006f8 <printf+0x170>
    80000708:	bf29                	j	80000622 <printf+0x9a>
        s = "(null)";
    8000070a:	00008917          	auipc	s2,0x8
    8000070e:	91690913          	addi	s2,s2,-1770 # 80008020 <current_cpu_number+0x18>
      for(; *s; s++)
    80000712:	02800513          	li	a0,40
    80000716:	b7cd                	j	800006f8 <printf+0x170>
      consputc('%');
    80000718:	8556                	mv	a0,s5
    8000071a:	00000097          	auipc	ra,0x0
    8000071e:	b62080e7          	jalr	-1182(ra) # 8000027c <consputc>
      break;
    80000722:	b701                	j	80000622 <printf+0x9a>
      consputc('%');
    80000724:	8556                	mv	a0,s5
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b56080e7          	jalr	-1194(ra) # 8000027c <consputc>
      consputc(c);
    8000072e:	854a                	mv	a0,s2
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b4c080e7          	jalr	-1204(ra) # 8000027c <consputc>
      break;
    80000738:	b5ed                	j	80000622 <printf+0x9a>
  if(locking)
    8000073a:	020d9163          	bnez	s11,8000075c <printf+0x1d4>
}
    8000073e:	70e6                	ld	ra,120(sp)
    80000740:	7446                	ld	s0,112(sp)
    80000742:	74a6                	ld	s1,104(sp)
    80000744:	7906                	ld	s2,96(sp)
    80000746:	69e6                	ld	s3,88(sp)
    80000748:	6a46                	ld	s4,80(sp)
    8000074a:	6aa6                	ld	s5,72(sp)
    8000074c:	6b06                	ld	s6,64(sp)
    8000074e:	7be2                	ld	s7,56(sp)
    80000750:	7c42                	ld	s8,48(sp)
    80000752:	7ca2                	ld	s9,40(sp)
    80000754:	7d02                	ld	s10,32(sp)
    80000756:	6de2                	ld	s11,24(sp)
    80000758:	6129                	addi	sp,sp,192
    8000075a:	8082                	ret
    release(&pr.lock);
    8000075c:	00011517          	auipc	a0,0x11
    80000760:	acc50513          	addi	a0,a0,-1332 # 80011228 <pr>
    80000764:	00000097          	auipc	ra,0x0
    80000768:	534080e7          	jalr	1332(ra) # 80000c98 <release>
}
    8000076c:	bfc9                	j	8000073e <printf+0x1b6>

000000008000076e <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076e:	1101                	addi	sp,sp,-32
    80000770:	ec06                	sd	ra,24(sp)
    80000772:	e822                	sd	s0,16(sp)
    80000774:	e426                	sd	s1,8(sp)
    80000776:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000778:	00011497          	auipc	s1,0x11
    8000077c:	ab048493          	addi	s1,s1,-1360 # 80011228 <pr>
    80000780:	00008597          	auipc	a1,0x8
    80000784:	8b858593          	addi	a1,a1,-1864 # 80008038 <current_cpu_number+0x30>
    80000788:	8526                	mv	a0,s1
    8000078a:	00000097          	auipc	ra,0x0
    8000078e:	3ca080e7          	jalr	970(ra) # 80000b54 <initlock>
  pr.locking = 1;
    80000792:	4785                	li	a5,1
    80000794:	cc9c                	sw	a5,24(s1)
}
    80000796:	60e2                	ld	ra,24(sp)
    80000798:	6442                	ld	s0,16(sp)
    8000079a:	64a2                	ld	s1,8(sp)
    8000079c:	6105                	addi	sp,sp,32
    8000079e:	8082                	ret

00000000800007a0 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a0:	1141                	addi	sp,sp,-16
    800007a2:	e406                	sd	ra,8(sp)
    800007a4:	e022                	sd	s0,0(sp)
    800007a6:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a8:	100007b7          	lui	a5,0x10000
    800007ac:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b0:	f8000713          	li	a4,-128
    800007b4:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b8:	470d                	li	a4,3
    800007ba:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007be:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c2:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c6:	469d                	li	a3,7
    800007c8:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007cc:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d0:	00008597          	auipc	a1,0x8
    800007d4:	88858593          	addi	a1,a1,-1912 # 80008058 <digits+0x18>
    800007d8:	00011517          	auipc	a0,0x11
    800007dc:	a7050513          	addi	a0,a0,-1424 # 80011248 <uart_tx_lock>
    800007e0:	00000097          	auipc	ra,0x0
    800007e4:	374080e7          	jalr	884(ra) # 80000b54 <initlock>
}
    800007e8:	60a2                	ld	ra,8(sp)
    800007ea:	6402                	ld	s0,0(sp)
    800007ec:	0141                	addi	sp,sp,16
    800007ee:	8082                	ret

00000000800007f0 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f0:	1101                	addi	sp,sp,-32
    800007f2:	ec06                	sd	ra,24(sp)
    800007f4:	e822                	sd	s0,16(sp)
    800007f6:	e426                	sd	s1,8(sp)
    800007f8:	1000                	addi	s0,sp,32
    800007fa:	84aa                	mv	s1,a0
  push_off();
    800007fc:	00000097          	auipc	ra,0x0
    80000800:	39c080e7          	jalr	924(ra) # 80000b98 <push_off>

  if(panicked){
    80000804:	00008797          	auipc	a5,0x8
    80000808:	7fc7a783          	lw	a5,2044(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080c:	10000737          	lui	a4,0x10000
  if(panicked){
    80000810:	c391                	beqz	a5,80000814 <uartputc_sync+0x24>
    for(;;)
    80000812:	a001                	j	80000812 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000814:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000818:	0ff7f793          	andi	a5,a5,255
    8000081c:	0207f793          	andi	a5,a5,32
    80000820:	dbf5                	beqz	a5,80000814 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000822:	0ff4f793          	andi	a5,s1,255
    80000826:	10000737          	lui	a4,0x10000
    8000082a:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    8000082e:	00000097          	auipc	ra,0x0
    80000832:	40a080e7          	jalr	1034(ra) # 80000c38 <pop_off>
}
    80000836:	60e2                	ld	ra,24(sp)
    80000838:	6442                	ld	s0,16(sp)
    8000083a:	64a2                	ld	s1,8(sp)
    8000083c:	6105                	addi	sp,sp,32
    8000083e:	8082                	ret

0000000080000840 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000840:	00008717          	auipc	a4,0x8
    80000844:	7c873703          	ld	a4,1992(a4) # 80009008 <uart_tx_r>
    80000848:	00008797          	auipc	a5,0x8
    8000084c:	7c87b783          	ld	a5,1992(a5) # 80009010 <uart_tx_w>
    80000850:	06e78c63          	beq	a5,a4,800008c8 <uartstart+0x88>
{
    80000854:	7139                	addi	sp,sp,-64
    80000856:	fc06                	sd	ra,56(sp)
    80000858:	f822                	sd	s0,48(sp)
    8000085a:	f426                	sd	s1,40(sp)
    8000085c:	f04a                	sd	s2,32(sp)
    8000085e:	ec4e                	sd	s3,24(sp)
    80000860:	e852                	sd	s4,16(sp)
    80000862:	e456                	sd	s5,8(sp)
    80000864:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000866:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086a:	00011a17          	auipc	s4,0x11
    8000086e:	9dea0a13          	addi	s4,s4,-1570 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000872:	00008497          	auipc	s1,0x8
    80000876:	79648493          	addi	s1,s1,1942 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000087a:	00008997          	auipc	s3,0x8
    8000087e:	79698993          	addi	s3,s3,1942 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000882:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000886:	0ff7f793          	andi	a5,a5,255
    8000088a:	0207f793          	andi	a5,a5,32
    8000088e:	c785                	beqz	a5,800008b6 <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000890:	01f77793          	andi	a5,a4,31
    80000894:	97d2                	add	a5,a5,s4
    80000896:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    8000089a:	0705                	addi	a4,a4,1
    8000089c:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000089e:	8526                	mv	a0,s1
    800008a0:	00002097          	auipc	ra,0x2
    800008a4:	e7c080e7          	jalr	-388(ra) # 8000271c <wakeup>
    
    WriteReg(THR, c);
    800008a8:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ac:	6098                	ld	a4,0(s1)
    800008ae:	0009b783          	ld	a5,0(s3)
    800008b2:	fce798e3          	bne	a5,a4,80000882 <uartstart+0x42>
  }
}
    800008b6:	70e2                	ld	ra,56(sp)
    800008b8:	7442                	ld	s0,48(sp)
    800008ba:	74a2                	ld	s1,40(sp)
    800008bc:	7902                	ld	s2,32(sp)
    800008be:	69e2                	ld	s3,24(sp)
    800008c0:	6a42                	ld	s4,16(sp)
    800008c2:	6aa2                	ld	s5,8(sp)
    800008c4:	6121                	addi	sp,sp,64
    800008c6:	8082                	ret
    800008c8:	8082                	ret

00000000800008ca <uartputc>:
{
    800008ca:	7179                	addi	sp,sp,-48
    800008cc:	f406                	sd	ra,40(sp)
    800008ce:	f022                	sd	s0,32(sp)
    800008d0:	ec26                	sd	s1,24(sp)
    800008d2:	e84a                	sd	s2,16(sp)
    800008d4:	e44e                	sd	s3,8(sp)
    800008d6:	e052                	sd	s4,0(sp)
    800008d8:	1800                	addi	s0,sp,48
    800008da:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008dc:	00011517          	auipc	a0,0x11
    800008e0:	96c50513          	addi	a0,a0,-1684 # 80011248 <uart_tx_lock>
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	300080e7          	jalr	768(ra) # 80000be4 <acquire>
  if(panicked){
    800008ec:	00008797          	auipc	a5,0x8
    800008f0:	7147a783          	lw	a5,1812(a5) # 80009000 <panicked>
    800008f4:	c391                	beqz	a5,800008f8 <uartputc+0x2e>
    for(;;)
    800008f6:	a001                	j	800008f6 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	00008797          	auipc	a5,0x8
    800008fc:	7187b783          	ld	a5,1816(a5) # 80009010 <uart_tx_w>
    80000900:	00008717          	auipc	a4,0x8
    80000904:	70873703          	ld	a4,1800(a4) # 80009008 <uart_tx_r>
    80000908:	02070713          	addi	a4,a4,32
    8000090c:	02f71b63          	bne	a4,a5,80000942 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00011a17          	auipc	s4,0x11
    80000914:	938a0a13          	addi	s4,s4,-1736 # 80011248 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	c4e080e7          	jalr	-946(ra) # 8000257a <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00011497          	auipc	s1,0x11
    80000946:	90648493          	addi	s1,s1,-1786 # 80011248 <uart_tx_lock>
    8000094a:	01f7f713          	andi	a4,a5,31
    8000094e:	9726                	add	a4,a4,s1
    80000950:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000954:	0785                	addi	a5,a5,1
    80000956:	00008717          	auipc	a4,0x8
    8000095a:	6af73d23          	sd	a5,1722(a4) # 80009010 <uart_tx_w>
      uartstart();
    8000095e:	00000097          	auipc	ra,0x0
    80000962:	ee2080e7          	jalr	-286(ra) # 80000840 <uartstart>
      release(&uart_tx_lock);
    80000966:	8526                	mv	a0,s1
    80000968:	00000097          	auipc	ra,0x0
    8000096c:	330080e7          	jalr	816(ra) # 80000c98 <release>
}
    80000970:	70a2                	ld	ra,40(sp)
    80000972:	7402                	ld	s0,32(sp)
    80000974:	64e2                	ld	s1,24(sp)
    80000976:	6942                	ld	s2,16(sp)
    80000978:	69a2                	ld	s3,8(sp)
    8000097a:	6a02                	ld	s4,0(sp)
    8000097c:	6145                	addi	sp,sp,48
    8000097e:	8082                	ret

0000000080000980 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000980:	1141                	addi	sp,sp,-16
    80000982:	e422                	sd	s0,8(sp)
    80000984:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000098e:	8b85                	andi	a5,a5,1
    80000990:	cb91                	beqz	a5,800009a4 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000992:	100007b7          	lui	a5,0x10000
    80000996:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000099a:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000099e:	6422                	ld	s0,8(sp)
    800009a0:	0141                	addi	sp,sp,16
    800009a2:	8082                	ret
    return -1;
    800009a4:	557d                	li	a0,-1
    800009a6:	bfe5                	j	8000099e <uartgetc+0x1e>

00000000800009a8 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009a8:	1101                	addi	sp,sp,-32
    800009aa:	ec06                	sd	ra,24(sp)
    800009ac:	e822                	sd	s0,16(sp)
    800009ae:	e426                	sd	s1,8(sp)
    800009b0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b2:	54fd                	li	s1,-1
    int c = uartgetc();
    800009b4:	00000097          	auipc	ra,0x0
    800009b8:	fcc080e7          	jalr	-52(ra) # 80000980 <uartgetc>
    if(c == -1)
    800009bc:	00950763          	beq	a0,s1,800009ca <uartintr+0x22>
      break;
    consoleintr(c);
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	8fe080e7          	jalr	-1794(ra) # 800002be <consoleintr>
  while(1){
    800009c8:	b7f5                	j	800009b4 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ca:	00011497          	auipc	s1,0x11
    800009ce:	87e48493          	addi	s1,s1,-1922 # 80011248 <uart_tx_lock>
    800009d2:	8526                	mv	a0,s1
    800009d4:	00000097          	auipc	ra,0x0
    800009d8:	210080e7          	jalr	528(ra) # 80000be4 <acquire>
  uartstart();
    800009dc:	00000097          	auipc	ra,0x0
    800009e0:	e64080e7          	jalr	-412(ra) # 80000840 <uartstart>
  release(&uart_tx_lock);
    800009e4:	8526                	mv	a0,s1
    800009e6:	00000097          	auipc	ra,0x0
    800009ea:	2b2080e7          	jalr	690(ra) # 80000c98 <release>
}
    800009ee:	60e2                	ld	ra,24(sp)
    800009f0:	6442                	ld	s0,16(sp)
    800009f2:	64a2                	ld	s1,8(sp)
    800009f4:	6105                	addi	sp,sp,32
    800009f6:	8082                	ret

00000000800009f8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009f8:	1101                	addi	sp,sp,-32
    800009fa:	ec06                	sd	ra,24(sp)
    800009fc:	e822                	sd	s0,16(sp)
    800009fe:	e426                	sd	s1,8(sp)
    80000a00:	e04a                	sd	s2,0(sp)
    80000a02:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a04:	03451793          	slli	a5,a0,0x34
    80000a08:	ebb9                	bnez	a5,80000a5e <kfree+0x66>
    80000a0a:	84aa                	mv	s1,a0
    80000a0c:	00025797          	auipc	a5,0x25
    80000a10:	5f478793          	addi	a5,a5,1524 # 80026000 <end>
    80000a14:	04f56563          	bltu	a0,a5,80000a5e <kfree+0x66>
    80000a18:	47c5                	li	a5,17
    80000a1a:	07ee                	slli	a5,a5,0x1b
    80000a1c:	04f57163          	bgeu	a0,a5,80000a5e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a20:	6605                	lui	a2,0x1
    80000a22:	4585                	li	a1,1
    80000a24:	00000097          	auipc	ra,0x0
    80000a28:	2bc080e7          	jalr	700(ra) # 80000ce0 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a2c:	00011917          	auipc	s2,0x11
    80000a30:	85490913          	addi	s2,s2,-1964 # 80011280 <kmem>
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	1ae080e7          	jalr	430(ra) # 80000be4 <acquire>
  r->next = kmem.freelist;
    80000a3e:	01893783          	ld	a5,24(s2)
    80000a42:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a44:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a48:	854a                	mv	a0,s2
    80000a4a:	00000097          	auipc	ra,0x0
    80000a4e:	24e080e7          	jalr	590(ra) # 80000c98 <release>
}
    80000a52:	60e2                	ld	ra,24(sp)
    80000a54:	6442                	ld	s0,16(sp)
    80000a56:	64a2                	ld	s1,8(sp)
    80000a58:	6902                	ld	s2,0(sp)
    80000a5a:	6105                	addi	sp,sp,32
    80000a5c:	8082                	ret
    panic("kfree");
    80000a5e:	00007517          	auipc	a0,0x7
    80000a62:	60250513          	addi	a0,a0,1538 # 80008060 <digits+0x20>
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	ad8080e7          	jalr	-1320(ra) # 8000053e <panic>

0000000080000a6e <freerange>:
{
    80000a6e:	7179                	addi	sp,sp,-48
    80000a70:	f406                	sd	ra,40(sp)
    80000a72:	f022                	sd	s0,32(sp)
    80000a74:	ec26                	sd	s1,24(sp)
    80000a76:	e84a                	sd	s2,16(sp)
    80000a78:	e44e                	sd	s3,8(sp)
    80000a7a:	e052                	sd	s4,0(sp)
    80000a7c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a7e:	6785                	lui	a5,0x1
    80000a80:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a84:	94aa                	add	s1,s1,a0
    80000a86:	757d                	lui	a0,0xfffff
    80000a88:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8a:	94be                	add	s1,s1,a5
    80000a8c:	0095ee63          	bltu	a1,s1,80000aa8 <freerange+0x3a>
    80000a90:	892e                	mv	s2,a1
    kfree(p);
    80000a92:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	6985                	lui	s3,0x1
    kfree(p);
    80000a96:	01448533          	add	a0,s1,s4
    80000a9a:	00000097          	auipc	ra,0x0
    80000a9e:	f5e080e7          	jalr	-162(ra) # 800009f8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa2:	94ce                	add	s1,s1,s3
    80000aa4:	fe9979e3          	bgeu	s2,s1,80000a96 <freerange+0x28>
}
    80000aa8:	70a2                	ld	ra,40(sp)
    80000aaa:	7402                	ld	s0,32(sp)
    80000aac:	64e2                	ld	s1,24(sp)
    80000aae:	6942                	ld	s2,16(sp)
    80000ab0:	69a2                	ld	s3,8(sp)
    80000ab2:	6a02                	ld	s4,0(sp)
    80000ab4:	6145                	addi	sp,sp,48
    80000ab6:	8082                	ret

0000000080000ab8 <kinit>:
{
    80000ab8:	1141                	addi	sp,sp,-16
    80000aba:	e406                	sd	ra,8(sp)
    80000abc:	e022                	sd	s0,0(sp)
    80000abe:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac0:	00007597          	auipc	a1,0x7
    80000ac4:	5a858593          	addi	a1,a1,1448 # 80008068 <digits+0x28>
    80000ac8:	00010517          	auipc	a0,0x10
    80000acc:	7b850513          	addi	a0,a0,1976 # 80011280 <kmem>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	084080e7          	jalr	132(ra) # 80000b54 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ad8:	45c5                	li	a1,17
    80000ada:	05ee                	slli	a1,a1,0x1b
    80000adc:	00025517          	auipc	a0,0x25
    80000ae0:	52450513          	addi	a0,a0,1316 # 80026000 <end>
    80000ae4:	00000097          	auipc	ra,0x0
    80000ae8:	f8a080e7          	jalr	-118(ra) # 80000a6e <freerange>
}
    80000aec:	60a2                	ld	ra,8(sp)
    80000aee:	6402                	ld	s0,0(sp)
    80000af0:	0141                	addi	sp,sp,16
    80000af2:	8082                	ret

0000000080000af4 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000af4:	1101                	addi	sp,sp,-32
    80000af6:	ec06                	sd	ra,24(sp)
    80000af8:	e822                	sd	s0,16(sp)
    80000afa:	e426                	sd	s1,8(sp)
    80000afc:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000afe:	00010497          	auipc	s1,0x10
    80000b02:	78248493          	addi	s1,s1,1922 # 80011280 <kmem>
    80000b06:	8526                	mv	a0,s1
    80000b08:	00000097          	auipc	ra,0x0
    80000b0c:	0dc080e7          	jalr	220(ra) # 80000be4 <acquire>
  r = kmem.freelist;
    80000b10:	6c84                	ld	s1,24(s1)
  if(r)
    80000b12:	c885                	beqz	s1,80000b42 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b14:	609c                	ld	a5,0(s1)
    80000b16:	00010517          	auipc	a0,0x10
    80000b1a:	76a50513          	addi	a0,a0,1898 # 80011280 <kmem>
    80000b1e:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	178080e7          	jalr	376(ra) # 80000c98 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b28:	6605                	lui	a2,0x1
    80000b2a:	4595                	li	a1,5
    80000b2c:	8526                	mv	a0,s1
    80000b2e:	00000097          	auipc	ra,0x0
    80000b32:	1b2080e7          	jalr	434(ra) # 80000ce0 <memset>
  return (void*)r;
}
    80000b36:	8526                	mv	a0,s1
    80000b38:	60e2                	ld	ra,24(sp)
    80000b3a:	6442                	ld	s0,16(sp)
    80000b3c:	64a2                	ld	s1,8(sp)
    80000b3e:	6105                	addi	sp,sp,32
    80000b40:	8082                	ret
  release(&kmem.lock);
    80000b42:	00010517          	auipc	a0,0x10
    80000b46:	73e50513          	addi	a0,a0,1854 # 80011280 <kmem>
    80000b4a:	00000097          	auipc	ra,0x0
    80000b4e:	14e080e7          	jalr	334(ra) # 80000c98 <release>
  if(r)
    80000b52:	b7d5                	j	80000b36 <kalloc+0x42>

0000000080000b54 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b54:	1141                	addi	sp,sp,-16
    80000b56:	e422                	sd	s0,8(sp)
    80000b58:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b5a:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b5c:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b60:	00053823          	sd	zero,16(a0)
}
    80000b64:	6422                	ld	s0,8(sp)
    80000b66:	0141                	addi	sp,sp,16
    80000b68:	8082                	ret

0000000080000b6a <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b6a:	411c                	lw	a5,0(a0)
    80000b6c:	e399                	bnez	a5,80000b72 <holding+0x8>
    80000b6e:	4501                	li	a0,0
  return r;
}
    80000b70:	8082                	ret
{
    80000b72:	1101                	addi	sp,sp,-32
    80000b74:	ec06                	sd	ra,24(sp)
    80000b76:	e822                	sd	s0,16(sp)
    80000b78:	e426                	sd	s1,8(sp)
    80000b7a:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b7c:	6904                	ld	s1,16(a0)
    80000b7e:	00001097          	auipc	ra,0x1
    80000b82:	2c4080e7          	jalr	708(ra) # 80001e42 <mycpu>
    80000b86:	40a48533          	sub	a0,s1,a0
    80000b8a:	00153513          	seqz	a0,a0
}
    80000b8e:	60e2                	ld	ra,24(sp)
    80000b90:	6442                	ld	s0,16(sp)
    80000b92:	64a2                	ld	s1,8(sp)
    80000b94:	6105                	addi	sp,sp,32
    80000b96:	8082                	ret

0000000080000b98 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b98:	1101                	addi	sp,sp,-32
    80000b9a:	ec06                	sd	ra,24(sp)
    80000b9c:	e822                	sd	s0,16(sp)
    80000b9e:	e426                	sd	s1,8(sp)
    80000ba0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba2:	100024f3          	csrr	s1,sstatus
    80000ba6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000baa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bac:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb0:	00001097          	auipc	ra,0x1
    80000bb4:	292080e7          	jalr	658(ra) # 80001e42 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	286080e7          	jalr	646(ra) # 80001e42 <mycpu>
    80000bc4:	5d3c                	lw	a5,120(a0)
    80000bc6:	2785                	addiw	a5,a5,1
    80000bc8:	dd3c                	sw	a5,120(a0)
}
    80000bca:	60e2                	ld	ra,24(sp)
    80000bcc:	6442                	ld	s0,16(sp)
    80000bce:	64a2                	ld	s1,8(sp)
    80000bd0:	6105                	addi	sp,sp,32
    80000bd2:	8082                	ret
    mycpu()->intena = old;
    80000bd4:	00001097          	auipc	ra,0x1
    80000bd8:	26e080e7          	jalr	622(ra) # 80001e42 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bdc:	8085                	srli	s1,s1,0x1
    80000bde:	8885                	andi	s1,s1,1
    80000be0:	dd64                	sw	s1,124(a0)
    80000be2:	bfe9                	j	80000bbc <push_off+0x24>

0000000080000be4 <acquire>:
{
    80000be4:	1101                	addi	sp,sp,-32
    80000be6:	ec06                	sd	ra,24(sp)
    80000be8:	e822                	sd	s0,16(sp)
    80000bea:	e426                	sd	s1,8(sp)
    80000bec:	1000                	addi	s0,sp,32
    80000bee:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf0:	00000097          	auipc	ra,0x0
    80000bf4:	fa8080e7          	jalr	-88(ra) # 80000b98 <push_off>
  if(holding(lk))
    80000bf8:	8526                	mv	a0,s1
    80000bfa:	00000097          	auipc	ra,0x0
    80000bfe:	f70080e7          	jalr	-144(ra) # 80000b6a <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c02:	4705                	li	a4,1
  if(holding(lk))
    80000c04:	e115                	bnez	a0,80000c28 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c06:	87ba                	mv	a5,a4
    80000c08:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c0c:	2781                	sext.w	a5,a5
    80000c0e:	ffe5                	bnez	a5,80000c06 <acquire+0x22>
  __sync_synchronize();
    80000c10:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c14:	00001097          	auipc	ra,0x1
    80000c18:	22e080e7          	jalr	558(ra) # 80001e42 <mycpu>
    80000c1c:	e888                	sd	a0,16(s1)
}
    80000c1e:	60e2                	ld	ra,24(sp)
    80000c20:	6442                	ld	s0,16(sp)
    80000c22:	64a2                	ld	s1,8(sp)
    80000c24:	6105                	addi	sp,sp,32
    80000c26:	8082                	ret
    panic("acquire");
    80000c28:	00007517          	auipc	a0,0x7
    80000c2c:	44850513          	addi	a0,a0,1096 # 80008070 <digits+0x30>
    80000c30:	00000097          	auipc	ra,0x0
    80000c34:	90e080e7          	jalr	-1778(ra) # 8000053e <panic>

0000000080000c38 <pop_off>:

void
pop_off(void)
{
    80000c38:	1141                	addi	sp,sp,-16
    80000c3a:	e406                	sd	ra,8(sp)
    80000c3c:	e022                	sd	s0,0(sp)
    80000c3e:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	202080e7          	jalr	514(ra) # 80001e42 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c48:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c4c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c4e:	e78d                	bnez	a5,80000c78 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c50:	5d3c                	lw	a5,120(a0)
    80000c52:	02f05b63          	blez	a5,80000c88 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c56:	37fd                	addiw	a5,a5,-1
    80000c58:	0007871b          	sext.w	a4,a5
    80000c5c:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c5e:	eb09                	bnez	a4,80000c70 <pop_off+0x38>
    80000c60:	5d7c                	lw	a5,124(a0)
    80000c62:	c799                	beqz	a5,80000c70 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c64:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c68:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c6c:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c70:	60a2                	ld	ra,8(sp)
    80000c72:	6402                	ld	s0,0(sp)
    80000c74:	0141                	addi	sp,sp,16
    80000c76:	8082                	ret
    panic("pop_off - interruptible");
    80000c78:	00007517          	auipc	a0,0x7
    80000c7c:	40050513          	addi	a0,a0,1024 # 80008078 <digits+0x38>
    80000c80:	00000097          	auipc	ra,0x0
    80000c84:	8be080e7          	jalr	-1858(ra) # 8000053e <panic>
    panic("pop_off");
    80000c88:	00007517          	auipc	a0,0x7
    80000c8c:	40850513          	addi	a0,a0,1032 # 80008090 <digits+0x50>
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	8ae080e7          	jalr	-1874(ra) # 8000053e <panic>

0000000080000c98 <release>:
{
    80000c98:	1101                	addi	sp,sp,-32
    80000c9a:	ec06                	sd	ra,24(sp)
    80000c9c:	e822                	sd	s0,16(sp)
    80000c9e:	e426                	sd	s1,8(sp)
    80000ca0:	1000                	addi	s0,sp,32
    80000ca2:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000ca4:	00000097          	auipc	ra,0x0
    80000ca8:	ec6080e7          	jalr	-314(ra) # 80000b6a <holding>
    80000cac:	c115                	beqz	a0,80000cd0 <release+0x38>
  lk->cpu = 0;
    80000cae:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb2:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cb6:	0f50000f          	fence	iorw,ow
    80000cba:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cbe:	00000097          	auipc	ra,0x0
    80000cc2:	f7a080e7          	jalr	-134(ra) # 80000c38 <pop_off>
}
    80000cc6:	60e2                	ld	ra,24(sp)
    80000cc8:	6442                	ld	s0,16(sp)
    80000cca:	64a2                	ld	s1,8(sp)
    80000ccc:	6105                	addi	sp,sp,32
    80000cce:	8082                	ret
    panic("release");
    80000cd0:	00007517          	auipc	a0,0x7
    80000cd4:	3c850513          	addi	a0,a0,968 # 80008098 <digits+0x58>
    80000cd8:	00000097          	auipc	ra,0x0
    80000cdc:	866080e7          	jalr	-1946(ra) # 8000053e <panic>

0000000080000ce0 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce0:	1141                	addi	sp,sp,-16
    80000ce2:	e422                	sd	s0,8(sp)
    80000ce4:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000ce6:	ce09                	beqz	a2,80000d00 <memset+0x20>
    80000ce8:	87aa                	mv	a5,a0
    80000cea:	fff6071b          	addiw	a4,a2,-1
    80000cee:	1702                	slli	a4,a4,0x20
    80000cf0:	9301                	srli	a4,a4,0x20
    80000cf2:	0705                	addi	a4,a4,1
    80000cf4:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000cf6:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cfa:	0785                	addi	a5,a5,1
    80000cfc:	fee79de3          	bne	a5,a4,80000cf6 <memset+0x16>
  }
  return dst;
}
    80000d00:	6422                	ld	s0,8(sp)
    80000d02:	0141                	addi	sp,sp,16
    80000d04:	8082                	ret

0000000080000d06 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d06:	1141                	addi	sp,sp,-16
    80000d08:	e422                	sd	s0,8(sp)
    80000d0a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d0c:	ca05                	beqz	a2,80000d3c <memcmp+0x36>
    80000d0e:	fff6069b          	addiw	a3,a2,-1
    80000d12:	1682                	slli	a3,a3,0x20
    80000d14:	9281                	srli	a3,a3,0x20
    80000d16:	0685                	addi	a3,a3,1
    80000d18:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d1a:	00054783          	lbu	a5,0(a0)
    80000d1e:	0005c703          	lbu	a4,0(a1)
    80000d22:	00e79863          	bne	a5,a4,80000d32 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d26:	0505                	addi	a0,a0,1
    80000d28:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d2a:	fed518e3          	bne	a0,a3,80000d1a <memcmp+0x14>
  }

  return 0;
    80000d2e:	4501                	li	a0,0
    80000d30:	a019                	j	80000d36 <memcmp+0x30>
      return *s1 - *s2;
    80000d32:	40e7853b          	subw	a0,a5,a4
}
    80000d36:	6422                	ld	s0,8(sp)
    80000d38:	0141                	addi	sp,sp,16
    80000d3a:	8082                	ret
  return 0;
    80000d3c:	4501                	li	a0,0
    80000d3e:	bfe5                	j	80000d36 <memcmp+0x30>

0000000080000d40 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d40:	1141                	addi	sp,sp,-16
    80000d42:	e422                	sd	s0,8(sp)
    80000d44:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d46:	ca0d                	beqz	a2,80000d78 <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d48:	00a5f963          	bgeu	a1,a0,80000d5a <memmove+0x1a>
    80000d4c:	02061693          	slli	a3,a2,0x20
    80000d50:	9281                	srli	a3,a3,0x20
    80000d52:	00d58733          	add	a4,a1,a3
    80000d56:	02e56463          	bltu	a0,a4,80000d7e <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d5a:	fff6079b          	addiw	a5,a2,-1
    80000d5e:	1782                	slli	a5,a5,0x20
    80000d60:	9381                	srli	a5,a5,0x20
    80000d62:	0785                	addi	a5,a5,1
    80000d64:	97ae                	add	a5,a5,a1
    80000d66:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d68:	0585                	addi	a1,a1,1
    80000d6a:	0705                	addi	a4,a4,1
    80000d6c:	fff5c683          	lbu	a3,-1(a1)
    80000d70:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d74:	fef59ae3          	bne	a1,a5,80000d68 <memmove+0x28>

  return dst;
}
    80000d78:	6422                	ld	s0,8(sp)
    80000d7a:	0141                	addi	sp,sp,16
    80000d7c:	8082                	ret
    d += n;
    80000d7e:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d80:	fff6079b          	addiw	a5,a2,-1
    80000d84:	1782                	slli	a5,a5,0x20
    80000d86:	9381                	srli	a5,a5,0x20
    80000d88:	fff7c793          	not	a5,a5
    80000d8c:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d8e:	177d                	addi	a4,a4,-1
    80000d90:	16fd                	addi	a3,a3,-1
    80000d92:	00074603          	lbu	a2,0(a4)
    80000d96:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d9a:	fef71ae3          	bne	a4,a5,80000d8e <memmove+0x4e>
    80000d9e:	bfe9                	j	80000d78 <memmove+0x38>

0000000080000da0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da0:	1141                	addi	sp,sp,-16
    80000da2:	e406                	sd	ra,8(sp)
    80000da4:	e022                	sd	s0,0(sp)
    80000da6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000da8:	00000097          	auipc	ra,0x0
    80000dac:	f98080e7          	jalr	-104(ra) # 80000d40 <memmove>
}
    80000db0:	60a2                	ld	ra,8(sp)
    80000db2:	6402                	ld	s0,0(sp)
    80000db4:	0141                	addi	sp,sp,16
    80000db6:	8082                	ret

0000000080000db8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000db8:	1141                	addi	sp,sp,-16
    80000dba:	e422                	sd	s0,8(sp)
    80000dbc:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dbe:	ce11                	beqz	a2,80000dda <strncmp+0x22>
    80000dc0:	00054783          	lbu	a5,0(a0)
    80000dc4:	cf89                	beqz	a5,80000dde <strncmp+0x26>
    80000dc6:	0005c703          	lbu	a4,0(a1)
    80000dca:	00f71a63          	bne	a4,a5,80000dde <strncmp+0x26>
    n--, p++, q++;
    80000dce:	367d                	addiw	a2,a2,-1
    80000dd0:	0505                	addi	a0,a0,1
    80000dd2:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dd4:	f675                	bnez	a2,80000dc0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dd6:	4501                	li	a0,0
    80000dd8:	a809                	j	80000dea <strncmp+0x32>
    80000dda:	4501                	li	a0,0
    80000ddc:	a039                	j	80000dea <strncmp+0x32>
  if(n == 0)
    80000dde:	ca09                	beqz	a2,80000df0 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de0:	00054503          	lbu	a0,0(a0)
    80000de4:	0005c783          	lbu	a5,0(a1)
    80000de8:	9d1d                	subw	a0,a0,a5
}
    80000dea:	6422                	ld	s0,8(sp)
    80000dec:	0141                	addi	sp,sp,16
    80000dee:	8082                	ret
    return 0;
    80000df0:	4501                	li	a0,0
    80000df2:	bfe5                	j	80000dea <strncmp+0x32>

0000000080000df4 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000df4:	1141                	addi	sp,sp,-16
    80000df6:	e422                	sd	s0,8(sp)
    80000df8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dfa:	872a                	mv	a4,a0
    80000dfc:	8832                	mv	a6,a2
    80000dfe:	367d                	addiw	a2,a2,-1
    80000e00:	01005963          	blez	a6,80000e12 <strncpy+0x1e>
    80000e04:	0705                	addi	a4,a4,1
    80000e06:	0005c783          	lbu	a5,0(a1)
    80000e0a:	fef70fa3          	sb	a5,-1(a4)
    80000e0e:	0585                	addi	a1,a1,1
    80000e10:	f7f5                	bnez	a5,80000dfc <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e12:	00c05d63          	blez	a2,80000e2c <strncpy+0x38>
    80000e16:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e18:	0685                	addi	a3,a3,1
    80000e1a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e1e:	fff6c793          	not	a5,a3
    80000e22:	9fb9                	addw	a5,a5,a4
    80000e24:	010787bb          	addw	a5,a5,a6
    80000e28:	fef048e3          	bgtz	a5,80000e18 <strncpy+0x24>
  return os;
}
    80000e2c:	6422                	ld	s0,8(sp)
    80000e2e:	0141                	addi	sp,sp,16
    80000e30:	8082                	ret

0000000080000e32 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e32:	1141                	addi	sp,sp,-16
    80000e34:	e422                	sd	s0,8(sp)
    80000e36:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e38:	02c05363          	blez	a2,80000e5e <safestrcpy+0x2c>
    80000e3c:	fff6069b          	addiw	a3,a2,-1
    80000e40:	1682                	slli	a3,a3,0x20
    80000e42:	9281                	srli	a3,a3,0x20
    80000e44:	96ae                	add	a3,a3,a1
    80000e46:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e48:	00d58963          	beq	a1,a3,80000e5a <safestrcpy+0x28>
    80000e4c:	0585                	addi	a1,a1,1
    80000e4e:	0785                	addi	a5,a5,1
    80000e50:	fff5c703          	lbu	a4,-1(a1)
    80000e54:	fee78fa3          	sb	a4,-1(a5)
    80000e58:	fb65                	bnez	a4,80000e48 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e5a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e5e:	6422                	ld	s0,8(sp)
    80000e60:	0141                	addi	sp,sp,16
    80000e62:	8082                	ret

0000000080000e64 <strlen>:

int
strlen(const char *s)
{
    80000e64:	1141                	addi	sp,sp,-16
    80000e66:	e422                	sd	s0,8(sp)
    80000e68:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e6a:	00054783          	lbu	a5,0(a0)
    80000e6e:	cf91                	beqz	a5,80000e8a <strlen+0x26>
    80000e70:	0505                	addi	a0,a0,1
    80000e72:	87aa                	mv	a5,a0
    80000e74:	4685                	li	a3,1
    80000e76:	9e89                	subw	a3,a3,a0
    80000e78:	00f6853b          	addw	a0,a3,a5
    80000e7c:	0785                	addi	a5,a5,1
    80000e7e:	fff7c703          	lbu	a4,-1(a5)
    80000e82:	fb7d                	bnez	a4,80000e78 <strlen+0x14>
    ;
  return n;
}
    80000e84:	6422                	ld	s0,8(sp)
    80000e86:	0141                	addi	sp,sp,16
    80000e88:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e8a:	4501                	li	a0,0
    80000e8c:	bfe5                	j	80000e84 <strlen+0x20>

0000000080000e8e <main>:


// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e8e:	1141                	addi	sp,sp,-16
    80000e90:	e406                	sd	ra,8(sp)
    80000e92:	e022                	sd	s0,0(sp)
    80000e94:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	f9c080e7          	jalr	-100(ra) # 80001e32 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e9e:	00008717          	auipc	a4,0x8
    80000ea2:	17a70713          	addi	a4,a4,378 # 80009018 <started>
  if(cpuid() == 0){
    80000ea6:	c139                	beqz	a0,80000eec <main+0x5e>
    while(started == 0)
    80000ea8:	431c                	lw	a5,0(a4)
    80000eaa:	2781                	sext.w	a5,a5
    80000eac:	dff5                	beqz	a5,80000ea8 <main+0x1a>
      ;
    __sync_synchronize();
    80000eae:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb2:	00001097          	auipc	ra,0x1
    80000eb6:	f80080e7          	jalr	-128(ra) # 80001e32 <cpuid>
    80000eba:	85aa                	mv	a1,a0
    80000ebc:	00007517          	auipc	a0,0x7
    80000ec0:	1fc50513          	addi	a0,a0,508 # 800080b8 <digits+0x78>
    80000ec4:	fffff097          	auipc	ra,0xfffff
    80000ec8:	6c4080e7          	jalr	1732(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ecc:	00000097          	auipc	ra,0x0
    80000ed0:	0d8080e7          	jalr	216(ra) # 80000fa4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ed4:	00002097          	auipc	ra,0x2
    80000ed8:	1d0080e7          	jalr	464(ra) # 800030a4 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	7a4080e7          	jalr	1956(ra) # 80006680 <plicinithart>
  }

  scheduler();        
    80000ee4:	00002097          	auipc	ra,0x2
    80000ee8:	d3c080e7          	jalr	-708(ra) # 80002c20 <scheduler>
    consoleinit();
    80000eec:	fffff097          	auipc	ra,0xfffff
    80000ef0:	564080e7          	jalr	1380(ra) # 80000450 <consoleinit>
    printfinit();
    80000ef4:	00000097          	auipc	ra,0x0
    80000ef8:	87a080e7          	jalr	-1926(ra) # 8000076e <printfinit>
    printf("\n");
    80000efc:	00007517          	auipc	a0,0x7
    80000f00:	3f450513          	addi	a0,a0,1012 # 800082f0 <digits+0x2b0>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	684080e7          	jalr	1668(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	19450513          	addi	a0,a0,404 # 800080a0 <digits+0x60>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	3d450513          	addi	a0,a0,980 # 800082f0 <digits+0x2b0>
    80000f24:	fffff097          	auipc	ra,0xfffff
    80000f28:	664080e7          	jalr	1636(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f2c:	00000097          	auipc	ra,0x0
    80000f30:	b8c080e7          	jalr	-1140(ra) # 80000ab8 <kinit>
    kvminit();       // create kernel page table
    80000f34:	00000097          	auipc	ra,0x0
    80000f38:	322080e7          	jalr	802(ra) # 80001256 <kvminit>
    kvminithart();   // turn on paging
    80000f3c:	00000097          	auipc	ra,0x0
    80000f40:	068080e7          	jalr	104(ra) # 80000fa4 <kvminithart>
    procinit();      // process table
    80000f44:	00001097          	auipc	ra,0x1
    80000f48:	dfc080e7          	jalr	-516(ra) # 80001d40 <procinit>
    trapinit();      // trap vectors
    80000f4c:	00002097          	auipc	ra,0x2
    80000f50:	130080e7          	jalr	304(ra) # 8000307c <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	150080e7          	jalr	336(ra) # 800030a4 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	70e080e7          	jalr	1806(ra) # 8000666a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	71c080e7          	jalr	1820(ra) # 80006680 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00003097          	auipc	ra,0x3
    80000f70:	8f6080e7          	jalr	-1802(ra) # 80003862 <binit>
    iinit();         // inode table
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	f86080e7          	jalr	-122(ra) # 80003efa <iinit>
    fileinit();      // file table
    80000f7c:	00004097          	auipc	ra,0x4
    80000f80:	f30080e7          	jalr	-208(ra) # 80004eac <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00006097          	auipc	ra,0x6
    80000f88:	81e080e7          	jalr	-2018(ra) # 800067a2 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	236080e7          	jalr	566(ra) # 800021c2 <userinit>
    __sync_synchronize();
    80000f94:	0ff0000f          	fence
    started = 1;
    80000f98:	4785                	li	a5,1
    80000f9a:	00008717          	auipc	a4,0x8
    80000f9e:	06f72f23          	sw	a5,126(a4) # 80009018 <started>
    80000fa2:	b789                	j	80000ee4 <main+0x56>

0000000080000fa4 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fa4:	1141                	addi	sp,sp,-16
    80000fa6:	e422                	sd	s0,8(sp)
    80000fa8:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000faa:	00008797          	auipc	a5,0x8
    80000fae:	0767b783          	ld	a5,118(a5) # 80009020 <kernel_pagetable>
    80000fb2:	83b1                	srli	a5,a5,0xc
    80000fb4:	577d                	li	a4,-1
    80000fb6:	177e                	slli	a4,a4,0x3f
    80000fb8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fba:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fbe:	12000073          	sfence.vma
  sfence_vma();
}
    80000fc2:	6422                	ld	s0,8(sp)
    80000fc4:	0141                	addi	sp,sp,16
    80000fc6:	8082                	ret

0000000080000fc8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fc8:	7139                	addi	sp,sp,-64
    80000fca:	fc06                	sd	ra,56(sp)
    80000fcc:	f822                	sd	s0,48(sp)
    80000fce:	f426                	sd	s1,40(sp)
    80000fd0:	f04a                	sd	s2,32(sp)
    80000fd2:	ec4e                	sd	s3,24(sp)
    80000fd4:	e852                	sd	s4,16(sp)
    80000fd6:	e456                	sd	s5,8(sp)
    80000fd8:	e05a                	sd	s6,0(sp)
    80000fda:	0080                	addi	s0,sp,64
    80000fdc:	84aa                	mv	s1,a0
    80000fde:	89ae                	mv	s3,a1
    80000fe0:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fe2:	57fd                	li	a5,-1
    80000fe4:	83e9                	srli	a5,a5,0x1a
    80000fe6:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fe8:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fea:	04b7f263          	bgeu	a5,a1,8000102e <walk+0x66>
    panic("walk");
    80000fee:	00007517          	auipc	a0,0x7
    80000ff2:	0e250513          	addi	a0,a0,226 # 800080d0 <digits+0x90>
    80000ff6:	fffff097          	auipc	ra,0xfffff
    80000ffa:	548080e7          	jalr	1352(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000ffe:	060a8663          	beqz	s5,8000106a <walk+0xa2>
    80001002:	00000097          	auipc	ra,0x0
    80001006:	af2080e7          	jalr	-1294(ra) # 80000af4 <kalloc>
    8000100a:	84aa                	mv	s1,a0
    8000100c:	c529                	beqz	a0,80001056 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000100e:	6605                	lui	a2,0x1
    80001010:	4581                	li	a1,0
    80001012:	00000097          	auipc	ra,0x0
    80001016:	cce080e7          	jalr	-818(ra) # 80000ce0 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000101a:	00c4d793          	srli	a5,s1,0xc
    8000101e:	07aa                	slli	a5,a5,0xa
    80001020:	0017e793          	ori	a5,a5,1
    80001024:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001028:	3a5d                	addiw	s4,s4,-9
    8000102a:	036a0063          	beq	s4,s6,8000104a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000102e:	0149d933          	srl	s2,s3,s4
    80001032:	1ff97913          	andi	s2,s2,511
    80001036:	090e                	slli	s2,s2,0x3
    80001038:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000103a:	00093483          	ld	s1,0(s2)
    8000103e:	0014f793          	andi	a5,s1,1
    80001042:	dfd5                	beqz	a5,80000ffe <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001044:	80a9                	srli	s1,s1,0xa
    80001046:	04b2                	slli	s1,s1,0xc
    80001048:	b7c5                	j	80001028 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000104a:	00c9d513          	srli	a0,s3,0xc
    8000104e:	1ff57513          	andi	a0,a0,511
    80001052:	050e                	slli	a0,a0,0x3
    80001054:	9526                	add	a0,a0,s1
}
    80001056:	70e2                	ld	ra,56(sp)
    80001058:	7442                	ld	s0,48(sp)
    8000105a:	74a2                	ld	s1,40(sp)
    8000105c:	7902                	ld	s2,32(sp)
    8000105e:	69e2                	ld	s3,24(sp)
    80001060:	6a42                	ld	s4,16(sp)
    80001062:	6aa2                	ld	s5,8(sp)
    80001064:	6b02                	ld	s6,0(sp)
    80001066:	6121                	addi	sp,sp,64
    80001068:	8082                	ret
        return 0;
    8000106a:	4501                	li	a0,0
    8000106c:	b7ed                	j	80001056 <walk+0x8e>

000000008000106e <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000106e:	57fd                	li	a5,-1
    80001070:	83e9                	srli	a5,a5,0x1a
    80001072:	00b7f463          	bgeu	a5,a1,8000107a <walkaddr+0xc>
    return 0;
    80001076:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001078:	8082                	ret
{
    8000107a:	1141                	addi	sp,sp,-16
    8000107c:	e406                	sd	ra,8(sp)
    8000107e:	e022                	sd	s0,0(sp)
    80001080:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001082:	4601                	li	a2,0
    80001084:	00000097          	auipc	ra,0x0
    80001088:	f44080e7          	jalr	-188(ra) # 80000fc8 <walk>
  if(pte == 0)
    8000108c:	c105                	beqz	a0,800010ac <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000108e:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001090:	0117f693          	andi	a3,a5,17
    80001094:	4745                	li	a4,17
    return 0;
    80001096:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001098:	00e68663          	beq	a3,a4,800010a4 <walkaddr+0x36>
}
    8000109c:	60a2                	ld	ra,8(sp)
    8000109e:	6402                	ld	s0,0(sp)
    800010a0:	0141                	addi	sp,sp,16
    800010a2:	8082                	ret
  pa = PTE2PA(*pte);
    800010a4:	00a7d513          	srli	a0,a5,0xa
    800010a8:	0532                	slli	a0,a0,0xc
  return pa;
    800010aa:	bfcd                	j	8000109c <walkaddr+0x2e>
    return 0;
    800010ac:	4501                	li	a0,0
    800010ae:	b7fd                	j	8000109c <walkaddr+0x2e>

00000000800010b0 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010b0:	715d                	addi	sp,sp,-80
    800010b2:	e486                	sd	ra,72(sp)
    800010b4:	e0a2                	sd	s0,64(sp)
    800010b6:	fc26                	sd	s1,56(sp)
    800010b8:	f84a                	sd	s2,48(sp)
    800010ba:	f44e                	sd	s3,40(sp)
    800010bc:	f052                	sd	s4,32(sp)
    800010be:	ec56                	sd	s5,24(sp)
    800010c0:	e85a                	sd	s6,16(sp)
    800010c2:	e45e                	sd	s7,8(sp)
    800010c4:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010c6:	c205                	beqz	a2,800010e6 <mappages+0x36>
    800010c8:	8aaa                	mv	s5,a0
    800010ca:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010cc:	77fd                	lui	a5,0xfffff
    800010ce:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010d2:	15fd                	addi	a1,a1,-1
    800010d4:	00c589b3          	add	s3,a1,a2
    800010d8:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010dc:	8952                	mv	s2,s4
    800010de:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010e2:	6b85                	lui	s7,0x1
    800010e4:	a015                	j	80001108 <mappages+0x58>
    panic("mappages: size");
    800010e6:	00007517          	auipc	a0,0x7
    800010ea:	ff250513          	addi	a0,a0,-14 # 800080d8 <digits+0x98>
    800010ee:	fffff097          	auipc	ra,0xfffff
    800010f2:	450080e7          	jalr	1104(ra) # 8000053e <panic>
      panic("mappages: remap");
    800010f6:	00007517          	auipc	a0,0x7
    800010fa:	ff250513          	addi	a0,a0,-14 # 800080e8 <digits+0xa8>
    800010fe:	fffff097          	auipc	ra,0xfffff
    80001102:	440080e7          	jalr	1088(ra) # 8000053e <panic>
    a += PGSIZE;
    80001106:	995e                	add	s2,s2,s7
  for(;;){
    80001108:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000110c:	4605                	li	a2,1
    8000110e:	85ca                	mv	a1,s2
    80001110:	8556                	mv	a0,s5
    80001112:	00000097          	auipc	ra,0x0
    80001116:	eb6080e7          	jalr	-330(ra) # 80000fc8 <walk>
    8000111a:	cd19                	beqz	a0,80001138 <mappages+0x88>
    if(*pte & PTE_V)
    8000111c:	611c                	ld	a5,0(a0)
    8000111e:	8b85                	andi	a5,a5,1
    80001120:	fbf9                	bnez	a5,800010f6 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001122:	80b1                	srli	s1,s1,0xc
    80001124:	04aa                	slli	s1,s1,0xa
    80001126:	0164e4b3          	or	s1,s1,s6
    8000112a:	0014e493          	ori	s1,s1,1
    8000112e:	e104                	sd	s1,0(a0)
    if(a == last)
    80001130:	fd391be3          	bne	s2,s3,80001106 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    80001134:	4501                	li	a0,0
    80001136:	a011                	j	8000113a <mappages+0x8a>
      return -1;
    80001138:	557d                	li	a0,-1
}
    8000113a:	60a6                	ld	ra,72(sp)
    8000113c:	6406                	ld	s0,64(sp)
    8000113e:	74e2                	ld	s1,56(sp)
    80001140:	7942                	ld	s2,48(sp)
    80001142:	79a2                	ld	s3,40(sp)
    80001144:	7a02                	ld	s4,32(sp)
    80001146:	6ae2                	ld	s5,24(sp)
    80001148:	6b42                	ld	s6,16(sp)
    8000114a:	6ba2                	ld	s7,8(sp)
    8000114c:	6161                	addi	sp,sp,80
    8000114e:	8082                	ret

0000000080001150 <kvmmap>:
{
    80001150:	1141                	addi	sp,sp,-16
    80001152:	e406                	sd	ra,8(sp)
    80001154:	e022                	sd	s0,0(sp)
    80001156:	0800                	addi	s0,sp,16
    80001158:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000115a:	86b2                	mv	a3,a2
    8000115c:	863e                	mv	a2,a5
    8000115e:	00000097          	auipc	ra,0x0
    80001162:	f52080e7          	jalr	-174(ra) # 800010b0 <mappages>
    80001166:	e509                	bnez	a0,80001170 <kvmmap+0x20>
}
    80001168:	60a2                	ld	ra,8(sp)
    8000116a:	6402                	ld	s0,0(sp)
    8000116c:	0141                	addi	sp,sp,16
    8000116e:	8082                	ret
    panic("kvmmap");
    80001170:	00007517          	auipc	a0,0x7
    80001174:	f8850513          	addi	a0,a0,-120 # 800080f8 <digits+0xb8>
    80001178:	fffff097          	auipc	ra,0xfffff
    8000117c:	3c6080e7          	jalr	966(ra) # 8000053e <panic>

0000000080001180 <kvmmake>:
{
    80001180:	1101                	addi	sp,sp,-32
    80001182:	ec06                	sd	ra,24(sp)
    80001184:	e822                	sd	s0,16(sp)
    80001186:	e426                	sd	s1,8(sp)
    80001188:	e04a                	sd	s2,0(sp)
    8000118a:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000118c:	00000097          	auipc	ra,0x0
    80001190:	968080e7          	jalr	-1688(ra) # 80000af4 <kalloc>
    80001194:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001196:	6605                	lui	a2,0x1
    80001198:	4581                	li	a1,0
    8000119a:	00000097          	auipc	ra,0x0
    8000119e:	b46080e7          	jalr	-1210(ra) # 80000ce0 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011a2:	4719                	li	a4,6
    800011a4:	6685                	lui	a3,0x1
    800011a6:	10000637          	lui	a2,0x10000
    800011aa:	100005b7          	lui	a1,0x10000
    800011ae:	8526                	mv	a0,s1
    800011b0:	00000097          	auipc	ra,0x0
    800011b4:	fa0080e7          	jalr	-96(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011b8:	4719                	li	a4,6
    800011ba:	6685                	lui	a3,0x1
    800011bc:	10001637          	lui	a2,0x10001
    800011c0:	100015b7          	lui	a1,0x10001
    800011c4:	8526                	mv	a0,s1
    800011c6:	00000097          	auipc	ra,0x0
    800011ca:	f8a080e7          	jalr	-118(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011ce:	4719                	li	a4,6
    800011d0:	004006b7          	lui	a3,0x400
    800011d4:	0c000637          	lui	a2,0xc000
    800011d8:	0c0005b7          	lui	a1,0xc000
    800011dc:	8526                	mv	a0,s1
    800011de:	00000097          	auipc	ra,0x0
    800011e2:	f72080e7          	jalr	-142(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011e6:	00007917          	auipc	s2,0x7
    800011ea:	e1a90913          	addi	s2,s2,-486 # 80008000 <etext>
    800011ee:	4729                	li	a4,10
    800011f0:	80007697          	auipc	a3,0x80007
    800011f4:	e1068693          	addi	a3,a3,-496 # 8000 <_entry-0x7fff8000>
    800011f8:	4605                	li	a2,1
    800011fa:	067e                	slli	a2,a2,0x1f
    800011fc:	85b2                	mv	a1,a2
    800011fe:	8526                	mv	a0,s1
    80001200:	00000097          	auipc	ra,0x0
    80001204:	f50080e7          	jalr	-176(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001208:	4719                	li	a4,6
    8000120a:	46c5                	li	a3,17
    8000120c:	06ee                	slli	a3,a3,0x1b
    8000120e:	412686b3          	sub	a3,a3,s2
    80001212:	864a                	mv	a2,s2
    80001214:	85ca                	mv	a1,s2
    80001216:	8526                	mv	a0,s1
    80001218:	00000097          	auipc	ra,0x0
    8000121c:	f38080e7          	jalr	-200(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001220:	4729                	li	a4,10
    80001222:	6685                	lui	a3,0x1
    80001224:	00006617          	auipc	a2,0x6
    80001228:	ddc60613          	addi	a2,a2,-548 # 80007000 <_trampoline>
    8000122c:	040005b7          	lui	a1,0x4000
    80001230:	15fd                	addi	a1,a1,-1
    80001232:	05b2                	slli	a1,a1,0xc
    80001234:	8526                	mv	a0,s1
    80001236:	00000097          	auipc	ra,0x0
    8000123a:	f1a080e7          	jalr	-230(ra) # 80001150 <kvmmap>
  proc_mapstacks(kpgtbl);
    8000123e:	8526                	mv	a0,s1
    80001240:	00001097          	auipc	ra,0x1
    80001244:	a6a080e7          	jalr	-1430(ra) # 80001caa <proc_mapstacks>
}
    80001248:	8526                	mv	a0,s1
    8000124a:	60e2                	ld	ra,24(sp)
    8000124c:	6442                	ld	s0,16(sp)
    8000124e:	64a2                	ld	s1,8(sp)
    80001250:	6902                	ld	s2,0(sp)
    80001252:	6105                	addi	sp,sp,32
    80001254:	8082                	ret

0000000080001256 <kvminit>:
{
    80001256:	1141                	addi	sp,sp,-16
    80001258:	e406                	sd	ra,8(sp)
    8000125a:	e022                	sd	s0,0(sp)
    8000125c:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000125e:	00000097          	auipc	ra,0x0
    80001262:	f22080e7          	jalr	-222(ra) # 80001180 <kvmmake>
    80001266:	00008797          	auipc	a5,0x8
    8000126a:	daa7bd23          	sd	a0,-582(a5) # 80009020 <kernel_pagetable>
}
    8000126e:	60a2                	ld	ra,8(sp)
    80001270:	6402                	ld	s0,0(sp)
    80001272:	0141                	addi	sp,sp,16
    80001274:	8082                	ret

0000000080001276 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001276:	715d                	addi	sp,sp,-80
    80001278:	e486                	sd	ra,72(sp)
    8000127a:	e0a2                	sd	s0,64(sp)
    8000127c:	fc26                	sd	s1,56(sp)
    8000127e:	f84a                	sd	s2,48(sp)
    80001280:	f44e                	sd	s3,40(sp)
    80001282:	f052                	sd	s4,32(sp)
    80001284:	ec56                	sd	s5,24(sp)
    80001286:	e85a                	sd	s6,16(sp)
    80001288:	e45e                	sd	s7,8(sp)
    8000128a:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000128c:	03459793          	slli	a5,a1,0x34
    80001290:	e795                	bnez	a5,800012bc <uvmunmap+0x46>
    80001292:	8a2a                	mv	s4,a0
    80001294:	892e                	mv	s2,a1
    80001296:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001298:	0632                	slli	a2,a2,0xc
    8000129a:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000129e:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a0:	6b05                	lui	s6,0x1
    800012a2:	0735e863          	bltu	a1,s3,80001312 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012a6:	60a6                	ld	ra,72(sp)
    800012a8:	6406                	ld	s0,64(sp)
    800012aa:	74e2                	ld	s1,56(sp)
    800012ac:	7942                	ld	s2,48(sp)
    800012ae:	79a2                	ld	s3,40(sp)
    800012b0:	7a02                	ld	s4,32(sp)
    800012b2:	6ae2                	ld	s5,24(sp)
    800012b4:	6b42                	ld	s6,16(sp)
    800012b6:	6ba2                	ld	s7,8(sp)
    800012b8:	6161                	addi	sp,sp,80
    800012ba:	8082                	ret
    panic("uvmunmap: not aligned");
    800012bc:	00007517          	auipc	a0,0x7
    800012c0:	e4450513          	addi	a0,a0,-444 # 80008100 <digits+0xc0>
    800012c4:	fffff097          	auipc	ra,0xfffff
    800012c8:	27a080e7          	jalr	634(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012cc:	00007517          	auipc	a0,0x7
    800012d0:	e4c50513          	addi	a0,a0,-436 # 80008118 <digits+0xd8>
    800012d4:	fffff097          	auipc	ra,0xfffff
    800012d8:	26a080e7          	jalr	618(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012dc:	00007517          	auipc	a0,0x7
    800012e0:	e4c50513          	addi	a0,a0,-436 # 80008128 <digits+0xe8>
    800012e4:	fffff097          	auipc	ra,0xfffff
    800012e8:	25a080e7          	jalr	602(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012ec:	00007517          	auipc	a0,0x7
    800012f0:	e5450513          	addi	a0,a0,-428 # 80008140 <digits+0x100>
    800012f4:	fffff097          	auipc	ra,0xfffff
    800012f8:	24a080e7          	jalr	586(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    800012fc:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800012fe:	0532                	slli	a0,a0,0xc
    80001300:	fffff097          	auipc	ra,0xfffff
    80001304:	6f8080e7          	jalr	1784(ra) # 800009f8 <kfree>
    *pte = 0;
    80001308:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000130c:	995a                	add	s2,s2,s6
    8000130e:	f9397ce3          	bgeu	s2,s3,800012a6 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001312:	4601                	li	a2,0
    80001314:	85ca                	mv	a1,s2
    80001316:	8552                	mv	a0,s4
    80001318:	00000097          	auipc	ra,0x0
    8000131c:	cb0080e7          	jalr	-848(ra) # 80000fc8 <walk>
    80001320:	84aa                	mv	s1,a0
    80001322:	d54d                	beqz	a0,800012cc <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001324:	6108                	ld	a0,0(a0)
    80001326:	00157793          	andi	a5,a0,1
    8000132a:	dbcd                	beqz	a5,800012dc <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000132c:	3ff57793          	andi	a5,a0,1023
    80001330:	fb778ee3          	beq	a5,s7,800012ec <uvmunmap+0x76>
    if(do_free){
    80001334:	fc0a8ae3          	beqz	s5,80001308 <uvmunmap+0x92>
    80001338:	b7d1                	j	800012fc <uvmunmap+0x86>

000000008000133a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000133a:	1101                	addi	sp,sp,-32
    8000133c:	ec06                	sd	ra,24(sp)
    8000133e:	e822                	sd	s0,16(sp)
    80001340:	e426                	sd	s1,8(sp)
    80001342:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001344:	fffff097          	auipc	ra,0xfffff
    80001348:	7b0080e7          	jalr	1968(ra) # 80000af4 <kalloc>
    8000134c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000134e:	c519                	beqz	a0,8000135c <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001350:	6605                	lui	a2,0x1
    80001352:	4581                	li	a1,0
    80001354:	00000097          	auipc	ra,0x0
    80001358:	98c080e7          	jalr	-1652(ra) # 80000ce0 <memset>
  return pagetable;
}
    8000135c:	8526                	mv	a0,s1
    8000135e:	60e2                	ld	ra,24(sp)
    80001360:	6442                	ld	s0,16(sp)
    80001362:	64a2                	ld	s1,8(sp)
    80001364:	6105                	addi	sp,sp,32
    80001366:	8082                	ret

0000000080001368 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001368:	7179                	addi	sp,sp,-48
    8000136a:	f406                	sd	ra,40(sp)
    8000136c:	f022                	sd	s0,32(sp)
    8000136e:	ec26                	sd	s1,24(sp)
    80001370:	e84a                	sd	s2,16(sp)
    80001372:	e44e                	sd	s3,8(sp)
    80001374:	e052                	sd	s4,0(sp)
    80001376:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001378:	6785                	lui	a5,0x1
    8000137a:	04f67863          	bgeu	a2,a5,800013ca <uvminit+0x62>
    8000137e:	8a2a                	mv	s4,a0
    80001380:	89ae                	mv	s3,a1
    80001382:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001384:	fffff097          	auipc	ra,0xfffff
    80001388:	770080e7          	jalr	1904(ra) # 80000af4 <kalloc>
    8000138c:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000138e:	6605                	lui	a2,0x1
    80001390:	4581                	li	a1,0
    80001392:	00000097          	auipc	ra,0x0
    80001396:	94e080e7          	jalr	-1714(ra) # 80000ce0 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000139a:	4779                	li	a4,30
    8000139c:	86ca                	mv	a3,s2
    8000139e:	6605                	lui	a2,0x1
    800013a0:	4581                	li	a1,0
    800013a2:	8552                	mv	a0,s4
    800013a4:	00000097          	auipc	ra,0x0
    800013a8:	d0c080e7          	jalr	-756(ra) # 800010b0 <mappages>
  memmove(mem, src, sz);
    800013ac:	8626                	mv	a2,s1
    800013ae:	85ce                	mv	a1,s3
    800013b0:	854a                	mv	a0,s2
    800013b2:	00000097          	auipc	ra,0x0
    800013b6:	98e080e7          	jalr	-1650(ra) # 80000d40 <memmove>
}
    800013ba:	70a2                	ld	ra,40(sp)
    800013bc:	7402                	ld	s0,32(sp)
    800013be:	64e2                	ld	s1,24(sp)
    800013c0:	6942                	ld	s2,16(sp)
    800013c2:	69a2                	ld	s3,8(sp)
    800013c4:	6a02                	ld	s4,0(sp)
    800013c6:	6145                	addi	sp,sp,48
    800013c8:	8082                	ret
    panic("inituvm: more than a page");
    800013ca:	00007517          	auipc	a0,0x7
    800013ce:	d8e50513          	addi	a0,a0,-626 # 80008158 <digits+0x118>
    800013d2:	fffff097          	auipc	ra,0xfffff
    800013d6:	16c080e7          	jalr	364(ra) # 8000053e <panic>

00000000800013da <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013da:	1101                	addi	sp,sp,-32
    800013dc:	ec06                	sd	ra,24(sp)
    800013de:	e822                	sd	s0,16(sp)
    800013e0:	e426                	sd	s1,8(sp)
    800013e2:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013e4:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013e6:	00b67d63          	bgeu	a2,a1,80001400 <uvmdealloc+0x26>
    800013ea:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013ec:	6785                	lui	a5,0x1
    800013ee:	17fd                	addi	a5,a5,-1
    800013f0:	00f60733          	add	a4,a2,a5
    800013f4:	767d                	lui	a2,0xfffff
    800013f6:	8f71                	and	a4,a4,a2
    800013f8:	97ae                	add	a5,a5,a1
    800013fa:	8ff1                	and	a5,a5,a2
    800013fc:	00f76863          	bltu	a4,a5,8000140c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001400:	8526                	mv	a0,s1
    80001402:	60e2                	ld	ra,24(sp)
    80001404:	6442                	ld	s0,16(sp)
    80001406:	64a2                	ld	s1,8(sp)
    80001408:	6105                	addi	sp,sp,32
    8000140a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000140c:	8f99                	sub	a5,a5,a4
    8000140e:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001410:	4685                	li	a3,1
    80001412:	0007861b          	sext.w	a2,a5
    80001416:	85ba                	mv	a1,a4
    80001418:	00000097          	auipc	ra,0x0
    8000141c:	e5e080e7          	jalr	-418(ra) # 80001276 <uvmunmap>
    80001420:	b7c5                	j	80001400 <uvmdealloc+0x26>

0000000080001422 <uvmalloc>:
  if(newsz < oldsz)
    80001422:	0ab66163          	bltu	a2,a1,800014c4 <uvmalloc+0xa2>
{
    80001426:	7139                	addi	sp,sp,-64
    80001428:	fc06                	sd	ra,56(sp)
    8000142a:	f822                	sd	s0,48(sp)
    8000142c:	f426                	sd	s1,40(sp)
    8000142e:	f04a                	sd	s2,32(sp)
    80001430:	ec4e                	sd	s3,24(sp)
    80001432:	e852                	sd	s4,16(sp)
    80001434:	e456                	sd	s5,8(sp)
    80001436:	0080                	addi	s0,sp,64
    80001438:	8aaa                	mv	s5,a0
    8000143a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000143c:	6985                	lui	s3,0x1
    8000143e:	19fd                	addi	s3,s3,-1
    80001440:	95ce                	add	a1,a1,s3
    80001442:	79fd                	lui	s3,0xfffff
    80001444:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001448:	08c9f063          	bgeu	s3,a2,800014c8 <uvmalloc+0xa6>
    8000144c:	894e                	mv	s2,s3
    mem = kalloc();
    8000144e:	fffff097          	auipc	ra,0xfffff
    80001452:	6a6080e7          	jalr	1702(ra) # 80000af4 <kalloc>
    80001456:	84aa                	mv	s1,a0
    if(mem == 0){
    80001458:	c51d                	beqz	a0,80001486 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000145a:	6605                	lui	a2,0x1
    8000145c:	4581                	li	a1,0
    8000145e:	00000097          	auipc	ra,0x0
    80001462:	882080e7          	jalr	-1918(ra) # 80000ce0 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001466:	4779                	li	a4,30
    80001468:	86a6                	mv	a3,s1
    8000146a:	6605                	lui	a2,0x1
    8000146c:	85ca                	mv	a1,s2
    8000146e:	8556                	mv	a0,s5
    80001470:	00000097          	auipc	ra,0x0
    80001474:	c40080e7          	jalr	-960(ra) # 800010b0 <mappages>
    80001478:	e905                	bnez	a0,800014a8 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000147a:	6785                	lui	a5,0x1
    8000147c:	993e                	add	s2,s2,a5
    8000147e:	fd4968e3          	bltu	s2,s4,8000144e <uvmalloc+0x2c>
  return newsz;
    80001482:	8552                	mv	a0,s4
    80001484:	a809                	j	80001496 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001486:	864e                	mv	a2,s3
    80001488:	85ca                	mv	a1,s2
    8000148a:	8556                	mv	a0,s5
    8000148c:	00000097          	auipc	ra,0x0
    80001490:	f4e080e7          	jalr	-178(ra) # 800013da <uvmdealloc>
      return 0;
    80001494:	4501                	li	a0,0
}
    80001496:	70e2                	ld	ra,56(sp)
    80001498:	7442                	ld	s0,48(sp)
    8000149a:	74a2                	ld	s1,40(sp)
    8000149c:	7902                	ld	s2,32(sp)
    8000149e:	69e2                	ld	s3,24(sp)
    800014a0:	6a42                	ld	s4,16(sp)
    800014a2:	6aa2                	ld	s5,8(sp)
    800014a4:	6121                	addi	sp,sp,64
    800014a6:	8082                	ret
      kfree(mem);
    800014a8:	8526                	mv	a0,s1
    800014aa:	fffff097          	auipc	ra,0xfffff
    800014ae:	54e080e7          	jalr	1358(ra) # 800009f8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014b2:	864e                	mv	a2,s3
    800014b4:	85ca                	mv	a1,s2
    800014b6:	8556                	mv	a0,s5
    800014b8:	00000097          	auipc	ra,0x0
    800014bc:	f22080e7          	jalr	-222(ra) # 800013da <uvmdealloc>
      return 0;
    800014c0:	4501                	li	a0,0
    800014c2:	bfd1                	j	80001496 <uvmalloc+0x74>
    return oldsz;
    800014c4:	852e                	mv	a0,a1
}
    800014c6:	8082                	ret
  return newsz;
    800014c8:	8532                	mv	a0,a2
    800014ca:	b7f1                	j	80001496 <uvmalloc+0x74>

00000000800014cc <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014cc:	7179                	addi	sp,sp,-48
    800014ce:	f406                	sd	ra,40(sp)
    800014d0:	f022                	sd	s0,32(sp)
    800014d2:	ec26                	sd	s1,24(sp)
    800014d4:	e84a                	sd	s2,16(sp)
    800014d6:	e44e                	sd	s3,8(sp)
    800014d8:	e052                	sd	s4,0(sp)
    800014da:	1800                	addi	s0,sp,48
    800014dc:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014de:	84aa                	mv	s1,a0
    800014e0:	6905                	lui	s2,0x1
    800014e2:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e4:	4985                	li	s3,1
    800014e6:	a821                	j	800014fe <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014e8:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014ea:	0532                	slli	a0,a0,0xc
    800014ec:	00000097          	auipc	ra,0x0
    800014f0:	fe0080e7          	jalr	-32(ra) # 800014cc <freewalk>
      pagetable[i] = 0;
    800014f4:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f8:	04a1                	addi	s1,s1,8
    800014fa:	03248163          	beq	s1,s2,8000151c <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014fe:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001500:	00f57793          	andi	a5,a0,15
    80001504:	ff3782e3          	beq	a5,s3,800014e8 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001508:	8905                	andi	a0,a0,1
    8000150a:	d57d                	beqz	a0,800014f8 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000150c:	00007517          	auipc	a0,0x7
    80001510:	c6c50513          	addi	a0,a0,-916 # 80008178 <digits+0x138>
    80001514:	fffff097          	auipc	ra,0xfffff
    80001518:	02a080e7          	jalr	42(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    8000151c:	8552                	mv	a0,s4
    8000151e:	fffff097          	auipc	ra,0xfffff
    80001522:	4da080e7          	jalr	1242(ra) # 800009f8 <kfree>
}
    80001526:	70a2                	ld	ra,40(sp)
    80001528:	7402                	ld	s0,32(sp)
    8000152a:	64e2                	ld	s1,24(sp)
    8000152c:	6942                	ld	s2,16(sp)
    8000152e:	69a2                	ld	s3,8(sp)
    80001530:	6a02                	ld	s4,0(sp)
    80001532:	6145                	addi	sp,sp,48
    80001534:	8082                	ret

0000000080001536 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001536:	1101                	addi	sp,sp,-32
    80001538:	ec06                	sd	ra,24(sp)
    8000153a:	e822                	sd	s0,16(sp)
    8000153c:	e426                	sd	s1,8(sp)
    8000153e:	1000                	addi	s0,sp,32
    80001540:	84aa                	mv	s1,a0
  if(sz > 0)
    80001542:	e999                	bnez	a1,80001558 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001544:	8526                	mv	a0,s1
    80001546:	00000097          	auipc	ra,0x0
    8000154a:	f86080e7          	jalr	-122(ra) # 800014cc <freewalk>
}
    8000154e:	60e2                	ld	ra,24(sp)
    80001550:	6442                	ld	s0,16(sp)
    80001552:	64a2                	ld	s1,8(sp)
    80001554:	6105                	addi	sp,sp,32
    80001556:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001558:	6605                	lui	a2,0x1
    8000155a:	167d                	addi	a2,a2,-1
    8000155c:	962e                	add	a2,a2,a1
    8000155e:	4685                	li	a3,1
    80001560:	8231                	srli	a2,a2,0xc
    80001562:	4581                	li	a1,0
    80001564:	00000097          	auipc	ra,0x0
    80001568:	d12080e7          	jalr	-750(ra) # 80001276 <uvmunmap>
    8000156c:	bfe1                	j	80001544 <uvmfree+0xe>

000000008000156e <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000156e:	c679                	beqz	a2,8000163c <uvmcopy+0xce>
{
    80001570:	715d                	addi	sp,sp,-80
    80001572:	e486                	sd	ra,72(sp)
    80001574:	e0a2                	sd	s0,64(sp)
    80001576:	fc26                	sd	s1,56(sp)
    80001578:	f84a                	sd	s2,48(sp)
    8000157a:	f44e                	sd	s3,40(sp)
    8000157c:	f052                	sd	s4,32(sp)
    8000157e:	ec56                	sd	s5,24(sp)
    80001580:	e85a                	sd	s6,16(sp)
    80001582:	e45e                	sd	s7,8(sp)
    80001584:	0880                	addi	s0,sp,80
    80001586:	8b2a                	mv	s6,a0
    80001588:	8aae                	mv	s5,a1
    8000158a:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000158c:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000158e:	4601                	li	a2,0
    80001590:	85ce                	mv	a1,s3
    80001592:	855a                	mv	a0,s6
    80001594:	00000097          	auipc	ra,0x0
    80001598:	a34080e7          	jalr	-1484(ra) # 80000fc8 <walk>
    8000159c:	c531                	beqz	a0,800015e8 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000159e:	6118                	ld	a4,0(a0)
    800015a0:	00177793          	andi	a5,a4,1
    800015a4:	cbb1                	beqz	a5,800015f8 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a6:	00a75593          	srli	a1,a4,0xa
    800015aa:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015ae:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015b2:	fffff097          	auipc	ra,0xfffff
    800015b6:	542080e7          	jalr	1346(ra) # 80000af4 <kalloc>
    800015ba:	892a                	mv	s2,a0
    800015bc:	c939                	beqz	a0,80001612 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015be:	6605                	lui	a2,0x1
    800015c0:	85de                	mv	a1,s7
    800015c2:	fffff097          	auipc	ra,0xfffff
    800015c6:	77e080e7          	jalr	1918(ra) # 80000d40 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015ca:	8726                	mv	a4,s1
    800015cc:	86ca                	mv	a3,s2
    800015ce:	6605                	lui	a2,0x1
    800015d0:	85ce                	mv	a1,s3
    800015d2:	8556                	mv	a0,s5
    800015d4:	00000097          	auipc	ra,0x0
    800015d8:	adc080e7          	jalr	-1316(ra) # 800010b0 <mappages>
    800015dc:	e515                	bnez	a0,80001608 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015de:	6785                	lui	a5,0x1
    800015e0:	99be                	add	s3,s3,a5
    800015e2:	fb49e6e3          	bltu	s3,s4,8000158e <uvmcopy+0x20>
    800015e6:	a081                	j	80001626 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e8:	00007517          	auipc	a0,0x7
    800015ec:	ba050513          	addi	a0,a0,-1120 # 80008188 <digits+0x148>
    800015f0:	fffff097          	auipc	ra,0xfffff
    800015f4:	f4e080e7          	jalr	-178(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800015f8:	00007517          	auipc	a0,0x7
    800015fc:	bb050513          	addi	a0,a0,-1104 # 800081a8 <digits+0x168>
    80001600:	fffff097          	auipc	ra,0xfffff
    80001604:	f3e080e7          	jalr	-194(ra) # 8000053e <panic>
      kfree(mem);
    80001608:	854a                	mv	a0,s2
    8000160a:	fffff097          	auipc	ra,0xfffff
    8000160e:	3ee080e7          	jalr	1006(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001612:	4685                	li	a3,1
    80001614:	00c9d613          	srli	a2,s3,0xc
    80001618:	4581                	li	a1,0
    8000161a:	8556                	mv	a0,s5
    8000161c:	00000097          	auipc	ra,0x0
    80001620:	c5a080e7          	jalr	-934(ra) # 80001276 <uvmunmap>
  return -1;
    80001624:	557d                	li	a0,-1
}
    80001626:	60a6                	ld	ra,72(sp)
    80001628:	6406                	ld	s0,64(sp)
    8000162a:	74e2                	ld	s1,56(sp)
    8000162c:	7942                	ld	s2,48(sp)
    8000162e:	79a2                	ld	s3,40(sp)
    80001630:	7a02                	ld	s4,32(sp)
    80001632:	6ae2                	ld	s5,24(sp)
    80001634:	6b42                	ld	s6,16(sp)
    80001636:	6ba2                	ld	s7,8(sp)
    80001638:	6161                	addi	sp,sp,80
    8000163a:	8082                	ret
  return 0;
    8000163c:	4501                	li	a0,0
}
    8000163e:	8082                	ret

0000000080001640 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001640:	1141                	addi	sp,sp,-16
    80001642:	e406                	sd	ra,8(sp)
    80001644:	e022                	sd	s0,0(sp)
    80001646:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001648:	4601                	li	a2,0
    8000164a:	00000097          	auipc	ra,0x0
    8000164e:	97e080e7          	jalr	-1666(ra) # 80000fc8 <walk>
  if(pte == 0)
    80001652:	c901                	beqz	a0,80001662 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001654:	611c                	ld	a5,0(a0)
    80001656:	9bbd                	andi	a5,a5,-17
    80001658:	e11c                	sd	a5,0(a0)
}
    8000165a:	60a2                	ld	ra,8(sp)
    8000165c:	6402                	ld	s0,0(sp)
    8000165e:	0141                	addi	sp,sp,16
    80001660:	8082                	ret
    panic("uvmclear");
    80001662:	00007517          	auipc	a0,0x7
    80001666:	b6650513          	addi	a0,a0,-1178 # 800081c8 <digits+0x188>
    8000166a:	fffff097          	auipc	ra,0xfffff
    8000166e:	ed4080e7          	jalr	-300(ra) # 8000053e <panic>

0000000080001672 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001672:	c6bd                	beqz	a3,800016e0 <copyout+0x6e>
{
    80001674:	715d                	addi	sp,sp,-80
    80001676:	e486                	sd	ra,72(sp)
    80001678:	e0a2                	sd	s0,64(sp)
    8000167a:	fc26                	sd	s1,56(sp)
    8000167c:	f84a                	sd	s2,48(sp)
    8000167e:	f44e                	sd	s3,40(sp)
    80001680:	f052                	sd	s4,32(sp)
    80001682:	ec56                	sd	s5,24(sp)
    80001684:	e85a                	sd	s6,16(sp)
    80001686:	e45e                	sd	s7,8(sp)
    80001688:	e062                	sd	s8,0(sp)
    8000168a:	0880                	addi	s0,sp,80
    8000168c:	8b2a                	mv	s6,a0
    8000168e:	8c2e                	mv	s8,a1
    80001690:	8a32                	mv	s4,a2
    80001692:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001694:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001696:	6a85                	lui	s5,0x1
    80001698:	a015                	j	800016bc <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000169a:	9562                	add	a0,a0,s8
    8000169c:	0004861b          	sext.w	a2,s1
    800016a0:	85d2                	mv	a1,s4
    800016a2:	41250533          	sub	a0,a0,s2
    800016a6:	fffff097          	auipc	ra,0xfffff
    800016aa:	69a080e7          	jalr	1690(ra) # 80000d40 <memmove>

    len -= n;
    800016ae:	409989b3          	sub	s3,s3,s1
    src += n;
    800016b2:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016b4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b8:	02098263          	beqz	s3,800016dc <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016bc:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016c0:	85ca                	mv	a1,s2
    800016c2:	855a                	mv	a0,s6
    800016c4:	00000097          	auipc	ra,0x0
    800016c8:	9aa080e7          	jalr	-1622(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800016cc:	cd01                	beqz	a0,800016e4 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016ce:	418904b3          	sub	s1,s2,s8
    800016d2:	94d6                	add	s1,s1,s5
    if(n > len)
    800016d4:	fc99f3e3          	bgeu	s3,s1,8000169a <copyout+0x28>
    800016d8:	84ce                	mv	s1,s3
    800016da:	b7c1                	j	8000169a <copyout+0x28>
  }
  return 0;
    800016dc:	4501                	li	a0,0
    800016de:	a021                	j	800016e6 <copyout+0x74>
    800016e0:	4501                	li	a0,0
}
    800016e2:	8082                	ret
      return -1;
    800016e4:	557d                	li	a0,-1
}
    800016e6:	60a6                	ld	ra,72(sp)
    800016e8:	6406                	ld	s0,64(sp)
    800016ea:	74e2                	ld	s1,56(sp)
    800016ec:	7942                	ld	s2,48(sp)
    800016ee:	79a2                	ld	s3,40(sp)
    800016f0:	7a02                	ld	s4,32(sp)
    800016f2:	6ae2                	ld	s5,24(sp)
    800016f4:	6b42                	ld	s6,16(sp)
    800016f6:	6ba2                	ld	s7,8(sp)
    800016f8:	6c02                	ld	s8,0(sp)
    800016fa:	6161                	addi	sp,sp,80
    800016fc:	8082                	ret

00000000800016fe <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016fe:	c6bd                	beqz	a3,8000176c <copyin+0x6e>
{
    80001700:	715d                	addi	sp,sp,-80
    80001702:	e486                	sd	ra,72(sp)
    80001704:	e0a2                	sd	s0,64(sp)
    80001706:	fc26                	sd	s1,56(sp)
    80001708:	f84a                	sd	s2,48(sp)
    8000170a:	f44e                	sd	s3,40(sp)
    8000170c:	f052                	sd	s4,32(sp)
    8000170e:	ec56                	sd	s5,24(sp)
    80001710:	e85a                	sd	s6,16(sp)
    80001712:	e45e                	sd	s7,8(sp)
    80001714:	e062                	sd	s8,0(sp)
    80001716:	0880                	addi	s0,sp,80
    80001718:	8b2a                	mv	s6,a0
    8000171a:	8a2e                	mv	s4,a1
    8000171c:	8c32                	mv	s8,a2
    8000171e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001720:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001722:	6a85                	lui	s5,0x1
    80001724:	a015                	j	80001748 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001726:	9562                	add	a0,a0,s8
    80001728:	0004861b          	sext.w	a2,s1
    8000172c:	412505b3          	sub	a1,a0,s2
    80001730:	8552                	mv	a0,s4
    80001732:	fffff097          	auipc	ra,0xfffff
    80001736:	60e080e7          	jalr	1550(ra) # 80000d40 <memmove>

    len -= n;
    8000173a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001740:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001744:	02098263          	beqz	s3,80001768 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001748:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000174c:	85ca                	mv	a1,s2
    8000174e:	855a                	mv	a0,s6
    80001750:	00000097          	auipc	ra,0x0
    80001754:	91e080e7          	jalr	-1762(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    80001758:	cd01                	beqz	a0,80001770 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000175a:	418904b3          	sub	s1,s2,s8
    8000175e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001760:	fc99f3e3          	bgeu	s3,s1,80001726 <copyin+0x28>
    80001764:	84ce                	mv	s1,s3
    80001766:	b7c1                	j	80001726 <copyin+0x28>
  }
  return 0;
    80001768:	4501                	li	a0,0
    8000176a:	a021                	j	80001772 <copyin+0x74>
    8000176c:	4501                	li	a0,0
}
    8000176e:	8082                	ret
      return -1;
    80001770:	557d                	li	a0,-1
}
    80001772:	60a6                	ld	ra,72(sp)
    80001774:	6406                	ld	s0,64(sp)
    80001776:	74e2                	ld	s1,56(sp)
    80001778:	7942                	ld	s2,48(sp)
    8000177a:	79a2                	ld	s3,40(sp)
    8000177c:	7a02                	ld	s4,32(sp)
    8000177e:	6ae2                	ld	s5,24(sp)
    80001780:	6b42                	ld	s6,16(sp)
    80001782:	6ba2                	ld	s7,8(sp)
    80001784:	6c02                	ld	s8,0(sp)
    80001786:	6161                	addi	sp,sp,80
    80001788:	8082                	ret

000000008000178a <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000178a:	c6c5                	beqz	a3,80001832 <copyinstr+0xa8>
{
    8000178c:	715d                	addi	sp,sp,-80
    8000178e:	e486                	sd	ra,72(sp)
    80001790:	e0a2                	sd	s0,64(sp)
    80001792:	fc26                	sd	s1,56(sp)
    80001794:	f84a                	sd	s2,48(sp)
    80001796:	f44e                	sd	s3,40(sp)
    80001798:	f052                	sd	s4,32(sp)
    8000179a:	ec56                	sd	s5,24(sp)
    8000179c:	e85a                	sd	s6,16(sp)
    8000179e:	e45e                	sd	s7,8(sp)
    800017a0:	0880                	addi	s0,sp,80
    800017a2:	8a2a                	mv	s4,a0
    800017a4:	8b2e                	mv	s6,a1
    800017a6:	8bb2                	mv	s7,a2
    800017a8:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017aa:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017ac:	6985                	lui	s3,0x1
    800017ae:	a035                	j	800017da <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017b0:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b4:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b6:	0017b793          	seqz	a5,a5
    800017ba:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017be:	60a6                	ld	ra,72(sp)
    800017c0:	6406                	ld	s0,64(sp)
    800017c2:	74e2                	ld	s1,56(sp)
    800017c4:	7942                	ld	s2,48(sp)
    800017c6:	79a2                	ld	s3,40(sp)
    800017c8:	7a02                	ld	s4,32(sp)
    800017ca:	6ae2                	ld	s5,24(sp)
    800017cc:	6b42                	ld	s6,16(sp)
    800017ce:	6ba2                	ld	s7,8(sp)
    800017d0:	6161                	addi	sp,sp,80
    800017d2:	8082                	ret
    srcva = va0 + PGSIZE;
    800017d4:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d8:	c8a9                	beqz	s1,8000182a <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017da:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017de:	85ca                	mv	a1,s2
    800017e0:	8552                	mv	a0,s4
    800017e2:	00000097          	auipc	ra,0x0
    800017e6:	88c080e7          	jalr	-1908(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800017ea:	c131                	beqz	a0,8000182e <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017ec:	41790833          	sub	a6,s2,s7
    800017f0:	984e                	add	a6,a6,s3
    if(n > max)
    800017f2:	0104f363          	bgeu	s1,a6,800017f8 <copyinstr+0x6e>
    800017f6:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f8:	955e                	add	a0,a0,s7
    800017fa:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017fe:	fc080be3          	beqz	a6,800017d4 <copyinstr+0x4a>
    80001802:	985a                	add	a6,a6,s6
    80001804:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001806:	41650633          	sub	a2,a0,s6
    8000180a:	14fd                	addi	s1,s1,-1
    8000180c:	9b26                	add	s6,s6,s1
    8000180e:	00f60733          	add	a4,a2,a5
    80001812:	00074703          	lbu	a4,0(a4)
    80001816:	df49                	beqz	a4,800017b0 <copyinstr+0x26>
        *dst = *p;
    80001818:	00e78023          	sb	a4,0(a5)
      --max;
    8000181c:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001820:	0785                	addi	a5,a5,1
    while(n > 0){
    80001822:	ff0796e3          	bne	a5,a6,8000180e <copyinstr+0x84>
      dst++;
    80001826:	8b42                	mv	s6,a6
    80001828:	b775                	j	800017d4 <copyinstr+0x4a>
    8000182a:	4781                	li	a5,0
    8000182c:	b769                	j	800017b6 <copyinstr+0x2c>
      return -1;
    8000182e:	557d                	li	a0,-1
    80001830:	b779                	j	800017be <copyinstr+0x34>
  int got_null = 0;
    80001832:	4781                	li	a5,0
  if(got_null){
    80001834:	0017b793          	seqz	a5,a5
    80001838:	40f00533          	neg	a0,a5
}
    8000183c:	8082                	ret

000000008000183e <lists_init>:

extern char trampoline[]; // trampoline.S

extern uint64 cas(volatile void* addr, int expected, int newval);

void lists_init(void){
    8000183e:	1141                	addi	sp,sp,-16
    80001840:	e422                	sd	s0,8(sp)
    80001842:	0800                	addi	s0,sp,16

  
  
  unused_list.head = -1;
    80001844:	00010797          	auipc	a5,0x10
    80001848:	a5c78793          	addi	a5,a5,-1444 # 800112a0 <runnable_cpu_lists>
    8000184c:	56fd                	li	a3,-1
    8000184e:	dfb4                	sw	a3,120(a5)
  unused_list.counter = -1;
    80001850:	577d                	li	a4,-1
    80001852:	efd8                	sd	a4,152(a5)
  unused_list.last = -1;
    80001854:	dff8                	sw	a4,124(a5)
  
  sleeping_list.head = -1;
    80001856:	0ad7a023          	sw	a3,160(a5)
  sleeping_list.last = -1;
    8000185a:	0ad7a223          	sw	a3,164(a5)
  sleeping_list.counter = -1;
    8000185e:	e3f8                	sd	a4,192(a5)
  zombie_list.head = -1;
    80001860:	0ce7a423          	sw	a4,200(a5)
  zombie_list.last = -1;
    80001864:	0ce7a623          	sw	a4,204(a5)
  zombie_list.counter = -1;
    80001868:	f7f8                	sd	a4,232(a5)
  struct processList* p;
  for (p = runnable_cpu_lists; p<&runnable_cpu_lists[current_cpu_number]; p++){
    8000186a:	00010697          	auipc	a3,0x10
    8000186e:	aae68693          	addi	a3,a3,-1362 # 80011318 <unused_list>
      
      p->head = -1;
    80001872:	c398                	sw	a4,0(a5)
      p->last = -1;
    80001874:	c3d8                	sw	a4,4(a5)
      p->counter = 0;
    80001876:	0207b023          	sd	zero,32(a5)
  for (p = runnable_cpu_lists; p<&runnable_cpu_lists[current_cpu_number]; p++){
    8000187a:	02878793          	addi	a5,a5,40
    8000187e:	fed79ae3          	bne	a5,a3,80001872 <lists_init+0x34>
  }
  
}
    80001882:	6422                	ld	s0,8(sp)
    80001884:	0141                	addi	sp,sp,16
    80001886:	8082                	ret

0000000080001888 <get_balanced_cpu>:

int get_balanced_cpu(void){
    80001888:	1141                	addi	sp,sp,-16
    8000188a:	e422                	sd	s0,8(sp)
    8000188c:	0800                	addi	s0,sp,16

    uint64 min = runnable_cpu_lists[0].counter;
    8000188e:	00010797          	auipc	a5,0x10
    80001892:	a1278793          	addi	a5,a5,-1518 # 800112a0 <runnable_cpu_lists>
    80001896:	7398                	ld	a4,32(a5)
    if (current_cpu_number < 2)
      return 0;
    int index = 1;
    struct processList* p = &runnable_cpu_lists[1];
    for (;p<&runnable_cpu_lists[current_cpu_number];p++){
        if (p->counter<min){
    80001898:	67bc                	ld	a5,72(a5)
    int index = 1;
    8000189a:	4505                	li	a0,1
        if (p->counter<min){
    8000189c:	00e7e463          	bltu	a5,a4,800018a4 <get_balanced_cpu+0x1c>
    uint64 min = runnable_cpu_lists[0].counter;
    800018a0:	87ba                	mv	a5,a4
    int min_cpu = 0;
    800018a2:	4501                	li	a0,0
        if (p->counter<min){
    800018a4:	00010717          	auipc	a4,0x10
    800018a8:	a6c73703          	ld	a4,-1428(a4) # 80011310 <runnable_cpu_lists+0x70>
    800018ac:	00f77363          	bgeu	a4,a5,800018b2 <get_balanced_cpu+0x2a>
            min = p->counter;
            min_cpu = index;
        }
        index++;
    800018b0:	4509                	li	a0,2
    }

    return min_cpu;

}
    800018b2:	6422                	ld	s0,8(sp)
    800018b4:	0141                	addi	sp,sp,16
    800018b6:	8082                	ret

00000000800018b8 <remove_link>:
void remove_link(struct processList* list, int index){  // index = the process index in proc
    800018b8:	715d                	addi	sp,sp,-80
    800018ba:	e486                	sd	ra,72(sp)
    800018bc:	e0a2                	sd	s0,64(sp)
    800018be:	fc26                	sd	s1,56(sp)
    800018c0:	f84a                	sd	s2,48(sp)
    800018c2:	f44e                	sd	s3,40(sp)
    800018c4:	f052                	sd	s4,32(sp)
    800018c6:	ec56                	sd	s5,24(sp)
    800018c8:	e85a                	sd	s6,16(sp)
    800018ca:	e45e                	sd	s7,8(sp)
    800018cc:	0880                	addi	s0,sp,80
    800018ce:	8aaa                	mv	s5,a0
    800018d0:	892e                	mv	s2,a1
  //printf("start remove proc with index %d\n", index);
  acquire(&list->head_lock);
    800018d2:	00850993          	addi	s3,a0,8
    800018d6:	854e                	mv	a0,s3
    800018d8:	fffff097          	auipc	ra,0xfffff
    800018dc:	30c080e7          	jalr	780(ra) # 80000be4 <acquire>
  if (list->head == -1){  //empty list
    800018e0:	000aa503          	lw	a0,0(s5) # fffffffffffff000 <end+0xffffffff7ffd9000>
    800018e4:	57fd                	li	a5,-1
    800018e6:	1af50363          	beq	a0,a5,80001a8c <remove_link+0x1d4>
    return;
  }
  acquire(&proc[list->head].list_lock);
    800018ea:	19000793          	li	a5,400
    800018ee:	02f50533          	mul	a0,a0,a5
    800018f2:	00010797          	auipc	a5,0x10
    800018f6:	ee678793          	addi	a5,a5,-282 # 800117d8 <proc+0x18>
    800018fa:	953e                	add	a0,a0,a5
    800018fc:	fffff097          	auipc	ra,0xfffff
    80001900:	2e8080e7          	jalr	744(ra) # 80000be4 <acquire>
  struct proc* head = &proc[list->head];
    80001904:	000aab83          	lw	s7,0(s5)
  if (list->head == list->last){  //list of size 1
    80001908:	004aa783          	lw	a5,4(s5)
    8000190c:	0b778763          	beq	a5,s7,800019ba <remove_link+0x102>
      release(&head->list_lock);
      release(&list->head_lock);
      return;
  }
  else{  //list of size > 1 and removing the head
    if (head->proc_index == index){
    80001910:	19000793          	li	a5,400
    80001914:	02fb8733          	mul	a4,s7,a5
    80001918:	00010797          	auipc	a5,0x10
    8000191c:	ea878793          	addi	a5,a5,-344 # 800117c0 <proc>
    80001920:	97ba                	add	a5,a5,a4
    80001922:	1847a783          	lw	a5,388(a5)
    80001926:	0f278b63          	beq	a5,s2,80001a1c <remove_link+0x164>
  struct proc* head = &proc[list->head];
    8000192a:	19000493          	li	s1,400
    8000192e:	029b8bb3          	mul	s7,s7,s1
    80001932:	00010a17          	auipc	s4,0x10
    80001936:	e8ea0a13          	addi	s4,s4,-370 # 800117c0 <proc>
    8000193a:	9bd2                	add	s7,s7,s4
      release(&list->head_lock);
      return;
    }
  }
  
  acquire(&proc[head->next_proc_index].list_lock);
    8000193c:	180ba503          	lw	a0,384(s7) # fffffffffffff180 <end+0xffffffff7ffd9180>
    80001940:	02950533          	mul	a0,a0,s1
    80001944:	0561                	addi	a0,a0,24
    80001946:	9552                	add	a0,a0,s4
    80001948:	fffff097          	auipc	ra,0xfffff
    8000194c:	29c080e7          	jalr	668(ra) # 80000be4 <acquire>
  struct proc* next = &proc[head->next_proc_index];
    80001950:	180ba783          	lw	a5,384(s7)
    80001954:	029784b3          	mul	s1,a5,s1
    80001958:	94d2                	add	s1,s1,s4
  release(&list->head_lock);
    8000195a:	854e                	mv	a0,s3
    8000195c:	fffff097          	auipc	ra,0xfffff
    80001960:	33c080e7          	jalr	828(ra) # 80000c98 <release>
  while(next->proc_index != index && next->next_proc_index != -1){
    80001964:	1844a703          	lw	a4,388(s1)
    80001968:	5b7d                	li	s6,-1
      release(&head->list_lock);
      head = next;
      acquire(&proc[head->next_proc_index].list_lock);
    8000196a:	19000a13          	li	s4,400
    8000196e:	00010997          	auipc	s3,0x10
    80001972:	e5298993          	addi	s3,s3,-430 # 800117c0 <proc>
  while(next->proc_index != index && next->next_proc_index != -1){
    80001976:	0ce90d63          	beq	s2,a4,80001a50 <remove_link+0x198>
    8000197a:	1804a783          	lw	a5,384(s1)
    8000197e:	0f678963          	beq	a5,s6,80001a70 <remove_link+0x1b8>
      release(&head->list_lock);
    80001982:	018b8513          	addi	a0,s7,24
    80001986:	fffff097          	auipc	ra,0xfffff
    8000198a:	312080e7          	jalr	786(ra) # 80000c98 <release>
      acquire(&proc[head->next_proc_index].list_lock);
    8000198e:	1804a503          	lw	a0,384(s1)
    80001992:	03450533          	mul	a0,a0,s4
    80001996:	0561                	addi	a0,a0,24
    80001998:	954e                	add	a0,a0,s3
    8000199a:	fffff097          	auipc	ra,0xfffff
    8000199e:	24a080e7          	jalr	586(ra) # 80000be4 <acquire>
      next = &proc[next->next_proc_index];
    800019a2:	1804a783          	lw	a5,384(s1)
    800019a6:	034787b3          	mul	a5,a5,s4
    800019aa:	97ce                	add	a5,a5,s3
  while(next->proc_index != index && next->next_proc_index != -1){
    800019ac:	1847a703          	lw	a4,388(a5)
    800019b0:	8ba6                	mv	s7,s1
    800019b2:	0b270163          	beq	a4,s2,80001a54 <remove_link+0x19c>
      next = &proc[next->next_proc_index];
    800019b6:	84be                	mv	s1,a5
    800019b8:	b7c9                	j	8000197a <remove_link+0xc2>
    if (head->proc_index == index){
    800019ba:	19000793          	li	a5,400
    800019be:	02fb8733          	mul	a4,s7,a5
    800019c2:	00010797          	auipc	a5,0x10
    800019c6:	dfe78793          	addi	a5,a5,-514 # 800117c0 <proc>
    800019ca:	97ba                	add	a5,a5,a4
    800019cc:	1847a783          	lw	a5,388(a5)
    800019d0:	03278563          	beq	a5,s2,800019fa <remove_link+0x142>
      release(&head->list_lock);
    800019d4:	19000513          	li	a0,400
    800019d8:	02ab8bb3          	mul	s7,s7,a0
    800019dc:	00010517          	auipc	a0,0x10
    800019e0:	dfc50513          	addi	a0,a0,-516 # 800117d8 <proc+0x18>
    800019e4:	955e                	add	a0,a0,s7
    800019e6:	fffff097          	auipc	ra,0xfffff
    800019ea:	2b2080e7          	jalr	690(ra) # 80000c98 <release>
      release(&list->head_lock);
    800019ee:	854e                	mv	a0,s3
    800019f0:	fffff097          	auipc	ra,0xfffff
    800019f4:	2a8080e7          	jalr	680(ra) # 80000c98 <release>
      return;
    800019f8:	a851                	j	80001a8c <remove_link+0x1d4>
      list->head = -1;
    800019fa:	577d                	li	a4,-1
    800019fc:	00eaa023          	sw	a4,0(s5)
      list->last = -1;
    80001a00:	00eaa223          	sw	a4,4(s5)
      head->next_proc_index = -1;
    80001a04:	19000793          	li	a5,400
    80001a08:	02fb86b3          	mul	a3,s7,a5
    80001a0c:	00010797          	auipc	a5,0x10
    80001a10:	db478793          	addi	a5,a5,-588 # 800117c0 <proc>
    80001a14:	97b6                	add	a5,a5,a3
    80001a16:	18e7a023          	sw	a4,384(a5)
    80001a1a:	bf6d                	j	800019d4 <remove_link+0x11c>
      list->head = head->next_proc_index;
    80001a1c:	00010517          	auipc	a0,0x10
    80001a20:	da450513          	addi	a0,a0,-604 # 800117c0 <proc>
    80001a24:	8bba                	mv	s7,a4
    80001a26:	00e507b3          	add	a5,a0,a4
    80001a2a:	1807a703          	lw	a4,384(a5)
    80001a2e:	00eaa023          	sw	a4,0(s5)
      head->next_proc_index = -1;
    80001a32:	577d                	li	a4,-1
    80001a34:	18e7a023          	sw	a4,384(a5)
      release(&head->list_lock);
    80001a38:	0be1                	addi	s7,s7,24
    80001a3a:	955e                	add	a0,a0,s7
    80001a3c:	fffff097          	auipc	ra,0xfffff
    80001a40:	25c080e7          	jalr	604(ra) # 80000c98 <release>
      release(&list->head_lock);
    80001a44:	854e                	mv	a0,s3
    80001a46:	fffff097          	auipc	ra,0xfffff
    80001a4a:	252080e7          	jalr	594(ra) # 80000c98 <release>
      return;
    80001a4e:	a83d                	j	80001a8c <remove_link+0x1d4>
  struct proc* next = &proc[head->next_proc_index];
    80001a50:	87a6                	mv	a5,s1
  struct proc* head = &proc[list->head];
    80001a52:	84de                	mv	s1,s7
  }
  if (next->proc_index == index){
      head->next_proc_index = next->next_proc_index;
    80001a54:	1807a703          	lw	a4,384(a5)
    80001a58:	18e4a023          	sw	a4,384(s1)
      next->next_proc_index = -1;
    80001a5c:	577d                	li	a4,-1
    80001a5e:	18e7a023          	sw	a4,384(a5)
      if (next->next_proc_index == -1){
          list->last = head->proc_index;
    80001a62:	1844a703          	lw	a4,388(s1)
    80001a66:	00eaa223          	sw	a4,4(s5)
    80001a6a:	8ba6                	mv	s7,s1
    80001a6c:	84be                	mv	s1,a5
    80001a6e:	a019                	j	80001a74 <remove_link+0x1bc>
  if (next->proc_index == index){
    80001a70:	02e90963          	beq	s2,a4,80001aa2 <remove_link+0x1ea>
      }
    }
  release(&head->list_lock);
    80001a74:	018b8513          	addi	a0,s7,24
    80001a78:	fffff097          	auipc	ra,0xfffff
    80001a7c:	220080e7          	jalr	544(ra) # 80000c98 <release>
  release(&next->list_lock);
    80001a80:	01848513          	addi	a0,s1,24
    80001a84:	fffff097          	auipc	ra,0xfffff
    80001a88:	214080e7          	jalr	532(ra) # 80000c98 <release>


}
    80001a8c:	60a6                	ld	ra,72(sp)
    80001a8e:	6406                	ld	s0,64(sp)
    80001a90:	74e2                	ld	s1,56(sp)
    80001a92:	7942                	ld	s2,48(sp)
    80001a94:	79a2                	ld	s3,40(sp)
    80001a96:	7a02                	ld	s4,32(sp)
    80001a98:	6ae2                	ld	s5,24(sp)
    80001a9a:	6b42                	ld	s6,16(sp)
    80001a9c:	6ba2                	ld	s7,8(sp)
    80001a9e:	6161                	addi	sp,sp,80
    80001aa0:	8082                	ret
    80001aa2:	87a6                	mv	a5,s1
    80001aa4:	84de                	mv	s1,s7
    80001aa6:	b77d                	j	80001a54 <remove_link+0x19c>

0000000080001aa8 <increment_counter>:

uint64 increment_counter(struct processList* list){
    80001aa8:	7179                	addi	sp,sp,-48
    80001aaa:	f406                	sd	ra,40(sp)
    80001aac:	f022                	sd	s0,32(sp)
    80001aae:	ec26                	sd	s1,24(sp)
    80001ab0:	e84a                	sd	s2,16(sp)
    80001ab2:	e44e                	sd	s3,8(sp)
    80001ab4:	1800                	addi	s0,sp,48
    80001ab6:	892a                	mv	s2,a0
  uint64 old;
  do {
    old = list->counter;
  } while(cas(&list->counter, old,old+1));
    80001ab8:	02050993          	addi	s3,a0,32
    old = list->counter;
    80001abc:	02093483          	ld	s1,32(s2) # 1020 <_entry-0x7fffefe0>
  } while(cas(&list->counter, old,old+1));
    80001ac0:	0014861b          	addiw	a2,s1,1
    80001ac4:	0004859b          	sext.w	a1,s1
    80001ac8:	854e                	mv	a0,s3
    80001aca:	00005097          	auipc	ra,0x5
    80001ace:	1bc080e7          	jalr	444(ra) # 80006c86 <cas>
    80001ad2:	f56d                	bnez	a0,80001abc <increment_counter+0x14>

  return old+1;
}
    80001ad4:	00148513          	addi	a0,s1,1
    80001ad8:	70a2                	ld	ra,40(sp)
    80001ada:	7402                	ld	s0,32(sp)
    80001adc:	64e2                	ld	s1,24(sp)
    80001ade:	6942                	ld	s2,16(sp)
    80001ae0:	69a2                	ld	s3,8(sp)
    80001ae2:	6145                	addi	sp,sp,48
    80001ae4:	8082                	ret

0000000080001ae6 <add_link>:

void add_link(struct processList* list, int index, int is_yield){ // index = the process index in proc
    80001ae6:	715d                	addi	sp,sp,-80
    80001ae8:	e486                	sd	ra,72(sp)
    80001aea:	e0a2                	sd	s0,64(sp)
    80001aec:	fc26                	sd	s1,56(sp)
    80001aee:	f84a                	sd	s2,48(sp)
    80001af0:	f44e                	sd	s3,40(sp)
    80001af2:	f052                	sd	s4,32(sp)
    80001af4:	ec56                	sd	s5,24(sp)
    80001af6:	e85a                	sd	s6,16(sp)
    80001af8:	e45e                	sd	s7,8(sp)
    80001afa:	0880                	addi	s0,sp,80
    80001afc:	84aa                	mv	s1,a0
    80001afe:	892e                	mv	s2,a1
    80001b00:	8ab2                	mv	s5,a2
 
  acquire(&list->head_lock);
    80001b02:	00850b13          	addi	s6,a0,8
    80001b06:	855a                	mv	a0,s6
    80001b08:	fffff097          	auipc	ra,0xfffff
    80001b0c:	0dc080e7          	jalr	220(ra) # 80000be4 <acquire>
  acquire(&proc[index].list_lock);
    80001b10:	19000993          	li	s3,400
    80001b14:	033909b3          	mul	s3,s2,s3
    80001b18:	00010797          	auipc	a5,0x10
    80001b1c:	cc078793          	addi	a5,a5,-832 # 800117d8 <proc+0x18>
    80001b20:	99be                	add	s3,s3,a5
    80001b22:	854e                	mv	a0,s3
    80001b24:	fffff097          	auipc	ra,0xfffff
    80001b28:	0c0080e7          	jalr	192(ra) # 80000be4 <acquire>
  //printf("index to insert is %d\n",index);
  //printf("list head is %d\n", list->head);
  //printf("list last is %d\n", list->last);
  //procdump();
  
  if (list->head == -1){  //empty list
    80001b2c:	0004ab83          	lw	s7,0(s1)
    80001b30:	57fd                	li	a5,-1
    80001b32:	0cfb8063          	beq	s7,a5,80001bf2 <add_link+0x10c>
    }
    //printf("finished add_link\n");
    return;
  }
  struct proc* head = &proc[list->head];
  acquire(&head->list_lock);
    80001b36:	19000a13          	li	s4,400
    80001b3a:	034b8a33          	mul	s4,s7,s4
    80001b3e:	00010797          	auipc	a5,0x10
    80001b42:	c9a78793          	addi	a5,a5,-870 # 800117d8 <proc+0x18>
    80001b46:	9a3e                	add	s4,s4,a5
    80001b48:	8552                	mv	a0,s4
    80001b4a:	fffff097          	auipc	ra,0xfffff
    80001b4e:	09a080e7          	jalr	154(ra) # 80000be4 <acquire>
  if (list->head == list->last){  //list of size 1
    80001b52:	4098                	lw	a4,0(s1)
    80001b54:	40dc                	lw	a5,4(s1)
    80001b56:	0ef70463          	beq	a4,a5,80001c3e <add_link+0x158>
      release(&head->list_lock);
      release(&list->head_lock);
      release(&proc[index].list_lock);
      return;
  }
  release(&list->head_lock);
    80001b5a:	855a                	mv	a0,s6
    80001b5c:	fffff097          	auipc	ra,0xfffff
    80001b60:	13c080e7          	jalr	316(ra) # 80000c98 <release>
  release(&head->list_lock);
    80001b64:	8552                	mv	a0,s4
    80001b66:	fffff097          	auipc	ra,0xfffff
    80001b6a:	132080e7          	jalr	306(ra) # 80000c98 <release>
  acquire(&proc[list->last].list_lock);
    80001b6e:	40c8                	lw	a0,4(s1)
    80001b70:	19000b93          	li	s7,400
    80001b74:	03750533          	mul	a0,a0,s7
    80001b78:	0561                	addi	a0,a0,24
    80001b7a:	00010a17          	auipc	s4,0x10
    80001b7e:	c46a0a13          	addi	s4,s4,-954 # 800117c0 <proc>
    80001b82:	9552                	add	a0,a0,s4
    80001b84:	fffff097          	auipc	ra,0xfffff
    80001b88:	060080e7          	jalr	96(ra) # 80000be4 <acquire>
  struct proc* last = &proc[list->last];
    80001b8c:	0044ab03          	lw	s6,4(s1)
  last->next_proc_index = index;
    80001b90:	037b07b3          	mul	a5,s6,s7
    80001b94:	97d2                	add	a5,a5,s4
    80001b96:	1927a023          	sw	s2,384(a5)
  list->last = index;
    80001b9a:	0124a223          	sw	s2,4(s1)
  p->next_proc_index = -1;
    80001b9e:	03790933          	mul	s2,s2,s7
    80001ba2:	9952                	add	s2,s2,s4
    80001ba4:	57fd                	li	a5,-1
    80001ba6:	18f92023          	sw	a5,384(s2)
  if (balance && list->counter >= 0 && !is_yield){
    80001baa:	00007797          	auipc	a5,0x7
    80001bae:	cfe7a783          	lw	a5,-770(a5) # 800088a8 <balance>
    80001bb2:	c399                	beqz	a5,80001bb8 <add_link+0xd2>
    80001bb4:	0e0a8563          	beqz	s5,80001c9e <add_link+0x1b8>
    increment_counter(list);
  }
  release(&last->list_lock);
    80001bb8:	19000513          	li	a0,400
    80001bbc:	02ab0b33          	mul	s6,s6,a0
    80001bc0:	00010517          	auipc	a0,0x10
    80001bc4:	c1850513          	addi	a0,a0,-1000 # 800117d8 <proc+0x18>
    80001bc8:	955a                	add	a0,a0,s6
    80001bca:	fffff097          	auipc	ra,0xfffff
    80001bce:	0ce080e7          	jalr	206(ra) # 80000c98 <release>
  release(&proc[index].list_lock);
    80001bd2:	854e                	mv	a0,s3
    80001bd4:	fffff097          	auipc	ra,0xfffff
    80001bd8:	0c4080e7          	jalr	196(ra) # 80000c98 <release>
  
  return;


}
    80001bdc:	60a6                	ld	ra,72(sp)
    80001bde:	6406                	ld	s0,64(sp)
    80001be0:	74e2                	ld	s1,56(sp)
    80001be2:	7942                	ld	s2,48(sp)
    80001be4:	79a2                	ld	s3,40(sp)
    80001be6:	7a02                	ld	s4,32(sp)
    80001be8:	6ae2                	ld	s5,24(sp)
    80001bea:	6b42                	ld	s6,16(sp)
    80001bec:	6ba2                	ld	s7,8(sp)
    80001bee:	6161                	addi	sp,sp,80
    80001bf0:	8082                	ret
    list->head = index;
    80001bf2:	0124a023          	sw	s2,0(s1)
    list->last = index;
    80001bf6:	0124a223          	sw	s2,4(s1)
    p->next_proc_index = -1;
    80001bfa:	19000593          	li	a1,400
    80001bfe:	02b905b3          	mul	a1,s2,a1
    80001c02:	00010917          	auipc	s2,0x10
    80001c06:	bbe90913          	addi	s2,s2,-1090 # 800117c0 <proc>
    80001c0a:	992e                	add	s2,s2,a1
    80001c0c:	18f92023          	sw	a5,384(s2)
    release(&list->head_lock);
    80001c10:	855a                	mv	a0,s6
    80001c12:	fffff097          	auipc	ra,0xfffff
    80001c16:	086080e7          	jalr	134(ra) # 80000c98 <release>
    release(&proc[index].list_lock);
    80001c1a:	854e                	mv	a0,s3
    80001c1c:	fffff097          	auipc	ra,0xfffff
    80001c20:	07c080e7          	jalr	124(ra) # 80000c98 <release>
    if (balance && !is_yield && list->counter >= 0 ){
    80001c24:	00007797          	auipc	a5,0x7
    80001c28:	c847a783          	lw	a5,-892(a5) # 800088a8 <balance>
    80001c2c:	dbc5                	beqz	a5,80001bdc <add_link+0xf6>
    80001c2e:	fa0a97e3          	bnez	s5,80001bdc <add_link+0xf6>
      increment_counter(list);
    80001c32:	8526                	mv	a0,s1
    80001c34:	00000097          	auipc	ra,0x0
    80001c38:	e74080e7          	jalr	-396(ra) # 80001aa8 <increment_counter>
    80001c3c:	b745                	j	80001bdc <add_link+0xf6>
      head->next_proc_index = index;
    80001c3e:	00010717          	auipc	a4,0x10
    80001c42:	b8270713          	addi	a4,a4,-1150 # 800117c0 <proc>
    80001c46:	19000593          	li	a1,400
    80001c4a:	02bb87b3          	mul	a5,s7,a1
    80001c4e:	97ba                	add	a5,a5,a4
    80001c50:	1927a023          	sw	s2,384(a5)
      list->last = index;
    80001c54:	0124a223          	sw	s2,4(s1)
      p->next_proc_index = -1;
    80001c58:	02b90933          	mul	s2,s2,a1
    80001c5c:	974a                	add	a4,a4,s2
    80001c5e:	57fd                	li	a5,-1
    80001c60:	18f72023          	sw	a5,384(a4)
      if (balance && list->counter >= 0 && !is_yield){
    80001c64:	00007797          	auipc	a5,0x7
    80001c68:	c447a783          	lw	a5,-956(a5) # 800088a8 <balance>
    80001c6c:	c399                	beqz	a5,80001c72 <add_link+0x18c>
    80001c6e:	020a8263          	beqz	s5,80001c92 <add_link+0x1ac>
      release(&head->list_lock);
    80001c72:	8552                	mv	a0,s4
    80001c74:	fffff097          	auipc	ra,0xfffff
    80001c78:	024080e7          	jalr	36(ra) # 80000c98 <release>
      release(&list->head_lock);
    80001c7c:	855a                	mv	a0,s6
    80001c7e:	fffff097          	auipc	ra,0xfffff
    80001c82:	01a080e7          	jalr	26(ra) # 80000c98 <release>
      release(&proc[index].list_lock);
    80001c86:	854e                	mv	a0,s3
    80001c88:	fffff097          	auipc	ra,0xfffff
    80001c8c:	010080e7          	jalr	16(ra) # 80000c98 <release>
      return;
    80001c90:	b7b1                	j	80001bdc <add_link+0xf6>
        increment_counter(list);
    80001c92:	8526                	mv	a0,s1
    80001c94:	00000097          	auipc	ra,0x0
    80001c98:	e14080e7          	jalr	-492(ra) # 80001aa8 <increment_counter>
    80001c9c:	bfd9                	j	80001c72 <add_link+0x18c>
    increment_counter(list);
    80001c9e:	8526                	mv	a0,s1
    80001ca0:	00000097          	auipc	ra,0x0
    80001ca4:	e08080e7          	jalr	-504(ra) # 80001aa8 <increment_counter>
    80001ca8:	bf01                	j	80001bb8 <add_link+0xd2>

0000000080001caa <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001caa:	7139                	addi	sp,sp,-64
    80001cac:	fc06                	sd	ra,56(sp)
    80001cae:	f822                	sd	s0,48(sp)
    80001cb0:	f426                	sd	s1,40(sp)
    80001cb2:	f04a                	sd	s2,32(sp)
    80001cb4:	ec4e                	sd	s3,24(sp)
    80001cb6:	e852                	sd	s4,16(sp)
    80001cb8:	e456                	sd	s5,8(sp)
    80001cba:	e05a                	sd	s6,0(sp)
    80001cbc:	0080                	addi	s0,sp,64
    80001cbe:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cc0:	00010497          	auipc	s1,0x10
    80001cc4:	b0048493          	addi	s1,s1,-1280 # 800117c0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001cc8:	8b26                	mv	s6,s1
    80001cca:	00006a97          	auipc	s5,0x6
    80001cce:	336a8a93          	addi	s5,s5,822 # 80008000 <etext>
    80001cd2:	04000937          	lui	s2,0x4000
    80001cd6:	197d                	addi	s2,s2,-1
    80001cd8:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cda:	00016a17          	auipc	s4,0x16
    80001cde:	ee6a0a13          	addi	s4,s4,-282 # 80017bc0 <tickslock>
    char *pa = kalloc();
    80001ce2:	fffff097          	auipc	ra,0xfffff
    80001ce6:	e12080e7          	jalr	-494(ra) # 80000af4 <kalloc>
    80001cea:	862a                	mv	a2,a0
    if(pa == 0)
    80001cec:	c131                	beqz	a0,80001d30 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001cee:	416485b3          	sub	a1,s1,s6
    80001cf2:	8591                	srai	a1,a1,0x4
    80001cf4:	000ab783          	ld	a5,0(s5)
    80001cf8:	02f585b3          	mul	a1,a1,a5
    80001cfc:	2585                	addiw	a1,a1,1
    80001cfe:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001d02:	4719                	li	a4,6
    80001d04:	6685                	lui	a3,0x1
    80001d06:	40b905b3          	sub	a1,s2,a1
    80001d0a:	854e                	mv	a0,s3
    80001d0c:	fffff097          	auipc	ra,0xfffff
    80001d10:	444080e7          	jalr	1092(ra) # 80001150 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d14:	19048493          	addi	s1,s1,400
    80001d18:	fd4495e3          	bne	s1,s4,80001ce2 <proc_mapstacks+0x38>
  }
}
    80001d1c:	70e2                	ld	ra,56(sp)
    80001d1e:	7442                	ld	s0,48(sp)
    80001d20:	74a2                	ld	s1,40(sp)
    80001d22:	7902                	ld	s2,32(sp)
    80001d24:	69e2                	ld	s3,24(sp)
    80001d26:	6a42                	ld	s4,16(sp)
    80001d28:	6aa2                	ld	s5,8(sp)
    80001d2a:	6b02                	ld	s6,0(sp)
    80001d2c:	6121                	addi	sp,sp,64
    80001d2e:	8082                	ret
      panic("kalloc");
    80001d30:	00006517          	auipc	a0,0x6
    80001d34:	4a850513          	addi	a0,a0,1192 # 800081d8 <digits+0x198>
    80001d38:	fffff097          	auipc	ra,0xfffff
    80001d3c:	806080e7          	jalr	-2042(ra) # 8000053e <panic>

0000000080001d40 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    80001d40:	715d                	addi	sp,sp,-80
    80001d42:	e486                	sd	ra,72(sp)
    80001d44:	e0a2                	sd	s0,64(sp)
    80001d46:	fc26                	sd	s1,56(sp)
    80001d48:	f84a                	sd	s2,48(sp)
    80001d4a:	f44e                	sd	s3,40(sp)
    80001d4c:	f052                	sd	s4,32(sp)
    80001d4e:	ec56                	sd	s5,24(sp)
    80001d50:	e85a                	sd	s6,16(sp)
    80001d52:	e45e                	sd	s7,8(sp)
    80001d54:	e062                	sd	s8,0(sp)
    80001d56:	0880                	addi	s0,sp,80
  lists_init();
    80001d58:	00000097          	auipc	ra,0x0
    80001d5c:	ae6080e7          	jalr	-1306(ra) # 8000183e <lists_init>
  struct proc *p;
  int index = 0;
  initlock(&pid_lock, "nextpid");
    80001d60:	00006597          	auipc	a1,0x6
    80001d64:	48058593          	addi	a1,a1,1152 # 800081e0 <digits+0x1a0>
    80001d68:	0000f517          	auipc	a0,0xf
    80001d6c:	62850513          	addi	a0,a0,1576 # 80011390 <pid_lock>
    80001d70:	fffff097          	auipc	ra,0xfffff
    80001d74:	de4080e7          	jalr	-540(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001d78:	00006597          	auipc	a1,0x6
    80001d7c:	47058593          	addi	a1,a1,1136 # 800081e8 <digits+0x1a8>
    80001d80:	0000f517          	auipc	a0,0xf
    80001d84:	62850513          	addi	a0,a0,1576 # 800113a8 <wait_lock>
    80001d88:	fffff097          	auipc	ra,0xfffff
    80001d8c:	dcc080e7          	jalr	-564(ra) # 80000b54 <initlock>
  int index = 0;
    80001d90:	4901                	li	s2,0
  //printf("start procinit\n");
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d92:	00010497          	auipc	s1,0x10
    80001d96:	a2e48493          	addi	s1,s1,-1490 # 800117c0 <proc>
      initlock(&p->lock, "proc");
    80001d9a:	00006c17          	auipc	s8,0x6
    80001d9e:	45ec0c13          	addi	s8,s8,1118 # 800081f8 <digits+0x1b8>
      p->kstack = KSTACK((int) (p - proc));
    80001da2:	8ba6                	mv	s7,s1
    80001da4:	00006b17          	auipc	s6,0x6
    80001da8:	25cb0b13          	addi	s6,s6,604 # 80008000 <etext>
    80001dac:	040009b7          	lui	s3,0x4000
    80001db0:	19fd                	addi	s3,s3,-1
    80001db2:	09b2                	slli	s3,s3,0xc
      p->proc_index=index;
      p->next_proc_index = index + 1;
      //printf("proc is %d\n", index);
      add_link(&unused_list, index, 0);
    80001db4:	0000fa97          	auipc	s5,0xf
    80001db8:	564a8a93          	addi	s5,s5,1380 # 80011318 <unused_list>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001dbc:	00016a17          	auipc	s4,0x16
    80001dc0:	e04a0a13          	addi	s4,s4,-508 # 80017bc0 <tickslock>
      initlock(&p->lock, "proc");
    80001dc4:	85e2                	mv	a1,s8
    80001dc6:	8526                	mv	a0,s1
    80001dc8:	fffff097          	auipc	ra,0xfffff
    80001dcc:	d8c080e7          	jalr	-628(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001dd0:	417487b3          	sub	a5,s1,s7
    80001dd4:	8791                	srai	a5,a5,0x4
    80001dd6:	000b3703          	ld	a4,0(s6)
    80001dda:	02e787b3          	mul	a5,a5,a4
    80001dde:	2785                	addiw	a5,a5,1
    80001de0:	00d7979b          	slliw	a5,a5,0xd
    80001de4:	40f987b3          	sub	a5,s3,a5
    80001de8:	ecbc                	sd	a5,88(s1)
      p->proc_index=index;
    80001dea:	1924a223          	sw	s2,388(s1)
      p->next_proc_index = index + 1;
    80001dee:	85ca                	mv	a1,s2
    80001df0:	0019079b          	addiw	a5,s2,1
    80001df4:	0007891b          	sext.w	s2,a5
    80001df8:	18f4a023          	sw	a5,384(s1)
      add_link(&unused_list, index, 0);
    80001dfc:	4601                	li	a2,0
    80001dfe:	8556                	mv	a0,s5
    80001e00:	00000097          	auipc	ra,0x0
    80001e04:	ce6080e7          	jalr	-794(ra) # 80001ae6 <add_link>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e08:	19048493          	addi	s1,s1,400
    80001e0c:	fb449ce3          	bne	s1,s4,80001dc4 <procinit+0x84>
      index++;
  }

  p = &proc[NPROC-1];
  p->next_proc_index = -1;
    80001e10:	57fd                	li	a5,-1
    80001e12:	00016717          	auipc	a4,0x16
    80001e16:	d8f72f23          	sw	a5,-610(a4) # 80017bb0 <proc+0x63f0>
}
    80001e1a:	60a6                	ld	ra,72(sp)
    80001e1c:	6406                	ld	s0,64(sp)
    80001e1e:	74e2                	ld	s1,56(sp)
    80001e20:	7942                	ld	s2,48(sp)
    80001e22:	79a2                	ld	s3,40(sp)
    80001e24:	7a02                	ld	s4,32(sp)
    80001e26:	6ae2                	ld	s5,24(sp)
    80001e28:	6b42                	ld	s6,16(sp)
    80001e2a:	6ba2                	ld	s7,8(sp)
    80001e2c:	6c02                	ld	s8,0(sp)
    80001e2e:	6161                	addi	sp,sp,80
    80001e30:	8082                	ret

0000000080001e32 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001e32:	1141                	addi	sp,sp,-16
    80001e34:	e422                	sd	s0,8(sp)
    80001e36:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001e38:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001e3a:	2501                	sext.w	a0,a0
    80001e3c:	6422                	ld	s0,8(sp)
    80001e3e:	0141                	addi	sp,sp,16
    80001e40:	8082                	ret

0000000080001e42 <mycpu>:


// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001e42:	1141                	addi	sp,sp,-16
    80001e44:	e422                	sd	s0,8(sp)
    80001e46:	0800                	addi	s0,sp,16
    80001e48:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001e4a:	2781                	sext.w	a5,a5
    80001e4c:	079e                	slli	a5,a5,0x7
  return c;
}
    80001e4e:	0000f517          	auipc	a0,0xf
    80001e52:	57250513          	addi	a0,a0,1394 # 800113c0 <cpus>
    80001e56:	953e                	add	a0,a0,a5
    80001e58:	6422                	ld	s0,8(sp)
    80001e5a:	0141                	addi	sp,sp,16
    80001e5c:	8082                	ret

0000000080001e5e <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001e5e:	1101                	addi	sp,sp,-32
    80001e60:	ec06                	sd	ra,24(sp)
    80001e62:	e822                	sd	s0,16(sp)
    80001e64:	e426                	sd	s1,8(sp)
    80001e66:	1000                	addi	s0,sp,32
  push_off();
    80001e68:	fffff097          	auipc	ra,0xfffff
    80001e6c:	d30080e7          	jalr	-720(ra) # 80000b98 <push_off>
    80001e70:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001e72:	2781                	sext.w	a5,a5
    80001e74:	079e                	slli	a5,a5,0x7
    80001e76:	0000f717          	auipc	a4,0xf
    80001e7a:	42a70713          	addi	a4,a4,1066 # 800112a0 <runnable_cpu_lists>
    80001e7e:	97ba                	add	a5,a5,a4
    80001e80:	1207b483          	ld	s1,288(a5)
  pop_off();
    80001e84:	fffff097          	auipc	ra,0xfffff
    80001e88:	db4080e7          	jalr	-588(ra) # 80000c38 <pop_off>
  return p;
}
    80001e8c:	8526                	mv	a0,s1
    80001e8e:	60e2                	ld	ra,24(sp)
    80001e90:	6442                	ld	s0,16(sp)
    80001e92:	64a2                	ld	s1,8(sp)
    80001e94:	6105                	addi	sp,sp,32
    80001e96:	8082                	ret

0000000080001e98 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001e98:	1141                	addi	sp,sp,-16
    80001e9a:	e406                	sd	ra,8(sp)
    80001e9c:	e022                	sd	s0,0(sp)
    80001e9e:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001ea0:	00000097          	auipc	ra,0x0
    80001ea4:	fbe080e7          	jalr	-66(ra) # 80001e5e <myproc>
    80001ea8:	fffff097          	auipc	ra,0xfffff
    80001eac:	df0080e7          	jalr	-528(ra) # 80000c98 <release>

  if (first) {
    80001eb0:	00007797          	auipc	a5,0x7
    80001eb4:	9f07a783          	lw	a5,-1552(a5) # 800088a0 <first.1741>
    80001eb8:	eb89                	bnez	a5,80001eca <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001eba:	00001097          	auipc	ra,0x1
    80001ebe:	202080e7          	jalr	514(ra) # 800030bc <usertrapret>
}
    80001ec2:	60a2                	ld	ra,8(sp)
    80001ec4:	6402                	ld	s0,0(sp)
    80001ec6:	0141                	addi	sp,sp,16
    80001ec8:	8082                	ret
    first = 0;
    80001eca:	00007797          	auipc	a5,0x7
    80001ece:	9c07ab23          	sw	zero,-1578(a5) # 800088a0 <first.1741>
    fsinit(ROOTDEV);
    80001ed2:	4505                	li	a0,1
    80001ed4:	00002097          	auipc	ra,0x2
    80001ed8:	fa6080e7          	jalr	-90(ra) # 80003e7a <fsinit>
    80001edc:	bff9                	j	80001eba <forkret+0x22>

0000000080001ede <allocpid>:
allocpid() {
    80001ede:	1101                	addi	sp,sp,-32
    80001ee0:	ec06                	sd	ra,24(sp)
    80001ee2:	e822                	sd	s0,16(sp)
    80001ee4:	e426                	sd	s1,8(sp)
    80001ee6:	e04a                	sd	s2,0(sp)
    80001ee8:	1000                	addi	s0,sp,32
    pid = nextpid;
    80001eea:	00007917          	auipc	s2,0x7
    80001eee:	9ba90913          	addi	s2,s2,-1606 # 800088a4 <nextpid>
    80001ef2:	00092483          	lw	s1,0(s2)
  } while (cas(&nextpid, pid, pid+1));
    80001ef6:	0014861b          	addiw	a2,s1,1
    80001efa:	85a6                	mv	a1,s1
    80001efc:	854a                	mv	a0,s2
    80001efe:	00005097          	auipc	ra,0x5
    80001f02:	d88080e7          	jalr	-632(ra) # 80006c86 <cas>
    80001f06:	f575                	bnez	a0,80001ef2 <allocpid+0x14>
}
    80001f08:	8526                	mv	a0,s1
    80001f0a:	60e2                	ld	ra,24(sp)
    80001f0c:	6442                	ld	s0,16(sp)
    80001f0e:	64a2                	ld	s1,8(sp)
    80001f10:	6902                	ld	s2,0(sp)
    80001f12:	6105                	addi	sp,sp,32
    80001f14:	8082                	ret

0000000080001f16 <proc_pagetable>:
{
    80001f16:	1101                	addi	sp,sp,-32
    80001f18:	ec06                	sd	ra,24(sp)
    80001f1a:	e822                	sd	s0,16(sp)
    80001f1c:	e426                	sd	s1,8(sp)
    80001f1e:	e04a                	sd	s2,0(sp)
    80001f20:	1000                	addi	s0,sp,32
    80001f22:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001f24:	fffff097          	auipc	ra,0xfffff
    80001f28:	416080e7          	jalr	1046(ra) # 8000133a <uvmcreate>
    80001f2c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001f2e:	c121                	beqz	a0,80001f6e <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001f30:	4729                	li	a4,10
    80001f32:	00005697          	auipc	a3,0x5
    80001f36:	0ce68693          	addi	a3,a3,206 # 80007000 <_trampoline>
    80001f3a:	6605                	lui	a2,0x1
    80001f3c:	040005b7          	lui	a1,0x4000
    80001f40:	15fd                	addi	a1,a1,-1
    80001f42:	05b2                	slli	a1,a1,0xc
    80001f44:	fffff097          	auipc	ra,0xfffff
    80001f48:	16c080e7          	jalr	364(ra) # 800010b0 <mappages>
    80001f4c:	02054863          	bltz	a0,80001f7c <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001f50:	4719                	li	a4,6
    80001f52:	07093683          	ld	a3,112(s2)
    80001f56:	6605                	lui	a2,0x1
    80001f58:	020005b7          	lui	a1,0x2000
    80001f5c:	15fd                	addi	a1,a1,-1
    80001f5e:	05b6                	slli	a1,a1,0xd
    80001f60:	8526                	mv	a0,s1
    80001f62:	fffff097          	auipc	ra,0xfffff
    80001f66:	14e080e7          	jalr	334(ra) # 800010b0 <mappages>
    80001f6a:	02054163          	bltz	a0,80001f8c <proc_pagetable+0x76>
}
    80001f6e:	8526                	mv	a0,s1
    80001f70:	60e2                	ld	ra,24(sp)
    80001f72:	6442                	ld	s0,16(sp)
    80001f74:	64a2                	ld	s1,8(sp)
    80001f76:	6902                	ld	s2,0(sp)
    80001f78:	6105                	addi	sp,sp,32
    80001f7a:	8082                	ret
    uvmfree(pagetable, 0);
    80001f7c:	4581                	li	a1,0
    80001f7e:	8526                	mv	a0,s1
    80001f80:	fffff097          	auipc	ra,0xfffff
    80001f84:	5b6080e7          	jalr	1462(ra) # 80001536 <uvmfree>
    return 0;
    80001f88:	4481                	li	s1,0
    80001f8a:	b7d5                	j	80001f6e <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001f8c:	4681                	li	a3,0
    80001f8e:	4605                	li	a2,1
    80001f90:	040005b7          	lui	a1,0x4000
    80001f94:	15fd                	addi	a1,a1,-1
    80001f96:	05b2                	slli	a1,a1,0xc
    80001f98:	8526                	mv	a0,s1
    80001f9a:	fffff097          	auipc	ra,0xfffff
    80001f9e:	2dc080e7          	jalr	732(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80001fa2:	4581                	li	a1,0
    80001fa4:	8526                	mv	a0,s1
    80001fa6:	fffff097          	auipc	ra,0xfffff
    80001faa:	590080e7          	jalr	1424(ra) # 80001536 <uvmfree>
    return 0;
    80001fae:	4481                	li	s1,0
    80001fb0:	bf7d                	j	80001f6e <proc_pagetable+0x58>

0000000080001fb2 <proc_freepagetable>:
{
    80001fb2:	1101                	addi	sp,sp,-32
    80001fb4:	ec06                	sd	ra,24(sp)
    80001fb6:	e822                	sd	s0,16(sp)
    80001fb8:	e426                	sd	s1,8(sp)
    80001fba:	e04a                	sd	s2,0(sp)
    80001fbc:	1000                	addi	s0,sp,32
    80001fbe:	84aa                	mv	s1,a0
    80001fc0:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001fc2:	4681                	li	a3,0
    80001fc4:	4605                	li	a2,1
    80001fc6:	040005b7          	lui	a1,0x4000
    80001fca:	15fd                	addi	a1,a1,-1
    80001fcc:	05b2                	slli	a1,a1,0xc
    80001fce:	fffff097          	auipc	ra,0xfffff
    80001fd2:	2a8080e7          	jalr	680(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001fd6:	4681                	li	a3,0
    80001fd8:	4605                	li	a2,1
    80001fda:	020005b7          	lui	a1,0x2000
    80001fde:	15fd                	addi	a1,a1,-1
    80001fe0:	05b6                	slli	a1,a1,0xd
    80001fe2:	8526                	mv	a0,s1
    80001fe4:	fffff097          	auipc	ra,0xfffff
    80001fe8:	292080e7          	jalr	658(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80001fec:	85ca                	mv	a1,s2
    80001fee:	8526                	mv	a0,s1
    80001ff0:	fffff097          	auipc	ra,0xfffff
    80001ff4:	546080e7          	jalr	1350(ra) # 80001536 <uvmfree>
}
    80001ff8:	60e2                	ld	ra,24(sp)
    80001ffa:	6442                	ld	s0,16(sp)
    80001ffc:	64a2                	ld	s1,8(sp)
    80001ffe:	6902                	ld	s2,0(sp)
    80002000:	6105                	addi	sp,sp,32
    80002002:	8082                	ret

0000000080002004 <freeproc>:
{
    80002004:	1101                	addi	sp,sp,-32
    80002006:	ec06                	sd	ra,24(sp)
    80002008:	e822                	sd	s0,16(sp)
    8000200a:	e426                	sd	s1,8(sp)
    8000200c:	1000                	addi	s0,sp,32
    8000200e:	84aa                	mv	s1,a0
  if(p->trapframe)
    80002010:	7928                	ld	a0,112(a0)
    80002012:	c509                	beqz	a0,8000201c <freeproc+0x18>
    kfree((void*)p->trapframe);
    80002014:	fffff097          	auipc	ra,0xfffff
    80002018:	9e4080e7          	jalr	-1564(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    8000201c:	0604b823          	sd	zero,112(s1)
  if(p->pagetable)
    80002020:	74a8                	ld	a0,104(s1)
    80002022:	c511                	beqz	a0,8000202e <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80002024:	70ac                	ld	a1,96(s1)
    80002026:	00000097          	auipc	ra,0x0
    8000202a:	f8c080e7          	jalr	-116(ra) # 80001fb2 <proc_freepagetable>
  remove_link(&zombie_list, p->proc_index);
    8000202e:	1844a583          	lw	a1,388(s1)
    80002032:	0000f517          	auipc	a0,0xf
    80002036:	33650513          	addi	a0,a0,822 # 80011368 <zombie_list>
    8000203a:	00000097          	auipc	ra,0x0
    8000203e:	87e080e7          	jalr	-1922(ra) # 800018b8 <remove_link>
  add_link(&unused_list, p->proc_index, 0);
    80002042:	4601                	li	a2,0
    80002044:	1844a583          	lw	a1,388(s1)
    80002048:	0000f517          	auipc	a0,0xf
    8000204c:	2d050513          	addi	a0,a0,720 # 80011318 <unused_list>
    80002050:	00000097          	auipc	ra,0x0
    80002054:	a96080e7          	jalr	-1386(ra) # 80001ae6 <add_link>
  p->pagetable = 0;
    80002058:	0604b423          	sd	zero,104(s1)
  p->sz = 0;
    8000205c:	0604b023          	sd	zero,96(s1)
  p->pid = 0;
    80002060:	0404a423          	sw	zero,72(s1)
  p->parent = 0;
    80002064:	0404b823          	sd	zero,80(s1)
  p->name[0] = 0;
    80002068:	16048823          	sb	zero,368(s1)
  p->chan = 0;
    8000206c:	0204bc23          	sd	zero,56(s1)
  p->killed = 0;
    80002070:	0404a023          	sw	zero,64(s1)
  p->xstate = 0;
    80002074:	0404a223          	sw	zero,68(s1)
  p->state = UNUSED;
    80002078:	0204a823          	sw	zero,48(s1)
}
    8000207c:	60e2                	ld	ra,24(sp)
    8000207e:	6442                	ld	s0,16(sp)
    80002080:	64a2                	ld	s1,8(sp)
    80002082:	6105                	addi	sp,sp,32
    80002084:	8082                	ret

0000000080002086 <allocproc>:
{
    80002086:	7139                	addi	sp,sp,-64
    80002088:	fc06                	sd	ra,56(sp)
    8000208a:	f822                	sd	s0,48(sp)
    8000208c:	f426                	sd	s1,40(sp)
    8000208e:	f04a                	sd	s2,32(sp)
    80002090:	ec4e                	sd	s3,24(sp)
    80002092:	e852                	sd	s4,16(sp)
    80002094:	e456                	sd	s5,8(sp)
    80002096:	0080                	addi	s0,sp,64
  if (unused_list.head == -1){
    80002098:	0000f497          	auipc	s1,0xf
    8000209c:	2804a483          	lw	s1,640(s1) # 80011318 <unused_list>
    800020a0:	57fd                	li	a5,-1
    800020a2:	0cf48363          	beq	s1,a5,80002168 <allocproc+0xe2>
  struct proc *p = &proc[unused_list.head];
    800020a6:	19000793          	li	a5,400
    800020aa:	02f484b3          	mul	s1,s1,a5
    800020ae:	0000f797          	auipc	a5,0xf
    800020b2:	71278793          	addi	a5,a5,1810 # 800117c0 <proc>
    800020b6:	94be                	add	s1,s1,a5
  acquire(&p->lock);
    800020b8:	8526                	mv	a0,s1
    800020ba:	fffff097          	auipc	ra,0xfffff
    800020be:	b2a080e7          	jalr	-1238(ra) # 80000be4 <acquire>
  while(p->state != UNUSED){
    800020c2:	589c                	lw	a5,48(s1)
    800020c4:	cf9d                	beqz	a5,80002102 <allocproc+0x7c>
    if (unused_list.head == -1)
    800020c6:	0000f997          	auipc	s3,0xf
    800020ca:	1da98993          	addi	s3,s3,474 # 800112a0 <runnable_cpu_lists>
    800020ce:	597d                	li	s2,-1
    p = &proc[unused_list.head];
    800020d0:	19000a93          	li	s5,400
    800020d4:	0000fa17          	auipc	s4,0xf
    800020d8:	6eca0a13          	addi	s4,s4,1772 # 800117c0 <proc>
    release(&p->lock);
    800020dc:	8526                	mv	a0,s1
    800020de:	fffff097          	auipc	ra,0xfffff
    800020e2:	bba080e7          	jalr	-1094(ra) # 80000c98 <release>
    if (unused_list.head == -1)
    800020e6:	0789a483          	lw	s1,120(s3)
    800020ea:	0d248163          	beq	s1,s2,800021ac <allocproc+0x126>
    p = &proc[unused_list.head];
    800020ee:	035484b3          	mul	s1,s1,s5
    800020f2:	94d2                	add	s1,s1,s4
    acquire(&p->lock);
    800020f4:	8526                	mv	a0,s1
    800020f6:	fffff097          	auipc	ra,0xfffff
    800020fa:	aee080e7          	jalr	-1298(ra) # 80000be4 <acquire>
  while(p->state != UNUSED){
    800020fe:	589c                	lw	a5,48(s1)
    80002100:	fff1                	bnez	a5,800020dc <allocproc+0x56>
  remove_link(&unused_list, p->proc_index);
    80002102:	1844a583          	lw	a1,388(s1)
    80002106:	0000f517          	auipc	a0,0xf
    8000210a:	21250513          	addi	a0,a0,530 # 80011318 <unused_list>
    8000210e:	fffff097          	auipc	ra,0xfffff
    80002112:	7aa080e7          	jalr	1962(ra) # 800018b8 <remove_link>
  p->pid = allocpid();
    80002116:	00000097          	auipc	ra,0x0
    8000211a:	dc8080e7          	jalr	-568(ra) # 80001ede <allocpid>
    8000211e:	c4a8                	sw	a0,72(s1)
  p->state = USED;
    80002120:	4785                	li	a5,1
    80002122:	d89c                	sw	a5,48(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80002124:	fffff097          	auipc	ra,0xfffff
    80002128:	9d0080e7          	jalr	-1584(ra) # 80000af4 <kalloc>
    8000212c:	892a                	mv	s2,a0
    8000212e:	f8a8                	sd	a0,112(s1)
    80002130:	c531                	beqz	a0,8000217c <allocproc+0xf6>
  p->pagetable = proc_pagetable(p);
    80002132:	8526                	mv	a0,s1
    80002134:	00000097          	auipc	ra,0x0
    80002138:	de2080e7          	jalr	-542(ra) # 80001f16 <proc_pagetable>
    8000213c:	892a                	mv	s2,a0
    8000213e:	f4a8                	sd	a0,104(s1)
  if(p->pagetable == 0){
    80002140:	c931                	beqz	a0,80002194 <allocproc+0x10e>
  memset(&p->context, 0, sizeof(p->context));
    80002142:	07000613          	li	a2,112
    80002146:	4581                	li	a1,0
    80002148:	07848513          	addi	a0,s1,120
    8000214c:	fffff097          	auipc	ra,0xfffff
    80002150:	b94080e7          	jalr	-1132(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80002154:	00000797          	auipc	a5,0x0
    80002158:	d4478793          	addi	a5,a5,-700 # 80001e98 <forkret>
    8000215c:	fcbc                	sd	a5,120(s1)
  p->context.sp = p->kstack + PGSIZE;
    8000215e:	6cbc                	ld	a5,88(s1)
    80002160:	6705                	lui	a4,0x1
    80002162:	97ba                	add	a5,a5,a4
    80002164:	e0dc                	sd	a5,128(s1)
  return p;
    80002166:	a0a1                	j	800021ae <allocproc+0x128>
    printf("unused list is empty in allocproc\n");
    80002168:	00006517          	auipc	a0,0x6
    8000216c:	09850513          	addi	a0,a0,152 # 80008200 <digits+0x1c0>
    80002170:	ffffe097          	auipc	ra,0xffffe
    80002174:	418080e7          	jalr	1048(ra) # 80000588 <printf>
    return 0;
    80002178:	4481                	li	s1,0
    8000217a:	a815                	j	800021ae <allocproc+0x128>
    freeproc(p);
    8000217c:	8526                	mv	a0,s1
    8000217e:	00000097          	auipc	ra,0x0
    80002182:	e86080e7          	jalr	-378(ra) # 80002004 <freeproc>
    release(&p->lock);
    80002186:	8526                	mv	a0,s1
    80002188:	fffff097          	auipc	ra,0xfffff
    8000218c:	b10080e7          	jalr	-1264(ra) # 80000c98 <release>
    return 0;
    80002190:	84ca                	mv	s1,s2
    80002192:	a831                	j	800021ae <allocproc+0x128>
    freeproc(p);
    80002194:	8526                	mv	a0,s1
    80002196:	00000097          	auipc	ra,0x0
    8000219a:	e6e080e7          	jalr	-402(ra) # 80002004 <freeproc>
    release(&p->lock);
    8000219e:	8526                	mv	a0,s1
    800021a0:	fffff097          	auipc	ra,0xfffff
    800021a4:	af8080e7          	jalr	-1288(ra) # 80000c98 <release>
    return 0;
    800021a8:	84ca                	mv	s1,s2
    800021aa:	a011                	j	800021ae <allocproc+0x128>
      return 0;
    800021ac:	4481                	li	s1,0
}
    800021ae:	8526                	mv	a0,s1
    800021b0:	70e2                	ld	ra,56(sp)
    800021b2:	7442                	ld	s0,48(sp)
    800021b4:	74a2                	ld	s1,40(sp)
    800021b6:	7902                	ld	s2,32(sp)
    800021b8:	69e2                	ld	s3,24(sp)
    800021ba:	6a42                	ld	s4,16(sp)
    800021bc:	6aa2                	ld	s5,8(sp)
    800021be:	6121                	addi	sp,sp,64
    800021c0:	8082                	ret

00000000800021c2 <userinit>:
{
    800021c2:	1101                	addi	sp,sp,-32
    800021c4:	ec06                	sd	ra,24(sp)
    800021c6:	e822                	sd	s0,16(sp)
    800021c8:	e426                	sd	s1,8(sp)
    800021ca:	1000                	addi	s0,sp,32
  p = allocproc();
    800021cc:	00000097          	auipc	ra,0x0
    800021d0:	eba080e7          	jalr	-326(ra) # 80002086 <allocproc>
    800021d4:	84aa                	mv	s1,a0
  initproc = p;
    800021d6:	00007797          	auipc	a5,0x7
    800021da:	e4a7b923          	sd	a0,-430(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    800021de:	03400613          	li	a2,52
    800021e2:	00006597          	auipc	a1,0x6
    800021e6:	6ce58593          	addi	a1,a1,1742 # 800088b0 <initcode>
    800021ea:	7528                	ld	a0,104(a0)
    800021ec:	fffff097          	auipc	ra,0xfffff
    800021f0:	17c080e7          	jalr	380(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    800021f4:	6785                	lui	a5,0x1
    800021f6:	f0bc                	sd	a5,96(s1)
  p->trapframe->epc = 0;      // user program counter
    800021f8:	78b8                	ld	a4,112(s1)
    800021fa:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    800021fe:	78b8                	ld	a4,112(s1)
    80002200:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80002202:	4641                	li	a2,16
    80002204:	00006597          	auipc	a1,0x6
    80002208:	02458593          	addi	a1,a1,36 # 80008228 <digits+0x1e8>
    8000220c:	17048513          	addi	a0,s1,368
    80002210:	fffff097          	auipc	ra,0xfffff
    80002214:	c22080e7          	jalr	-990(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80002218:	00006517          	auipc	a0,0x6
    8000221c:	02050513          	addi	a0,a0,32 # 80008238 <digits+0x1f8>
    80002220:	00002097          	auipc	ra,0x2
    80002224:	688080e7          	jalr	1672(ra) # 800048a8 <namei>
    80002228:	16a4b423          	sd	a0,360(s1)
  p->state = RUNNABLE;
    8000222c:	478d                	li	a5,3
    8000222e:	d89c                	sw	a5,48(s1)
  add_link(&runnable_cpu_lists[0], p->proc_index, 0); // init_proc index is 0
    80002230:	4601                	li	a2,0
    80002232:	1844a583          	lw	a1,388(s1)
    80002236:	0000f517          	auipc	a0,0xf
    8000223a:	06a50513          	addi	a0,a0,106 # 800112a0 <runnable_cpu_lists>
    8000223e:	00000097          	auipc	ra,0x0
    80002242:	8a8080e7          	jalr	-1880(ra) # 80001ae6 <add_link>
  release(&p->lock);
    80002246:	8526                	mv	a0,s1
    80002248:	fffff097          	auipc	ra,0xfffff
    8000224c:	a50080e7          	jalr	-1456(ra) # 80000c98 <release>
}
    80002250:	60e2                	ld	ra,24(sp)
    80002252:	6442                	ld	s0,16(sp)
    80002254:	64a2                	ld	s1,8(sp)
    80002256:	6105                	addi	sp,sp,32
    80002258:	8082                	ret

000000008000225a <growproc>:
{
    8000225a:	1101                	addi	sp,sp,-32
    8000225c:	ec06                	sd	ra,24(sp)
    8000225e:	e822                	sd	s0,16(sp)
    80002260:	e426                	sd	s1,8(sp)
    80002262:	e04a                	sd	s2,0(sp)
    80002264:	1000                	addi	s0,sp,32
    80002266:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002268:	00000097          	auipc	ra,0x0
    8000226c:	bf6080e7          	jalr	-1034(ra) # 80001e5e <myproc>
    80002270:	892a                	mv	s2,a0
  sz = p->sz;
    80002272:	712c                	ld	a1,96(a0)
    80002274:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80002278:	00904f63          	bgtz	s1,80002296 <growproc+0x3c>
  } else if(n < 0){
    8000227c:	0204cc63          	bltz	s1,800022b4 <growproc+0x5a>
  p->sz = sz;
    80002280:	1602                	slli	a2,a2,0x20
    80002282:	9201                	srli	a2,a2,0x20
    80002284:	06c93023          	sd	a2,96(s2)
  return 0;
    80002288:	4501                	li	a0,0
}
    8000228a:	60e2                	ld	ra,24(sp)
    8000228c:	6442                	ld	s0,16(sp)
    8000228e:	64a2                	ld	s1,8(sp)
    80002290:	6902                	ld	s2,0(sp)
    80002292:	6105                	addi	sp,sp,32
    80002294:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80002296:	9e25                	addw	a2,a2,s1
    80002298:	1602                	slli	a2,a2,0x20
    8000229a:	9201                	srli	a2,a2,0x20
    8000229c:	1582                	slli	a1,a1,0x20
    8000229e:	9181                	srli	a1,a1,0x20
    800022a0:	7528                	ld	a0,104(a0)
    800022a2:	fffff097          	auipc	ra,0xfffff
    800022a6:	180080e7          	jalr	384(ra) # 80001422 <uvmalloc>
    800022aa:	0005061b          	sext.w	a2,a0
    800022ae:	fa69                	bnez	a2,80002280 <growproc+0x26>
      return -1;
    800022b0:	557d                	li	a0,-1
    800022b2:	bfe1                	j	8000228a <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    800022b4:	9e25                	addw	a2,a2,s1
    800022b6:	1602                	slli	a2,a2,0x20
    800022b8:	9201                	srli	a2,a2,0x20
    800022ba:	1582                	slli	a1,a1,0x20
    800022bc:	9181                	srli	a1,a1,0x20
    800022be:	7528                	ld	a0,104(a0)
    800022c0:	fffff097          	auipc	ra,0xfffff
    800022c4:	11a080e7          	jalr	282(ra) # 800013da <uvmdealloc>
    800022c8:	0005061b          	sext.w	a2,a0
    800022cc:	bf55                	j	80002280 <growproc+0x26>

00000000800022ce <fork>:
{
    800022ce:	7179                	addi	sp,sp,-48
    800022d0:	f406                	sd	ra,40(sp)
    800022d2:	f022                	sd	s0,32(sp)
    800022d4:	ec26                	sd	s1,24(sp)
    800022d6:	e84a                	sd	s2,16(sp)
    800022d8:	e44e                	sd	s3,8(sp)
    800022da:	e052                	sd	s4,0(sp)
    800022dc:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800022de:	00000097          	auipc	ra,0x0
    800022e2:	b80080e7          	jalr	-1152(ra) # 80001e5e <myproc>
    800022e6:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    800022e8:	00000097          	auipc	ra,0x0
    800022ec:	d9e080e7          	jalr	-610(ra) # 80002086 <allocproc>
    800022f0:	14050863          	beqz	a0,80002440 <fork+0x172>
    800022f4:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    800022f6:	06093603          	ld	a2,96(s2)
    800022fa:	752c                	ld	a1,104(a0)
    800022fc:	06893503          	ld	a0,104(s2)
    80002300:	fffff097          	auipc	ra,0xfffff
    80002304:	26e080e7          	jalr	622(ra) # 8000156e <uvmcopy>
    80002308:	04054663          	bltz	a0,80002354 <fork+0x86>
  np->sz = p->sz;
    8000230c:	06093783          	ld	a5,96(s2)
    80002310:	06f9b023          	sd	a5,96(s3)
  *(np->trapframe) = *(p->trapframe);
    80002314:	07093683          	ld	a3,112(s2)
    80002318:	87b6                	mv	a5,a3
    8000231a:	0709b703          	ld	a4,112(s3)
    8000231e:	12068693          	addi	a3,a3,288
    80002322:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80002326:	6788                	ld	a0,8(a5)
    80002328:	6b8c                	ld	a1,16(a5)
    8000232a:	6f90                	ld	a2,24(a5)
    8000232c:	01073023          	sd	a6,0(a4)
    80002330:	e708                	sd	a0,8(a4)
    80002332:	eb0c                	sd	a1,16(a4)
    80002334:	ef10                	sd	a2,24(a4)
    80002336:	02078793          	addi	a5,a5,32
    8000233a:	02070713          	addi	a4,a4,32
    8000233e:	fed792e3          	bne	a5,a3,80002322 <fork+0x54>
  np->trapframe->a0 = 0;
    80002342:	0709b783          	ld	a5,112(s3)
    80002346:	0607b823          	sd	zero,112(a5)
    8000234a:	0e800493          	li	s1,232
  for(i = 0; i < NOFILE; i++)
    8000234e:	16800a13          	li	s4,360
    80002352:	a03d                	j	80002380 <fork+0xb2>
    freeproc(np);
    80002354:	854e                	mv	a0,s3
    80002356:	00000097          	auipc	ra,0x0
    8000235a:	cae080e7          	jalr	-850(ra) # 80002004 <freeproc>
    release(&np->lock);
    8000235e:	854e                	mv	a0,s3
    80002360:	fffff097          	auipc	ra,0xfffff
    80002364:	938080e7          	jalr	-1736(ra) # 80000c98 <release>
    return -1;
    80002368:	5a7d                	li	s4,-1
    8000236a:	a0d1                	j	8000242e <fork+0x160>
      np->ofile[i] = filedup(p->ofile[i]);
    8000236c:	00003097          	auipc	ra,0x3
    80002370:	bd2080e7          	jalr	-1070(ra) # 80004f3e <filedup>
    80002374:	009987b3          	add	a5,s3,s1
    80002378:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    8000237a:	04a1                	addi	s1,s1,8
    8000237c:	01448763          	beq	s1,s4,8000238a <fork+0xbc>
    if(p->ofile[i])
    80002380:	009907b3          	add	a5,s2,s1
    80002384:	6388                	ld	a0,0(a5)
    80002386:	f17d                	bnez	a0,8000236c <fork+0x9e>
    80002388:	bfcd                	j	8000237a <fork+0xac>
  np->cwd = idup(p->cwd);
    8000238a:	16893503          	ld	a0,360(s2)
    8000238e:	00002097          	auipc	ra,0x2
    80002392:	d26080e7          	jalr	-730(ra) # 800040b4 <idup>
    80002396:	16a9b423          	sd	a0,360(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    8000239a:	4641                	li	a2,16
    8000239c:	17090593          	addi	a1,s2,368
    800023a0:	17098513          	addi	a0,s3,368
    800023a4:	fffff097          	auipc	ra,0xfffff
    800023a8:	a8e080e7          	jalr	-1394(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    800023ac:	0489aa03          	lw	s4,72(s3)
  release(&np->lock);
    800023b0:	854e                	mv	a0,s3
    800023b2:	fffff097          	auipc	ra,0xfffff
    800023b6:	8e6080e7          	jalr	-1818(ra) # 80000c98 <release>
  acquire(&wait_lock);
    800023ba:	0000f497          	auipc	s1,0xf
    800023be:	fee48493          	addi	s1,s1,-18 # 800113a8 <wait_lock>
    800023c2:	8526                	mv	a0,s1
    800023c4:	fffff097          	auipc	ra,0xfffff
    800023c8:	820080e7          	jalr	-2016(ra) # 80000be4 <acquire>
  np->parent = p;
    800023cc:	0529b823          	sd	s2,80(s3)
  release(&wait_lock);
    800023d0:	8526                	mv	a0,s1
    800023d2:	fffff097          	auipc	ra,0xfffff
    800023d6:	8c6080e7          	jalr	-1850(ra) # 80000c98 <release>
  acquire(&np->lock);
    800023da:	854e                	mv	a0,s3
    800023dc:	fffff097          	auipc	ra,0xfffff
    800023e0:	808080e7          	jalr	-2040(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    800023e4:	478d                	li	a5,3
    800023e6:	02f9a823          	sw	a5,48(s3)
  np-> affiliated_cpu = p-> affiliated_cpu;
    800023ea:	18892503          	lw	a0,392(s2)
    800023ee:	18a9a423          	sw	a0,392(s3)
  if (balance){
    800023f2:	00006797          	auipc	a5,0x6
    800023f6:	4b67a783          	lw	a5,1206(a5) # 800088a8 <balance>
    800023fa:	c789                	beqz	a5,80002404 <fork+0x136>
    cpu_to_add = get_balanced_cpu();
    800023fc:	fffff097          	auipc	ra,0xfffff
    80002400:	48c080e7          	jalr	1164(ra) # 80001888 <get_balanced_cpu>
  add_link(&runnable_cpu_lists[cpu_to_add], np->proc_index, 0);
    80002404:	00251793          	slli	a5,a0,0x2
    80002408:	97aa                	add	a5,a5,a0
    8000240a:	078e                	slli	a5,a5,0x3
    8000240c:	4601                	li	a2,0
    8000240e:	1849a583          	lw	a1,388(s3)
    80002412:	0000f517          	auipc	a0,0xf
    80002416:	e8e50513          	addi	a0,a0,-370 # 800112a0 <runnable_cpu_lists>
    8000241a:	953e                	add	a0,a0,a5
    8000241c:	fffff097          	auipc	ra,0xfffff
    80002420:	6ca080e7          	jalr	1738(ra) # 80001ae6 <add_link>
  release(&np->lock);
    80002424:	854e                	mv	a0,s3
    80002426:	fffff097          	auipc	ra,0xfffff
    8000242a:	872080e7          	jalr	-1934(ra) # 80000c98 <release>
}
    8000242e:	8552                	mv	a0,s4
    80002430:	70a2                	ld	ra,40(sp)
    80002432:	7402                	ld	s0,32(sp)
    80002434:	64e2                	ld	s1,24(sp)
    80002436:	6942                	ld	s2,16(sp)
    80002438:	69a2                	ld	s3,8(sp)
    8000243a:	6a02                	ld	s4,0(sp)
    8000243c:	6145                	addi	sp,sp,48
    8000243e:	8082                	ret
    return -1;
    80002440:	5a7d                	li	s4,-1
    80002442:	b7f5                	j	8000242e <fork+0x160>

0000000080002444 <sched>:
{
    80002444:	7179                	addi	sp,sp,-48
    80002446:	f406                	sd	ra,40(sp)
    80002448:	f022                	sd	s0,32(sp)
    8000244a:	ec26                	sd	s1,24(sp)
    8000244c:	e84a                	sd	s2,16(sp)
    8000244e:	e44e                	sd	s3,8(sp)
    80002450:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002452:	00000097          	auipc	ra,0x0
    80002456:	a0c080e7          	jalr	-1524(ra) # 80001e5e <myproc>
    8000245a:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000245c:	ffffe097          	auipc	ra,0xffffe
    80002460:	70e080e7          	jalr	1806(ra) # 80000b6a <holding>
    80002464:	c93d                	beqz	a0,800024da <sched+0x96>
    80002466:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002468:	2781                	sext.w	a5,a5
    8000246a:	079e                	slli	a5,a5,0x7
    8000246c:	0000f717          	auipc	a4,0xf
    80002470:	e3470713          	addi	a4,a4,-460 # 800112a0 <runnable_cpu_lists>
    80002474:	97ba                	add	a5,a5,a4
    80002476:	1987a703          	lw	a4,408(a5)
    8000247a:	4785                	li	a5,1
    8000247c:	06f71763          	bne	a4,a5,800024ea <sched+0xa6>
  if(p->state == RUNNING)
    80002480:	5898                	lw	a4,48(s1)
    80002482:	4791                	li	a5,4
    80002484:	06f70b63          	beq	a4,a5,800024fa <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002488:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000248c:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000248e:	efb5                	bnez	a5,8000250a <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002490:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002492:	0000f917          	auipc	s2,0xf
    80002496:	e0e90913          	addi	s2,s2,-498 # 800112a0 <runnable_cpu_lists>
    8000249a:	2781                	sext.w	a5,a5
    8000249c:	079e                	slli	a5,a5,0x7
    8000249e:	97ca                	add	a5,a5,s2
    800024a0:	19c7a983          	lw	s3,412(a5)
    800024a4:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800024a6:	2781                	sext.w	a5,a5
    800024a8:	079e                	slli	a5,a5,0x7
    800024aa:	0000f597          	auipc	a1,0xf
    800024ae:	f1e58593          	addi	a1,a1,-226 # 800113c8 <cpus+0x8>
    800024b2:	95be                	add	a1,a1,a5
    800024b4:	07848513          	addi	a0,s1,120
    800024b8:	00001097          	auipc	ra,0x1
    800024bc:	b5a080e7          	jalr	-1190(ra) # 80003012 <swtch>
    800024c0:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800024c2:	2781                	sext.w	a5,a5
    800024c4:	079e                	slli	a5,a5,0x7
    800024c6:	97ca                	add	a5,a5,s2
    800024c8:	1937ae23          	sw	s3,412(a5)
}
    800024cc:	70a2                	ld	ra,40(sp)
    800024ce:	7402                	ld	s0,32(sp)
    800024d0:	64e2                	ld	s1,24(sp)
    800024d2:	6942                	ld	s2,16(sp)
    800024d4:	69a2                	ld	s3,8(sp)
    800024d6:	6145                	addi	sp,sp,48
    800024d8:	8082                	ret
    panic("sched p->lock");
    800024da:	00006517          	auipc	a0,0x6
    800024de:	d6650513          	addi	a0,a0,-666 # 80008240 <digits+0x200>
    800024e2:	ffffe097          	auipc	ra,0xffffe
    800024e6:	05c080e7          	jalr	92(ra) # 8000053e <panic>
    panic("sched locks");
    800024ea:	00006517          	auipc	a0,0x6
    800024ee:	d6650513          	addi	a0,a0,-666 # 80008250 <digits+0x210>
    800024f2:	ffffe097          	auipc	ra,0xffffe
    800024f6:	04c080e7          	jalr	76(ra) # 8000053e <panic>
    panic("sched running");
    800024fa:	00006517          	auipc	a0,0x6
    800024fe:	d6650513          	addi	a0,a0,-666 # 80008260 <digits+0x220>
    80002502:	ffffe097          	auipc	ra,0xffffe
    80002506:	03c080e7          	jalr	60(ra) # 8000053e <panic>
    panic("sched interruptible");
    8000250a:	00006517          	auipc	a0,0x6
    8000250e:	d6650513          	addi	a0,a0,-666 # 80008270 <digits+0x230>
    80002512:	ffffe097          	auipc	ra,0xffffe
    80002516:	02c080e7          	jalr	44(ra) # 8000053e <panic>

000000008000251a <yield>:
{
    8000251a:	1101                	addi	sp,sp,-32
    8000251c:	ec06                	sd	ra,24(sp)
    8000251e:	e822                	sd	s0,16(sp)
    80002520:	e426                	sd	s1,8(sp)
    80002522:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002524:	00000097          	auipc	ra,0x0
    80002528:	93a080e7          	jalr	-1734(ra) # 80001e5e <myproc>
    8000252c:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000252e:	ffffe097          	auipc	ra,0xffffe
    80002532:	6b6080e7          	jalr	1718(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    80002536:	478d                	li	a5,3
    80002538:	d89c                	sw	a5,48(s1)
  add_link(&runnable_cpu_lists[p->affiliated_cpu], p->proc_index,1);
    8000253a:	1884a503          	lw	a0,392(s1)
    8000253e:	00251793          	slli	a5,a0,0x2
    80002542:	97aa                	add	a5,a5,a0
    80002544:	078e                	slli	a5,a5,0x3
    80002546:	4605                	li	a2,1
    80002548:	1844a583          	lw	a1,388(s1)
    8000254c:	0000f517          	auipc	a0,0xf
    80002550:	d5450513          	addi	a0,a0,-684 # 800112a0 <runnable_cpu_lists>
    80002554:	953e                	add	a0,a0,a5
    80002556:	fffff097          	auipc	ra,0xfffff
    8000255a:	590080e7          	jalr	1424(ra) # 80001ae6 <add_link>
  sched();
    8000255e:	00000097          	auipc	ra,0x0
    80002562:	ee6080e7          	jalr	-282(ra) # 80002444 <sched>
  release(&p->lock);
    80002566:	8526                	mv	a0,s1
    80002568:	ffffe097          	auipc	ra,0xffffe
    8000256c:	730080e7          	jalr	1840(ra) # 80000c98 <release>
}
    80002570:	60e2                	ld	ra,24(sp)
    80002572:	6442                	ld	s0,16(sp)
    80002574:	64a2                	ld	s1,8(sp)
    80002576:	6105                	addi	sp,sp,32
    80002578:	8082                	ret

000000008000257a <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000257a:	7179                	addi	sp,sp,-48
    8000257c:	f406                	sd	ra,40(sp)
    8000257e:	f022                	sd	s0,32(sp)
    80002580:	ec26                	sd	s1,24(sp)
    80002582:	e84a                	sd	s2,16(sp)
    80002584:	e44e                	sd	s3,8(sp)
    80002586:	1800                	addi	s0,sp,48
    80002588:	89aa                	mv	s3,a0
    8000258a:	892e                	mv	s2,a1

  
  struct proc *p = myproc();
    8000258c:	00000097          	auipc	ra,0x0
    80002590:	8d2080e7          	jalr	-1838(ra) # 80001e5e <myproc>
    80002594:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002596:	ffffe097          	auipc	ra,0xffffe
    8000259a:	64e080e7          	jalr	1614(ra) # 80000be4 <acquire>
  //printf("start sleep for proc index %d\n", p->proc_index);
  release(lk);
    8000259e:	854a                	mv	a0,s2
    800025a0:	ffffe097          	auipc	ra,0xffffe
    800025a4:	6f8080e7          	jalr	1784(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    800025a8:	0334bc23          	sd	s3,56(s1)
  p->state = SLEEPING;
    800025ac:	4789                	li	a5,2
    800025ae:	d89c                	sw	a5,48(s1)
  
  add_link(&sleeping_list, p->proc_index, 0);
    800025b0:	4601                	li	a2,0
    800025b2:	1844a583          	lw	a1,388(s1)
    800025b6:	0000f517          	auipc	a0,0xf
    800025ba:	d8a50513          	addi	a0,a0,-630 # 80011340 <sleeping_list>
    800025be:	fffff097          	auipc	ra,0xfffff
    800025c2:	528080e7          	jalr	1320(ra) # 80001ae6 <add_link>
  //printf("after adding link to sleeping list\n");
  sched();
    800025c6:	00000097          	auipc	ra,0x0
    800025ca:	e7e080e7          	jalr	-386(ra) # 80002444 <sched>

  // Tidy up.
  p->chan = 0;
    800025ce:	0204bc23          	sd	zero,56(s1)

  // Reacquire original lock.
  release(&p->lock);
    800025d2:	8526                	mv	a0,s1
    800025d4:	ffffe097          	auipc	ra,0xffffe
    800025d8:	6c4080e7          	jalr	1732(ra) # 80000c98 <release>
  
  acquire(lk);
    800025dc:	854a                	mv	a0,s2
    800025de:	ffffe097          	auipc	ra,0xffffe
    800025e2:	606080e7          	jalr	1542(ra) # 80000be4 <acquire>
  //printf("finish sleep procedure\n");
}
    800025e6:	70a2                	ld	ra,40(sp)
    800025e8:	7402                	ld	s0,32(sp)
    800025ea:	64e2                	ld	s1,24(sp)
    800025ec:	6942                	ld	s2,16(sp)
    800025ee:	69a2                	ld	s3,8(sp)
    800025f0:	6145                	addi	sp,sp,48
    800025f2:	8082                	ret

00000000800025f4 <wait>:
{
    800025f4:	715d                	addi	sp,sp,-80
    800025f6:	e486                	sd	ra,72(sp)
    800025f8:	e0a2                	sd	s0,64(sp)
    800025fa:	fc26                	sd	s1,56(sp)
    800025fc:	f84a                	sd	s2,48(sp)
    800025fe:	f44e                	sd	s3,40(sp)
    80002600:	f052                	sd	s4,32(sp)
    80002602:	ec56                	sd	s5,24(sp)
    80002604:	e85a                	sd	s6,16(sp)
    80002606:	e45e                	sd	s7,8(sp)
    80002608:	e062                	sd	s8,0(sp)
    8000260a:	0880                	addi	s0,sp,80
    8000260c:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000260e:	00000097          	auipc	ra,0x0
    80002612:	850080e7          	jalr	-1968(ra) # 80001e5e <myproc>
    80002616:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002618:	0000f517          	auipc	a0,0xf
    8000261c:	d9050513          	addi	a0,a0,-624 # 800113a8 <wait_lock>
    80002620:	ffffe097          	auipc	ra,0xffffe
    80002624:	5c4080e7          	jalr	1476(ra) # 80000be4 <acquire>
    havekids = 0;
    80002628:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    8000262a:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    8000262c:	00015997          	auipc	s3,0x15
    80002630:	59498993          	addi	s3,s3,1428 # 80017bc0 <tickslock>
        havekids = 1;
    80002634:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002636:	0000fc17          	auipc	s8,0xf
    8000263a:	d72c0c13          	addi	s8,s8,-654 # 800113a8 <wait_lock>
    havekids = 0;
    8000263e:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002640:	0000f497          	auipc	s1,0xf
    80002644:	18048493          	addi	s1,s1,384 # 800117c0 <proc>
    80002648:	a0bd                	j	800026b6 <wait+0xc2>
          pid = np->pid;
    8000264a:	0484a983          	lw	s3,72(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000264e:	000b0e63          	beqz	s6,8000266a <wait+0x76>
    80002652:	4691                	li	a3,4
    80002654:	04448613          	addi	a2,s1,68
    80002658:	85da                	mv	a1,s6
    8000265a:	06893503          	ld	a0,104(s2)
    8000265e:	fffff097          	auipc	ra,0xfffff
    80002662:	014080e7          	jalr	20(ra) # 80001672 <copyout>
    80002666:	02054563          	bltz	a0,80002690 <wait+0x9c>
          freeproc(np);
    8000266a:	8526                	mv	a0,s1
    8000266c:	00000097          	auipc	ra,0x0
    80002670:	998080e7          	jalr	-1640(ra) # 80002004 <freeproc>
          release(&np->lock);
    80002674:	8526                	mv	a0,s1
    80002676:	ffffe097          	auipc	ra,0xffffe
    8000267a:	622080e7          	jalr	1570(ra) # 80000c98 <release>
          release(&wait_lock);
    8000267e:	0000f517          	auipc	a0,0xf
    80002682:	d2a50513          	addi	a0,a0,-726 # 800113a8 <wait_lock>
    80002686:	ffffe097          	auipc	ra,0xffffe
    8000268a:	612080e7          	jalr	1554(ra) # 80000c98 <release>
          return pid;
    8000268e:	a09d                	j	800026f4 <wait+0x100>
            release(&np->lock);
    80002690:	8526                	mv	a0,s1
    80002692:	ffffe097          	auipc	ra,0xffffe
    80002696:	606080e7          	jalr	1542(ra) # 80000c98 <release>
            release(&wait_lock);
    8000269a:	0000f517          	auipc	a0,0xf
    8000269e:	d0e50513          	addi	a0,a0,-754 # 800113a8 <wait_lock>
    800026a2:	ffffe097          	auipc	ra,0xffffe
    800026a6:	5f6080e7          	jalr	1526(ra) # 80000c98 <release>
            return -1;
    800026aa:	59fd                	li	s3,-1
    800026ac:	a0a1                	j	800026f4 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    800026ae:	19048493          	addi	s1,s1,400
    800026b2:	03348463          	beq	s1,s3,800026da <wait+0xe6>
      if(np->parent == p){
    800026b6:	68bc                	ld	a5,80(s1)
    800026b8:	ff279be3          	bne	a5,s2,800026ae <wait+0xba>
        acquire(&np->lock);
    800026bc:	8526                	mv	a0,s1
    800026be:	ffffe097          	auipc	ra,0xffffe
    800026c2:	526080e7          	jalr	1318(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    800026c6:	589c                	lw	a5,48(s1)
    800026c8:	f94781e3          	beq	a5,s4,8000264a <wait+0x56>
        release(&np->lock);
    800026cc:	8526                	mv	a0,s1
    800026ce:	ffffe097          	auipc	ra,0xffffe
    800026d2:	5ca080e7          	jalr	1482(ra) # 80000c98 <release>
        havekids = 1;
    800026d6:	8756                	mv	a4,s5
    800026d8:	bfd9                	j	800026ae <wait+0xba>
    if(!havekids || p->killed){
    800026da:	c701                	beqz	a4,800026e2 <wait+0xee>
    800026dc:	04092783          	lw	a5,64(s2)
    800026e0:	c79d                	beqz	a5,8000270e <wait+0x11a>
      release(&wait_lock);
    800026e2:	0000f517          	auipc	a0,0xf
    800026e6:	cc650513          	addi	a0,a0,-826 # 800113a8 <wait_lock>
    800026ea:	ffffe097          	auipc	ra,0xffffe
    800026ee:	5ae080e7          	jalr	1454(ra) # 80000c98 <release>
      return -1;
    800026f2:	59fd                	li	s3,-1
}
    800026f4:	854e                	mv	a0,s3
    800026f6:	60a6                	ld	ra,72(sp)
    800026f8:	6406                	ld	s0,64(sp)
    800026fa:	74e2                	ld	s1,56(sp)
    800026fc:	7942                	ld	s2,48(sp)
    800026fe:	79a2                	ld	s3,40(sp)
    80002700:	7a02                	ld	s4,32(sp)
    80002702:	6ae2                	ld	s5,24(sp)
    80002704:	6b42                	ld	s6,16(sp)
    80002706:	6ba2                	ld	s7,8(sp)
    80002708:	6c02                	ld	s8,0(sp)
    8000270a:	6161                	addi	sp,sp,80
    8000270c:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000270e:	85e2                	mv	a1,s8
    80002710:	854a                	mv	a0,s2
    80002712:	00000097          	auipc	ra,0x0
    80002716:	e68080e7          	jalr	-408(ra) # 8000257a <sleep>
    havekids = 0;
    8000271a:	b715                	j	8000263e <wait+0x4a>

000000008000271c <wakeup>:

}

void
wakeup(void *chan)
{
    8000271c:	711d                	addi	sp,sp,-96
    8000271e:	ec86                	sd	ra,88(sp)
    80002720:	e8a2                	sd	s0,80(sp)
    80002722:	e4a6                	sd	s1,72(sp)
    80002724:	e0ca                	sd	s2,64(sp)
    80002726:	fc4e                	sd	s3,56(sp)
    80002728:	f852                	sd	s4,48(sp)
    8000272a:	f456                	sd	s5,40(sp)
    8000272c:	f05a                	sd	s6,32(sp)
    8000272e:	ec5e                	sd	s7,24(sp)
    80002730:	e862                	sd	s8,16(sp)
    80002732:	e466                	sd	s9,8(sp)
    80002734:	e06a                	sd	s10,0(sp)
    80002736:	1080                	addi	s0,sp,96
    80002738:	8baa                	mv	s7,a0
  
  while(1) // Keep looping until no process is waken up
  {
    
    //Loop until finds process that needs to be waken up
    acquire(&sleeping_list.head_lock);
    8000273a:	0000fd17          	auipc	s10,0xf
    8000273e:	b66d0d13          	addi	s10,s10,-1178 # 800112a0 <runnable_cpu_lists>
    80002742:	0000fc97          	auipc	s9,0xf
    80002746:	c06c8c93          	addi	s9,s9,-1018 # 80011348 <sleeping_list+0x8>
    if (sleeping_list.head == -1) //empty list
    8000274a:	5c7d                	li	s8,-1
    8000274c:	19000a93          	li	s5,400
      
      release(&sleeping_list.head_lock);
      return;
    }
    //non-empty:
    curr = &proc[sleeping_list.head];
    80002750:	0000fa17          	auipc	s4,0xf
    80002754:	070a0a13          	addi	s4,s4,112 # 800117c0 <proc>
    80002758:	a8a9                	j	800027b2 <wakeup+0x96>
      release(&sleeping_list.head_lock);
    8000275a:	0000f517          	auipc	a0,0xf
    8000275e:	bee50513          	addi	a0,a0,-1042 # 80011348 <sleeping_list+0x8>
    80002762:	ffffe097          	auipc	ra,0xffffe
    80002766:	536080e7          	jalr	1334(ra) # 80000c98 <release>
      return;
    8000276a:	a20d                	j	8000288c <wakeup+0x170>
      cpu_to_add = curr->affiliated_cpu;
      if (balance){
          cpu_to_add = get_balanced_cpu();
      }
      struct processList* cpuList = &runnable_cpu_lists[cpu_to_add];
      release(&curr->list_lock);
    8000276c:	854a                	mv	a0,s2
    8000276e:	ffffe097          	auipc	ra,0xffffe
    80002772:	52a080e7          	jalr	1322(ra) # 80000c98 <release>
      remove_link(&sleeping_list, curr->proc_index);
    80002776:	035484b3          	mul	s1,s1,s5
    8000277a:	94d2                	add	s1,s1,s4
    8000277c:	1844a583          	lw	a1,388(s1)
    80002780:	0000f517          	auipc	a0,0xf
    80002784:	bc050513          	addi	a0,a0,-1088 # 80011340 <sleeping_list>
    80002788:	fffff097          	auipc	ra,0xfffff
    8000278c:	130080e7          	jalr	304(ra) # 800018b8 <remove_link>
      struct processList* cpuList = &runnable_cpu_lists[cpu_to_add];
    80002790:	002b1513          	slli	a0,s6,0x2
    80002794:	955a                	add	a0,a0,s6
    80002796:	050e                	slli	a0,a0,0x3
      add_link(cpuList, curr->proc_index, 0);
    80002798:	4601                	li	a2,0
    8000279a:	1844a583          	lw	a1,388(s1)
    8000279e:	956a                	add	a0,a0,s10
    800027a0:	fffff097          	auipc	ra,0xfffff
    800027a4:	346080e7          	jalr	838(ra) # 80001ae6 <add_link>
      release(&curr->lock);
    800027a8:	854e                	mv	a0,s3
    800027aa:	ffffe097          	auipc	ra,0xffffe
    800027ae:	4ee080e7          	jalr	1262(ra) # 80000c98 <release>
    acquire(&sleeping_list.head_lock);
    800027b2:	8566                	mv	a0,s9
    800027b4:	ffffe097          	auipc	ra,0xffffe
    800027b8:	430080e7          	jalr	1072(ra) # 80000be4 <acquire>
    if (sleeping_list.head == -1) //empty list
    800027bc:	0a0d2483          	lw	s1,160(s10)
    800027c0:	f9848de3          	beq	s1,s8,8000275a <wakeup+0x3e>
    curr = &proc[sleeping_list.head];
    800027c4:	03548533          	mul	a0,s1,s5
    800027c8:	014509b3          	add	s3,a0,s4
    acquire(&curr->list_lock);
    800027cc:	0561                	addi	a0,a0,24
    800027ce:	01450933          	add	s2,a0,s4
    800027d2:	854a                	mv	a0,s2
    800027d4:	ffffe097          	auipc	ra,0xffffe
    800027d8:	410080e7          	jalr	1040(ra) # 80000be4 <acquire>
    release(&sleeping_list.head_lock);
    800027dc:	8566                	mv	a0,s9
    800027de:	ffffe097          	auipc	ra,0xffffe
    800027e2:	4ba080e7          	jalr	1210(ra) # 80000c98 <release>
    acquire(&curr->lock);
    800027e6:	854e                	mv	a0,s3
    800027e8:	ffffe097          	auipc	ra,0xffffe
    800027ec:	3fc080e7          	jalr	1020(ra) # 80000be4 <acquire>
    if(curr->chan == chan) //needs to wake up
    800027f0:	0389b783          	ld	a5,56(s3)
    800027f4:	03779263          	bne	a5,s7,80002818 <wakeup+0xfc>
      curr->state = RUNNABLE;
    800027f8:	470d                	li	a4,3
    800027fa:	02e9a823          	sw	a4,48(s3)
      cpu_to_add = curr->affiliated_cpu;
    800027fe:	1889ab03          	lw	s6,392(s3)
      if (balance){
    80002802:	00006797          	auipc	a5,0x6
    80002806:	0a67a783          	lw	a5,166(a5) # 800088a8 <balance>
    8000280a:	d3ad                	beqz	a5,8000276c <wakeup+0x50>
          cpu_to_add = get_balanced_cpu();
    8000280c:	fffff097          	auipc	ra,0xfffff
    80002810:	07c080e7          	jalr	124(ra) # 80001888 <get_balanced_cpu>
    80002814:	8b2a                	mv	s6,a0
    80002816:	bf99                	j	8000276c <wakeup+0x50>
      continue; //another iteration on list
    }
    release(&curr->lock);
    80002818:	854e                	mv	a0,s3
    8000281a:	ffffe097          	auipc	ra,0xffffe
    8000281e:	47e080e7          	jalr	1150(ra) # 80000c98 <release>
    int finished = 1;
    while(curr->next_proc_index!= -1) //loop to find process that needs to be waken up
    80002822:	035484b3          	mul	s1,s1,s5
    80002826:	94d2                	add	s1,s1,s4
    80002828:	1804a483          	lw	s1,384(s1)
    8000282c:	05848a63          	beq	s1,s8,80002880 <wakeup+0x164>
    {
      next = &proc[curr->next_proc_index];
    80002830:	035487b3          	mul	a5,s1,s5
    80002834:	8b4e                	mv	s6,s3
    80002836:	014789b3          	add	s3,a5,s4
      acquire(&next->list_lock);
    8000283a:	07e1                	addi	a5,a5,24
    8000283c:	01478933          	add	s2,a5,s4
    80002840:	854a                	mv	a0,s2
    80002842:	ffffe097          	auipc	ra,0xffffe
    80002846:	3a2080e7          	jalr	930(ra) # 80000be4 <acquire>
      release(&curr->list_lock);
    8000284a:	018b0513          	addi	a0,s6,24
    8000284e:	ffffe097          	auipc	ra,0xffffe
    80002852:	44a080e7          	jalr	1098(ra) # 80000c98 <release>
      curr = next;

      acquire(&curr->lock);
    80002856:	854e                	mv	a0,s3
    80002858:	ffffe097          	auipc	ra,0xffffe
    8000285c:	38c080e7          	jalr	908(ra) # 80000be4 <acquire>
      if(curr->chan == chan) //needs to wake up
    80002860:	0389b783          	ld	a5,56(s3)
    80002864:	05778263          	beq	a5,s7,800028a8 <wakeup+0x18c>
        add_link(cpuList, curr->proc_index, 0);
        release(&curr->lock);
        finished = 0;
        break; //another iteration on list
      }
      release(&curr->lock);
    80002868:	854e                	mv	a0,s3
    8000286a:	ffffe097          	auipc	ra,0xffffe
    8000286e:	42e080e7          	jalr	1070(ra) # 80000c98 <release>
    while(curr->next_proc_index!= -1) //loop to find process that needs to be waken up
    80002872:	035484b3          	mul	s1,s1,s5
    80002876:	94d2                	add	s1,s1,s4
    80002878:	1804a483          	lw	s1,384(s1)
    8000287c:	fb849ae3          	bne	s1,s8,80002830 <wakeup+0x114>
    }
    if(finished == 1) //full iteration with no wakeup
    {
      //printf("exiting wakeup\n");
      release(&curr->list_lock);
    80002880:	01898513          	addi	a0,s3,24
    80002884:	ffffe097          	auipc	ra,0xffffe
    80002888:	414080e7          	jalr	1044(ra) # 80000c98 <release>
      return;
    }
  }
}
    8000288c:	60e6                	ld	ra,88(sp)
    8000288e:	6446                	ld	s0,80(sp)
    80002890:	64a6                	ld	s1,72(sp)
    80002892:	6906                	ld	s2,64(sp)
    80002894:	79e2                	ld	s3,56(sp)
    80002896:	7a42                	ld	s4,48(sp)
    80002898:	7aa2                	ld	s5,40(sp)
    8000289a:	7b02                	ld	s6,32(sp)
    8000289c:	6be2                	ld	s7,24(sp)
    8000289e:	6c42                	ld	s8,16(sp)
    800028a0:	6ca2                	ld	s9,8(sp)
    800028a2:	6d02                	ld	s10,0(sp)
    800028a4:	6125                	addi	sp,sp,96
    800028a6:	8082                	ret
        curr->state = RUNNABLE;
    800028a8:	470d                	li	a4,3
    800028aa:	02e9a823          	sw	a4,48(s3)
        cpu_to_add = curr->affiliated_cpu;
    800028ae:	1889ab03          	lw	s6,392(s3)
        if (balance){
    800028b2:	00006797          	auipc	a5,0x6
    800028b6:	ff67a783          	lw	a5,-10(a5) # 800088a8 <balance>
    800028ba:	c791                	beqz	a5,800028c6 <wakeup+0x1aa>
            cpu_to_add = get_balanced_cpu();
    800028bc:	fffff097          	auipc	ra,0xfffff
    800028c0:	fcc080e7          	jalr	-52(ra) # 80001888 <get_balanced_cpu>
    800028c4:	8b2a                	mv	s6,a0
        release(&curr->list_lock);
    800028c6:	854a                	mv	a0,s2
    800028c8:	ffffe097          	auipc	ra,0xffffe
    800028cc:	3d0080e7          	jalr	976(ra) # 80000c98 <release>
        remove_link(&sleeping_list, curr->proc_index);
    800028d0:	035484b3          	mul	s1,s1,s5
    800028d4:	94d2                	add	s1,s1,s4
    800028d6:	1844a583          	lw	a1,388(s1)
    800028da:	0000f517          	auipc	a0,0xf
    800028de:	a6650513          	addi	a0,a0,-1434 # 80011340 <sleeping_list>
    800028e2:	fffff097          	auipc	ra,0xfffff
    800028e6:	fd6080e7          	jalr	-42(ra) # 800018b8 <remove_link>
        struct processList* cpuList = &runnable_cpu_lists[cpu_to_add];
    800028ea:	002b1513          	slli	a0,s6,0x2
    800028ee:	955a                	add	a0,a0,s6
    800028f0:	050e                	slli	a0,a0,0x3
        add_link(cpuList, curr->proc_index, 0);
    800028f2:	4601                	li	a2,0
    800028f4:	1844a583          	lw	a1,388(s1)
    800028f8:	956a                	add	a0,a0,s10
    800028fa:	fffff097          	auipc	ra,0xfffff
    800028fe:	1ec080e7          	jalr	492(ra) # 80001ae6 <add_link>
        release(&curr->lock);
    80002902:	854e                	mv	a0,s3
    80002904:	ffffe097          	auipc	ra,0xffffe
    80002908:	394080e7          	jalr	916(ra) # 80000c98 <release>
    if(finished == 1) //full iteration with no wakeup
    8000290c:	b55d                	j	800027b2 <wakeup+0x96>

000000008000290e <reparent>:
{
    8000290e:	7179                	addi	sp,sp,-48
    80002910:	f406                	sd	ra,40(sp)
    80002912:	f022                	sd	s0,32(sp)
    80002914:	ec26                	sd	s1,24(sp)
    80002916:	e84a                	sd	s2,16(sp)
    80002918:	e44e                	sd	s3,8(sp)
    8000291a:	e052                	sd	s4,0(sp)
    8000291c:	1800                	addi	s0,sp,48
    8000291e:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002920:	0000f497          	auipc	s1,0xf
    80002924:	ea048493          	addi	s1,s1,-352 # 800117c0 <proc>
      pp->parent = initproc;
    80002928:	00006a17          	auipc	s4,0x6
    8000292c:	700a0a13          	addi	s4,s4,1792 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002930:	00015997          	auipc	s3,0x15
    80002934:	29098993          	addi	s3,s3,656 # 80017bc0 <tickslock>
    80002938:	a029                	j	80002942 <reparent+0x34>
    8000293a:	19048493          	addi	s1,s1,400
    8000293e:	01348d63          	beq	s1,s3,80002958 <reparent+0x4a>
    if(pp->parent == p){
    80002942:	68bc                	ld	a5,80(s1)
    80002944:	ff279be3          	bne	a5,s2,8000293a <reparent+0x2c>
      pp->parent = initproc;
    80002948:	000a3503          	ld	a0,0(s4)
    8000294c:	e8a8                	sd	a0,80(s1)
      wakeup(initproc);
    8000294e:	00000097          	auipc	ra,0x0
    80002952:	dce080e7          	jalr	-562(ra) # 8000271c <wakeup>
    80002956:	b7d5                	j	8000293a <reparent+0x2c>
}
    80002958:	70a2                	ld	ra,40(sp)
    8000295a:	7402                	ld	s0,32(sp)
    8000295c:	64e2                	ld	s1,24(sp)
    8000295e:	6942                	ld	s2,16(sp)
    80002960:	69a2                	ld	s3,8(sp)
    80002962:	6a02                	ld	s4,0(sp)
    80002964:	6145                	addi	sp,sp,48
    80002966:	8082                	ret

0000000080002968 <exit>:
{
    80002968:	7179                	addi	sp,sp,-48
    8000296a:	f406                	sd	ra,40(sp)
    8000296c:	f022                	sd	s0,32(sp)
    8000296e:	ec26                	sd	s1,24(sp)
    80002970:	e84a                	sd	s2,16(sp)
    80002972:	e44e                	sd	s3,8(sp)
    80002974:	e052                	sd	s4,0(sp)
    80002976:	1800                	addi	s0,sp,48
    80002978:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000297a:	fffff097          	auipc	ra,0xfffff
    8000297e:	4e4080e7          	jalr	1252(ra) # 80001e5e <myproc>
    80002982:	89aa                	mv	s3,a0
  if(p == initproc)
    80002984:	00006797          	auipc	a5,0x6
    80002988:	6a47b783          	ld	a5,1700(a5) # 80009028 <initproc>
    8000298c:	0e850493          	addi	s1,a0,232
    80002990:	16850913          	addi	s2,a0,360
    80002994:	02a79363          	bne	a5,a0,800029ba <exit+0x52>
    panic("init exiting");
    80002998:	00006517          	auipc	a0,0x6
    8000299c:	8f050513          	addi	a0,a0,-1808 # 80008288 <digits+0x248>
    800029a0:	ffffe097          	auipc	ra,0xffffe
    800029a4:	b9e080e7          	jalr	-1122(ra) # 8000053e <panic>
      fileclose(f);
    800029a8:	00002097          	auipc	ra,0x2
    800029ac:	5e8080e7          	jalr	1512(ra) # 80004f90 <fileclose>
      p->ofile[fd] = 0;
    800029b0:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800029b4:	04a1                	addi	s1,s1,8
    800029b6:	01248563          	beq	s1,s2,800029c0 <exit+0x58>
    if(p->ofile[fd]){
    800029ba:	6088                	ld	a0,0(s1)
    800029bc:	f575                	bnez	a0,800029a8 <exit+0x40>
    800029be:	bfdd                	j	800029b4 <exit+0x4c>
  begin_op();
    800029c0:	00002097          	auipc	ra,0x2
    800029c4:	104080e7          	jalr	260(ra) # 80004ac4 <begin_op>
  iput(p->cwd);
    800029c8:	1689b503          	ld	a0,360(s3)
    800029cc:	00002097          	auipc	ra,0x2
    800029d0:	8e0080e7          	jalr	-1824(ra) # 800042ac <iput>
  end_op();
    800029d4:	00002097          	auipc	ra,0x2
    800029d8:	170080e7          	jalr	368(ra) # 80004b44 <end_op>
  p->cwd = 0;
    800029dc:	1609b423          	sd	zero,360(s3)
  acquire(&wait_lock);
    800029e0:	0000f497          	auipc	s1,0xf
    800029e4:	9c848493          	addi	s1,s1,-1592 # 800113a8 <wait_lock>
    800029e8:	8526                	mv	a0,s1
    800029ea:	ffffe097          	auipc	ra,0xffffe
    800029ee:	1fa080e7          	jalr	506(ra) # 80000be4 <acquire>
  reparent(p);
    800029f2:	854e                	mv	a0,s3
    800029f4:	00000097          	auipc	ra,0x0
    800029f8:	f1a080e7          	jalr	-230(ra) # 8000290e <reparent>
  wakeup(p->parent);
    800029fc:	0509b503          	ld	a0,80(s3)
    80002a00:	00000097          	auipc	ra,0x0
    80002a04:	d1c080e7          	jalr	-740(ra) # 8000271c <wakeup>
  acquire(&p->lock);
    80002a08:	854e                	mv	a0,s3
    80002a0a:	ffffe097          	auipc	ra,0xffffe
    80002a0e:	1da080e7          	jalr	474(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002a12:	0549a223          	sw	s4,68(s3)
  p->state = ZOMBIE;
    80002a16:	4795                	li	a5,5
    80002a18:	02f9a823          	sw	a5,48(s3)
  add_link(&zombie_list, p->proc_index, 0);
    80002a1c:	4601                	li	a2,0
    80002a1e:	1849a583          	lw	a1,388(s3)
    80002a22:	0000f517          	auipc	a0,0xf
    80002a26:	94650513          	addi	a0,a0,-1722 # 80011368 <zombie_list>
    80002a2a:	fffff097          	auipc	ra,0xfffff
    80002a2e:	0bc080e7          	jalr	188(ra) # 80001ae6 <add_link>
  release(&wait_lock);
    80002a32:	8526                	mv	a0,s1
    80002a34:	ffffe097          	auipc	ra,0xffffe
    80002a38:	264080e7          	jalr	612(ra) # 80000c98 <release>
  sched();
    80002a3c:	00000097          	auipc	ra,0x0
    80002a40:	a08080e7          	jalr	-1528(ra) # 80002444 <sched>
  panic("zombie exit");
    80002a44:	00006517          	auipc	a0,0x6
    80002a48:	85450513          	addi	a0,a0,-1964 # 80008298 <digits+0x258>
    80002a4c:	ffffe097          	auipc	ra,0xffffe
    80002a50:	af2080e7          	jalr	-1294(ra) # 8000053e <panic>

0000000080002a54 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002a54:	7179                	addi	sp,sp,-48
    80002a56:	f406                	sd	ra,40(sp)
    80002a58:	f022                	sd	s0,32(sp)
    80002a5a:	ec26                	sd	s1,24(sp)
    80002a5c:	e84a                	sd	s2,16(sp)
    80002a5e:	e44e                	sd	s3,8(sp)
    80002a60:	1800                	addi	s0,sp,48
    80002a62:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002a64:	0000f497          	auipc	s1,0xf
    80002a68:	d5c48493          	addi	s1,s1,-676 # 800117c0 <proc>
    80002a6c:	00015997          	auipc	s3,0x15
    80002a70:	15498993          	addi	s3,s3,340 # 80017bc0 <tickslock>
    acquire(&p->lock);
    80002a74:	8526                	mv	a0,s1
    80002a76:	ffffe097          	auipc	ra,0xffffe
    80002a7a:	16e080e7          	jalr	366(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    80002a7e:	44bc                	lw	a5,72(s1)
    80002a80:	01278d63          	beq	a5,s2,80002a9a <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002a84:	8526                	mv	a0,s1
    80002a86:	ffffe097          	auipc	ra,0xffffe
    80002a8a:	212080e7          	jalr	530(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002a8e:	19048493          	addi	s1,s1,400
    80002a92:	ff3491e3          	bne	s1,s3,80002a74 <kill+0x20>
  }
  return -1;
    80002a96:	557d                	li	a0,-1
    80002a98:	a829                	j	80002ab2 <kill+0x5e>
      p->killed = 1;
    80002a9a:	4785                	li	a5,1
    80002a9c:	c0bc                	sw	a5,64(s1)
      if(p->state == SLEEPING){
    80002a9e:	5898                	lw	a4,48(s1)
    80002aa0:	4789                	li	a5,2
    80002aa2:	00f70f63          	beq	a4,a5,80002ac0 <kill+0x6c>
      release(&p->lock);
    80002aa6:	8526                	mv	a0,s1
    80002aa8:	ffffe097          	auipc	ra,0xffffe
    80002aac:	1f0080e7          	jalr	496(ra) # 80000c98 <release>
      return 0;
    80002ab0:	4501                	li	a0,0
}
    80002ab2:	70a2                	ld	ra,40(sp)
    80002ab4:	7402                	ld	s0,32(sp)
    80002ab6:	64e2                	ld	s1,24(sp)
    80002ab8:	6942                	ld	s2,16(sp)
    80002aba:	69a2                	ld	s3,8(sp)
    80002abc:	6145                	addi	sp,sp,48
    80002abe:	8082                	ret
        p->state = RUNNABLE;
    80002ac0:	478d                	li	a5,3
    80002ac2:	d89c                	sw	a5,48(s1)
    80002ac4:	b7cd                	j	80002aa6 <kill+0x52>

0000000080002ac6 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002ac6:	7179                	addi	sp,sp,-48
    80002ac8:	f406                	sd	ra,40(sp)
    80002aca:	f022                	sd	s0,32(sp)
    80002acc:	ec26                	sd	s1,24(sp)
    80002ace:	e84a                	sd	s2,16(sp)
    80002ad0:	e44e                	sd	s3,8(sp)
    80002ad2:	e052                	sd	s4,0(sp)
    80002ad4:	1800                	addi	s0,sp,48
    80002ad6:	84aa                	mv	s1,a0
    80002ad8:	892e                	mv	s2,a1
    80002ada:	89b2                	mv	s3,a2
    80002adc:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002ade:	fffff097          	auipc	ra,0xfffff
    80002ae2:	380080e7          	jalr	896(ra) # 80001e5e <myproc>
  if(user_dst){
    80002ae6:	c08d                	beqz	s1,80002b08 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002ae8:	86d2                	mv	a3,s4
    80002aea:	864e                	mv	a2,s3
    80002aec:	85ca                	mv	a1,s2
    80002aee:	7528                	ld	a0,104(a0)
    80002af0:	fffff097          	auipc	ra,0xfffff
    80002af4:	b82080e7          	jalr	-1150(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002af8:	70a2                	ld	ra,40(sp)
    80002afa:	7402                	ld	s0,32(sp)
    80002afc:	64e2                	ld	s1,24(sp)
    80002afe:	6942                	ld	s2,16(sp)
    80002b00:	69a2                	ld	s3,8(sp)
    80002b02:	6a02                	ld	s4,0(sp)
    80002b04:	6145                	addi	sp,sp,48
    80002b06:	8082                	ret
    memmove((char *)dst, src, len);
    80002b08:	000a061b          	sext.w	a2,s4
    80002b0c:	85ce                	mv	a1,s3
    80002b0e:	854a                	mv	a0,s2
    80002b10:	ffffe097          	auipc	ra,0xffffe
    80002b14:	230080e7          	jalr	560(ra) # 80000d40 <memmove>
    return 0;
    80002b18:	8526                	mv	a0,s1
    80002b1a:	bff9                	j	80002af8 <either_copyout+0x32>

0000000080002b1c <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002b1c:	7179                	addi	sp,sp,-48
    80002b1e:	f406                	sd	ra,40(sp)
    80002b20:	f022                	sd	s0,32(sp)
    80002b22:	ec26                	sd	s1,24(sp)
    80002b24:	e84a                	sd	s2,16(sp)
    80002b26:	e44e                	sd	s3,8(sp)
    80002b28:	e052                	sd	s4,0(sp)
    80002b2a:	1800                	addi	s0,sp,48
    80002b2c:	892a                	mv	s2,a0
    80002b2e:	84ae                	mv	s1,a1
    80002b30:	89b2                	mv	s3,a2
    80002b32:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002b34:	fffff097          	auipc	ra,0xfffff
    80002b38:	32a080e7          	jalr	810(ra) # 80001e5e <myproc>
  if(user_src){
    80002b3c:	c08d                	beqz	s1,80002b5e <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002b3e:	86d2                	mv	a3,s4
    80002b40:	864e                	mv	a2,s3
    80002b42:	85ca                	mv	a1,s2
    80002b44:	7528                	ld	a0,104(a0)
    80002b46:	fffff097          	auipc	ra,0xfffff
    80002b4a:	bb8080e7          	jalr	-1096(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002b4e:	70a2                	ld	ra,40(sp)
    80002b50:	7402                	ld	s0,32(sp)
    80002b52:	64e2                	ld	s1,24(sp)
    80002b54:	6942                	ld	s2,16(sp)
    80002b56:	69a2                	ld	s3,8(sp)
    80002b58:	6a02                	ld	s4,0(sp)
    80002b5a:	6145                	addi	sp,sp,48
    80002b5c:	8082                	ret
    memmove(dst, (char*)src, len);
    80002b5e:	000a061b          	sext.w	a2,s4
    80002b62:	85ce                	mv	a1,s3
    80002b64:	854a                	mv	a0,s2
    80002b66:	ffffe097          	auipc	ra,0xffffe
    80002b6a:	1da080e7          	jalr	474(ra) # 80000d40 <memmove>
    return 0;
    80002b6e:	8526                	mv	a0,s1
    80002b70:	bff9                	j	80002b4e <either_copyin+0x32>

0000000080002b72 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002b72:	715d                	addi	sp,sp,-80
    80002b74:	e486                	sd	ra,72(sp)
    80002b76:	e0a2                	sd	s0,64(sp)
    80002b78:	fc26                	sd	s1,56(sp)
    80002b7a:	f84a                	sd	s2,48(sp)
    80002b7c:	f44e                	sd	s3,40(sp)
    80002b7e:	f052                	sd	s4,32(sp)
    80002b80:	ec56                	sd	s5,24(sp)
    80002b82:	e85a                	sd	s6,16(sp)
    80002b84:	e45e                	sd	s7,8(sp)
    80002b86:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002b88:	00005517          	auipc	a0,0x5
    80002b8c:	76850513          	addi	a0,a0,1896 # 800082f0 <digits+0x2b0>
    80002b90:	ffffe097          	auipc	ra,0xffffe
    80002b94:	9f8080e7          	jalr	-1544(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002b98:	0000f497          	auipc	s1,0xf
    80002b9c:	d9848493          	addi	s1,s1,-616 # 80011930 <proc+0x170>
    80002ba0:	00015917          	auipc	s2,0x15
    80002ba4:	19090913          	addi	s2,s2,400 # 80017d30 <bcache+0x158>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002ba8:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002baa:	00005997          	auipc	s3,0x5
    80002bae:	6fe98993          	addi	s3,s3,1790 # 800082a8 <digits+0x268>
    printf("%d %s %s", p->pid, state, p->name);
    80002bb2:	00005a97          	auipc	s5,0x5
    80002bb6:	6fea8a93          	addi	s5,s5,1790 # 800082b0 <digits+0x270>
    printf("\n");
    80002bba:	00005a17          	auipc	s4,0x5
    80002bbe:	736a0a13          	addi	s4,s4,1846 # 800082f0 <digits+0x2b0>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002bc2:	00005b97          	auipc	s7,0x5
    80002bc6:	76eb8b93          	addi	s7,s7,1902 # 80008330 <states.1793>
    80002bca:	a00d                	j	80002bec <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002bcc:	ed86a583          	lw	a1,-296(a3)
    80002bd0:	8556                	mv	a0,s5
    80002bd2:	ffffe097          	auipc	ra,0xffffe
    80002bd6:	9b6080e7          	jalr	-1610(ra) # 80000588 <printf>
    printf("\n");
    80002bda:	8552                	mv	a0,s4
    80002bdc:	ffffe097          	auipc	ra,0xffffe
    80002be0:	9ac080e7          	jalr	-1620(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002be4:	19048493          	addi	s1,s1,400
    80002be8:	03248163          	beq	s1,s2,80002c0a <procdump+0x98>
    if(p->state == UNUSED)
    80002bec:	86a6                	mv	a3,s1
    80002bee:	ec04a783          	lw	a5,-320(s1)
    80002bf2:	dbed                	beqz	a5,80002be4 <procdump+0x72>
      state = "???";
    80002bf4:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002bf6:	fcfb6be3          	bltu	s6,a5,80002bcc <procdump+0x5a>
    80002bfa:	1782                	slli	a5,a5,0x20
    80002bfc:	9381                	srli	a5,a5,0x20
    80002bfe:	078e                	slli	a5,a5,0x3
    80002c00:	97de                	add	a5,a5,s7
    80002c02:	6390                	ld	a2,0(a5)
    80002c04:	f661                	bnez	a2,80002bcc <procdump+0x5a>
      state = "???";
    80002c06:	864e                	mv	a2,s3
    80002c08:	b7d1                	j	80002bcc <procdump+0x5a>
  }
}
    80002c0a:	60a6                	ld	ra,72(sp)
    80002c0c:	6406                	ld	s0,64(sp)
    80002c0e:	74e2                	ld	s1,56(sp)
    80002c10:	7942                	ld	s2,48(sp)
    80002c12:	79a2                	ld	s3,40(sp)
    80002c14:	7a02                	ld	s4,32(sp)
    80002c16:	6ae2                	ld	s5,24(sp)
    80002c18:	6b42                	ld	s6,16(sp)
    80002c1a:	6ba2                	ld	s7,8(sp)
    80002c1c:	6161                	addi	sp,sp,80
    80002c1e:	8082                	ret

0000000080002c20 <scheduler>:
{
    80002c20:	7119                	addi	sp,sp,-128
    80002c22:	fc86                	sd	ra,120(sp)
    80002c24:	f8a2                	sd	s0,112(sp)
    80002c26:	f4a6                	sd	s1,104(sp)
    80002c28:	f0ca                	sd	s2,96(sp)
    80002c2a:	ecce                	sd	s3,88(sp)
    80002c2c:	e8d2                	sd	s4,80(sp)
    80002c2e:	e4d6                	sd	s5,72(sp)
    80002c30:	e0da                	sd	s6,64(sp)
    80002c32:	fc5e                	sd	s7,56(sp)
    80002c34:	f862                	sd	s8,48(sp)
    80002c36:	f466                	sd	s9,40(sp)
    80002c38:	f06a                	sd	s10,32(sp)
    80002c3a:	ec6e                	sd	s11,24(sp)
    80002c3c:	0100                	addi	s0,sp,128
    80002c3e:	8712                	mv	a4,tp
  int id = r_tp();
    80002c40:	2701                	sext.w	a4,a4
    80002c42:	8692                	mv	a3,tp
    80002c44:	2681                	sext.w	a3,a3
  struct processList* ready_list = &runnable_cpu_lists[cpu_id];
    80002c46:	00269793          	slli	a5,a3,0x2
    80002c4a:	97b6                	add	a5,a5,a3
    80002c4c:	078e                	slli	a5,a5,0x3
    80002c4e:	0000e917          	auipc	s2,0xe
    80002c52:	65290913          	addi	s2,s2,1618 # 800112a0 <runnable_cpu_lists>
    80002c56:	00f90d33          	add	s10,s2,a5
  c->proc = 0;
    80002c5a:	00771613          	slli	a2,a4,0x7
    80002c5e:	00c905b3          	add	a1,s2,a2
    80002c62:	1205b023          	sd	zero,288(a1)
    acquire(&ready_list->head_lock);
    80002c66:	07a1                	addi	a5,a5,8
    80002c68:	993e                	add	s2,s2,a5
        swtch(&c->context, &p->context);
    80002c6a:	0000e797          	auipc	a5,0xe
    80002c6e:	75e78793          	addi	a5,a5,1886 # 800113c8 <cpus+0x8>
    80002c72:	97b2                	add	a5,a5,a2
    80002c74:	f8f43423          	sd	a5,-120(s0)
    if (ready_list->head == -1){
    80002c78:	89ea                	mv	s3,s10
    80002c7a:	5b7d                	li	s6,-1
    80002c7c:	19000c13          	li	s8,400
    p = &proc[ready_list->head];
    80002c80:	0000fb97          	auipc	s7,0xf
    80002c84:	b40b8b93          	addi	s7,s7,-1216 # 800117c0 <proc>
    if(p->state == RUNNABLE) {
    80002c88:	4c8d                	li	s9,3
        c->proc = p;
    80002c8a:	8dae                	mv	s11,a1
    80002c8c:	a081                	j	80002ccc <scheduler+0xac>
    release(&ready_list->head_lock);
    80002c8e:	854a                	mv	a0,s2
    80002c90:	ffffe097          	auipc	ra,0xffffe
    80002c94:	008080e7          	jalr	8(ra) # 80000c98 <release>
    p = &proc[ready_list->head];
    80002c98:	0009aa03          	lw	s4,0(s3)
    80002c9c:	038a0ab3          	mul	s5,s4,s8
    80002ca0:	017a84b3          	add	s1,s5,s7
    remove_link(ready_list, p->proc_index);
    80002ca4:	1844a583          	lw	a1,388(s1)
    80002ca8:	856a                	mv	a0,s10
    80002caa:	fffff097          	auipc	ra,0xfffff
    80002cae:	c0e080e7          	jalr	-1010(ra) # 800018b8 <remove_link>
    acquire(&p->lock);
    80002cb2:	8526                	mv	a0,s1
    80002cb4:	ffffe097          	auipc	ra,0xffffe
    80002cb8:	f30080e7          	jalr	-208(ra) # 80000be4 <acquire>
    if(p->state == RUNNABLE) {
    80002cbc:	589c                	lw	a5,48(s1)
    80002cbe:	03978c63          	beq	a5,s9,80002cf6 <scheduler+0xd6>
    release(&p->lock);
    80002cc2:	8526                	mv	a0,s1
    80002cc4:	ffffe097          	auipc	ra,0xffffe
    80002cc8:	fd4080e7          	jalr	-44(ra) # 80000c98 <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ccc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002cd0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002cd4:	10079073          	csrw	sstatus,a5
    acquire(&ready_list->head_lock);
    80002cd8:	854a                	mv	a0,s2
    80002cda:	ffffe097          	auipc	ra,0xffffe
    80002cde:	f0a080e7          	jalr	-246(ra) # 80000be4 <acquire>
    if (ready_list->head == -1){
    80002ce2:	0009a783          	lw	a5,0(s3)
    80002ce6:	fb6794e3          	bne	a5,s6,80002c8e <scheduler+0x6e>
        release(&ready_list->head_lock);
    80002cea:	854a                	mv	a0,s2
    80002cec:	ffffe097          	auipc	ra,0xffffe
    80002cf0:	fac080e7          	jalr	-84(ra) # 80000c98 <release>
        continue; // TODO: CHECK IT OUT
    80002cf4:	bfe1                	j	80002ccc <scheduler+0xac>
        procdump();
    80002cf6:	00000097          	auipc	ra,0x0
    80002cfa:	e7c080e7          	jalr	-388(ra) # 80002b72 <procdump>
        p->state = RUNNING;
    80002cfe:	4791                	li	a5,4
    80002d00:	d89c                	sw	a5,48(s1)
        c->proc = p;
    80002d02:	129db023          	sd	s1,288(s11)
        swtch(&c->context, &p->context);
    80002d06:	078a8593          	addi	a1,s5,120
    80002d0a:	95de                	add	a1,a1,s7
    80002d0c:	f8843503          	ld	a0,-120(s0)
    80002d10:	00000097          	auipc	ra,0x0
    80002d14:	302080e7          	jalr	770(ra) # 80003012 <swtch>
        c->proc = 0;
    80002d18:	120db023          	sd	zero,288(s11)
    80002d1c:	b75d                	j	80002cc2 <scheduler+0xa2>

0000000080002d1e <wakeup2>:
{
    80002d1e:	7159                	addi	sp,sp,-112
    80002d20:	f486                	sd	ra,104(sp)
    80002d22:	f0a2                	sd	s0,96(sp)
    80002d24:	eca6                	sd	s1,88(sp)
    80002d26:	e8ca                	sd	s2,80(sp)
    80002d28:	e4ce                	sd	s3,72(sp)
    80002d2a:	e0d2                	sd	s4,64(sp)
    80002d2c:	fc56                	sd	s5,56(sp)
    80002d2e:	f85a                	sd	s6,48(sp)
    80002d30:	f45e                	sd	s7,40(sp)
    80002d32:	f062                	sd	s8,32(sp)
    80002d34:	ec66                	sd	s9,24(sp)
    80002d36:	e86a                	sd	s10,16(sp)
    80002d38:	e46e                	sd	s11,8(sp)
    80002d3a:	1880                	addi	s0,sp,112
    80002d3c:	8b2a                	mv	s6,a0
  acquire(&sleeping_list.head_lock);
    80002d3e:	0000e517          	auipc	a0,0xe
    80002d42:	60a50513          	addi	a0,a0,1546 # 80011348 <sleeping_list+0x8>
    80002d46:	ffffe097          	auipc	ra,0xffffe
    80002d4a:	e9e080e7          	jalr	-354(ra) # 80000be4 <acquire>
  if (sleeping_list.head == -1){
    80002d4e:	0000e797          	auipc	a5,0xe
    80002d52:	5f27a783          	lw	a5,1522(a5) # 80011340 <sleeping_list>
    80002d56:	577d                	li	a4,-1
    80002d58:	0ae78c63          	beq	a5,a4,80002e10 <wakeup2+0xf2>
  acquire(&proc[sleeping_list.head].list_lock);
    80002d5c:	19000913          	li	s2,400
    80002d60:	032787b3          	mul	a5,a5,s2
    80002d64:	01878513          	addi	a0,a5,24
    80002d68:	0000f997          	auipc	s3,0xf
    80002d6c:	a5898993          	addi	s3,s3,-1448 # 800117c0 <proc>
    80002d70:	954e                	add	a0,a0,s3
    80002d72:	ffffe097          	auipc	ra,0xffffe
    80002d76:	e72080e7          	jalr	-398(ra) # 80000be4 <acquire>
  p = &proc[sleeping_list.head];
    80002d7a:	0000e497          	auipc	s1,0xe
    80002d7e:	5c64a483          	lw	s1,1478(s1) # 80011340 <sleeping_list>
    80002d82:	03248933          	mul	s2,s1,s2
    80002d86:	994e                	add	s2,s2,s3
  acquire(&p->lock);
    80002d88:	854a                	mv	a0,s2
    80002d8a:	ffffe097          	auipc	ra,0xffffe
    80002d8e:	e5a080e7          	jalr	-422(ra) # 80000be4 <acquire>
  if(p!=myproc()&&p->chan == chan) {
    80002d92:	fffff097          	auipc	ra,0xfffff
    80002d96:	0cc080e7          	jalr	204(ra) # 80001e5e <myproc>
    80002d9a:	00a90663          	beq	s2,a0,80002da6 <wakeup2+0x88>
    80002d9e:	03893783          	ld	a5,56(s2)
    80002da2:	09678c63          	beq	a5,s6,80002e3a <wakeup2+0x11c>
        release(&sleeping_list.head_lock);
    80002da6:	0000e517          	auipc	a0,0xe
    80002daa:	5a250513          	addi	a0,a0,1442 # 80011348 <sleeping_list+0x8>
    80002dae:	ffffe097          	auipc	ra,0xffffe
    80002db2:	eea080e7          	jalr	-278(ra) # 80000c98 <release>
        release(&proc[sleeping_list.head].list_lock);
    80002db6:	0000e797          	auipc	a5,0xe
    80002dba:	58a7a783          	lw	a5,1418(a5) # 80011340 <sleeping_list>
    80002dbe:	19000513          	li	a0,400
    80002dc2:	02a787b3          	mul	a5,a5,a0
    80002dc6:	0000f517          	auipc	a0,0xf
    80002dca:	a1250513          	addi	a0,a0,-1518 # 800117d8 <proc+0x18>
    80002dce:	953e                	add	a0,a0,a5
    80002dd0:	ffffe097          	auipc	ra,0xffffe
    80002dd4:	ec8080e7          	jalr	-312(ra) # 80000c98 <release>
  release(&p->lock);
    80002dd8:	854a                	mv	a0,s2
    80002dda:	ffffe097          	auipc	ra,0xffffe
    80002dde:	ebe080e7          	jalr	-322(ra) # 80000c98 <release>
  printf("exiting wakeup\n");
    80002de2:	00005517          	auipc	a0,0x5
    80002de6:	51650513          	addi	a0,a0,1302 # 800082f8 <digits+0x2b8>
    80002dea:	ffffd097          	auipc	ra,0xffffd
    80002dee:	79e080e7          	jalr	1950(ra) # 80000588 <printf>
}
    80002df2:	70a6                	ld	ra,104(sp)
    80002df4:	7406                	ld	s0,96(sp)
    80002df6:	64e6                	ld	s1,88(sp)
    80002df8:	6946                	ld	s2,80(sp)
    80002dfa:	69a6                	ld	s3,72(sp)
    80002dfc:	6a06                	ld	s4,64(sp)
    80002dfe:	7ae2                	ld	s5,56(sp)
    80002e00:	7b42                	ld	s6,48(sp)
    80002e02:	7ba2                	ld	s7,40(sp)
    80002e04:	7c02                	ld	s8,32(sp)
    80002e06:	6ce2                	ld	s9,24(sp)
    80002e08:	6d42                	ld	s10,16(sp)
    80002e0a:	6da2                	ld	s11,8(sp)
    80002e0c:	6165                	addi	sp,sp,112
    80002e0e:	8082                	ret
    printf("sleeping list is empty\n");
    80002e10:	00005517          	auipc	a0,0x5
    80002e14:	4b050513          	addi	a0,a0,1200 # 800082c0 <digits+0x280>
    80002e18:	ffffd097          	auipc	ra,0xffffd
    80002e1c:	770080e7          	jalr	1904(ra) # 80000588 <printf>
    release(&sleeping_list.head_lock);
    80002e20:	0000e517          	auipc	a0,0xe
    80002e24:	52850513          	addi	a0,a0,1320 # 80011348 <sleeping_list+0x8>
    80002e28:	ffffe097          	auipc	ra,0xffffe
    80002e2c:	e70080e7          	jalr	-400(ra) # 80000c98 <release>
    procdump();
    80002e30:	00000097          	auipc	ra,0x0
    80002e34:	d42080e7          	jalr	-702(ra) # 80002b72 <procdump>
    return;
    80002e38:	bf6d                	j	80002df2 <wakeup2+0xd4>
        printf("waking up proc number %d\n", p->pid);
    80002e3a:	8ace                	mv	s5,s3
    80002e3c:	19000b93          	li	s7,400
    80002e40:	04892583          	lw	a1,72(s2)
    80002e44:	00005517          	auipc	a0,0x5
    80002e48:	49450513          	addi	a0,a0,1172 # 800082d8 <digits+0x298>
    80002e4c:	ffffd097          	auipc	ra,0xffffd
    80002e50:	73c080e7          	jalr	1852(ra) # 80000588 <printf>
        p->state = RUNNABLE;
    80002e54:	478d                	li	a5,3
    80002e56:	02f92823          	sw	a5,48(s2)
        next_link_index = p->next_proc_index;
    80002e5a:	18092983          	lw	s3,384(s2)
        release(&sleeping_list.head_lock);
    80002e5e:	0000ea17          	auipc	s4,0xe
    80002e62:	442a0a13          	addi	s4,s4,1090 # 800112a0 <runnable_cpu_lists>
    80002e66:	0000e517          	auipc	a0,0xe
    80002e6a:	4e250513          	addi	a0,a0,1250 # 80011348 <sleeping_list+0x8>
    80002e6e:	ffffe097          	auipc	ra,0xffffe
    80002e72:	e2a080e7          	jalr	-470(ra) # 80000c98 <release>
        release(&proc[sleeping_list.head].list_lock);
    80002e76:	0a0a2503          	lw	a0,160(s4)
    80002e7a:	03750533          	mul	a0,a0,s7
    80002e7e:	0561                	addi	a0,a0,24
    80002e80:	9556                	add	a0,a0,s5
    80002e82:	ffffe097          	auipc	ra,0xffffe
    80002e86:	e16080e7          	jalr	-490(ra) # 80000c98 <release>
        remove_link(&sleeping_list, p->proc_index);
    80002e8a:	18492583          	lw	a1,388(s2)
    80002e8e:	0000e517          	auipc	a0,0xe
    80002e92:	4b250513          	addi	a0,a0,1202 # 80011340 <sleeping_list>
    80002e96:	fffff097          	auipc	ra,0xfffff
    80002e9a:	a22080e7          	jalr	-1502(ra) # 800018b8 <remove_link>
        add_link(&runnable_cpu_lists[p->affiliated_cpu], p->proc_index, 0);
    80002e9e:	18892783          	lw	a5,392(s2)
    80002ea2:	00279513          	slli	a0,a5,0x2
    80002ea6:	953e                	add	a0,a0,a5
    80002ea8:	050e                	slli	a0,a0,0x3
    80002eaa:	4601                	li	a2,0
    80002eac:	18492583          	lw	a1,388(s2)
    80002eb0:	9552                	add	a0,a0,s4
    80002eb2:	fffff097          	auipc	ra,0xfffff
    80002eb6:	c34080e7          	jalr	-972(ra) # 80001ae6 <add_link>
  release(&p->lock);
    80002eba:	854a                	mv	a0,s2
    80002ebc:	ffffe097          	auipc	ra,0xffffe
    80002ec0:	ddc080e7          	jalr	-548(ra) # 80000c98 <release>
  while(next_link_index != -1){   // TODO: NOT SAFE!!
    80002ec4:	57fd                	li	a5,-1
    80002ec6:	f0f98ee3          	beq	s3,a5,80002de2 <wakeup2+0xc4>
    80002eca:	19000a93          	li	s5,400
    acquire(&proc[next_link_index].list_lock);
    80002ece:	0000fa17          	auipc	s4,0xf
    80002ed2:	8f2a0a13          	addi	s4,s4,-1806 # 800117c0 <proc>
        p->state = RUNNABLE;
    80002ed6:	4d0d                	li	s10,3
        remove_link(&sleeping_list, p->proc_index);
    80002ed8:	0000ec97          	auipc	s9,0xe
    80002edc:	3c8c8c93          	addi	s9,s9,968 # 800112a0 <runnable_cpu_lists>
    80002ee0:	0000ec17          	auipc	s8,0xe
    80002ee4:	460c0c13          	addi	s8,s8,1120 # 80011340 <sleeping_list>
  while(next_link_index != -1){   // TODO: NOT SAFE!!
    80002ee8:	5bfd                	li	s7,-1
    80002eea:	a829                	j	80002f04 <wakeup2+0x1e6>
        release(&proc[next_link_index].list_lock);
    80002eec:	854a                	mv	a0,s2
    80002eee:	ffffe097          	auipc	ra,0xffffe
    80002ef2:	daa080e7          	jalr	-598(ra) # 80000c98 <release>
    release(&p->lock);
    80002ef6:	8526                	mv	a0,s1
    80002ef8:	ffffe097          	auipc	ra,0xffffe
    80002efc:	da0080e7          	jalr	-608(ra) # 80000c98 <release>
  while(next_link_index != -1){   // TODO: NOT SAFE!!
    80002f00:	ef7981e3          	beq	s3,s7,80002de2 <wakeup2+0xc4>
    acquire(&proc[next_link_index].list_lock);
    80002f04:	035984b3          	mul	s1,s3,s5
    80002f08:	01848913          	addi	s2,s1,24
    80002f0c:	9952                	add	s2,s2,s4
    80002f0e:	854a                	mv	a0,s2
    80002f10:	ffffe097          	auipc	ra,0xffffe
    80002f14:	cd4080e7          	jalr	-812(ra) # 80000be4 <acquire>
    p = &proc[next_link_index];
    80002f18:	94d2                	add	s1,s1,s4
    acquire(&p->lock);
    80002f1a:	8526                	mv	a0,s1
    80002f1c:	ffffe097          	auipc	ra,0xffffe
    80002f20:	cc8080e7          	jalr	-824(ra) # 80000be4 <acquire>
      if(p!=myproc()&&p->chan == chan) {
    80002f24:	fffff097          	auipc	ra,0xfffff
    80002f28:	f3a080e7          	jalr	-198(ra) # 80001e5e <myproc>
    80002f2c:	fca480e3          	beq	s1,a0,80002eec <wakeup2+0x1ce>
    80002f30:	7c9c                	ld	a5,56(s1)
    80002f32:	fb679de3          	bne	a5,s6,80002eec <wakeup2+0x1ce>
        p->state = RUNNABLE;
    80002f36:	03a4a823          	sw	s10,48(s1)
        release(&proc[next_link_index].list_lock);
    80002f3a:	854a                	mv	a0,s2
    80002f3c:	ffffe097          	auipc	ra,0xffffe
    80002f40:	d5c080e7          	jalr	-676(ra) # 80000c98 <release>
        next_link_index = p->next_proc_index;
    80002f44:	1804a983          	lw	s3,384(s1)
        remove_link(&sleeping_list, p->proc_index);
    80002f48:	1844a583          	lw	a1,388(s1)
    80002f4c:	8562                	mv	a0,s8
    80002f4e:	fffff097          	auipc	ra,0xfffff
    80002f52:	96a080e7          	jalr	-1686(ra) # 800018b8 <remove_link>
        add_link(&runnable_cpu_lists[p->affiliated_cpu], p->proc_index, 0);
    80002f56:	1884a783          	lw	a5,392(s1)
    80002f5a:	00279513          	slli	a0,a5,0x2
    80002f5e:	953e                	add	a0,a0,a5
    80002f60:	050e                	slli	a0,a0,0x3
    80002f62:	4601                	li	a2,0
    80002f64:	1844a583          	lw	a1,388(s1)
    80002f68:	9566                	add	a0,a0,s9
    80002f6a:	fffff097          	auipc	ra,0xfffff
    80002f6e:	b7c080e7          	jalr	-1156(ra) # 80001ae6 <add_link>
    80002f72:	b751                	j	80002ef6 <wakeup2+0x1d8>

0000000080002f74 <set_cpu>:

int set_cpu(int cpu_num){
  if (cpu_num >= current_cpu_number)
    80002f74:	4789                	li	a5,2
    80002f76:	04a7c463          	blt	a5,a0,80002fbe <set_cpu+0x4a>
int set_cpu(int cpu_num){
    80002f7a:	1101                	addi	sp,sp,-32
    80002f7c:	ec06                	sd	ra,24(sp)
    80002f7e:	e822                	sd	s0,16(sp)
    80002f80:	e426                	sd	s1,8(sp)
    80002f82:	e04a                	sd	s2,0(sp)
    80002f84:	1000                	addi	s0,sp,32
    80002f86:	84aa                	mv	s1,a0
    return -1;
  
  struct proc* my_proc = myproc();
    80002f88:	fffff097          	auipc	ra,0xfffff
    80002f8c:	ed6080e7          	jalr	-298(ra) # 80001e5e <myproc>
    80002f90:	892a                	mv	s2,a0
  acquire(&my_proc->lock);
    80002f92:	ffffe097          	auipc	ra,0xffffe
    80002f96:	c52080e7          	jalr	-942(ra) # 80000be4 <acquire>
  my_proc -> affiliated_cpu = cpu_num; 
    80002f9a:	18992423          	sw	s1,392(s2)
  release(&my_proc->lock);
    80002f9e:	854a                	mv	a0,s2
    80002fa0:	ffffe097          	auipc	ra,0xffffe
    80002fa4:	cf8080e7          	jalr	-776(ra) # 80000c98 <release>
  yield();
    80002fa8:	fffff097          	auipc	ra,0xfffff
    80002fac:	572080e7          	jalr	1394(ra) # 8000251a <yield>

  return cpu_num;
    80002fb0:	8526                	mv	a0,s1

}
    80002fb2:	60e2                	ld	ra,24(sp)
    80002fb4:	6442                	ld	s0,16(sp)
    80002fb6:	64a2                	ld	s1,8(sp)
    80002fb8:	6902                	ld	s2,0(sp)
    80002fba:	6105                	addi	sp,sp,32
    80002fbc:	8082                	ret
    return -1;
    80002fbe:	557d                	li	a0,-1
}
    80002fc0:	8082                	ret

0000000080002fc2 <get_cpu>:

int get_cpu(void){
    80002fc2:	1141                	addi	sp,sp,-16
    80002fc4:	e422                	sd	s0,8(sp)
    80002fc6:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fc8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002fcc:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002fce:	10079073          	csrw	sstatus,a5
  asm volatile("mv %0, tp" : "=r" (x) );
    80002fd2:	8512                	mv	a0,tp
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fd4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002fd8:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002fdc:	10079073          	csrw	sstatus,a5
  intr_off();
  int res = cpuid();
  intr_on();
  
  return res;
}
    80002fe0:	2501                	sext.w	a0,a0
    80002fe2:	6422                	ld	s0,8(sp)
    80002fe4:	0141                	addi	sp,sp,16
    80002fe6:	8082                	ret

0000000080002fe8 <cpu_process_count>:

int cpu_process_count(int cpu_num){
    80002fe8:	1141                	addi	sp,sp,-16
    80002fea:	e422                	sd	s0,8(sp)
    80002fec:	0800                	addi	s0,sp,16
  if (cpu_num >= current_cpu_number){
    80002fee:	4789                	li	a5,2
    80002ff0:	00a7cf63          	blt	a5,a0,8000300e <cpu_process_count+0x26>
    return -1;
  }

  return runnable_cpu_lists[cpu_num].counter;
    80002ff4:	00251793          	slli	a5,a0,0x2
    80002ff8:	953e                	add	a0,a0,a5
    80002ffa:	050e                	slli	a0,a0,0x3
    80002ffc:	0000e797          	auipc	a5,0xe
    80003000:	2a478793          	addi	a5,a5,676 # 800112a0 <runnable_cpu_lists>
    80003004:	953e                	add	a0,a0,a5
    80003006:	5108                	lw	a0,32(a0)
}
    80003008:	6422                	ld	s0,8(sp)
    8000300a:	0141                	addi	sp,sp,16
    8000300c:	8082                	ret
    return -1;
    8000300e:	557d                	li	a0,-1
    80003010:	bfe5                	j	80003008 <cpu_process_count+0x20>

0000000080003012 <swtch>:
    80003012:	00153023          	sd	ra,0(a0)
    80003016:	00253423          	sd	sp,8(a0)
    8000301a:	e900                	sd	s0,16(a0)
    8000301c:	ed04                	sd	s1,24(a0)
    8000301e:	03253023          	sd	s2,32(a0)
    80003022:	03353423          	sd	s3,40(a0)
    80003026:	03453823          	sd	s4,48(a0)
    8000302a:	03553c23          	sd	s5,56(a0)
    8000302e:	05653023          	sd	s6,64(a0)
    80003032:	05753423          	sd	s7,72(a0)
    80003036:	05853823          	sd	s8,80(a0)
    8000303a:	05953c23          	sd	s9,88(a0)
    8000303e:	07a53023          	sd	s10,96(a0)
    80003042:	07b53423          	sd	s11,104(a0)
    80003046:	0005b083          	ld	ra,0(a1)
    8000304a:	0085b103          	ld	sp,8(a1)
    8000304e:	6980                	ld	s0,16(a1)
    80003050:	6d84                	ld	s1,24(a1)
    80003052:	0205b903          	ld	s2,32(a1)
    80003056:	0285b983          	ld	s3,40(a1)
    8000305a:	0305ba03          	ld	s4,48(a1)
    8000305e:	0385ba83          	ld	s5,56(a1)
    80003062:	0405bb03          	ld	s6,64(a1)
    80003066:	0485bb83          	ld	s7,72(a1)
    8000306a:	0505bc03          	ld	s8,80(a1)
    8000306e:	0585bc83          	ld	s9,88(a1)
    80003072:	0605bd03          	ld	s10,96(a1)
    80003076:	0685bd83          	ld	s11,104(a1)
    8000307a:	8082                	ret

000000008000307c <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000307c:	1141                	addi	sp,sp,-16
    8000307e:	e406                	sd	ra,8(sp)
    80003080:	e022                	sd	s0,0(sp)
    80003082:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80003084:	00005597          	auipc	a1,0x5
    80003088:	2dc58593          	addi	a1,a1,732 # 80008360 <states.1793+0x30>
    8000308c:	00015517          	auipc	a0,0x15
    80003090:	b3450513          	addi	a0,a0,-1228 # 80017bc0 <tickslock>
    80003094:	ffffe097          	auipc	ra,0xffffe
    80003098:	ac0080e7          	jalr	-1344(ra) # 80000b54 <initlock>
}
    8000309c:	60a2                	ld	ra,8(sp)
    8000309e:	6402                	ld	s0,0(sp)
    800030a0:	0141                	addi	sp,sp,16
    800030a2:	8082                	ret

00000000800030a4 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800030a4:	1141                	addi	sp,sp,-16
    800030a6:	e422                	sd	s0,8(sp)
    800030a8:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800030aa:	00003797          	auipc	a5,0x3
    800030ae:	50678793          	addi	a5,a5,1286 # 800065b0 <kernelvec>
    800030b2:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800030b6:	6422                	ld	s0,8(sp)
    800030b8:	0141                	addi	sp,sp,16
    800030ba:	8082                	ret

00000000800030bc <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800030bc:	1141                	addi	sp,sp,-16
    800030be:	e406                	sd	ra,8(sp)
    800030c0:	e022                	sd	s0,0(sp)
    800030c2:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800030c4:	fffff097          	auipc	ra,0xfffff
    800030c8:	d9a080e7          	jalr	-614(ra) # 80001e5e <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800030cc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800030d0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800030d2:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800030d6:	00004617          	auipc	a2,0x4
    800030da:	f2a60613          	addi	a2,a2,-214 # 80007000 <_trampoline>
    800030de:	00004697          	auipc	a3,0x4
    800030e2:	f2268693          	addi	a3,a3,-222 # 80007000 <_trampoline>
    800030e6:	8e91                	sub	a3,a3,a2
    800030e8:	040007b7          	lui	a5,0x4000
    800030ec:	17fd                	addi	a5,a5,-1
    800030ee:	07b2                	slli	a5,a5,0xc
    800030f0:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800030f2:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800030f6:	7938                	ld	a4,112(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800030f8:	180026f3          	csrr	a3,satp
    800030fc:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800030fe:	7938                	ld	a4,112(a0)
    80003100:	6d34                	ld	a3,88(a0)
    80003102:	6585                	lui	a1,0x1
    80003104:	96ae                	add	a3,a3,a1
    80003106:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80003108:	7938                	ld	a4,112(a0)
    8000310a:	00000697          	auipc	a3,0x0
    8000310e:	13868693          	addi	a3,a3,312 # 80003242 <usertrap>
    80003112:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80003114:	7938                	ld	a4,112(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80003116:	8692                	mv	a3,tp
    80003118:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000311a:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000311e:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80003122:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003126:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000312a:	7938                	ld	a4,112(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000312c:	6f18                	ld	a4,24(a4)
    8000312e:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80003132:	752c                	ld	a1,104(a0)
    80003134:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80003136:	00004717          	auipc	a4,0x4
    8000313a:	f5a70713          	addi	a4,a4,-166 # 80007090 <userret>
    8000313e:	8f11                	sub	a4,a4,a2
    80003140:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80003142:	577d                	li	a4,-1
    80003144:	177e                	slli	a4,a4,0x3f
    80003146:	8dd9                	or	a1,a1,a4
    80003148:	02000537          	lui	a0,0x2000
    8000314c:	157d                	addi	a0,a0,-1
    8000314e:	0536                	slli	a0,a0,0xd
    80003150:	9782                	jalr	a5
}
    80003152:	60a2                	ld	ra,8(sp)
    80003154:	6402                	ld	s0,0(sp)
    80003156:	0141                	addi	sp,sp,16
    80003158:	8082                	ret

000000008000315a <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000315a:	1101                	addi	sp,sp,-32
    8000315c:	ec06                	sd	ra,24(sp)
    8000315e:	e822                	sd	s0,16(sp)
    80003160:	e426                	sd	s1,8(sp)
    80003162:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80003164:	00015497          	auipc	s1,0x15
    80003168:	a5c48493          	addi	s1,s1,-1444 # 80017bc0 <tickslock>
    8000316c:	8526                	mv	a0,s1
    8000316e:	ffffe097          	auipc	ra,0xffffe
    80003172:	a76080e7          	jalr	-1418(ra) # 80000be4 <acquire>
  ticks++;
    80003176:	00006517          	auipc	a0,0x6
    8000317a:	eba50513          	addi	a0,a0,-326 # 80009030 <ticks>
    8000317e:	411c                	lw	a5,0(a0)
    80003180:	2785                	addiw	a5,a5,1
    80003182:	c11c                	sw	a5,0(a0)
  //printf("clockintr\n");
  wakeup(&ticks);
    80003184:	fffff097          	auipc	ra,0xfffff
    80003188:	598080e7          	jalr	1432(ra) # 8000271c <wakeup>
  release(&tickslock);
    8000318c:	8526                	mv	a0,s1
    8000318e:	ffffe097          	auipc	ra,0xffffe
    80003192:	b0a080e7          	jalr	-1270(ra) # 80000c98 <release>
}
    80003196:	60e2                	ld	ra,24(sp)
    80003198:	6442                	ld	s0,16(sp)
    8000319a:	64a2                	ld	s1,8(sp)
    8000319c:	6105                	addi	sp,sp,32
    8000319e:	8082                	ret

00000000800031a0 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800031a0:	1101                	addi	sp,sp,-32
    800031a2:	ec06                	sd	ra,24(sp)
    800031a4:	e822                	sd	s0,16(sp)
    800031a6:	e426                	sd	s1,8(sp)
    800031a8:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800031aa:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800031ae:	00074d63          	bltz	a4,800031c8 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800031b2:	57fd                	li	a5,-1
    800031b4:	17fe                	slli	a5,a5,0x3f
    800031b6:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800031b8:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800031ba:	06f70363          	beq	a4,a5,80003220 <devintr+0x80>
  }
}
    800031be:	60e2                	ld	ra,24(sp)
    800031c0:	6442                	ld	s0,16(sp)
    800031c2:	64a2                	ld	s1,8(sp)
    800031c4:	6105                	addi	sp,sp,32
    800031c6:	8082                	ret
     (scause & 0xff) == 9){
    800031c8:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800031cc:	46a5                	li	a3,9
    800031ce:	fed792e3          	bne	a5,a3,800031b2 <devintr+0x12>
    int irq = plic_claim();
    800031d2:	00003097          	auipc	ra,0x3
    800031d6:	4e6080e7          	jalr	1254(ra) # 800066b8 <plic_claim>
    800031da:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800031dc:	47a9                	li	a5,10
    800031de:	02f50763          	beq	a0,a5,8000320c <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800031e2:	4785                	li	a5,1
    800031e4:	02f50963          	beq	a0,a5,80003216 <devintr+0x76>
    return 1;
    800031e8:	4505                	li	a0,1
    } else if(irq){
    800031ea:	d8f1                	beqz	s1,800031be <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800031ec:	85a6                	mv	a1,s1
    800031ee:	00005517          	auipc	a0,0x5
    800031f2:	17a50513          	addi	a0,a0,378 # 80008368 <states.1793+0x38>
    800031f6:	ffffd097          	auipc	ra,0xffffd
    800031fa:	392080e7          	jalr	914(ra) # 80000588 <printf>
      plic_complete(irq);
    800031fe:	8526                	mv	a0,s1
    80003200:	00003097          	auipc	ra,0x3
    80003204:	4dc080e7          	jalr	1244(ra) # 800066dc <plic_complete>
    return 1;
    80003208:	4505                	li	a0,1
    8000320a:	bf55                	j	800031be <devintr+0x1e>
      uartintr();
    8000320c:	ffffd097          	auipc	ra,0xffffd
    80003210:	79c080e7          	jalr	1948(ra) # 800009a8 <uartintr>
    80003214:	b7ed                	j	800031fe <devintr+0x5e>
      virtio_disk_intr();
    80003216:	00004097          	auipc	ra,0x4
    8000321a:	9a6080e7          	jalr	-1626(ra) # 80006bbc <virtio_disk_intr>
    8000321e:	b7c5                	j	800031fe <devintr+0x5e>
    if(cpuid() == 0){
    80003220:	fffff097          	auipc	ra,0xfffff
    80003224:	c12080e7          	jalr	-1006(ra) # 80001e32 <cpuid>
    80003228:	c901                	beqz	a0,80003238 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    8000322a:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    8000322e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80003230:	14479073          	csrw	sip,a5
    return 2;
    80003234:	4509                	li	a0,2
    80003236:	b761                	j	800031be <devintr+0x1e>
      clockintr();
    80003238:	00000097          	auipc	ra,0x0
    8000323c:	f22080e7          	jalr	-222(ra) # 8000315a <clockintr>
    80003240:	b7ed                	j	8000322a <devintr+0x8a>

0000000080003242 <usertrap>:
{
    80003242:	1101                	addi	sp,sp,-32
    80003244:	ec06                	sd	ra,24(sp)
    80003246:	e822                	sd	s0,16(sp)
    80003248:	e426                	sd	s1,8(sp)
    8000324a:	e04a                	sd	s2,0(sp)
    8000324c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000324e:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80003252:	1007f793          	andi	a5,a5,256
    80003256:	e3ad                	bnez	a5,800032b8 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003258:	00003797          	auipc	a5,0x3
    8000325c:	35878793          	addi	a5,a5,856 # 800065b0 <kernelvec>
    80003260:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80003264:	fffff097          	auipc	ra,0xfffff
    80003268:	bfa080e7          	jalr	-1030(ra) # 80001e5e <myproc>
    8000326c:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    8000326e:	793c                	ld	a5,112(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003270:	14102773          	csrr	a4,sepc
    80003274:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003276:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    8000327a:	47a1                	li	a5,8
    8000327c:	04f71c63          	bne	a4,a5,800032d4 <usertrap+0x92>
    if(p->killed)
    80003280:	413c                	lw	a5,64(a0)
    80003282:	e3b9                	bnez	a5,800032c8 <usertrap+0x86>
    p->trapframe->epc += 4;
    80003284:	78b8                	ld	a4,112(s1)
    80003286:	6f1c                	ld	a5,24(a4)
    80003288:	0791                	addi	a5,a5,4
    8000328a:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000328c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80003290:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003294:	10079073          	csrw	sstatus,a5
    syscall();
    80003298:	00000097          	auipc	ra,0x0
    8000329c:	2e0080e7          	jalr	736(ra) # 80003578 <syscall>
  if(p->killed)
    800032a0:	40bc                	lw	a5,64(s1)
    800032a2:	ebc1                	bnez	a5,80003332 <usertrap+0xf0>
  usertrapret();
    800032a4:	00000097          	auipc	ra,0x0
    800032a8:	e18080e7          	jalr	-488(ra) # 800030bc <usertrapret>
}
    800032ac:	60e2                	ld	ra,24(sp)
    800032ae:	6442                	ld	s0,16(sp)
    800032b0:	64a2                	ld	s1,8(sp)
    800032b2:	6902                	ld	s2,0(sp)
    800032b4:	6105                	addi	sp,sp,32
    800032b6:	8082                	ret
    panic("usertrap: not from user mode");
    800032b8:	00005517          	auipc	a0,0x5
    800032bc:	0d050513          	addi	a0,a0,208 # 80008388 <states.1793+0x58>
    800032c0:	ffffd097          	auipc	ra,0xffffd
    800032c4:	27e080e7          	jalr	638(ra) # 8000053e <panic>
      exit(-1);
    800032c8:	557d                	li	a0,-1
    800032ca:	fffff097          	auipc	ra,0xfffff
    800032ce:	69e080e7          	jalr	1694(ra) # 80002968 <exit>
    800032d2:	bf4d                	j	80003284 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    800032d4:	00000097          	auipc	ra,0x0
    800032d8:	ecc080e7          	jalr	-308(ra) # 800031a0 <devintr>
    800032dc:	892a                	mv	s2,a0
    800032de:	c501                	beqz	a0,800032e6 <usertrap+0xa4>
  if(p->killed)
    800032e0:	40bc                	lw	a5,64(s1)
    800032e2:	c3a1                	beqz	a5,80003322 <usertrap+0xe0>
    800032e4:	a815                	j	80003318 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800032e6:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800032ea:	44b0                	lw	a2,72(s1)
    800032ec:	00005517          	auipc	a0,0x5
    800032f0:	0bc50513          	addi	a0,a0,188 # 800083a8 <states.1793+0x78>
    800032f4:	ffffd097          	auipc	ra,0xffffd
    800032f8:	294080e7          	jalr	660(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800032fc:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003300:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003304:	00005517          	auipc	a0,0x5
    80003308:	0d450513          	addi	a0,a0,212 # 800083d8 <states.1793+0xa8>
    8000330c:	ffffd097          	auipc	ra,0xffffd
    80003310:	27c080e7          	jalr	636(ra) # 80000588 <printf>
    p->killed = 1;
    80003314:	4785                	li	a5,1
    80003316:	c0bc                	sw	a5,64(s1)
    exit(-1);
    80003318:	557d                	li	a0,-1
    8000331a:	fffff097          	auipc	ra,0xfffff
    8000331e:	64e080e7          	jalr	1614(ra) # 80002968 <exit>
  if(which_dev == 2)
    80003322:	4789                	li	a5,2
    80003324:	f8f910e3          	bne	s2,a5,800032a4 <usertrap+0x62>
    yield();
    80003328:	fffff097          	auipc	ra,0xfffff
    8000332c:	1f2080e7          	jalr	498(ra) # 8000251a <yield>
    80003330:	bf95                	j	800032a4 <usertrap+0x62>
  int which_dev = 0;
    80003332:	4901                	li	s2,0
    80003334:	b7d5                	j	80003318 <usertrap+0xd6>

0000000080003336 <kerneltrap>:
{
    80003336:	7179                	addi	sp,sp,-48
    80003338:	f406                	sd	ra,40(sp)
    8000333a:	f022                	sd	s0,32(sp)
    8000333c:	ec26                	sd	s1,24(sp)
    8000333e:	e84a                	sd	s2,16(sp)
    80003340:	e44e                	sd	s3,8(sp)
    80003342:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003344:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003348:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000334c:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80003350:	1004f793          	andi	a5,s1,256
    80003354:	cb85                	beqz	a5,80003384 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003356:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000335a:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    8000335c:	ef85                	bnez	a5,80003394 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    8000335e:	00000097          	auipc	ra,0x0
    80003362:	e42080e7          	jalr	-446(ra) # 800031a0 <devintr>
    80003366:	cd1d                	beqz	a0,800033a4 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003368:	4789                	li	a5,2
    8000336a:	06f50a63          	beq	a0,a5,800033de <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000336e:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003372:	10049073          	csrw	sstatus,s1
}
    80003376:	70a2                	ld	ra,40(sp)
    80003378:	7402                	ld	s0,32(sp)
    8000337a:	64e2                	ld	s1,24(sp)
    8000337c:	6942                	ld	s2,16(sp)
    8000337e:	69a2                	ld	s3,8(sp)
    80003380:	6145                	addi	sp,sp,48
    80003382:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80003384:	00005517          	auipc	a0,0x5
    80003388:	07450513          	addi	a0,a0,116 # 800083f8 <states.1793+0xc8>
    8000338c:	ffffd097          	auipc	ra,0xffffd
    80003390:	1b2080e7          	jalr	434(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80003394:	00005517          	auipc	a0,0x5
    80003398:	08c50513          	addi	a0,a0,140 # 80008420 <states.1793+0xf0>
    8000339c:	ffffd097          	auipc	ra,0xffffd
    800033a0:	1a2080e7          	jalr	418(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    800033a4:	85ce                	mv	a1,s3
    800033a6:	00005517          	auipc	a0,0x5
    800033aa:	09a50513          	addi	a0,a0,154 # 80008440 <states.1793+0x110>
    800033ae:	ffffd097          	auipc	ra,0xffffd
    800033b2:	1da080e7          	jalr	474(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800033b6:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800033ba:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    800033be:	00005517          	auipc	a0,0x5
    800033c2:	09250513          	addi	a0,a0,146 # 80008450 <states.1793+0x120>
    800033c6:	ffffd097          	auipc	ra,0xffffd
    800033ca:	1c2080e7          	jalr	450(ra) # 80000588 <printf>
    panic("kerneltrap");
    800033ce:	00005517          	auipc	a0,0x5
    800033d2:	09a50513          	addi	a0,a0,154 # 80008468 <states.1793+0x138>
    800033d6:	ffffd097          	auipc	ra,0xffffd
    800033da:	168080e7          	jalr	360(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800033de:	fffff097          	auipc	ra,0xfffff
    800033e2:	a80080e7          	jalr	-1408(ra) # 80001e5e <myproc>
    800033e6:	d541                	beqz	a0,8000336e <kerneltrap+0x38>
    800033e8:	fffff097          	auipc	ra,0xfffff
    800033ec:	a76080e7          	jalr	-1418(ra) # 80001e5e <myproc>
    800033f0:	5918                	lw	a4,48(a0)
    800033f2:	4791                	li	a5,4
    800033f4:	f6f71de3          	bne	a4,a5,8000336e <kerneltrap+0x38>
    yield();
    800033f8:	fffff097          	auipc	ra,0xfffff
    800033fc:	122080e7          	jalr	290(ra) # 8000251a <yield>
    80003400:	b7bd                	j	8000336e <kerneltrap+0x38>

0000000080003402 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80003402:	1101                	addi	sp,sp,-32
    80003404:	ec06                	sd	ra,24(sp)
    80003406:	e822                	sd	s0,16(sp)
    80003408:	e426                	sd	s1,8(sp)
    8000340a:	1000                	addi	s0,sp,32
    8000340c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000340e:	fffff097          	auipc	ra,0xfffff
    80003412:	a50080e7          	jalr	-1456(ra) # 80001e5e <myproc>
  switch (n) {
    80003416:	4795                	li	a5,5
    80003418:	0497e163          	bltu	a5,s1,8000345a <argraw+0x58>
    8000341c:	048a                	slli	s1,s1,0x2
    8000341e:	00005717          	auipc	a4,0x5
    80003422:	08270713          	addi	a4,a4,130 # 800084a0 <states.1793+0x170>
    80003426:	94ba                	add	s1,s1,a4
    80003428:	409c                	lw	a5,0(s1)
    8000342a:	97ba                	add	a5,a5,a4
    8000342c:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    8000342e:	793c                	ld	a5,112(a0)
    80003430:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80003432:	60e2                	ld	ra,24(sp)
    80003434:	6442                	ld	s0,16(sp)
    80003436:	64a2                	ld	s1,8(sp)
    80003438:	6105                	addi	sp,sp,32
    8000343a:	8082                	ret
    return p->trapframe->a1;
    8000343c:	793c                	ld	a5,112(a0)
    8000343e:	7fa8                	ld	a0,120(a5)
    80003440:	bfcd                	j	80003432 <argraw+0x30>
    return p->trapframe->a2;
    80003442:	793c                	ld	a5,112(a0)
    80003444:	63c8                	ld	a0,128(a5)
    80003446:	b7f5                	j	80003432 <argraw+0x30>
    return p->trapframe->a3;
    80003448:	793c                	ld	a5,112(a0)
    8000344a:	67c8                	ld	a0,136(a5)
    8000344c:	b7dd                	j	80003432 <argraw+0x30>
    return p->trapframe->a4;
    8000344e:	793c                	ld	a5,112(a0)
    80003450:	6bc8                	ld	a0,144(a5)
    80003452:	b7c5                	j	80003432 <argraw+0x30>
    return p->trapframe->a5;
    80003454:	793c                	ld	a5,112(a0)
    80003456:	6fc8                	ld	a0,152(a5)
    80003458:	bfe9                	j	80003432 <argraw+0x30>
  panic("argraw");
    8000345a:	00005517          	auipc	a0,0x5
    8000345e:	01e50513          	addi	a0,a0,30 # 80008478 <states.1793+0x148>
    80003462:	ffffd097          	auipc	ra,0xffffd
    80003466:	0dc080e7          	jalr	220(ra) # 8000053e <panic>

000000008000346a <fetchaddr>:
{
    8000346a:	1101                	addi	sp,sp,-32
    8000346c:	ec06                	sd	ra,24(sp)
    8000346e:	e822                	sd	s0,16(sp)
    80003470:	e426                	sd	s1,8(sp)
    80003472:	e04a                	sd	s2,0(sp)
    80003474:	1000                	addi	s0,sp,32
    80003476:	84aa                	mv	s1,a0
    80003478:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000347a:	fffff097          	auipc	ra,0xfffff
    8000347e:	9e4080e7          	jalr	-1564(ra) # 80001e5e <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80003482:	713c                	ld	a5,96(a0)
    80003484:	02f4f863          	bgeu	s1,a5,800034b4 <fetchaddr+0x4a>
    80003488:	00848713          	addi	a4,s1,8
    8000348c:	02e7e663          	bltu	a5,a4,800034b8 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80003490:	46a1                	li	a3,8
    80003492:	8626                	mv	a2,s1
    80003494:	85ca                	mv	a1,s2
    80003496:	7528                	ld	a0,104(a0)
    80003498:	ffffe097          	auipc	ra,0xffffe
    8000349c:	266080e7          	jalr	614(ra) # 800016fe <copyin>
    800034a0:	00a03533          	snez	a0,a0
    800034a4:	40a00533          	neg	a0,a0
}
    800034a8:	60e2                	ld	ra,24(sp)
    800034aa:	6442                	ld	s0,16(sp)
    800034ac:	64a2                	ld	s1,8(sp)
    800034ae:	6902                	ld	s2,0(sp)
    800034b0:	6105                	addi	sp,sp,32
    800034b2:	8082                	ret
    return -1;
    800034b4:	557d                	li	a0,-1
    800034b6:	bfcd                	j	800034a8 <fetchaddr+0x3e>
    800034b8:	557d                	li	a0,-1
    800034ba:	b7fd                	j	800034a8 <fetchaddr+0x3e>

00000000800034bc <fetchstr>:
{
    800034bc:	7179                	addi	sp,sp,-48
    800034be:	f406                	sd	ra,40(sp)
    800034c0:	f022                	sd	s0,32(sp)
    800034c2:	ec26                	sd	s1,24(sp)
    800034c4:	e84a                	sd	s2,16(sp)
    800034c6:	e44e                	sd	s3,8(sp)
    800034c8:	1800                	addi	s0,sp,48
    800034ca:	892a                	mv	s2,a0
    800034cc:	84ae                	mv	s1,a1
    800034ce:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    800034d0:	fffff097          	auipc	ra,0xfffff
    800034d4:	98e080e7          	jalr	-1650(ra) # 80001e5e <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    800034d8:	86ce                	mv	a3,s3
    800034da:	864a                	mv	a2,s2
    800034dc:	85a6                	mv	a1,s1
    800034de:	7528                	ld	a0,104(a0)
    800034e0:	ffffe097          	auipc	ra,0xffffe
    800034e4:	2aa080e7          	jalr	682(ra) # 8000178a <copyinstr>
  if(err < 0)
    800034e8:	00054763          	bltz	a0,800034f6 <fetchstr+0x3a>
  return strlen(buf);
    800034ec:	8526                	mv	a0,s1
    800034ee:	ffffe097          	auipc	ra,0xffffe
    800034f2:	976080e7          	jalr	-1674(ra) # 80000e64 <strlen>
}
    800034f6:	70a2                	ld	ra,40(sp)
    800034f8:	7402                	ld	s0,32(sp)
    800034fa:	64e2                	ld	s1,24(sp)
    800034fc:	6942                	ld	s2,16(sp)
    800034fe:	69a2                	ld	s3,8(sp)
    80003500:	6145                	addi	sp,sp,48
    80003502:	8082                	ret

0000000080003504 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80003504:	1101                	addi	sp,sp,-32
    80003506:	ec06                	sd	ra,24(sp)
    80003508:	e822                	sd	s0,16(sp)
    8000350a:	e426                	sd	s1,8(sp)
    8000350c:	1000                	addi	s0,sp,32
    8000350e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003510:	00000097          	auipc	ra,0x0
    80003514:	ef2080e7          	jalr	-270(ra) # 80003402 <argraw>
    80003518:	c088                	sw	a0,0(s1)
  return 0;
}
    8000351a:	4501                	li	a0,0
    8000351c:	60e2                	ld	ra,24(sp)
    8000351e:	6442                	ld	s0,16(sp)
    80003520:	64a2                	ld	s1,8(sp)
    80003522:	6105                	addi	sp,sp,32
    80003524:	8082                	ret

0000000080003526 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80003526:	1101                	addi	sp,sp,-32
    80003528:	ec06                	sd	ra,24(sp)
    8000352a:	e822                	sd	s0,16(sp)
    8000352c:	e426                	sd	s1,8(sp)
    8000352e:	1000                	addi	s0,sp,32
    80003530:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003532:	00000097          	auipc	ra,0x0
    80003536:	ed0080e7          	jalr	-304(ra) # 80003402 <argraw>
    8000353a:	e088                	sd	a0,0(s1)
  return 0;
}
    8000353c:	4501                	li	a0,0
    8000353e:	60e2                	ld	ra,24(sp)
    80003540:	6442                	ld	s0,16(sp)
    80003542:	64a2                	ld	s1,8(sp)
    80003544:	6105                	addi	sp,sp,32
    80003546:	8082                	ret

0000000080003548 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80003548:	1101                	addi	sp,sp,-32
    8000354a:	ec06                	sd	ra,24(sp)
    8000354c:	e822                	sd	s0,16(sp)
    8000354e:	e426                	sd	s1,8(sp)
    80003550:	e04a                	sd	s2,0(sp)
    80003552:	1000                	addi	s0,sp,32
    80003554:	84ae                	mv	s1,a1
    80003556:	8932                	mv	s2,a2
  *ip = argraw(n);
    80003558:	00000097          	auipc	ra,0x0
    8000355c:	eaa080e7          	jalr	-342(ra) # 80003402 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80003560:	864a                	mv	a2,s2
    80003562:	85a6                	mv	a1,s1
    80003564:	00000097          	auipc	ra,0x0
    80003568:	f58080e7          	jalr	-168(ra) # 800034bc <fetchstr>
}
    8000356c:	60e2                	ld	ra,24(sp)
    8000356e:	6442                	ld	s0,16(sp)
    80003570:	64a2                	ld	s1,8(sp)
    80003572:	6902                	ld	s2,0(sp)
    80003574:	6105                	addi	sp,sp,32
    80003576:	8082                	ret

0000000080003578 <syscall>:
[SYS_cpu_process_count] sys_cpu_process_count,
};

void
syscall(void)
{
    80003578:	1101                	addi	sp,sp,-32
    8000357a:	ec06                	sd	ra,24(sp)
    8000357c:	e822                	sd	s0,16(sp)
    8000357e:	e426                	sd	s1,8(sp)
    80003580:	e04a                	sd	s2,0(sp)
    80003582:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80003584:	fffff097          	auipc	ra,0xfffff
    80003588:	8da080e7          	jalr	-1830(ra) # 80001e5e <myproc>
    8000358c:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    8000358e:	07053903          	ld	s2,112(a0)
    80003592:	0a893783          	ld	a5,168(s2)
    80003596:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    8000359a:	37fd                	addiw	a5,a5,-1
    8000359c:	475d                	li	a4,23
    8000359e:	00f76f63          	bltu	a4,a5,800035bc <syscall+0x44>
    800035a2:	00369713          	slli	a4,a3,0x3
    800035a6:	00005797          	auipc	a5,0x5
    800035aa:	f1278793          	addi	a5,a5,-238 # 800084b8 <syscalls>
    800035ae:	97ba                	add	a5,a5,a4
    800035b0:	639c                	ld	a5,0(a5)
    800035b2:	c789                	beqz	a5,800035bc <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    800035b4:	9782                	jalr	a5
    800035b6:	06a93823          	sd	a0,112(s2)
    800035ba:	a839                	j	800035d8 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    800035bc:	17048613          	addi	a2,s1,368
    800035c0:	44ac                	lw	a1,72(s1)
    800035c2:	00005517          	auipc	a0,0x5
    800035c6:	ebe50513          	addi	a0,a0,-322 # 80008480 <states.1793+0x150>
    800035ca:	ffffd097          	auipc	ra,0xffffd
    800035ce:	fbe080e7          	jalr	-66(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    800035d2:	78bc                	ld	a5,112(s1)
    800035d4:	577d                	li	a4,-1
    800035d6:	fbb8                	sd	a4,112(a5)
  }
}
    800035d8:	60e2                	ld	ra,24(sp)
    800035da:	6442                	ld	s0,16(sp)
    800035dc:	64a2                	ld	s1,8(sp)
    800035de:	6902                	ld	s2,0(sp)
    800035e0:	6105                	addi	sp,sp,32
    800035e2:	8082                	ret

00000000800035e4 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    800035e4:	1101                	addi	sp,sp,-32
    800035e6:	ec06                	sd	ra,24(sp)
    800035e8:	e822                	sd	s0,16(sp)
    800035ea:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    800035ec:	fec40593          	addi	a1,s0,-20
    800035f0:	4501                	li	a0,0
    800035f2:	00000097          	auipc	ra,0x0
    800035f6:	f12080e7          	jalr	-238(ra) # 80003504 <argint>
    return -1;
    800035fa:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800035fc:	00054963          	bltz	a0,8000360e <sys_exit+0x2a>
  exit(n);
    80003600:	fec42503          	lw	a0,-20(s0)
    80003604:	fffff097          	auipc	ra,0xfffff
    80003608:	364080e7          	jalr	868(ra) # 80002968 <exit>
  return 0;  // not reached
    8000360c:	4781                	li	a5,0
}
    8000360e:	853e                	mv	a0,a5
    80003610:	60e2                	ld	ra,24(sp)
    80003612:	6442                	ld	s0,16(sp)
    80003614:	6105                	addi	sp,sp,32
    80003616:	8082                	ret

0000000080003618 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003618:	1141                	addi	sp,sp,-16
    8000361a:	e406                	sd	ra,8(sp)
    8000361c:	e022                	sd	s0,0(sp)
    8000361e:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003620:	fffff097          	auipc	ra,0xfffff
    80003624:	83e080e7          	jalr	-1986(ra) # 80001e5e <myproc>
}
    80003628:	4528                	lw	a0,72(a0)
    8000362a:	60a2                	ld	ra,8(sp)
    8000362c:	6402                	ld	s0,0(sp)
    8000362e:	0141                	addi	sp,sp,16
    80003630:	8082                	ret

0000000080003632 <sys_fork>:

uint64
sys_fork(void)
{
    80003632:	1141                	addi	sp,sp,-16
    80003634:	e406                	sd	ra,8(sp)
    80003636:	e022                	sd	s0,0(sp)
    80003638:	0800                	addi	s0,sp,16
  return fork();
    8000363a:	fffff097          	auipc	ra,0xfffff
    8000363e:	c94080e7          	jalr	-876(ra) # 800022ce <fork>
}
    80003642:	60a2                	ld	ra,8(sp)
    80003644:	6402                	ld	s0,0(sp)
    80003646:	0141                	addi	sp,sp,16
    80003648:	8082                	ret

000000008000364a <sys_wait>:

uint64
sys_wait(void)
{
    8000364a:	1101                	addi	sp,sp,-32
    8000364c:	ec06                	sd	ra,24(sp)
    8000364e:	e822                	sd	s0,16(sp)
    80003650:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80003652:	fe840593          	addi	a1,s0,-24
    80003656:	4501                	li	a0,0
    80003658:	00000097          	auipc	ra,0x0
    8000365c:	ece080e7          	jalr	-306(ra) # 80003526 <argaddr>
    80003660:	87aa                	mv	a5,a0
    return -1;
    80003662:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80003664:	0007c863          	bltz	a5,80003674 <sys_wait+0x2a>
  return wait(p);
    80003668:	fe843503          	ld	a0,-24(s0)
    8000366c:	fffff097          	auipc	ra,0xfffff
    80003670:	f88080e7          	jalr	-120(ra) # 800025f4 <wait>
}
    80003674:	60e2                	ld	ra,24(sp)
    80003676:	6442                	ld	s0,16(sp)
    80003678:	6105                	addi	sp,sp,32
    8000367a:	8082                	ret

000000008000367c <sys_sbrk>:

uint64
sys_sbrk(void)
{
    8000367c:	7179                	addi	sp,sp,-48
    8000367e:	f406                	sd	ra,40(sp)
    80003680:	f022                	sd	s0,32(sp)
    80003682:	ec26                	sd	s1,24(sp)
    80003684:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80003686:	fdc40593          	addi	a1,s0,-36
    8000368a:	4501                	li	a0,0
    8000368c:	00000097          	auipc	ra,0x0
    80003690:	e78080e7          	jalr	-392(ra) # 80003504 <argint>
    80003694:	87aa                	mv	a5,a0
    return -1;
    80003696:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80003698:	0207c063          	bltz	a5,800036b8 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    8000369c:	ffffe097          	auipc	ra,0xffffe
    800036a0:	7c2080e7          	jalr	1986(ra) # 80001e5e <myproc>
    800036a4:	5124                	lw	s1,96(a0)
  if(growproc(n) < 0)
    800036a6:	fdc42503          	lw	a0,-36(s0)
    800036aa:	fffff097          	auipc	ra,0xfffff
    800036ae:	bb0080e7          	jalr	-1104(ra) # 8000225a <growproc>
    800036b2:	00054863          	bltz	a0,800036c2 <sys_sbrk+0x46>
    return -1;
  return addr;
    800036b6:	8526                	mv	a0,s1
}
    800036b8:	70a2                	ld	ra,40(sp)
    800036ba:	7402                	ld	s0,32(sp)
    800036bc:	64e2                	ld	s1,24(sp)
    800036be:	6145                	addi	sp,sp,48
    800036c0:	8082                	ret
    return -1;
    800036c2:	557d                	li	a0,-1
    800036c4:	bfd5                	j	800036b8 <sys_sbrk+0x3c>

00000000800036c6 <sys_sleep>:

uint64
sys_sleep(void)
{
    800036c6:	7139                	addi	sp,sp,-64
    800036c8:	fc06                	sd	ra,56(sp)
    800036ca:	f822                	sd	s0,48(sp)
    800036cc:	f426                	sd	s1,40(sp)
    800036ce:	f04a                	sd	s2,32(sp)
    800036d0:	ec4e                	sd	s3,24(sp)
    800036d2:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    800036d4:	fcc40593          	addi	a1,s0,-52
    800036d8:	4501                	li	a0,0
    800036da:	00000097          	auipc	ra,0x0
    800036de:	e2a080e7          	jalr	-470(ra) # 80003504 <argint>
    return -1;
    800036e2:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800036e4:	06054563          	bltz	a0,8000374e <sys_sleep+0x88>
  acquire(&tickslock);
    800036e8:	00014517          	auipc	a0,0x14
    800036ec:	4d850513          	addi	a0,a0,1240 # 80017bc0 <tickslock>
    800036f0:	ffffd097          	auipc	ra,0xffffd
    800036f4:	4f4080e7          	jalr	1268(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    800036f8:	00006917          	auipc	s2,0x6
    800036fc:	93892903          	lw	s2,-1736(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80003700:	fcc42783          	lw	a5,-52(s0)
    80003704:	cf85                	beqz	a5,8000373c <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003706:	00014997          	auipc	s3,0x14
    8000370a:	4ba98993          	addi	s3,s3,1210 # 80017bc0 <tickslock>
    8000370e:	00006497          	auipc	s1,0x6
    80003712:	92248493          	addi	s1,s1,-1758 # 80009030 <ticks>
    if(myproc()->killed){
    80003716:	ffffe097          	auipc	ra,0xffffe
    8000371a:	748080e7          	jalr	1864(ra) # 80001e5e <myproc>
    8000371e:	413c                	lw	a5,64(a0)
    80003720:	ef9d                	bnez	a5,8000375e <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003722:	85ce                	mv	a1,s3
    80003724:	8526                	mv	a0,s1
    80003726:	fffff097          	auipc	ra,0xfffff
    8000372a:	e54080e7          	jalr	-428(ra) # 8000257a <sleep>
  while(ticks - ticks0 < n){
    8000372e:	409c                	lw	a5,0(s1)
    80003730:	412787bb          	subw	a5,a5,s2
    80003734:	fcc42703          	lw	a4,-52(s0)
    80003738:	fce7efe3          	bltu	a5,a4,80003716 <sys_sleep+0x50>
  }
  release(&tickslock);
    8000373c:	00014517          	auipc	a0,0x14
    80003740:	48450513          	addi	a0,a0,1156 # 80017bc0 <tickslock>
    80003744:	ffffd097          	auipc	ra,0xffffd
    80003748:	554080e7          	jalr	1364(ra) # 80000c98 <release>
  return 0;
    8000374c:	4781                	li	a5,0
}
    8000374e:	853e                	mv	a0,a5
    80003750:	70e2                	ld	ra,56(sp)
    80003752:	7442                	ld	s0,48(sp)
    80003754:	74a2                	ld	s1,40(sp)
    80003756:	7902                	ld	s2,32(sp)
    80003758:	69e2                	ld	s3,24(sp)
    8000375a:	6121                	addi	sp,sp,64
    8000375c:	8082                	ret
      release(&tickslock);
    8000375e:	00014517          	auipc	a0,0x14
    80003762:	46250513          	addi	a0,a0,1122 # 80017bc0 <tickslock>
    80003766:	ffffd097          	auipc	ra,0xffffd
    8000376a:	532080e7          	jalr	1330(ra) # 80000c98 <release>
      return -1;
    8000376e:	57fd                	li	a5,-1
    80003770:	bff9                	j	8000374e <sys_sleep+0x88>

0000000080003772 <sys_kill>:

uint64
sys_kill(void)
{
    80003772:	1101                	addi	sp,sp,-32
    80003774:	ec06                	sd	ra,24(sp)
    80003776:	e822                	sd	s0,16(sp)
    80003778:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    8000377a:	fec40593          	addi	a1,s0,-20
    8000377e:	4501                	li	a0,0
    80003780:	00000097          	auipc	ra,0x0
    80003784:	d84080e7          	jalr	-636(ra) # 80003504 <argint>
    80003788:	87aa                	mv	a5,a0
    return -1;
    8000378a:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    8000378c:	0007c863          	bltz	a5,8000379c <sys_kill+0x2a>
  return kill(pid);
    80003790:	fec42503          	lw	a0,-20(s0)
    80003794:	fffff097          	auipc	ra,0xfffff
    80003798:	2c0080e7          	jalr	704(ra) # 80002a54 <kill>
}
    8000379c:	60e2                	ld	ra,24(sp)
    8000379e:	6442                	ld	s0,16(sp)
    800037a0:	6105                	addi	sp,sp,32
    800037a2:	8082                	ret

00000000800037a4 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800037a4:	1101                	addi	sp,sp,-32
    800037a6:	ec06                	sd	ra,24(sp)
    800037a8:	e822                	sd	s0,16(sp)
    800037aa:	e426                	sd	s1,8(sp)
    800037ac:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800037ae:	00014517          	auipc	a0,0x14
    800037b2:	41250513          	addi	a0,a0,1042 # 80017bc0 <tickslock>
    800037b6:	ffffd097          	auipc	ra,0xffffd
    800037ba:	42e080e7          	jalr	1070(ra) # 80000be4 <acquire>
  xticks = ticks;
    800037be:	00006497          	auipc	s1,0x6
    800037c2:	8724a483          	lw	s1,-1934(s1) # 80009030 <ticks>
  release(&tickslock);
    800037c6:	00014517          	auipc	a0,0x14
    800037ca:	3fa50513          	addi	a0,a0,1018 # 80017bc0 <tickslock>
    800037ce:	ffffd097          	auipc	ra,0xffffd
    800037d2:	4ca080e7          	jalr	1226(ra) # 80000c98 <release>
  return xticks;
}
    800037d6:	02049513          	slli	a0,s1,0x20
    800037da:	9101                	srli	a0,a0,0x20
    800037dc:	60e2                	ld	ra,24(sp)
    800037de:	6442                	ld	s0,16(sp)
    800037e0:	64a2                	ld	s1,8(sp)
    800037e2:	6105                	addi	sp,sp,32
    800037e4:	8082                	ret

00000000800037e6 <sys_set_cpu>:

uint64
sys_set_cpu(void){
    800037e6:	1101                	addi	sp,sp,-32
    800037e8:	ec06                	sd	ra,24(sp)
    800037ea:	e822                	sd	s0,16(sp)
    800037ec:	1000                	addi	s0,sp,32
  int cpid;
  if(argint(0, &cpid) < 0)
    800037ee:	fec40593          	addi	a1,s0,-20
    800037f2:	4501                	li	a0,0
    800037f4:	00000097          	auipc	ra,0x0
    800037f8:	d10080e7          	jalr	-752(ra) # 80003504 <argint>
    800037fc:	87aa                	mv	a5,a0
    return -1;
    800037fe:	557d                	li	a0,-1
  if(argint(0, &cpid) < 0)
    80003800:	0007c863          	bltz	a5,80003810 <sys_set_cpu+0x2a>

  return set_cpu(cpid);
    80003804:	fec42503          	lw	a0,-20(s0)
    80003808:	fffff097          	auipc	ra,0xfffff
    8000380c:	76c080e7          	jalr	1900(ra) # 80002f74 <set_cpu>

}
    80003810:	60e2                	ld	ra,24(sp)
    80003812:	6442                	ld	s0,16(sp)
    80003814:	6105                	addi	sp,sp,32
    80003816:	8082                	ret

0000000080003818 <sys_get_cpu>:

uint64
sys_get_cpu(void){
    80003818:	1141                	addi	sp,sp,-16
    8000381a:	e406                	sd	ra,8(sp)
    8000381c:	e022                	sd	s0,0(sp)
    8000381e:	0800                	addi	s0,sp,16
  return get_cpu();
    80003820:	fffff097          	auipc	ra,0xfffff
    80003824:	7a2080e7          	jalr	1954(ra) # 80002fc2 <get_cpu>
}
    80003828:	60a2                	ld	ra,8(sp)
    8000382a:	6402                	ld	s0,0(sp)
    8000382c:	0141                	addi	sp,sp,16
    8000382e:	8082                	ret

0000000080003830 <sys_cpu_process_count>:

uint64
sys_cpu_process_count(void){
    80003830:	1101                	addi	sp,sp,-32
    80003832:	ec06                	sd	ra,24(sp)
    80003834:	e822                	sd	s0,16(sp)
    80003836:	1000                	addi	s0,sp,32
  int cpid;
  if (argint(0, &cpid) < 0)
    80003838:	fec40593          	addi	a1,s0,-20
    8000383c:	4501                	li	a0,0
    8000383e:	00000097          	auipc	ra,0x0
    80003842:	cc6080e7          	jalr	-826(ra) # 80003504 <argint>
    80003846:	87aa                	mv	a5,a0
    return -1;
    80003848:	557d                	li	a0,-1
  if (argint(0, &cpid) < 0)
    8000384a:	0007c863          	bltz	a5,8000385a <sys_cpu_process_count+0x2a>
  return cpu_process_count(cpid);
    8000384e:	fec42503          	lw	a0,-20(s0)
    80003852:	fffff097          	auipc	ra,0xfffff
    80003856:	796080e7          	jalr	1942(ra) # 80002fe8 <cpu_process_count>
}
    8000385a:	60e2                	ld	ra,24(sp)
    8000385c:	6442                	ld	s0,16(sp)
    8000385e:	6105                	addi	sp,sp,32
    80003860:	8082                	ret

0000000080003862 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003862:	7179                	addi	sp,sp,-48
    80003864:	f406                	sd	ra,40(sp)
    80003866:	f022                	sd	s0,32(sp)
    80003868:	ec26                	sd	s1,24(sp)
    8000386a:	e84a                	sd	s2,16(sp)
    8000386c:	e44e                	sd	s3,8(sp)
    8000386e:	e052                	sd	s4,0(sp)
    80003870:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003872:	00005597          	auipc	a1,0x5
    80003876:	d0e58593          	addi	a1,a1,-754 # 80008580 <syscalls+0xc8>
    8000387a:	00014517          	auipc	a0,0x14
    8000387e:	35e50513          	addi	a0,a0,862 # 80017bd8 <bcache>
    80003882:	ffffd097          	auipc	ra,0xffffd
    80003886:	2d2080e7          	jalr	722(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000388a:	0001c797          	auipc	a5,0x1c
    8000388e:	34e78793          	addi	a5,a5,846 # 8001fbd8 <bcache+0x8000>
    80003892:	0001c717          	auipc	a4,0x1c
    80003896:	5ae70713          	addi	a4,a4,1454 # 8001fe40 <bcache+0x8268>
    8000389a:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000389e:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800038a2:	00014497          	auipc	s1,0x14
    800038a6:	34e48493          	addi	s1,s1,846 # 80017bf0 <bcache+0x18>
    b->next = bcache.head.next;
    800038aa:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800038ac:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800038ae:	00005a17          	auipc	s4,0x5
    800038b2:	cdaa0a13          	addi	s4,s4,-806 # 80008588 <syscalls+0xd0>
    b->next = bcache.head.next;
    800038b6:	2b893783          	ld	a5,696(s2)
    800038ba:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800038bc:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800038c0:	85d2                	mv	a1,s4
    800038c2:	01048513          	addi	a0,s1,16
    800038c6:	00001097          	auipc	ra,0x1
    800038ca:	4bc080e7          	jalr	1212(ra) # 80004d82 <initsleeplock>
    bcache.head.next->prev = b;
    800038ce:	2b893783          	ld	a5,696(s2)
    800038d2:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800038d4:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800038d8:	45848493          	addi	s1,s1,1112
    800038dc:	fd349de3          	bne	s1,s3,800038b6 <binit+0x54>
  }
}
    800038e0:	70a2                	ld	ra,40(sp)
    800038e2:	7402                	ld	s0,32(sp)
    800038e4:	64e2                	ld	s1,24(sp)
    800038e6:	6942                	ld	s2,16(sp)
    800038e8:	69a2                	ld	s3,8(sp)
    800038ea:	6a02                	ld	s4,0(sp)
    800038ec:	6145                	addi	sp,sp,48
    800038ee:	8082                	ret

00000000800038f0 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800038f0:	7179                	addi	sp,sp,-48
    800038f2:	f406                	sd	ra,40(sp)
    800038f4:	f022                	sd	s0,32(sp)
    800038f6:	ec26                	sd	s1,24(sp)
    800038f8:	e84a                	sd	s2,16(sp)
    800038fa:	e44e                	sd	s3,8(sp)
    800038fc:	1800                	addi	s0,sp,48
    800038fe:	89aa                	mv	s3,a0
    80003900:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003902:	00014517          	auipc	a0,0x14
    80003906:	2d650513          	addi	a0,a0,726 # 80017bd8 <bcache>
    8000390a:	ffffd097          	auipc	ra,0xffffd
    8000390e:	2da080e7          	jalr	730(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003912:	0001c497          	auipc	s1,0x1c
    80003916:	57e4b483          	ld	s1,1406(s1) # 8001fe90 <bcache+0x82b8>
    8000391a:	0001c797          	auipc	a5,0x1c
    8000391e:	52678793          	addi	a5,a5,1318 # 8001fe40 <bcache+0x8268>
    80003922:	02f48f63          	beq	s1,a5,80003960 <bread+0x70>
    80003926:	873e                	mv	a4,a5
    80003928:	a021                	j	80003930 <bread+0x40>
    8000392a:	68a4                	ld	s1,80(s1)
    8000392c:	02e48a63          	beq	s1,a4,80003960 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003930:	449c                	lw	a5,8(s1)
    80003932:	ff379ce3          	bne	a5,s3,8000392a <bread+0x3a>
    80003936:	44dc                	lw	a5,12(s1)
    80003938:	ff2799e3          	bne	a5,s2,8000392a <bread+0x3a>
      b->refcnt++;
    8000393c:	40bc                	lw	a5,64(s1)
    8000393e:	2785                	addiw	a5,a5,1
    80003940:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003942:	00014517          	auipc	a0,0x14
    80003946:	29650513          	addi	a0,a0,662 # 80017bd8 <bcache>
    8000394a:	ffffd097          	auipc	ra,0xffffd
    8000394e:	34e080e7          	jalr	846(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003952:	01048513          	addi	a0,s1,16
    80003956:	00001097          	auipc	ra,0x1
    8000395a:	466080e7          	jalr	1126(ra) # 80004dbc <acquiresleep>
      return b;
    8000395e:	a8b9                	j	800039bc <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003960:	0001c497          	auipc	s1,0x1c
    80003964:	5284b483          	ld	s1,1320(s1) # 8001fe88 <bcache+0x82b0>
    80003968:	0001c797          	auipc	a5,0x1c
    8000396c:	4d878793          	addi	a5,a5,1240 # 8001fe40 <bcache+0x8268>
    80003970:	00f48863          	beq	s1,a5,80003980 <bread+0x90>
    80003974:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003976:	40bc                	lw	a5,64(s1)
    80003978:	cf81                	beqz	a5,80003990 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000397a:	64a4                	ld	s1,72(s1)
    8000397c:	fee49de3          	bne	s1,a4,80003976 <bread+0x86>
  panic("bget: no buffers");
    80003980:	00005517          	auipc	a0,0x5
    80003984:	c1050513          	addi	a0,a0,-1008 # 80008590 <syscalls+0xd8>
    80003988:	ffffd097          	auipc	ra,0xffffd
    8000398c:	bb6080e7          	jalr	-1098(ra) # 8000053e <panic>
      b->dev = dev;
    80003990:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003994:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003998:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000399c:	4785                	li	a5,1
    8000399e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800039a0:	00014517          	auipc	a0,0x14
    800039a4:	23850513          	addi	a0,a0,568 # 80017bd8 <bcache>
    800039a8:	ffffd097          	auipc	ra,0xffffd
    800039ac:	2f0080e7          	jalr	752(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800039b0:	01048513          	addi	a0,s1,16
    800039b4:	00001097          	auipc	ra,0x1
    800039b8:	408080e7          	jalr	1032(ra) # 80004dbc <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800039bc:	409c                	lw	a5,0(s1)
    800039be:	cb89                	beqz	a5,800039d0 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800039c0:	8526                	mv	a0,s1
    800039c2:	70a2                	ld	ra,40(sp)
    800039c4:	7402                	ld	s0,32(sp)
    800039c6:	64e2                	ld	s1,24(sp)
    800039c8:	6942                	ld	s2,16(sp)
    800039ca:	69a2                	ld	s3,8(sp)
    800039cc:	6145                	addi	sp,sp,48
    800039ce:	8082                	ret
    virtio_disk_rw(b, 0);
    800039d0:	4581                	li	a1,0
    800039d2:	8526                	mv	a0,s1
    800039d4:	00003097          	auipc	ra,0x3
    800039d8:	f12080e7          	jalr	-238(ra) # 800068e6 <virtio_disk_rw>
    b->valid = 1;
    800039dc:	4785                	li	a5,1
    800039de:	c09c                	sw	a5,0(s1)
  return b;
    800039e0:	b7c5                	j	800039c0 <bread+0xd0>

00000000800039e2 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800039e2:	1101                	addi	sp,sp,-32
    800039e4:	ec06                	sd	ra,24(sp)
    800039e6:	e822                	sd	s0,16(sp)
    800039e8:	e426                	sd	s1,8(sp)
    800039ea:	1000                	addi	s0,sp,32
    800039ec:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800039ee:	0541                	addi	a0,a0,16
    800039f0:	00001097          	auipc	ra,0x1
    800039f4:	466080e7          	jalr	1126(ra) # 80004e56 <holdingsleep>
    800039f8:	cd01                	beqz	a0,80003a10 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800039fa:	4585                	li	a1,1
    800039fc:	8526                	mv	a0,s1
    800039fe:	00003097          	auipc	ra,0x3
    80003a02:	ee8080e7          	jalr	-280(ra) # 800068e6 <virtio_disk_rw>
}
    80003a06:	60e2                	ld	ra,24(sp)
    80003a08:	6442                	ld	s0,16(sp)
    80003a0a:	64a2                	ld	s1,8(sp)
    80003a0c:	6105                	addi	sp,sp,32
    80003a0e:	8082                	ret
    panic("bwrite");
    80003a10:	00005517          	auipc	a0,0x5
    80003a14:	b9850513          	addi	a0,a0,-1128 # 800085a8 <syscalls+0xf0>
    80003a18:	ffffd097          	auipc	ra,0xffffd
    80003a1c:	b26080e7          	jalr	-1242(ra) # 8000053e <panic>

0000000080003a20 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003a20:	1101                	addi	sp,sp,-32
    80003a22:	ec06                	sd	ra,24(sp)
    80003a24:	e822                	sd	s0,16(sp)
    80003a26:	e426                	sd	s1,8(sp)
    80003a28:	e04a                	sd	s2,0(sp)
    80003a2a:	1000                	addi	s0,sp,32
    80003a2c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003a2e:	01050913          	addi	s2,a0,16
    80003a32:	854a                	mv	a0,s2
    80003a34:	00001097          	auipc	ra,0x1
    80003a38:	422080e7          	jalr	1058(ra) # 80004e56 <holdingsleep>
    80003a3c:	c92d                	beqz	a0,80003aae <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003a3e:	854a                	mv	a0,s2
    80003a40:	00001097          	auipc	ra,0x1
    80003a44:	3d2080e7          	jalr	978(ra) # 80004e12 <releasesleep>

  acquire(&bcache.lock);
    80003a48:	00014517          	auipc	a0,0x14
    80003a4c:	19050513          	addi	a0,a0,400 # 80017bd8 <bcache>
    80003a50:	ffffd097          	auipc	ra,0xffffd
    80003a54:	194080e7          	jalr	404(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003a58:	40bc                	lw	a5,64(s1)
    80003a5a:	37fd                	addiw	a5,a5,-1
    80003a5c:	0007871b          	sext.w	a4,a5
    80003a60:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003a62:	eb05                	bnez	a4,80003a92 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003a64:	68bc                	ld	a5,80(s1)
    80003a66:	64b8                	ld	a4,72(s1)
    80003a68:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003a6a:	64bc                	ld	a5,72(s1)
    80003a6c:	68b8                	ld	a4,80(s1)
    80003a6e:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003a70:	0001c797          	auipc	a5,0x1c
    80003a74:	16878793          	addi	a5,a5,360 # 8001fbd8 <bcache+0x8000>
    80003a78:	2b87b703          	ld	a4,696(a5)
    80003a7c:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003a7e:	0001c717          	auipc	a4,0x1c
    80003a82:	3c270713          	addi	a4,a4,962 # 8001fe40 <bcache+0x8268>
    80003a86:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003a88:	2b87b703          	ld	a4,696(a5)
    80003a8c:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003a8e:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003a92:	00014517          	auipc	a0,0x14
    80003a96:	14650513          	addi	a0,a0,326 # 80017bd8 <bcache>
    80003a9a:	ffffd097          	auipc	ra,0xffffd
    80003a9e:	1fe080e7          	jalr	510(ra) # 80000c98 <release>
}
    80003aa2:	60e2                	ld	ra,24(sp)
    80003aa4:	6442                	ld	s0,16(sp)
    80003aa6:	64a2                	ld	s1,8(sp)
    80003aa8:	6902                	ld	s2,0(sp)
    80003aaa:	6105                	addi	sp,sp,32
    80003aac:	8082                	ret
    panic("brelse");
    80003aae:	00005517          	auipc	a0,0x5
    80003ab2:	b0250513          	addi	a0,a0,-1278 # 800085b0 <syscalls+0xf8>
    80003ab6:	ffffd097          	auipc	ra,0xffffd
    80003aba:	a88080e7          	jalr	-1400(ra) # 8000053e <panic>

0000000080003abe <bpin>:

void
bpin(struct buf *b) {
    80003abe:	1101                	addi	sp,sp,-32
    80003ac0:	ec06                	sd	ra,24(sp)
    80003ac2:	e822                	sd	s0,16(sp)
    80003ac4:	e426                	sd	s1,8(sp)
    80003ac6:	1000                	addi	s0,sp,32
    80003ac8:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003aca:	00014517          	auipc	a0,0x14
    80003ace:	10e50513          	addi	a0,a0,270 # 80017bd8 <bcache>
    80003ad2:	ffffd097          	auipc	ra,0xffffd
    80003ad6:	112080e7          	jalr	274(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003ada:	40bc                	lw	a5,64(s1)
    80003adc:	2785                	addiw	a5,a5,1
    80003ade:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003ae0:	00014517          	auipc	a0,0x14
    80003ae4:	0f850513          	addi	a0,a0,248 # 80017bd8 <bcache>
    80003ae8:	ffffd097          	auipc	ra,0xffffd
    80003aec:	1b0080e7          	jalr	432(ra) # 80000c98 <release>
}
    80003af0:	60e2                	ld	ra,24(sp)
    80003af2:	6442                	ld	s0,16(sp)
    80003af4:	64a2                	ld	s1,8(sp)
    80003af6:	6105                	addi	sp,sp,32
    80003af8:	8082                	ret

0000000080003afa <bunpin>:

void
bunpin(struct buf *b) {
    80003afa:	1101                	addi	sp,sp,-32
    80003afc:	ec06                	sd	ra,24(sp)
    80003afe:	e822                	sd	s0,16(sp)
    80003b00:	e426                	sd	s1,8(sp)
    80003b02:	1000                	addi	s0,sp,32
    80003b04:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003b06:	00014517          	auipc	a0,0x14
    80003b0a:	0d250513          	addi	a0,a0,210 # 80017bd8 <bcache>
    80003b0e:	ffffd097          	auipc	ra,0xffffd
    80003b12:	0d6080e7          	jalr	214(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003b16:	40bc                	lw	a5,64(s1)
    80003b18:	37fd                	addiw	a5,a5,-1
    80003b1a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003b1c:	00014517          	auipc	a0,0x14
    80003b20:	0bc50513          	addi	a0,a0,188 # 80017bd8 <bcache>
    80003b24:	ffffd097          	auipc	ra,0xffffd
    80003b28:	174080e7          	jalr	372(ra) # 80000c98 <release>
}
    80003b2c:	60e2                	ld	ra,24(sp)
    80003b2e:	6442                	ld	s0,16(sp)
    80003b30:	64a2                	ld	s1,8(sp)
    80003b32:	6105                	addi	sp,sp,32
    80003b34:	8082                	ret

0000000080003b36 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003b36:	1101                	addi	sp,sp,-32
    80003b38:	ec06                	sd	ra,24(sp)
    80003b3a:	e822                	sd	s0,16(sp)
    80003b3c:	e426                	sd	s1,8(sp)
    80003b3e:	e04a                	sd	s2,0(sp)
    80003b40:	1000                	addi	s0,sp,32
    80003b42:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003b44:	00d5d59b          	srliw	a1,a1,0xd
    80003b48:	0001c797          	auipc	a5,0x1c
    80003b4c:	76c7a783          	lw	a5,1900(a5) # 800202b4 <sb+0x1c>
    80003b50:	9dbd                	addw	a1,a1,a5
    80003b52:	00000097          	auipc	ra,0x0
    80003b56:	d9e080e7          	jalr	-610(ra) # 800038f0 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003b5a:	0074f713          	andi	a4,s1,7
    80003b5e:	4785                	li	a5,1
    80003b60:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003b64:	14ce                	slli	s1,s1,0x33
    80003b66:	90d9                	srli	s1,s1,0x36
    80003b68:	00950733          	add	a4,a0,s1
    80003b6c:	05874703          	lbu	a4,88(a4)
    80003b70:	00e7f6b3          	and	a3,a5,a4
    80003b74:	c69d                	beqz	a3,80003ba2 <bfree+0x6c>
    80003b76:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003b78:	94aa                	add	s1,s1,a0
    80003b7a:	fff7c793          	not	a5,a5
    80003b7e:	8ff9                	and	a5,a5,a4
    80003b80:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003b84:	00001097          	auipc	ra,0x1
    80003b88:	118080e7          	jalr	280(ra) # 80004c9c <log_write>
  brelse(bp);
    80003b8c:	854a                	mv	a0,s2
    80003b8e:	00000097          	auipc	ra,0x0
    80003b92:	e92080e7          	jalr	-366(ra) # 80003a20 <brelse>
}
    80003b96:	60e2                	ld	ra,24(sp)
    80003b98:	6442                	ld	s0,16(sp)
    80003b9a:	64a2                	ld	s1,8(sp)
    80003b9c:	6902                	ld	s2,0(sp)
    80003b9e:	6105                	addi	sp,sp,32
    80003ba0:	8082                	ret
    panic("freeing free block");
    80003ba2:	00005517          	auipc	a0,0x5
    80003ba6:	a1650513          	addi	a0,a0,-1514 # 800085b8 <syscalls+0x100>
    80003baa:	ffffd097          	auipc	ra,0xffffd
    80003bae:	994080e7          	jalr	-1644(ra) # 8000053e <panic>

0000000080003bb2 <balloc>:
{
    80003bb2:	711d                	addi	sp,sp,-96
    80003bb4:	ec86                	sd	ra,88(sp)
    80003bb6:	e8a2                	sd	s0,80(sp)
    80003bb8:	e4a6                	sd	s1,72(sp)
    80003bba:	e0ca                	sd	s2,64(sp)
    80003bbc:	fc4e                	sd	s3,56(sp)
    80003bbe:	f852                	sd	s4,48(sp)
    80003bc0:	f456                	sd	s5,40(sp)
    80003bc2:	f05a                	sd	s6,32(sp)
    80003bc4:	ec5e                	sd	s7,24(sp)
    80003bc6:	e862                	sd	s8,16(sp)
    80003bc8:	e466                	sd	s9,8(sp)
    80003bca:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003bcc:	0001c797          	auipc	a5,0x1c
    80003bd0:	6d07a783          	lw	a5,1744(a5) # 8002029c <sb+0x4>
    80003bd4:	cbd1                	beqz	a5,80003c68 <balloc+0xb6>
    80003bd6:	8baa                	mv	s7,a0
    80003bd8:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003bda:	0001cb17          	auipc	s6,0x1c
    80003bde:	6beb0b13          	addi	s6,s6,1726 # 80020298 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003be2:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003be4:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003be6:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003be8:	6c89                	lui	s9,0x2
    80003bea:	a831                	j	80003c06 <balloc+0x54>
    brelse(bp);
    80003bec:	854a                	mv	a0,s2
    80003bee:	00000097          	auipc	ra,0x0
    80003bf2:	e32080e7          	jalr	-462(ra) # 80003a20 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003bf6:	015c87bb          	addw	a5,s9,s5
    80003bfa:	00078a9b          	sext.w	s5,a5
    80003bfe:	004b2703          	lw	a4,4(s6)
    80003c02:	06eaf363          	bgeu	s5,a4,80003c68 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003c06:	41fad79b          	sraiw	a5,s5,0x1f
    80003c0a:	0137d79b          	srliw	a5,a5,0x13
    80003c0e:	015787bb          	addw	a5,a5,s5
    80003c12:	40d7d79b          	sraiw	a5,a5,0xd
    80003c16:	01cb2583          	lw	a1,28(s6)
    80003c1a:	9dbd                	addw	a1,a1,a5
    80003c1c:	855e                	mv	a0,s7
    80003c1e:	00000097          	auipc	ra,0x0
    80003c22:	cd2080e7          	jalr	-814(ra) # 800038f0 <bread>
    80003c26:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003c28:	004b2503          	lw	a0,4(s6)
    80003c2c:	000a849b          	sext.w	s1,s5
    80003c30:	8662                	mv	a2,s8
    80003c32:	faa4fde3          	bgeu	s1,a0,80003bec <balloc+0x3a>
      m = 1 << (bi % 8);
    80003c36:	41f6579b          	sraiw	a5,a2,0x1f
    80003c3a:	01d7d69b          	srliw	a3,a5,0x1d
    80003c3e:	00c6873b          	addw	a4,a3,a2
    80003c42:	00777793          	andi	a5,a4,7
    80003c46:	9f95                	subw	a5,a5,a3
    80003c48:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003c4c:	4037571b          	sraiw	a4,a4,0x3
    80003c50:	00e906b3          	add	a3,s2,a4
    80003c54:	0586c683          	lbu	a3,88(a3)
    80003c58:	00d7f5b3          	and	a1,a5,a3
    80003c5c:	cd91                	beqz	a1,80003c78 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003c5e:	2605                	addiw	a2,a2,1
    80003c60:	2485                	addiw	s1,s1,1
    80003c62:	fd4618e3          	bne	a2,s4,80003c32 <balloc+0x80>
    80003c66:	b759                	j	80003bec <balloc+0x3a>
  panic("balloc: out of blocks");
    80003c68:	00005517          	auipc	a0,0x5
    80003c6c:	96850513          	addi	a0,a0,-1688 # 800085d0 <syscalls+0x118>
    80003c70:	ffffd097          	auipc	ra,0xffffd
    80003c74:	8ce080e7          	jalr	-1842(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003c78:	974a                	add	a4,a4,s2
    80003c7a:	8fd5                	or	a5,a5,a3
    80003c7c:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003c80:	854a                	mv	a0,s2
    80003c82:	00001097          	auipc	ra,0x1
    80003c86:	01a080e7          	jalr	26(ra) # 80004c9c <log_write>
        brelse(bp);
    80003c8a:	854a                	mv	a0,s2
    80003c8c:	00000097          	auipc	ra,0x0
    80003c90:	d94080e7          	jalr	-620(ra) # 80003a20 <brelse>
  bp = bread(dev, bno);
    80003c94:	85a6                	mv	a1,s1
    80003c96:	855e                	mv	a0,s7
    80003c98:	00000097          	auipc	ra,0x0
    80003c9c:	c58080e7          	jalr	-936(ra) # 800038f0 <bread>
    80003ca0:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003ca2:	40000613          	li	a2,1024
    80003ca6:	4581                	li	a1,0
    80003ca8:	05850513          	addi	a0,a0,88
    80003cac:	ffffd097          	auipc	ra,0xffffd
    80003cb0:	034080e7          	jalr	52(ra) # 80000ce0 <memset>
  log_write(bp);
    80003cb4:	854a                	mv	a0,s2
    80003cb6:	00001097          	auipc	ra,0x1
    80003cba:	fe6080e7          	jalr	-26(ra) # 80004c9c <log_write>
  brelse(bp);
    80003cbe:	854a                	mv	a0,s2
    80003cc0:	00000097          	auipc	ra,0x0
    80003cc4:	d60080e7          	jalr	-672(ra) # 80003a20 <brelse>
}
    80003cc8:	8526                	mv	a0,s1
    80003cca:	60e6                	ld	ra,88(sp)
    80003ccc:	6446                	ld	s0,80(sp)
    80003cce:	64a6                	ld	s1,72(sp)
    80003cd0:	6906                	ld	s2,64(sp)
    80003cd2:	79e2                	ld	s3,56(sp)
    80003cd4:	7a42                	ld	s4,48(sp)
    80003cd6:	7aa2                	ld	s5,40(sp)
    80003cd8:	7b02                	ld	s6,32(sp)
    80003cda:	6be2                	ld	s7,24(sp)
    80003cdc:	6c42                	ld	s8,16(sp)
    80003cde:	6ca2                	ld	s9,8(sp)
    80003ce0:	6125                	addi	sp,sp,96
    80003ce2:	8082                	ret

0000000080003ce4 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003ce4:	7179                	addi	sp,sp,-48
    80003ce6:	f406                	sd	ra,40(sp)
    80003ce8:	f022                	sd	s0,32(sp)
    80003cea:	ec26                	sd	s1,24(sp)
    80003cec:	e84a                	sd	s2,16(sp)
    80003cee:	e44e                	sd	s3,8(sp)
    80003cf0:	e052                	sd	s4,0(sp)
    80003cf2:	1800                	addi	s0,sp,48
    80003cf4:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003cf6:	47ad                	li	a5,11
    80003cf8:	04b7fe63          	bgeu	a5,a1,80003d54 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003cfc:	ff45849b          	addiw	s1,a1,-12
    80003d00:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003d04:	0ff00793          	li	a5,255
    80003d08:	0ae7e363          	bltu	a5,a4,80003dae <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003d0c:	08052583          	lw	a1,128(a0)
    80003d10:	c5ad                	beqz	a1,80003d7a <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003d12:	00092503          	lw	a0,0(s2)
    80003d16:	00000097          	auipc	ra,0x0
    80003d1a:	bda080e7          	jalr	-1062(ra) # 800038f0 <bread>
    80003d1e:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003d20:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003d24:	02049593          	slli	a1,s1,0x20
    80003d28:	9181                	srli	a1,a1,0x20
    80003d2a:	058a                	slli	a1,a1,0x2
    80003d2c:	00b784b3          	add	s1,a5,a1
    80003d30:	0004a983          	lw	s3,0(s1)
    80003d34:	04098d63          	beqz	s3,80003d8e <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003d38:	8552                	mv	a0,s4
    80003d3a:	00000097          	auipc	ra,0x0
    80003d3e:	ce6080e7          	jalr	-794(ra) # 80003a20 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003d42:	854e                	mv	a0,s3
    80003d44:	70a2                	ld	ra,40(sp)
    80003d46:	7402                	ld	s0,32(sp)
    80003d48:	64e2                	ld	s1,24(sp)
    80003d4a:	6942                	ld	s2,16(sp)
    80003d4c:	69a2                	ld	s3,8(sp)
    80003d4e:	6a02                	ld	s4,0(sp)
    80003d50:	6145                	addi	sp,sp,48
    80003d52:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003d54:	02059493          	slli	s1,a1,0x20
    80003d58:	9081                	srli	s1,s1,0x20
    80003d5a:	048a                	slli	s1,s1,0x2
    80003d5c:	94aa                	add	s1,s1,a0
    80003d5e:	0504a983          	lw	s3,80(s1)
    80003d62:	fe0990e3          	bnez	s3,80003d42 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003d66:	4108                	lw	a0,0(a0)
    80003d68:	00000097          	auipc	ra,0x0
    80003d6c:	e4a080e7          	jalr	-438(ra) # 80003bb2 <balloc>
    80003d70:	0005099b          	sext.w	s3,a0
    80003d74:	0534a823          	sw	s3,80(s1)
    80003d78:	b7e9                	j	80003d42 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003d7a:	4108                	lw	a0,0(a0)
    80003d7c:	00000097          	auipc	ra,0x0
    80003d80:	e36080e7          	jalr	-458(ra) # 80003bb2 <balloc>
    80003d84:	0005059b          	sext.w	a1,a0
    80003d88:	08b92023          	sw	a1,128(s2)
    80003d8c:	b759                	j	80003d12 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003d8e:	00092503          	lw	a0,0(s2)
    80003d92:	00000097          	auipc	ra,0x0
    80003d96:	e20080e7          	jalr	-480(ra) # 80003bb2 <balloc>
    80003d9a:	0005099b          	sext.w	s3,a0
    80003d9e:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003da2:	8552                	mv	a0,s4
    80003da4:	00001097          	auipc	ra,0x1
    80003da8:	ef8080e7          	jalr	-264(ra) # 80004c9c <log_write>
    80003dac:	b771                	j	80003d38 <bmap+0x54>
  panic("bmap: out of range");
    80003dae:	00005517          	auipc	a0,0x5
    80003db2:	83a50513          	addi	a0,a0,-1990 # 800085e8 <syscalls+0x130>
    80003db6:	ffffc097          	auipc	ra,0xffffc
    80003dba:	788080e7          	jalr	1928(ra) # 8000053e <panic>

0000000080003dbe <iget>:
{
    80003dbe:	7179                	addi	sp,sp,-48
    80003dc0:	f406                	sd	ra,40(sp)
    80003dc2:	f022                	sd	s0,32(sp)
    80003dc4:	ec26                	sd	s1,24(sp)
    80003dc6:	e84a                	sd	s2,16(sp)
    80003dc8:	e44e                	sd	s3,8(sp)
    80003dca:	e052                	sd	s4,0(sp)
    80003dcc:	1800                	addi	s0,sp,48
    80003dce:	89aa                	mv	s3,a0
    80003dd0:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003dd2:	0001c517          	auipc	a0,0x1c
    80003dd6:	4e650513          	addi	a0,a0,1254 # 800202b8 <itable>
    80003dda:	ffffd097          	auipc	ra,0xffffd
    80003dde:	e0a080e7          	jalr	-502(ra) # 80000be4 <acquire>
  empty = 0;
    80003de2:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003de4:	0001c497          	auipc	s1,0x1c
    80003de8:	4ec48493          	addi	s1,s1,1260 # 800202d0 <itable+0x18>
    80003dec:	0001e697          	auipc	a3,0x1e
    80003df0:	f7468693          	addi	a3,a3,-140 # 80021d60 <log>
    80003df4:	a039                	j	80003e02 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003df6:	02090b63          	beqz	s2,80003e2c <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003dfa:	08848493          	addi	s1,s1,136
    80003dfe:	02d48a63          	beq	s1,a3,80003e32 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003e02:	449c                	lw	a5,8(s1)
    80003e04:	fef059e3          	blez	a5,80003df6 <iget+0x38>
    80003e08:	4098                	lw	a4,0(s1)
    80003e0a:	ff3716e3          	bne	a4,s3,80003df6 <iget+0x38>
    80003e0e:	40d8                	lw	a4,4(s1)
    80003e10:	ff4713e3          	bne	a4,s4,80003df6 <iget+0x38>
      ip->ref++;
    80003e14:	2785                	addiw	a5,a5,1
    80003e16:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003e18:	0001c517          	auipc	a0,0x1c
    80003e1c:	4a050513          	addi	a0,a0,1184 # 800202b8 <itable>
    80003e20:	ffffd097          	auipc	ra,0xffffd
    80003e24:	e78080e7          	jalr	-392(ra) # 80000c98 <release>
      return ip;
    80003e28:	8926                	mv	s2,s1
    80003e2a:	a03d                	j	80003e58 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003e2c:	f7f9                	bnez	a5,80003dfa <iget+0x3c>
    80003e2e:	8926                	mv	s2,s1
    80003e30:	b7e9                	j	80003dfa <iget+0x3c>
  if(empty == 0)
    80003e32:	02090c63          	beqz	s2,80003e6a <iget+0xac>
  ip->dev = dev;
    80003e36:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003e3a:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003e3e:	4785                	li	a5,1
    80003e40:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003e44:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003e48:	0001c517          	auipc	a0,0x1c
    80003e4c:	47050513          	addi	a0,a0,1136 # 800202b8 <itable>
    80003e50:	ffffd097          	auipc	ra,0xffffd
    80003e54:	e48080e7          	jalr	-440(ra) # 80000c98 <release>
}
    80003e58:	854a                	mv	a0,s2
    80003e5a:	70a2                	ld	ra,40(sp)
    80003e5c:	7402                	ld	s0,32(sp)
    80003e5e:	64e2                	ld	s1,24(sp)
    80003e60:	6942                	ld	s2,16(sp)
    80003e62:	69a2                	ld	s3,8(sp)
    80003e64:	6a02                	ld	s4,0(sp)
    80003e66:	6145                	addi	sp,sp,48
    80003e68:	8082                	ret
    panic("iget: no inodes");
    80003e6a:	00004517          	auipc	a0,0x4
    80003e6e:	79650513          	addi	a0,a0,1942 # 80008600 <syscalls+0x148>
    80003e72:	ffffc097          	auipc	ra,0xffffc
    80003e76:	6cc080e7          	jalr	1740(ra) # 8000053e <panic>

0000000080003e7a <fsinit>:
fsinit(int dev) {
    80003e7a:	7179                	addi	sp,sp,-48
    80003e7c:	f406                	sd	ra,40(sp)
    80003e7e:	f022                	sd	s0,32(sp)
    80003e80:	ec26                	sd	s1,24(sp)
    80003e82:	e84a                	sd	s2,16(sp)
    80003e84:	e44e                	sd	s3,8(sp)
    80003e86:	1800                	addi	s0,sp,48
    80003e88:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003e8a:	4585                	li	a1,1
    80003e8c:	00000097          	auipc	ra,0x0
    80003e90:	a64080e7          	jalr	-1436(ra) # 800038f0 <bread>
    80003e94:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003e96:	0001c997          	auipc	s3,0x1c
    80003e9a:	40298993          	addi	s3,s3,1026 # 80020298 <sb>
    80003e9e:	02000613          	li	a2,32
    80003ea2:	05850593          	addi	a1,a0,88
    80003ea6:	854e                	mv	a0,s3
    80003ea8:	ffffd097          	auipc	ra,0xffffd
    80003eac:	e98080e7          	jalr	-360(ra) # 80000d40 <memmove>
  brelse(bp);
    80003eb0:	8526                	mv	a0,s1
    80003eb2:	00000097          	auipc	ra,0x0
    80003eb6:	b6e080e7          	jalr	-1170(ra) # 80003a20 <brelse>
  if(sb.magic != FSMAGIC)
    80003eba:	0009a703          	lw	a4,0(s3)
    80003ebe:	102037b7          	lui	a5,0x10203
    80003ec2:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003ec6:	02f71263          	bne	a4,a5,80003eea <fsinit+0x70>
  initlog(dev, &sb);
    80003eca:	0001c597          	auipc	a1,0x1c
    80003ece:	3ce58593          	addi	a1,a1,974 # 80020298 <sb>
    80003ed2:	854a                	mv	a0,s2
    80003ed4:	00001097          	auipc	ra,0x1
    80003ed8:	b4c080e7          	jalr	-1204(ra) # 80004a20 <initlog>
}
    80003edc:	70a2                	ld	ra,40(sp)
    80003ede:	7402                	ld	s0,32(sp)
    80003ee0:	64e2                	ld	s1,24(sp)
    80003ee2:	6942                	ld	s2,16(sp)
    80003ee4:	69a2                	ld	s3,8(sp)
    80003ee6:	6145                	addi	sp,sp,48
    80003ee8:	8082                	ret
    panic("invalid file system");
    80003eea:	00004517          	auipc	a0,0x4
    80003eee:	72650513          	addi	a0,a0,1830 # 80008610 <syscalls+0x158>
    80003ef2:	ffffc097          	auipc	ra,0xffffc
    80003ef6:	64c080e7          	jalr	1612(ra) # 8000053e <panic>

0000000080003efa <iinit>:
{
    80003efa:	7179                	addi	sp,sp,-48
    80003efc:	f406                	sd	ra,40(sp)
    80003efe:	f022                	sd	s0,32(sp)
    80003f00:	ec26                	sd	s1,24(sp)
    80003f02:	e84a                	sd	s2,16(sp)
    80003f04:	e44e                	sd	s3,8(sp)
    80003f06:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003f08:	00004597          	auipc	a1,0x4
    80003f0c:	72058593          	addi	a1,a1,1824 # 80008628 <syscalls+0x170>
    80003f10:	0001c517          	auipc	a0,0x1c
    80003f14:	3a850513          	addi	a0,a0,936 # 800202b8 <itable>
    80003f18:	ffffd097          	auipc	ra,0xffffd
    80003f1c:	c3c080e7          	jalr	-964(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003f20:	0001c497          	auipc	s1,0x1c
    80003f24:	3c048493          	addi	s1,s1,960 # 800202e0 <itable+0x28>
    80003f28:	0001e997          	auipc	s3,0x1e
    80003f2c:	e4898993          	addi	s3,s3,-440 # 80021d70 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003f30:	00004917          	auipc	s2,0x4
    80003f34:	70090913          	addi	s2,s2,1792 # 80008630 <syscalls+0x178>
    80003f38:	85ca                	mv	a1,s2
    80003f3a:	8526                	mv	a0,s1
    80003f3c:	00001097          	auipc	ra,0x1
    80003f40:	e46080e7          	jalr	-442(ra) # 80004d82 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003f44:	08848493          	addi	s1,s1,136
    80003f48:	ff3498e3          	bne	s1,s3,80003f38 <iinit+0x3e>
}
    80003f4c:	70a2                	ld	ra,40(sp)
    80003f4e:	7402                	ld	s0,32(sp)
    80003f50:	64e2                	ld	s1,24(sp)
    80003f52:	6942                	ld	s2,16(sp)
    80003f54:	69a2                	ld	s3,8(sp)
    80003f56:	6145                	addi	sp,sp,48
    80003f58:	8082                	ret

0000000080003f5a <ialloc>:
{
    80003f5a:	715d                	addi	sp,sp,-80
    80003f5c:	e486                	sd	ra,72(sp)
    80003f5e:	e0a2                	sd	s0,64(sp)
    80003f60:	fc26                	sd	s1,56(sp)
    80003f62:	f84a                	sd	s2,48(sp)
    80003f64:	f44e                	sd	s3,40(sp)
    80003f66:	f052                	sd	s4,32(sp)
    80003f68:	ec56                	sd	s5,24(sp)
    80003f6a:	e85a                	sd	s6,16(sp)
    80003f6c:	e45e                	sd	s7,8(sp)
    80003f6e:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003f70:	0001c717          	auipc	a4,0x1c
    80003f74:	33472703          	lw	a4,820(a4) # 800202a4 <sb+0xc>
    80003f78:	4785                	li	a5,1
    80003f7a:	04e7fa63          	bgeu	a5,a4,80003fce <ialloc+0x74>
    80003f7e:	8aaa                	mv	s5,a0
    80003f80:	8bae                	mv	s7,a1
    80003f82:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003f84:	0001ca17          	auipc	s4,0x1c
    80003f88:	314a0a13          	addi	s4,s4,788 # 80020298 <sb>
    80003f8c:	00048b1b          	sext.w	s6,s1
    80003f90:	0044d593          	srli	a1,s1,0x4
    80003f94:	018a2783          	lw	a5,24(s4)
    80003f98:	9dbd                	addw	a1,a1,a5
    80003f9a:	8556                	mv	a0,s5
    80003f9c:	00000097          	auipc	ra,0x0
    80003fa0:	954080e7          	jalr	-1708(ra) # 800038f0 <bread>
    80003fa4:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003fa6:	05850993          	addi	s3,a0,88
    80003faa:	00f4f793          	andi	a5,s1,15
    80003fae:	079a                	slli	a5,a5,0x6
    80003fb0:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003fb2:	00099783          	lh	a5,0(s3)
    80003fb6:	c785                	beqz	a5,80003fde <ialloc+0x84>
    brelse(bp);
    80003fb8:	00000097          	auipc	ra,0x0
    80003fbc:	a68080e7          	jalr	-1432(ra) # 80003a20 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003fc0:	0485                	addi	s1,s1,1
    80003fc2:	00ca2703          	lw	a4,12(s4)
    80003fc6:	0004879b          	sext.w	a5,s1
    80003fca:	fce7e1e3          	bltu	a5,a4,80003f8c <ialloc+0x32>
  panic("ialloc: no inodes");
    80003fce:	00004517          	auipc	a0,0x4
    80003fd2:	66a50513          	addi	a0,a0,1642 # 80008638 <syscalls+0x180>
    80003fd6:	ffffc097          	auipc	ra,0xffffc
    80003fda:	568080e7          	jalr	1384(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003fde:	04000613          	li	a2,64
    80003fe2:	4581                	li	a1,0
    80003fe4:	854e                	mv	a0,s3
    80003fe6:	ffffd097          	auipc	ra,0xffffd
    80003fea:	cfa080e7          	jalr	-774(ra) # 80000ce0 <memset>
      dip->type = type;
    80003fee:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003ff2:	854a                	mv	a0,s2
    80003ff4:	00001097          	auipc	ra,0x1
    80003ff8:	ca8080e7          	jalr	-856(ra) # 80004c9c <log_write>
      brelse(bp);
    80003ffc:	854a                	mv	a0,s2
    80003ffe:	00000097          	auipc	ra,0x0
    80004002:	a22080e7          	jalr	-1502(ra) # 80003a20 <brelse>
      return iget(dev, inum);
    80004006:	85da                	mv	a1,s6
    80004008:	8556                	mv	a0,s5
    8000400a:	00000097          	auipc	ra,0x0
    8000400e:	db4080e7          	jalr	-588(ra) # 80003dbe <iget>
}
    80004012:	60a6                	ld	ra,72(sp)
    80004014:	6406                	ld	s0,64(sp)
    80004016:	74e2                	ld	s1,56(sp)
    80004018:	7942                	ld	s2,48(sp)
    8000401a:	79a2                	ld	s3,40(sp)
    8000401c:	7a02                	ld	s4,32(sp)
    8000401e:	6ae2                	ld	s5,24(sp)
    80004020:	6b42                	ld	s6,16(sp)
    80004022:	6ba2                	ld	s7,8(sp)
    80004024:	6161                	addi	sp,sp,80
    80004026:	8082                	ret

0000000080004028 <iupdate>:
{
    80004028:	1101                	addi	sp,sp,-32
    8000402a:	ec06                	sd	ra,24(sp)
    8000402c:	e822                	sd	s0,16(sp)
    8000402e:	e426                	sd	s1,8(sp)
    80004030:	e04a                	sd	s2,0(sp)
    80004032:	1000                	addi	s0,sp,32
    80004034:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80004036:	415c                	lw	a5,4(a0)
    80004038:	0047d79b          	srliw	a5,a5,0x4
    8000403c:	0001c597          	auipc	a1,0x1c
    80004040:	2745a583          	lw	a1,628(a1) # 800202b0 <sb+0x18>
    80004044:	9dbd                	addw	a1,a1,a5
    80004046:	4108                	lw	a0,0(a0)
    80004048:	00000097          	auipc	ra,0x0
    8000404c:	8a8080e7          	jalr	-1880(ra) # 800038f0 <bread>
    80004050:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80004052:	05850793          	addi	a5,a0,88
    80004056:	40c8                	lw	a0,4(s1)
    80004058:	893d                	andi	a0,a0,15
    8000405a:	051a                	slli	a0,a0,0x6
    8000405c:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000405e:	04449703          	lh	a4,68(s1)
    80004062:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80004066:	04649703          	lh	a4,70(s1)
    8000406a:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    8000406e:	04849703          	lh	a4,72(s1)
    80004072:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80004076:	04a49703          	lh	a4,74(s1)
    8000407a:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000407e:	44f8                	lw	a4,76(s1)
    80004080:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80004082:	03400613          	li	a2,52
    80004086:	05048593          	addi	a1,s1,80
    8000408a:	0531                	addi	a0,a0,12
    8000408c:	ffffd097          	auipc	ra,0xffffd
    80004090:	cb4080e7          	jalr	-844(ra) # 80000d40 <memmove>
  log_write(bp);
    80004094:	854a                	mv	a0,s2
    80004096:	00001097          	auipc	ra,0x1
    8000409a:	c06080e7          	jalr	-1018(ra) # 80004c9c <log_write>
  brelse(bp);
    8000409e:	854a                	mv	a0,s2
    800040a0:	00000097          	auipc	ra,0x0
    800040a4:	980080e7          	jalr	-1664(ra) # 80003a20 <brelse>
}
    800040a8:	60e2                	ld	ra,24(sp)
    800040aa:	6442                	ld	s0,16(sp)
    800040ac:	64a2                	ld	s1,8(sp)
    800040ae:	6902                	ld	s2,0(sp)
    800040b0:	6105                	addi	sp,sp,32
    800040b2:	8082                	ret

00000000800040b4 <idup>:
{
    800040b4:	1101                	addi	sp,sp,-32
    800040b6:	ec06                	sd	ra,24(sp)
    800040b8:	e822                	sd	s0,16(sp)
    800040ba:	e426                	sd	s1,8(sp)
    800040bc:	1000                	addi	s0,sp,32
    800040be:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800040c0:	0001c517          	auipc	a0,0x1c
    800040c4:	1f850513          	addi	a0,a0,504 # 800202b8 <itable>
    800040c8:	ffffd097          	auipc	ra,0xffffd
    800040cc:	b1c080e7          	jalr	-1252(ra) # 80000be4 <acquire>
  ip->ref++;
    800040d0:	449c                	lw	a5,8(s1)
    800040d2:	2785                	addiw	a5,a5,1
    800040d4:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800040d6:	0001c517          	auipc	a0,0x1c
    800040da:	1e250513          	addi	a0,a0,482 # 800202b8 <itable>
    800040de:	ffffd097          	auipc	ra,0xffffd
    800040e2:	bba080e7          	jalr	-1094(ra) # 80000c98 <release>
}
    800040e6:	8526                	mv	a0,s1
    800040e8:	60e2                	ld	ra,24(sp)
    800040ea:	6442                	ld	s0,16(sp)
    800040ec:	64a2                	ld	s1,8(sp)
    800040ee:	6105                	addi	sp,sp,32
    800040f0:	8082                	ret

00000000800040f2 <ilock>:
{
    800040f2:	1101                	addi	sp,sp,-32
    800040f4:	ec06                	sd	ra,24(sp)
    800040f6:	e822                	sd	s0,16(sp)
    800040f8:	e426                	sd	s1,8(sp)
    800040fa:	e04a                	sd	s2,0(sp)
    800040fc:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800040fe:	c115                	beqz	a0,80004122 <ilock+0x30>
    80004100:	84aa                	mv	s1,a0
    80004102:	451c                	lw	a5,8(a0)
    80004104:	00f05f63          	blez	a5,80004122 <ilock+0x30>
  acquiresleep(&ip->lock);
    80004108:	0541                	addi	a0,a0,16
    8000410a:	00001097          	auipc	ra,0x1
    8000410e:	cb2080e7          	jalr	-846(ra) # 80004dbc <acquiresleep>
  if(ip->valid == 0){
    80004112:	40bc                	lw	a5,64(s1)
    80004114:	cf99                	beqz	a5,80004132 <ilock+0x40>
}
    80004116:	60e2                	ld	ra,24(sp)
    80004118:	6442                	ld	s0,16(sp)
    8000411a:	64a2                	ld	s1,8(sp)
    8000411c:	6902                	ld	s2,0(sp)
    8000411e:	6105                	addi	sp,sp,32
    80004120:	8082                	ret
    panic("ilock");
    80004122:	00004517          	auipc	a0,0x4
    80004126:	52e50513          	addi	a0,a0,1326 # 80008650 <syscalls+0x198>
    8000412a:	ffffc097          	auipc	ra,0xffffc
    8000412e:	414080e7          	jalr	1044(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80004132:	40dc                	lw	a5,4(s1)
    80004134:	0047d79b          	srliw	a5,a5,0x4
    80004138:	0001c597          	auipc	a1,0x1c
    8000413c:	1785a583          	lw	a1,376(a1) # 800202b0 <sb+0x18>
    80004140:	9dbd                	addw	a1,a1,a5
    80004142:	4088                	lw	a0,0(s1)
    80004144:	fffff097          	auipc	ra,0xfffff
    80004148:	7ac080e7          	jalr	1964(ra) # 800038f0 <bread>
    8000414c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000414e:	05850593          	addi	a1,a0,88
    80004152:	40dc                	lw	a5,4(s1)
    80004154:	8bbd                	andi	a5,a5,15
    80004156:	079a                	slli	a5,a5,0x6
    80004158:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000415a:	00059783          	lh	a5,0(a1)
    8000415e:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80004162:	00259783          	lh	a5,2(a1)
    80004166:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000416a:	00459783          	lh	a5,4(a1)
    8000416e:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80004172:	00659783          	lh	a5,6(a1)
    80004176:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000417a:	459c                	lw	a5,8(a1)
    8000417c:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000417e:	03400613          	li	a2,52
    80004182:	05b1                	addi	a1,a1,12
    80004184:	05048513          	addi	a0,s1,80
    80004188:	ffffd097          	auipc	ra,0xffffd
    8000418c:	bb8080e7          	jalr	-1096(ra) # 80000d40 <memmove>
    brelse(bp);
    80004190:	854a                	mv	a0,s2
    80004192:	00000097          	auipc	ra,0x0
    80004196:	88e080e7          	jalr	-1906(ra) # 80003a20 <brelse>
    ip->valid = 1;
    8000419a:	4785                	li	a5,1
    8000419c:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000419e:	04449783          	lh	a5,68(s1)
    800041a2:	fbb5                	bnez	a5,80004116 <ilock+0x24>
      panic("ilock: no type");
    800041a4:	00004517          	auipc	a0,0x4
    800041a8:	4b450513          	addi	a0,a0,1204 # 80008658 <syscalls+0x1a0>
    800041ac:	ffffc097          	auipc	ra,0xffffc
    800041b0:	392080e7          	jalr	914(ra) # 8000053e <panic>

00000000800041b4 <iunlock>:
{
    800041b4:	1101                	addi	sp,sp,-32
    800041b6:	ec06                	sd	ra,24(sp)
    800041b8:	e822                	sd	s0,16(sp)
    800041ba:	e426                	sd	s1,8(sp)
    800041bc:	e04a                	sd	s2,0(sp)
    800041be:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800041c0:	c905                	beqz	a0,800041f0 <iunlock+0x3c>
    800041c2:	84aa                	mv	s1,a0
    800041c4:	01050913          	addi	s2,a0,16
    800041c8:	854a                	mv	a0,s2
    800041ca:	00001097          	auipc	ra,0x1
    800041ce:	c8c080e7          	jalr	-884(ra) # 80004e56 <holdingsleep>
    800041d2:	cd19                	beqz	a0,800041f0 <iunlock+0x3c>
    800041d4:	449c                	lw	a5,8(s1)
    800041d6:	00f05d63          	blez	a5,800041f0 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800041da:	854a                	mv	a0,s2
    800041dc:	00001097          	auipc	ra,0x1
    800041e0:	c36080e7          	jalr	-970(ra) # 80004e12 <releasesleep>
}
    800041e4:	60e2                	ld	ra,24(sp)
    800041e6:	6442                	ld	s0,16(sp)
    800041e8:	64a2                	ld	s1,8(sp)
    800041ea:	6902                	ld	s2,0(sp)
    800041ec:	6105                	addi	sp,sp,32
    800041ee:	8082                	ret
    panic("iunlock");
    800041f0:	00004517          	auipc	a0,0x4
    800041f4:	47850513          	addi	a0,a0,1144 # 80008668 <syscalls+0x1b0>
    800041f8:	ffffc097          	auipc	ra,0xffffc
    800041fc:	346080e7          	jalr	838(ra) # 8000053e <panic>

0000000080004200 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80004200:	7179                	addi	sp,sp,-48
    80004202:	f406                	sd	ra,40(sp)
    80004204:	f022                	sd	s0,32(sp)
    80004206:	ec26                	sd	s1,24(sp)
    80004208:	e84a                	sd	s2,16(sp)
    8000420a:	e44e                	sd	s3,8(sp)
    8000420c:	e052                	sd	s4,0(sp)
    8000420e:	1800                	addi	s0,sp,48
    80004210:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80004212:	05050493          	addi	s1,a0,80
    80004216:	08050913          	addi	s2,a0,128
    8000421a:	a021                	j	80004222 <itrunc+0x22>
    8000421c:	0491                	addi	s1,s1,4
    8000421e:	01248d63          	beq	s1,s2,80004238 <itrunc+0x38>
    if(ip->addrs[i]){
    80004222:	408c                	lw	a1,0(s1)
    80004224:	dde5                	beqz	a1,8000421c <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80004226:	0009a503          	lw	a0,0(s3)
    8000422a:	00000097          	auipc	ra,0x0
    8000422e:	90c080e7          	jalr	-1780(ra) # 80003b36 <bfree>
      ip->addrs[i] = 0;
    80004232:	0004a023          	sw	zero,0(s1)
    80004236:	b7dd                	j	8000421c <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80004238:	0809a583          	lw	a1,128(s3)
    8000423c:	e185                	bnez	a1,8000425c <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000423e:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80004242:	854e                	mv	a0,s3
    80004244:	00000097          	auipc	ra,0x0
    80004248:	de4080e7          	jalr	-540(ra) # 80004028 <iupdate>
}
    8000424c:	70a2                	ld	ra,40(sp)
    8000424e:	7402                	ld	s0,32(sp)
    80004250:	64e2                	ld	s1,24(sp)
    80004252:	6942                	ld	s2,16(sp)
    80004254:	69a2                	ld	s3,8(sp)
    80004256:	6a02                	ld	s4,0(sp)
    80004258:	6145                	addi	sp,sp,48
    8000425a:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000425c:	0009a503          	lw	a0,0(s3)
    80004260:	fffff097          	auipc	ra,0xfffff
    80004264:	690080e7          	jalr	1680(ra) # 800038f0 <bread>
    80004268:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    8000426a:	05850493          	addi	s1,a0,88
    8000426e:	45850913          	addi	s2,a0,1112
    80004272:	a811                	j	80004286 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80004274:	0009a503          	lw	a0,0(s3)
    80004278:	00000097          	auipc	ra,0x0
    8000427c:	8be080e7          	jalr	-1858(ra) # 80003b36 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80004280:	0491                	addi	s1,s1,4
    80004282:	01248563          	beq	s1,s2,8000428c <itrunc+0x8c>
      if(a[j])
    80004286:	408c                	lw	a1,0(s1)
    80004288:	dde5                	beqz	a1,80004280 <itrunc+0x80>
    8000428a:	b7ed                	j	80004274 <itrunc+0x74>
    brelse(bp);
    8000428c:	8552                	mv	a0,s4
    8000428e:	fffff097          	auipc	ra,0xfffff
    80004292:	792080e7          	jalr	1938(ra) # 80003a20 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80004296:	0809a583          	lw	a1,128(s3)
    8000429a:	0009a503          	lw	a0,0(s3)
    8000429e:	00000097          	auipc	ra,0x0
    800042a2:	898080e7          	jalr	-1896(ra) # 80003b36 <bfree>
    ip->addrs[NDIRECT] = 0;
    800042a6:	0809a023          	sw	zero,128(s3)
    800042aa:	bf51                	j	8000423e <itrunc+0x3e>

00000000800042ac <iput>:
{
    800042ac:	1101                	addi	sp,sp,-32
    800042ae:	ec06                	sd	ra,24(sp)
    800042b0:	e822                	sd	s0,16(sp)
    800042b2:	e426                	sd	s1,8(sp)
    800042b4:	e04a                	sd	s2,0(sp)
    800042b6:	1000                	addi	s0,sp,32
    800042b8:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800042ba:	0001c517          	auipc	a0,0x1c
    800042be:	ffe50513          	addi	a0,a0,-2 # 800202b8 <itable>
    800042c2:	ffffd097          	auipc	ra,0xffffd
    800042c6:	922080e7          	jalr	-1758(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800042ca:	4498                	lw	a4,8(s1)
    800042cc:	4785                	li	a5,1
    800042ce:	02f70363          	beq	a4,a5,800042f4 <iput+0x48>
  ip->ref--;
    800042d2:	449c                	lw	a5,8(s1)
    800042d4:	37fd                	addiw	a5,a5,-1
    800042d6:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800042d8:	0001c517          	auipc	a0,0x1c
    800042dc:	fe050513          	addi	a0,a0,-32 # 800202b8 <itable>
    800042e0:	ffffd097          	auipc	ra,0xffffd
    800042e4:	9b8080e7          	jalr	-1608(ra) # 80000c98 <release>
}
    800042e8:	60e2                	ld	ra,24(sp)
    800042ea:	6442                	ld	s0,16(sp)
    800042ec:	64a2                	ld	s1,8(sp)
    800042ee:	6902                	ld	s2,0(sp)
    800042f0:	6105                	addi	sp,sp,32
    800042f2:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800042f4:	40bc                	lw	a5,64(s1)
    800042f6:	dff1                	beqz	a5,800042d2 <iput+0x26>
    800042f8:	04a49783          	lh	a5,74(s1)
    800042fc:	fbf9                	bnez	a5,800042d2 <iput+0x26>
    acquiresleep(&ip->lock);
    800042fe:	01048913          	addi	s2,s1,16
    80004302:	854a                	mv	a0,s2
    80004304:	00001097          	auipc	ra,0x1
    80004308:	ab8080e7          	jalr	-1352(ra) # 80004dbc <acquiresleep>
    release(&itable.lock);
    8000430c:	0001c517          	auipc	a0,0x1c
    80004310:	fac50513          	addi	a0,a0,-84 # 800202b8 <itable>
    80004314:	ffffd097          	auipc	ra,0xffffd
    80004318:	984080e7          	jalr	-1660(ra) # 80000c98 <release>
    itrunc(ip);
    8000431c:	8526                	mv	a0,s1
    8000431e:	00000097          	auipc	ra,0x0
    80004322:	ee2080e7          	jalr	-286(ra) # 80004200 <itrunc>
    ip->type = 0;
    80004326:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    8000432a:	8526                	mv	a0,s1
    8000432c:	00000097          	auipc	ra,0x0
    80004330:	cfc080e7          	jalr	-772(ra) # 80004028 <iupdate>
    ip->valid = 0;
    80004334:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80004338:	854a                	mv	a0,s2
    8000433a:	00001097          	auipc	ra,0x1
    8000433e:	ad8080e7          	jalr	-1320(ra) # 80004e12 <releasesleep>
    acquire(&itable.lock);
    80004342:	0001c517          	auipc	a0,0x1c
    80004346:	f7650513          	addi	a0,a0,-138 # 800202b8 <itable>
    8000434a:	ffffd097          	auipc	ra,0xffffd
    8000434e:	89a080e7          	jalr	-1894(ra) # 80000be4 <acquire>
    80004352:	b741                	j	800042d2 <iput+0x26>

0000000080004354 <iunlockput>:
{
    80004354:	1101                	addi	sp,sp,-32
    80004356:	ec06                	sd	ra,24(sp)
    80004358:	e822                	sd	s0,16(sp)
    8000435a:	e426                	sd	s1,8(sp)
    8000435c:	1000                	addi	s0,sp,32
    8000435e:	84aa                	mv	s1,a0
  iunlock(ip);
    80004360:	00000097          	auipc	ra,0x0
    80004364:	e54080e7          	jalr	-428(ra) # 800041b4 <iunlock>
  iput(ip);
    80004368:	8526                	mv	a0,s1
    8000436a:	00000097          	auipc	ra,0x0
    8000436e:	f42080e7          	jalr	-190(ra) # 800042ac <iput>
}
    80004372:	60e2                	ld	ra,24(sp)
    80004374:	6442                	ld	s0,16(sp)
    80004376:	64a2                	ld	s1,8(sp)
    80004378:	6105                	addi	sp,sp,32
    8000437a:	8082                	ret

000000008000437c <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    8000437c:	1141                	addi	sp,sp,-16
    8000437e:	e422                	sd	s0,8(sp)
    80004380:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80004382:	411c                	lw	a5,0(a0)
    80004384:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80004386:	415c                	lw	a5,4(a0)
    80004388:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    8000438a:	04451783          	lh	a5,68(a0)
    8000438e:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80004392:	04a51783          	lh	a5,74(a0)
    80004396:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    8000439a:	04c56783          	lwu	a5,76(a0)
    8000439e:	e99c                	sd	a5,16(a1)
}
    800043a0:	6422                	ld	s0,8(sp)
    800043a2:	0141                	addi	sp,sp,16
    800043a4:	8082                	ret

00000000800043a6 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800043a6:	457c                	lw	a5,76(a0)
    800043a8:	0ed7e963          	bltu	a5,a3,8000449a <readi+0xf4>
{
    800043ac:	7159                	addi	sp,sp,-112
    800043ae:	f486                	sd	ra,104(sp)
    800043b0:	f0a2                	sd	s0,96(sp)
    800043b2:	eca6                	sd	s1,88(sp)
    800043b4:	e8ca                	sd	s2,80(sp)
    800043b6:	e4ce                	sd	s3,72(sp)
    800043b8:	e0d2                	sd	s4,64(sp)
    800043ba:	fc56                	sd	s5,56(sp)
    800043bc:	f85a                	sd	s6,48(sp)
    800043be:	f45e                	sd	s7,40(sp)
    800043c0:	f062                	sd	s8,32(sp)
    800043c2:	ec66                	sd	s9,24(sp)
    800043c4:	e86a                	sd	s10,16(sp)
    800043c6:	e46e                	sd	s11,8(sp)
    800043c8:	1880                	addi	s0,sp,112
    800043ca:	8baa                	mv	s7,a0
    800043cc:	8c2e                	mv	s8,a1
    800043ce:	8ab2                	mv	s5,a2
    800043d0:	84b6                	mv	s1,a3
    800043d2:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800043d4:	9f35                	addw	a4,a4,a3
    return 0;
    800043d6:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800043d8:	0ad76063          	bltu	a4,a3,80004478 <readi+0xd2>
  if(off + n > ip->size)
    800043dc:	00e7f463          	bgeu	a5,a4,800043e4 <readi+0x3e>
    n = ip->size - off;
    800043e0:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800043e4:	0a0b0963          	beqz	s6,80004496 <readi+0xf0>
    800043e8:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800043ea:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800043ee:	5cfd                	li	s9,-1
    800043f0:	a82d                	j	8000442a <readi+0x84>
    800043f2:	020a1d93          	slli	s11,s4,0x20
    800043f6:	020ddd93          	srli	s11,s11,0x20
    800043fa:	05890613          	addi	a2,s2,88
    800043fe:	86ee                	mv	a3,s11
    80004400:	963a                	add	a2,a2,a4
    80004402:	85d6                	mv	a1,s5
    80004404:	8562                	mv	a0,s8
    80004406:	ffffe097          	auipc	ra,0xffffe
    8000440a:	6c0080e7          	jalr	1728(ra) # 80002ac6 <either_copyout>
    8000440e:	05950d63          	beq	a0,s9,80004468 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004412:	854a                	mv	a0,s2
    80004414:	fffff097          	auipc	ra,0xfffff
    80004418:	60c080e7          	jalr	1548(ra) # 80003a20 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000441c:	013a09bb          	addw	s3,s4,s3
    80004420:	009a04bb          	addw	s1,s4,s1
    80004424:	9aee                	add	s5,s5,s11
    80004426:	0569f763          	bgeu	s3,s6,80004474 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    8000442a:	000ba903          	lw	s2,0(s7)
    8000442e:	00a4d59b          	srliw	a1,s1,0xa
    80004432:	855e                	mv	a0,s7
    80004434:	00000097          	auipc	ra,0x0
    80004438:	8b0080e7          	jalr	-1872(ra) # 80003ce4 <bmap>
    8000443c:	0005059b          	sext.w	a1,a0
    80004440:	854a                	mv	a0,s2
    80004442:	fffff097          	auipc	ra,0xfffff
    80004446:	4ae080e7          	jalr	1198(ra) # 800038f0 <bread>
    8000444a:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000444c:	3ff4f713          	andi	a4,s1,1023
    80004450:	40ed07bb          	subw	a5,s10,a4
    80004454:	413b06bb          	subw	a3,s6,s3
    80004458:	8a3e                	mv	s4,a5
    8000445a:	2781                	sext.w	a5,a5
    8000445c:	0006861b          	sext.w	a2,a3
    80004460:	f8f679e3          	bgeu	a2,a5,800043f2 <readi+0x4c>
    80004464:	8a36                	mv	s4,a3
    80004466:	b771                	j	800043f2 <readi+0x4c>
      brelse(bp);
    80004468:	854a                	mv	a0,s2
    8000446a:	fffff097          	auipc	ra,0xfffff
    8000446e:	5b6080e7          	jalr	1462(ra) # 80003a20 <brelse>
      tot = -1;
    80004472:	59fd                	li	s3,-1
  }
  return tot;
    80004474:	0009851b          	sext.w	a0,s3
}
    80004478:	70a6                	ld	ra,104(sp)
    8000447a:	7406                	ld	s0,96(sp)
    8000447c:	64e6                	ld	s1,88(sp)
    8000447e:	6946                	ld	s2,80(sp)
    80004480:	69a6                	ld	s3,72(sp)
    80004482:	6a06                	ld	s4,64(sp)
    80004484:	7ae2                	ld	s5,56(sp)
    80004486:	7b42                	ld	s6,48(sp)
    80004488:	7ba2                	ld	s7,40(sp)
    8000448a:	7c02                	ld	s8,32(sp)
    8000448c:	6ce2                	ld	s9,24(sp)
    8000448e:	6d42                	ld	s10,16(sp)
    80004490:	6da2                	ld	s11,8(sp)
    80004492:	6165                	addi	sp,sp,112
    80004494:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004496:	89da                	mv	s3,s6
    80004498:	bff1                	j	80004474 <readi+0xce>
    return 0;
    8000449a:	4501                	li	a0,0
}
    8000449c:	8082                	ret

000000008000449e <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000449e:	457c                	lw	a5,76(a0)
    800044a0:	10d7e863          	bltu	a5,a3,800045b0 <writei+0x112>
{
    800044a4:	7159                	addi	sp,sp,-112
    800044a6:	f486                	sd	ra,104(sp)
    800044a8:	f0a2                	sd	s0,96(sp)
    800044aa:	eca6                	sd	s1,88(sp)
    800044ac:	e8ca                	sd	s2,80(sp)
    800044ae:	e4ce                	sd	s3,72(sp)
    800044b0:	e0d2                	sd	s4,64(sp)
    800044b2:	fc56                	sd	s5,56(sp)
    800044b4:	f85a                	sd	s6,48(sp)
    800044b6:	f45e                	sd	s7,40(sp)
    800044b8:	f062                	sd	s8,32(sp)
    800044ba:	ec66                	sd	s9,24(sp)
    800044bc:	e86a                	sd	s10,16(sp)
    800044be:	e46e                	sd	s11,8(sp)
    800044c0:	1880                	addi	s0,sp,112
    800044c2:	8b2a                	mv	s6,a0
    800044c4:	8c2e                	mv	s8,a1
    800044c6:	8ab2                	mv	s5,a2
    800044c8:	8936                	mv	s2,a3
    800044ca:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    800044cc:	00e687bb          	addw	a5,a3,a4
    800044d0:	0ed7e263          	bltu	a5,a3,800045b4 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800044d4:	00043737          	lui	a4,0x43
    800044d8:	0ef76063          	bltu	a4,a5,800045b8 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800044dc:	0c0b8863          	beqz	s7,800045ac <writei+0x10e>
    800044e0:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800044e2:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800044e6:	5cfd                	li	s9,-1
    800044e8:	a091                	j	8000452c <writei+0x8e>
    800044ea:	02099d93          	slli	s11,s3,0x20
    800044ee:	020ddd93          	srli	s11,s11,0x20
    800044f2:	05848513          	addi	a0,s1,88
    800044f6:	86ee                	mv	a3,s11
    800044f8:	8656                	mv	a2,s5
    800044fa:	85e2                	mv	a1,s8
    800044fc:	953a                	add	a0,a0,a4
    800044fe:	ffffe097          	auipc	ra,0xffffe
    80004502:	61e080e7          	jalr	1566(ra) # 80002b1c <either_copyin>
    80004506:	07950263          	beq	a0,s9,8000456a <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    8000450a:	8526                	mv	a0,s1
    8000450c:	00000097          	auipc	ra,0x0
    80004510:	790080e7          	jalr	1936(ra) # 80004c9c <log_write>
    brelse(bp);
    80004514:	8526                	mv	a0,s1
    80004516:	fffff097          	auipc	ra,0xfffff
    8000451a:	50a080e7          	jalr	1290(ra) # 80003a20 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000451e:	01498a3b          	addw	s4,s3,s4
    80004522:	0129893b          	addw	s2,s3,s2
    80004526:	9aee                	add	s5,s5,s11
    80004528:	057a7663          	bgeu	s4,s7,80004574 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    8000452c:	000b2483          	lw	s1,0(s6)
    80004530:	00a9559b          	srliw	a1,s2,0xa
    80004534:	855a                	mv	a0,s6
    80004536:	fffff097          	auipc	ra,0xfffff
    8000453a:	7ae080e7          	jalr	1966(ra) # 80003ce4 <bmap>
    8000453e:	0005059b          	sext.w	a1,a0
    80004542:	8526                	mv	a0,s1
    80004544:	fffff097          	auipc	ra,0xfffff
    80004548:	3ac080e7          	jalr	940(ra) # 800038f0 <bread>
    8000454c:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000454e:	3ff97713          	andi	a4,s2,1023
    80004552:	40ed07bb          	subw	a5,s10,a4
    80004556:	414b86bb          	subw	a3,s7,s4
    8000455a:	89be                	mv	s3,a5
    8000455c:	2781                	sext.w	a5,a5
    8000455e:	0006861b          	sext.w	a2,a3
    80004562:	f8f674e3          	bgeu	a2,a5,800044ea <writei+0x4c>
    80004566:	89b6                	mv	s3,a3
    80004568:	b749                	j	800044ea <writei+0x4c>
      brelse(bp);
    8000456a:	8526                	mv	a0,s1
    8000456c:	fffff097          	auipc	ra,0xfffff
    80004570:	4b4080e7          	jalr	1204(ra) # 80003a20 <brelse>
  }

  if(off > ip->size)
    80004574:	04cb2783          	lw	a5,76(s6)
    80004578:	0127f463          	bgeu	a5,s2,80004580 <writei+0xe2>
    ip->size = off;
    8000457c:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004580:	855a                	mv	a0,s6
    80004582:	00000097          	auipc	ra,0x0
    80004586:	aa6080e7          	jalr	-1370(ra) # 80004028 <iupdate>

  return tot;
    8000458a:	000a051b          	sext.w	a0,s4
}
    8000458e:	70a6                	ld	ra,104(sp)
    80004590:	7406                	ld	s0,96(sp)
    80004592:	64e6                	ld	s1,88(sp)
    80004594:	6946                	ld	s2,80(sp)
    80004596:	69a6                	ld	s3,72(sp)
    80004598:	6a06                	ld	s4,64(sp)
    8000459a:	7ae2                	ld	s5,56(sp)
    8000459c:	7b42                	ld	s6,48(sp)
    8000459e:	7ba2                	ld	s7,40(sp)
    800045a0:	7c02                	ld	s8,32(sp)
    800045a2:	6ce2                	ld	s9,24(sp)
    800045a4:	6d42                	ld	s10,16(sp)
    800045a6:	6da2                	ld	s11,8(sp)
    800045a8:	6165                	addi	sp,sp,112
    800045aa:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800045ac:	8a5e                	mv	s4,s7
    800045ae:	bfc9                	j	80004580 <writei+0xe2>
    return -1;
    800045b0:	557d                	li	a0,-1
}
    800045b2:	8082                	ret
    return -1;
    800045b4:	557d                	li	a0,-1
    800045b6:	bfe1                	j	8000458e <writei+0xf0>
    return -1;
    800045b8:	557d                	li	a0,-1
    800045ba:	bfd1                	j	8000458e <writei+0xf0>

00000000800045bc <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800045bc:	1141                	addi	sp,sp,-16
    800045be:	e406                	sd	ra,8(sp)
    800045c0:	e022                	sd	s0,0(sp)
    800045c2:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800045c4:	4639                	li	a2,14
    800045c6:	ffffc097          	auipc	ra,0xffffc
    800045ca:	7f2080e7          	jalr	2034(ra) # 80000db8 <strncmp>
}
    800045ce:	60a2                	ld	ra,8(sp)
    800045d0:	6402                	ld	s0,0(sp)
    800045d2:	0141                	addi	sp,sp,16
    800045d4:	8082                	ret

00000000800045d6 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800045d6:	7139                	addi	sp,sp,-64
    800045d8:	fc06                	sd	ra,56(sp)
    800045da:	f822                	sd	s0,48(sp)
    800045dc:	f426                	sd	s1,40(sp)
    800045de:	f04a                	sd	s2,32(sp)
    800045e0:	ec4e                	sd	s3,24(sp)
    800045e2:	e852                	sd	s4,16(sp)
    800045e4:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800045e6:	04451703          	lh	a4,68(a0)
    800045ea:	4785                	li	a5,1
    800045ec:	00f71a63          	bne	a4,a5,80004600 <dirlookup+0x2a>
    800045f0:	892a                	mv	s2,a0
    800045f2:	89ae                	mv	s3,a1
    800045f4:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800045f6:	457c                	lw	a5,76(a0)
    800045f8:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800045fa:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800045fc:	e79d                	bnez	a5,8000462a <dirlookup+0x54>
    800045fe:	a8a5                	j	80004676 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004600:	00004517          	auipc	a0,0x4
    80004604:	07050513          	addi	a0,a0,112 # 80008670 <syscalls+0x1b8>
    80004608:	ffffc097          	auipc	ra,0xffffc
    8000460c:	f36080e7          	jalr	-202(ra) # 8000053e <panic>
      panic("dirlookup read");
    80004610:	00004517          	auipc	a0,0x4
    80004614:	07850513          	addi	a0,a0,120 # 80008688 <syscalls+0x1d0>
    80004618:	ffffc097          	auipc	ra,0xffffc
    8000461c:	f26080e7          	jalr	-218(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004620:	24c1                	addiw	s1,s1,16
    80004622:	04c92783          	lw	a5,76(s2)
    80004626:	04f4f763          	bgeu	s1,a5,80004674 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000462a:	4741                	li	a4,16
    8000462c:	86a6                	mv	a3,s1
    8000462e:	fc040613          	addi	a2,s0,-64
    80004632:	4581                	li	a1,0
    80004634:	854a                	mv	a0,s2
    80004636:	00000097          	auipc	ra,0x0
    8000463a:	d70080e7          	jalr	-656(ra) # 800043a6 <readi>
    8000463e:	47c1                	li	a5,16
    80004640:	fcf518e3          	bne	a0,a5,80004610 <dirlookup+0x3a>
    if(de.inum == 0)
    80004644:	fc045783          	lhu	a5,-64(s0)
    80004648:	dfe1                	beqz	a5,80004620 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    8000464a:	fc240593          	addi	a1,s0,-62
    8000464e:	854e                	mv	a0,s3
    80004650:	00000097          	auipc	ra,0x0
    80004654:	f6c080e7          	jalr	-148(ra) # 800045bc <namecmp>
    80004658:	f561                	bnez	a0,80004620 <dirlookup+0x4a>
      if(poff)
    8000465a:	000a0463          	beqz	s4,80004662 <dirlookup+0x8c>
        *poff = off;
    8000465e:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004662:	fc045583          	lhu	a1,-64(s0)
    80004666:	00092503          	lw	a0,0(s2)
    8000466a:	fffff097          	auipc	ra,0xfffff
    8000466e:	754080e7          	jalr	1876(ra) # 80003dbe <iget>
    80004672:	a011                	j	80004676 <dirlookup+0xa0>
  return 0;
    80004674:	4501                	li	a0,0
}
    80004676:	70e2                	ld	ra,56(sp)
    80004678:	7442                	ld	s0,48(sp)
    8000467a:	74a2                	ld	s1,40(sp)
    8000467c:	7902                	ld	s2,32(sp)
    8000467e:	69e2                	ld	s3,24(sp)
    80004680:	6a42                	ld	s4,16(sp)
    80004682:	6121                	addi	sp,sp,64
    80004684:	8082                	ret

0000000080004686 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004686:	711d                	addi	sp,sp,-96
    80004688:	ec86                	sd	ra,88(sp)
    8000468a:	e8a2                	sd	s0,80(sp)
    8000468c:	e4a6                	sd	s1,72(sp)
    8000468e:	e0ca                	sd	s2,64(sp)
    80004690:	fc4e                	sd	s3,56(sp)
    80004692:	f852                	sd	s4,48(sp)
    80004694:	f456                	sd	s5,40(sp)
    80004696:	f05a                	sd	s6,32(sp)
    80004698:	ec5e                	sd	s7,24(sp)
    8000469a:	e862                	sd	s8,16(sp)
    8000469c:	e466                	sd	s9,8(sp)
    8000469e:	1080                	addi	s0,sp,96
    800046a0:	84aa                	mv	s1,a0
    800046a2:	8b2e                	mv	s6,a1
    800046a4:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800046a6:	00054703          	lbu	a4,0(a0)
    800046aa:	02f00793          	li	a5,47
    800046ae:	02f70363          	beq	a4,a5,800046d4 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800046b2:	ffffd097          	auipc	ra,0xffffd
    800046b6:	7ac080e7          	jalr	1964(ra) # 80001e5e <myproc>
    800046ba:	16853503          	ld	a0,360(a0)
    800046be:	00000097          	auipc	ra,0x0
    800046c2:	9f6080e7          	jalr	-1546(ra) # 800040b4 <idup>
    800046c6:	89aa                	mv	s3,a0
  while(*path == '/')
    800046c8:	02f00913          	li	s2,47
  len = path - s;
    800046cc:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    800046ce:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800046d0:	4c05                	li	s8,1
    800046d2:	a865                	j	8000478a <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800046d4:	4585                	li	a1,1
    800046d6:	4505                	li	a0,1
    800046d8:	fffff097          	auipc	ra,0xfffff
    800046dc:	6e6080e7          	jalr	1766(ra) # 80003dbe <iget>
    800046e0:	89aa                	mv	s3,a0
    800046e2:	b7dd                	j	800046c8 <namex+0x42>
      iunlockput(ip);
    800046e4:	854e                	mv	a0,s3
    800046e6:	00000097          	auipc	ra,0x0
    800046ea:	c6e080e7          	jalr	-914(ra) # 80004354 <iunlockput>
      return 0;
    800046ee:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800046f0:	854e                	mv	a0,s3
    800046f2:	60e6                	ld	ra,88(sp)
    800046f4:	6446                	ld	s0,80(sp)
    800046f6:	64a6                	ld	s1,72(sp)
    800046f8:	6906                	ld	s2,64(sp)
    800046fa:	79e2                	ld	s3,56(sp)
    800046fc:	7a42                	ld	s4,48(sp)
    800046fe:	7aa2                	ld	s5,40(sp)
    80004700:	7b02                	ld	s6,32(sp)
    80004702:	6be2                	ld	s7,24(sp)
    80004704:	6c42                	ld	s8,16(sp)
    80004706:	6ca2                	ld	s9,8(sp)
    80004708:	6125                	addi	sp,sp,96
    8000470a:	8082                	ret
      iunlock(ip);
    8000470c:	854e                	mv	a0,s3
    8000470e:	00000097          	auipc	ra,0x0
    80004712:	aa6080e7          	jalr	-1370(ra) # 800041b4 <iunlock>
      return ip;
    80004716:	bfe9                	j	800046f0 <namex+0x6a>
      iunlockput(ip);
    80004718:	854e                	mv	a0,s3
    8000471a:	00000097          	auipc	ra,0x0
    8000471e:	c3a080e7          	jalr	-966(ra) # 80004354 <iunlockput>
      return 0;
    80004722:	89d2                	mv	s3,s4
    80004724:	b7f1                	j	800046f0 <namex+0x6a>
  len = path - s;
    80004726:	40b48633          	sub	a2,s1,a1
    8000472a:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    8000472e:	094cd463          	bge	s9,s4,800047b6 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004732:	4639                	li	a2,14
    80004734:	8556                	mv	a0,s5
    80004736:	ffffc097          	auipc	ra,0xffffc
    8000473a:	60a080e7          	jalr	1546(ra) # 80000d40 <memmove>
  while(*path == '/')
    8000473e:	0004c783          	lbu	a5,0(s1)
    80004742:	01279763          	bne	a5,s2,80004750 <namex+0xca>
    path++;
    80004746:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004748:	0004c783          	lbu	a5,0(s1)
    8000474c:	ff278de3          	beq	a5,s2,80004746 <namex+0xc0>
    ilock(ip);
    80004750:	854e                	mv	a0,s3
    80004752:	00000097          	auipc	ra,0x0
    80004756:	9a0080e7          	jalr	-1632(ra) # 800040f2 <ilock>
    if(ip->type != T_DIR){
    8000475a:	04499783          	lh	a5,68(s3)
    8000475e:	f98793e3          	bne	a5,s8,800046e4 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004762:	000b0563          	beqz	s6,8000476c <namex+0xe6>
    80004766:	0004c783          	lbu	a5,0(s1)
    8000476a:	d3cd                	beqz	a5,8000470c <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000476c:	865e                	mv	a2,s7
    8000476e:	85d6                	mv	a1,s5
    80004770:	854e                	mv	a0,s3
    80004772:	00000097          	auipc	ra,0x0
    80004776:	e64080e7          	jalr	-412(ra) # 800045d6 <dirlookup>
    8000477a:	8a2a                	mv	s4,a0
    8000477c:	dd51                	beqz	a0,80004718 <namex+0x92>
    iunlockput(ip);
    8000477e:	854e                	mv	a0,s3
    80004780:	00000097          	auipc	ra,0x0
    80004784:	bd4080e7          	jalr	-1068(ra) # 80004354 <iunlockput>
    ip = next;
    80004788:	89d2                	mv	s3,s4
  while(*path == '/')
    8000478a:	0004c783          	lbu	a5,0(s1)
    8000478e:	05279763          	bne	a5,s2,800047dc <namex+0x156>
    path++;
    80004792:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004794:	0004c783          	lbu	a5,0(s1)
    80004798:	ff278de3          	beq	a5,s2,80004792 <namex+0x10c>
  if(*path == 0)
    8000479c:	c79d                	beqz	a5,800047ca <namex+0x144>
    path++;
    8000479e:	85a6                	mv	a1,s1
  len = path - s;
    800047a0:	8a5e                	mv	s4,s7
    800047a2:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800047a4:	01278963          	beq	a5,s2,800047b6 <namex+0x130>
    800047a8:	dfbd                	beqz	a5,80004726 <namex+0xa0>
    path++;
    800047aa:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800047ac:	0004c783          	lbu	a5,0(s1)
    800047b0:	ff279ce3          	bne	a5,s2,800047a8 <namex+0x122>
    800047b4:	bf8d                	j	80004726 <namex+0xa0>
    memmove(name, s, len);
    800047b6:	2601                	sext.w	a2,a2
    800047b8:	8556                	mv	a0,s5
    800047ba:	ffffc097          	auipc	ra,0xffffc
    800047be:	586080e7          	jalr	1414(ra) # 80000d40 <memmove>
    name[len] = 0;
    800047c2:	9a56                	add	s4,s4,s5
    800047c4:	000a0023          	sb	zero,0(s4)
    800047c8:	bf9d                	j	8000473e <namex+0xb8>
  if(nameiparent){
    800047ca:	f20b03e3          	beqz	s6,800046f0 <namex+0x6a>
    iput(ip);
    800047ce:	854e                	mv	a0,s3
    800047d0:	00000097          	auipc	ra,0x0
    800047d4:	adc080e7          	jalr	-1316(ra) # 800042ac <iput>
    return 0;
    800047d8:	4981                	li	s3,0
    800047da:	bf19                	j	800046f0 <namex+0x6a>
  if(*path == 0)
    800047dc:	d7fd                	beqz	a5,800047ca <namex+0x144>
  while(*path != '/' && *path != 0)
    800047de:	0004c783          	lbu	a5,0(s1)
    800047e2:	85a6                	mv	a1,s1
    800047e4:	b7d1                	j	800047a8 <namex+0x122>

00000000800047e6 <dirlink>:
{
    800047e6:	7139                	addi	sp,sp,-64
    800047e8:	fc06                	sd	ra,56(sp)
    800047ea:	f822                	sd	s0,48(sp)
    800047ec:	f426                	sd	s1,40(sp)
    800047ee:	f04a                	sd	s2,32(sp)
    800047f0:	ec4e                	sd	s3,24(sp)
    800047f2:	e852                	sd	s4,16(sp)
    800047f4:	0080                	addi	s0,sp,64
    800047f6:	892a                	mv	s2,a0
    800047f8:	8a2e                	mv	s4,a1
    800047fa:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800047fc:	4601                	li	a2,0
    800047fe:	00000097          	auipc	ra,0x0
    80004802:	dd8080e7          	jalr	-552(ra) # 800045d6 <dirlookup>
    80004806:	e93d                	bnez	a0,8000487c <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004808:	04c92483          	lw	s1,76(s2)
    8000480c:	c49d                	beqz	s1,8000483a <dirlink+0x54>
    8000480e:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004810:	4741                	li	a4,16
    80004812:	86a6                	mv	a3,s1
    80004814:	fc040613          	addi	a2,s0,-64
    80004818:	4581                	li	a1,0
    8000481a:	854a                	mv	a0,s2
    8000481c:	00000097          	auipc	ra,0x0
    80004820:	b8a080e7          	jalr	-1142(ra) # 800043a6 <readi>
    80004824:	47c1                	li	a5,16
    80004826:	06f51163          	bne	a0,a5,80004888 <dirlink+0xa2>
    if(de.inum == 0)
    8000482a:	fc045783          	lhu	a5,-64(s0)
    8000482e:	c791                	beqz	a5,8000483a <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004830:	24c1                	addiw	s1,s1,16
    80004832:	04c92783          	lw	a5,76(s2)
    80004836:	fcf4ede3          	bltu	s1,a5,80004810 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000483a:	4639                	li	a2,14
    8000483c:	85d2                	mv	a1,s4
    8000483e:	fc240513          	addi	a0,s0,-62
    80004842:	ffffc097          	auipc	ra,0xffffc
    80004846:	5b2080e7          	jalr	1458(ra) # 80000df4 <strncpy>
  de.inum = inum;
    8000484a:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000484e:	4741                	li	a4,16
    80004850:	86a6                	mv	a3,s1
    80004852:	fc040613          	addi	a2,s0,-64
    80004856:	4581                	li	a1,0
    80004858:	854a                	mv	a0,s2
    8000485a:	00000097          	auipc	ra,0x0
    8000485e:	c44080e7          	jalr	-956(ra) # 8000449e <writei>
    80004862:	872a                	mv	a4,a0
    80004864:	47c1                	li	a5,16
  return 0;
    80004866:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004868:	02f71863          	bne	a4,a5,80004898 <dirlink+0xb2>
}
    8000486c:	70e2                	ld	ra,56(sp)
    8000486e:	7442                	ld	s0,48(sp)
    80004870:	74a2                	ld	s1,40(sp)
    80004872:	7902                	ld	s2,32(sp)
    80004874:	69e2                	ld	s3,24(sp)
    80004876:	6a42                	ld	s4,16(sp)
    80004878:	6121                	addi	sp,sp,64
    8000487a:	8082                	ret
    iput(ip);
    8000487c:	00000097          	auipc	ra,0x0
    80004880:	a30080e7          	jalr	-1488(ra) # 800042ac <iput>
    return -1;
    80004884:	557d                	li	a0,-1
    80004886:	b7dd                	j	8000486c <dirlink+0x86>
      panic("dirlink read");
    80004888:	00004517          	auipc	a0,0x4
    8000488c:	e1050513          	addi	a0,a0,-496 # 80008698 <syscalls+0x1e0>
    80004890:	ffffc097          	auipc	ra,0xffffc
    80004894:	cae080e7          	jalr	-850(ra) # 8000053e <panic>
    panic("dirlink");
    80004898:	00004517          	auipc	a0,0x4
    8000489c:	f1050513          	addi	a0,a0,-240 # 800087a8 <syscalls+0x2f0>
    800048a0:	ffffc097          	auipc	ra,0xffffc
    800048a4:	c9e080e7          	jalr	-866(ra) # 8000053e <panic>

00000000800048a8 <namei>:

struct inode*
namei(char *path)
{
    800048a8:	1101                	addi	sp,sp,-32
    800048aa:	ec06                	sd	ra,24(sp)
    800048ac:	e822                	sd	s0,16(sp)
    800048ae:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800048b0:	fe040613          	addi	a2,s0,-32
    800048b4:	4581                	li	a1,0
    800048b6:	00000097          	auipc	ra,0x0
    800048ba:	dd0080e7          	jalr	-560(ra) # 80004686 <namex>
}
    800048be:	60e2                	ld	ra,24(sp)
    800048c0:	6442                	ld	s0,16(sp)
    800048c2:	6105                	addi	sp,sp,32
    800048c4:	8082                	ret

00000000800048c6 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800048c6:	1141                	addi	sp,sp,-16
    800048c8:	e406                	sd	ra,8(sp)
    800048ca:	e022                	sd	s0,0(sp)
    800048cc:	0800                	addi	s0,sp,16
    800048ce:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800048d0:	4585                	li	a1,1
    800048d2:	00000097          	auipc	ra,0x0
    800048d6:	db4080e7          	jalr	-588(ra) # 80004686 <namex>
}
    800048da:	60a2                	ld	ra,8(sp)
    800048dc:	6402                	ld	s0,0(sp)
    800048de:	0141                	addi	sp,sp,16
    800048e0:	8082                	ret

00000000800048e2 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800048e2:	1101                	addi	sp,sp,-32
    800048e4:	ec06                	sd	ra,24(sp)
    800048e6:	e822                	sd	s0,16(sp)
    800048e8:	e426                	sd	s1,8(sp)
    800048ea:	e04a                	sd	s2,0(sp)
    800048ec:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800048ee:	0001d917          	auipc	s2,0x1d
    800048f2:	47290913          	addi	s2,s2,1138 # 80021d60 <log>
    800048f6:	01892583          	lw	a1,24(s2)
    800048fa:	02892503          	lw	a0,40(s2)
    800048fe:	fffff097          	auipc	ra,0xfffff
    80004902:	ff2080e7          	jalr	-14(ra) # 800038f0 <bread>
    80004906:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004908:	02c92683          	lw	a3,44(s2)
    8000490c:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000490e:	02d05763          	blez	a3,8000493c <write_head+0x5a>
    80004912:	0001d797          	auipc	a5,0x1d
    80004916:	47e78793          	addi	a5,a5,1150 # 80021d90 <log+0x30>
    8000491a:	05c50713          	addi	a4,a0,92
    8000491e:	36fd                	addiw	a3,a3,-1
    80004920:	1682                	slli	a3,a3,0x20
    80004922:	9281                	srli	a3,a3,0x20
    80004924:	068a                	slli	a3,a3,0x2
    80004926:	0001d617          	auipc	a2,0x1d
    8000492a:	46e60613          	addi	a2,a2,1134 # 80021d94 <log+0x34>
    8000492e:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004930:	4390                	lw	a2,0(a5)
    80004932:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004934:	0791                	addi	a5,a5,4
    80004936:	0711                	addi	a4,a4,4
    80004938:	fed79ce3          	bne	a5,a3,80004930 <write_head+0x4e>
  }
  bwrite(buf);
    8000493c:	8526                	mv	a0,s1
    8000493e:	fffff097          	auipc	ra,0xfffff
    80004942:	0a4080e7          	jalr	164(ra) # 800039e2 <bwrite>
  brelse(buf);
    80004946:	8526                	mv	a0,s1
    80004948:	fffff097          	auipc	ra,0xfffff
    8000494c:	0d8080e7          	jalr	216(ra) # 80003a20 <brelse>
}
    80004950:	60e2                	ld	ra,24(sp)
    80004952:	6442                	ld	s0,16(sp)
    80004954:	64a2                	ld	s1,8(sp)
    80004956:	6902                	ld	s2,0(sp)
    80004958:	6105                	addi	sp,sp,32
    8000495a:	8082                	ret

000000008000495c <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000495c:	0001d797          	auipc	a5,0x1d
    80004960:	4307a783          	lw	a5,1072(a5) # 80021d8c <log+0x2c>
    80004964:	0af05d63          	blez	a5,80004a1e <install_trans+0xc2>
{
    80004968:	7139                	addi	sp,sp,-64
    8000496a:	fc06                	sd	ra,56(sp)
    8000496c:	f822                	sd	s0,48(sp)
    8000496e:	f426                	sd	s1,40(sp)
    80004970:	f04a                	sd	s2,32(sp)
    80004972:	ec4e                	sd	s3,24(sp)
    80004974:	e852                	sd	s4,16(sp)
    80004976:	e456                	sd	s5,8(sp)
    80004978:	e05a                	sd	s6,0(sp)
    8000497a:	0080                	addi	s0,sp,64
    8000497c:	8b2a                	mv	s6,a0
    8000497e:	0001da97          	auipc	s5,0x1d
    80004982:	412a8a93          	addi	s5,s5,1042 # 80021d90 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004986:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004988:	0001d997          	auipc	s3,0x1d
    8000498c:	3d898993          	addi	s3,s3,984 # 80021d60 <log>
    80004990:	a035                	j	800049bc <install_trans+0x60>
      bunpin(dbuf);
    80004992:	8526                	mv	a0,s1
    80004994:	fffff097          	auipc	ra,0xfffff
    80004998:	166080e7          	jalr	358(ra) # 80003afa <bunpin>
    brelse(lbuf);
    8000499c:	854a                	mv	a0,s2
    8000499e:	fffff097          	auipc	ra,0xfffff
    800049a2:	082080e7          	jalr	130(ra) # 80003a20 <brelse>
    brelse(dbuf);
    800049a6:	8526                	mv	a0,s1
    800049a8:	fffff097          	auipc	ra,0xfffff
    800049ac:	078080e7          	jalr	120(ra) # 80003a20 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800049b0:	2a05                	addiw	s4,s4,1
    800049b2:	0a91                	addi	s5,s5,4
    800049b4:	02c9a783          	lw	a5,44(s3)
    800049b8:	04fa5963          	bge	s4,a5,80004a0a <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800049bc:	0189a583          	lw	a1,24(s3)
    800049c0:	014585bb          	addw	a1,a1,s4
    800049c4:	2585                	addiw	a1,a1,1
    800049c6:	0289a503          	lw	a0,40(s3)
    800049ca:	fffff097          	auipc	ra,0xfffff
    800049ce:	f26080e7          	jalr	-218(ra) # 800038f0 <bread>
    800049d2:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800049d4:	000aa583          	lw	a1,0(s5)
    800049d8:	0289a503          	lw	a0,40(s3)
    800049dc:	fffff097          	auipc	ra,0xfffff
    800049e0:	f14080e7          	jalr	-236(ra) # 800038f0 <bread>
    800049e4:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800049e6:	40000613          	li	a2,1024
    800049ea:	05890593          	addi	a1,s2,88
    800049ee:	05850513          	addi	a0,a0,88
    800049f2:	ffffc097          	auipc	ra,0xffffc
    800049f6:	34e080e7          	jalr	846(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    800049fa:	8526                	mv	a0,s1
    800049fc:	fffff097          	auipc	ra,0xfffff
    80004a00:	fe6080e7          	jalr	-26(ra) # 800039e2 <bwrite>
    if(recovering == 0)
    80004a04:	f80b1ce3          	bnez	s6,8000499c <install_trans+0x40>
    80004a08:	b769                	j	80004992 <install_trans+0x36>
}
    80004a0a:	70e2                	ld	ra,56(sp)
    80004a0c:	7442                	ld	s0,48(sp)
    80004a0e:	74a2                	ld	s1,40(sp)
    80004a10:	7902                	ld	s2,32(sp)
    80004a12:	69e2                	ld	s3,24(sp)
    80004a14:	6a42                	ld	s4,16(sp)
    80004a16:	6aa2                	ld	s5,8(sp)
    80004a18:	6b02                	ld	s6,0(sp)
    80004a1a:	6121                	addi	sp,sp,64
    80004a1c:	8082                	ret
    80004a1e:	8082                	ret

0000000080004a20 <initlog>:
{
    80004a20:	7179                	addi	sp,sp,-48
    80004a22:	f406                	sd	ra,40(sp)
    80004a24:	f022                	sd	s0,32(sp)
    80004a26:	ec26                	sd	s1,24(sp)
    80004a28:	e84a                	sd	s2,16(sp)
    80004a2a:	e44e                	sd	s3,8(sp)
    80004a2c:	1800                	addi	s0,sp,48
    80004a2e:	892a                	mv	s2,a0
    80004a30:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004a32:	0001d497          	auipc	s1,0x1d
    80004a36:	32e48493          	addi	s1,s1,814 # 80021d60 <log>
    80004a3a:	00004597          	auipc	a1,0x4
    80004a3e:	c6e58593          	addi	a1,a1,-914 # 800086a8 <syscalls+0x1f0>
    80004a42:	8526                	mv	a0,s1
    80004a44:	ffffc097          	auipc	ra,0xffffc
    80004a48:	110080e7          	jalr	272(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80004a4c:	0149a583          	lw	a1,20(s3)
    80004a50:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004a52:	0109a783          	lw	a5,16(s3)
    80004a56:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004a58:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004a5c:	854a                	mv	a0,s2
    80004a5e:	fffff097          	auipc	ra,0xfffff
    80004a62:	e92080e7          	jalr	-366(ra) # 800038f0 <bread>
  log.lh.n = lh->n;
    80004a66:	4d3c                	lw	a5,88(a0)
    80004a68:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004a6a:	02f05563          	blez	a5,80004a94 <initlog+0x74>
    80004a6e:	05c50713          	addi	a4,a0,92
    80004a72:	0001d697          	auipc	a3,0x1d
    80004a76:	31e68693          	addi	a3,a3,798 # 80021d90 <log+0x30>
    80004a7a:	37fd                	addiw	a5,a5,-1
    80004a7c:	1782                	slli	a5,a5,0x20
    80004a7e:	9381                	srli	a5,a5,0x20
    80004a80:	078a                	slli	a5,a5,0x2
    80004a82:	06050613          	addi	a2,a0,96
    80004a86:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004a88:	4310                	lw	a2,0(a4)
    80004a8a:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004a8c:	0711                	addi	a4,a4,4
    80004a8e:	0691                	addi	a3,a3,4
    80004a90:	fef71ce3          	bne	a4,a5,80004a88 <initlog+0x68>
  brelse(buf);
    80004a94:	fffff097          	auipc	ra,0xfffff
    80004a98:	f8c080e7          	jalr	-116(ra) # 80003a20 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004a9c:	4505                	li	a0,1
    80004a9e:	00000097          	auipc	ra,0x0
    80004aa2:	ebe080e7          	jalr	-322(ra) # 8000495c <install_trans>
  log.lh.n = 0;
    80004aa6:	0001d797          	auipc	a5,0x1d
    80004aaa:	2e07a323          	sw	zero,742(a5) # 80021d8c <log+0x2c>
  write_head(); // clear the log
    80004aae:	00000097          	auipc	ra,0x0
    80004ab2:	e34080e7          	jalr	-460(ra) # 800048e2 <write_head>
}
    80004ab6:	70a2                	ld	ra,40(sp)
    80004ab8:	7402                	ld	s0,32(sp)
    80004aba:	64e2                	ld	s1,24(sp)
    80004abc:	6942                	ld	s2,16(sp)
    80004abe:	69a2                	ld	s3,8(sp)
    80004ac0:	6145                	addi	sp,sp,48
    80004ac2:	8082                	ret

0000000080004ac4 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004ac4:	1101                	addi	sp,sp,-32
    80004ac6:	ec06                	sd	ra,24(sp)
    80004ac8:	e822                	sd	s0,16(sp)
    80004aca:	e426                	sd	s1,8(sp)
    80004acc:	e04a                	sd	s2,0(sp)
    80004ace:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004ad0:	0001d517          	auipc	a0,0x1d
    80004ad4:	29050513          	addi	a0,a0,656 # 80021d60 <log>
    80004ad8:	ffffc097          	auipc	ra,0xffffc
    80004adc:	10c080e7          	jalr	268(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80004ae0:	0001d497          	auipc	s1,0x1d
    80004ae4:	28048493          	addi	s1,s1,640 # 80021d60 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004ae8:	4979                	li	s2,30
    80004aea:	a039                	j	80004af8 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004aec:	85a6                	mv	a1,s1
    80004aee:	8526                	mv	a0,s1
    80004af0:	ffffe097          	auipc	ra,0xffffe
    80004af4:	a8a080e7          	jalr	-1398(ra) # 8000257a <sleep>
    if(log.committing){
    80004af8:	50dc                	lw	a5,36(s1)
    80004afa:	fbed                	bnez	a5,80004aec <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004afc:	509c                	lw	a5,32(s1)
    80004afe:	0017871b          	addiw	a4,a5,1
    80004b02:	0007069b          	sext.w	a3,a4
    80004b06:	0027179b          	slliw	a5,a4,0x2
    80004b0a:	9fb9                	addw	a5,a5,a4
    80004b0c:	0017979b          	slliw	a5,a5,0x1
    80004b10:	54d8                	lw	a4,44(s1)
    80004b12:	9fb9                	addw	a5,a5,a4
    80004b14:	00f95963          	bge	s2,a5,80004b26 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004b18:	85a6                	mv	a1,s1
    80004b1a:	8526                	mv	a0,s1
    80004b1c:	ffffe097          	auipc	ra,0xffffe
    80004b20:	a5e080e7          	jalr	-1442(ra) # 8000257a <sleep>
    80004b24:	bfd1                	j	80004af8 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004b26:	0001d517          	auipc	a0,0x1d
    80004b2a:	23a50513          	addi	a0,a0,570 # 80021d60 <log>
    80004b2e:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004b30:	ffffc097          	auipc	ra,0xffffc
    80004b34:	168080e7          	jalr	360(ra) # 80000c98 <release>
      break;
    }
  }
}
    80004b38:	60e2                	ld	ra,24(sp)
    80004b3a:	6442                	ld	s0,16(sp)
    80004b3c:	64a2                	ld	s1,8(sp)
    80004b3e:	6902                	ld	s2,0(sp)
    80004b40:	6105                	addi	sp,sp,32
    80004b42:	8082                	ret

0000000080004b44 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004b44:	7139                	addi	sp,sp,-64
    80004b46:	fc06                	sd	ra,56(sp)
    80004b48:	f822                	sd	s0,48(sp)
    80004b4a:	f426                	sd	s1,40(sp)
    80004b4c:	f04a                	sd	s2,32(sp)
    80004b4e:	ec4e                	sd	s3,24(sp)
    80004b50:	e852                	sd	s4,16(sp)
    80004b52:	e456                	sd	s5,8(sp)
    80004b54:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004b56:	0001d497          	auipc	s1,0x1d
    80004b5a:	20a48493          	addi	s1,s1,522 # 80021d60 <log>
    80004b5e:	8526                	mv	a0,s1
    80004b60:	ffffc097          	auipc	ra,0xffffc
    80004b64:	084080e7          	jalr	132(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    80004b68:	509c                	lw	a5,32(s1)
    80004b6a:	37fd                	addiw	a5,a5,-1
    80004b6c:	0007891b          	sext.w	s2,a5
    80004b70:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004b72:	50dc                	lw	a5,36(s1)
    80004b74:	efb9                	bnez	a5,80004bd2 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004b76:	06091663          	bnez	s2,80004be2 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004b7a:	0001d497          	auipc	s1,0x1d
    80004b7e:	1e648493          	addi	s1,s1,486 # 80021d60 <log>
    80004b82:	4785                	li	a5,1
    80004b84:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004b86:	8526                	mv	a0,s1
    80004b88:	ffffc097          	auipc	ra,0xffffc
    80004b8c:	110080e7          	jalr	272(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004b90:	54dc                	lw	a5,44(s1)
    80004b92:	06f04763          	bgtz	a5,80004c00 <end_op+0xbc>
    acquire(&log.lock);
    80004b96:	0001d497          	auipc	s1,0x1d
    80004b9a:	1ca48493          	addi	s1,s1,458 # 80021d60 <log>
    80004b9e:	8526                	mv	a0,s1
    80004ba0:	ffffc097          	auipc	ra,0xffffc
    80004ba4:	044080e7          	jalr	68(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004ba8:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004bac:	8526                	mv	a0,s1
    80004bae:	ffffe097          	auipc	ra,0xffffe
    80004bb2:	b6e080e7          	jalr	-1170(ra) # 8000271c <wakeup>
    release(&log.lock);
    80004bb6:	8526                	mv	a0,s1
    80004bb8:	ffffc097          	auipc	ra,0xffffc
    80004bbc:	0e0080e7          	jalr	224(ra) # 80000c98 <release>
}
    80004bc0:	70e2                	ld	ra,56(sp)
    80004bc2:	7442                	ld	s0,48(sp)
    80004bc4:	74a2                	ld	s1,40(sp)
    80004bc6:	7902                	ld	s2,32(sp)
    80004bc8:	69e2                	ld	s3,24(sp)
    80004bca:	6a42                	ld	s4,16(sp)
    80004bcc:	6aa2                	ld	s5,8(sp)
    80004bce:	6121                	addi	sp,sp,64
    80004bd0:	8082                	ret
    panic("log.committing");
    80004bd2:	00004517          	auipc	a0,0x4
    80004bd6:	ade50513          	addi	a0,a0,-1314 # 800086b0 <syscalls+0x1f8>
    80004bda:	ffffc097          	auipc	ra,0xffffc
    80004bde:	964080e7          	jalr	-1692(ra) # 8000053e <panic>
    wakeup(&log);
    80004be2:	0001d497          	auipc	s1,0x1d
    80004be6:	17e48493          	addi	s1,s1,382 # 80021d60 <log>
    80004bea:	8526                	mv	a0,s1
    80004bec:	ffffe097          	auipc	ra,0xffffe
    80004bf0:	b30080e7          	jalr	-1232(ra) # 8000271c <wakeup>
  release(&log.lock);
    80004bf4:	8526                	mv	a0,s1
    80004bf6:	ffffc097          	auipc	ra,0xffffc
    80004bfa:	0a2080e7          	jalr	162(ra) # 80000c98 <release>
  if(do_commit){
    80004bfe:	b7c9                	j	80004bc0 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004c00:	0001da97          	auipc	s5,0x1d
    80004c04:	190a8a93          	addi	s5,s5,400 # 80021d90 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004c08:	0001da17          	auipc	s4,0x1d
    80004c0c:	158a0a13          	addi	s4,s4,344 # 80021d60 <log>
    80004c10:	018a2583          	lw	a1,24(s4)
    80004c14:	012585bb          	addw	a1,a1,s2
    80004c18:	2585                	addiw	a1,a1,1
    80004c1a:	028a2503          	lw	a0,40(s4)
    80004c1e:	fffff097          	auipc	ra,0xfffff
    80004c22:	cd2080e7          	jalr	-814(ra) # 800038f0 <bread>
    80004c26:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004c28:	000aa583          	lw	a1,0(s5)
    80004c2c:	028a2503          	lw	a0,40(s4)
    80004c30:	fffff097          	auipc	ra,0xfffff
    80004c34:	cc0080e7          	jalr	-832(ra) # 800038f0 <bread>
    80004c38:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004c3a:	40000613          	li	a2,1024
    80004c3e:	05850593          	addi	a1,a0,88
    80004c42:	05848513          	addi	a0,s1,88
    80004c46:	ffffc097          	auipc	ra,0xffffc
    80004c4a:	0fa080e7          	jalr	250(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    80004c4e:	8526                	mv	a0,s1
    80004c50:	fffff097          	auipc	ra,0xfffff
    80004c54:	d92080e7          	jalr	-622(ra) # 800039e2 <bwrite>
    brelse(from);
    80004c58:	854e                	mv	a0,s3
    80004c5a:	fffff097          	auipc	ra,0xfffff
    80004c5e:	dc6080e7          	jalr	-570(ra) # 80003a20 <brelse>
    brelse(to);
    80004c62:	8526                	mv	a0,s1
    80004c64:	fffff097          	auipc	ra,0xfffff
    80004c68:	dbc080e7          	jalr	-580(ra) # 80003a20 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004c6c:	2905                	addiw	s2,s2,1
    80004c6e:	0a91                	addi	s5,s5,4
    80004c70:	02ca2783          	lw	a5,44(s4)
    80004c74:	f8f94ee3          	blt	s2,a5,80004c10 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004c78:	00000097          	auipc	ra,0x0
    80004c7c:	c6a080e7          	jalr	-918(ra) # 800048e2 <write_head>
    install_trans(0); // Now install writes to home locations
    80004c80:	4501                	li	a0,0
    80004c82:	00000097          	auipc	ra,0x0
    80004c86:	cda080e7          	jalr	-806(ra) # 8000495c <install_trans>
    log.lh.n = 0;
    80004c8a:	0001d797          	auipc	a5,0x1d
    80004c8e:	1007a123          	sw	zero,258(a5) # 80021d8c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004c92:	00000097          	auipc	ra,0x0
    80004c96:	c50080e7          	jalr	-944(ra) # 800048e2 <write_head>
    80004c9a:	bdf5                	j	80004b96 <end_op+0x52>

0000000080004c9c <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004c9c:	1101                	addi	sp,sp,-32
    80004c9e:	ec06                	sd	ra,24(sp)
    80004ca0:	e822                	sd	s0,16(sp)
    80004ca2:	e426                	sd	s1,8(sp)
    80004ca4:	e04a                	sd	s2,0(sp)
    80004ca6:	1000                	addi	s0,sp,32
    80004ca8:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004caa:	0001d917          	auipc	s2,0x1d
    80004cae:	0b690913          	addi	s2,s2,182 # 80021d60 <log>
    80004cb2:	854a                	mv	a0,s2
    80004cb4:	ffffc097          	auipc	ra,0xffffc
    80004cb8:	f30080e7          	jalr	-208(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004cbc:	02c92603          	lw	a2,44(s2)
    80004cc0:	47f5                	li	a5,29
    80004cc2:	06c7c563          	blt	a5,a2,80004d2c <log_write+0x90>
    80004cc6:	0001d797          	auipc	a5,0x1d
    80004cca:	0b67a783          	lw	a5,182(a5) # 80021d7c <log+0x1c>
    80004cce:	37fd                	addiw	a5,a5,-1
    80004cd0:	04f65e63          	bge	a2,a5,80004d2c <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004cd4:	0001d797          	auipc	a5,0x1d
    80004cd8:	0ac7a783          	lw	a5,172(a5) # 80021d80 <log+0x20>
    80004cdc:	06f05063          	blez	a5,80004d3c <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004ce0:	4781                	li	a5,0
    80004ce2:	06c05563          	blez	a2,80004d4c <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004ce6:	44cc                	lw	a1,12(s1)
    80004ce8:	0001d717          	auipc	a4,0x1d
    80004cec:	0a870713          	addi	a4,a4,168 # 80021d90 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004cf0:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004cf2:	4314                	lw	a3,0(a4)
    80004cf4:	04b68c63          	beq	a3,a1,80004d4c <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004cf8:	2785                	addiw	a5,a5,1
    80004cfa:	0711                	addi	a4,a4,4
    80004cfc:	fef61be3          	bne	a2,a5,80004cf2 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004d00:	0621                	addi	a2,a2,8
    80004d02:	060a                	slli	a2,a2,0x2
    80004d04:	0001d797          	auipc	a5,0x1d
    80004d08:	05c78793          	addi	a5,a5,92 # 80021d60 <log>
    80004d0c:	963e                	add	a2,a2,a5
    80004d0e:	44dc                	lw	a5,12(s1)
    80004d10:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004d12:	8526                	mv	a0,s1
    80004d14:	fffff097          	auipc	ra,0xfffff
    80004d18:	daa080e7          	jalr	-598(ra) # 80003abe <bpin>
    log.lh.n++;
    80004d1c:	0001d717          	auipc	a4,0x1d
    80004d20:	04470713          	addi	a4,a4,68 # 80021d60 <log>
    80004d24:	575c                	lw	a5,44(a4)
    80004d26:	2785                	addiw	a5,a5,1
    80004d28:	d75c                	sw	a5,44(a4)
    80004d2a:	a835                	j	80004d66 <log_write+0xca>
    panic("too big a transaction");
    80004d2c:	00004517          	auipc	a0,0x4
    80004d30:	99450513          	addi	a0,a0,-1644 # 800086c0 <syscalls+0x208>
    80004d34:	ffffc097          	auipc	ra,0xffffc
    80004d38:	80a080e7          	jalr	-2038(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004d3c:	00004517          	auipc	a0,0x4
    80004d40:	99c50513          	addi	a0,a0,-1636 # 800086d8 <syscalls+0x220>
    80004d44:	ffffb097          	auipc	ra,0xffffb
    80004d48:	7fa080e7          	jalr	2042(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004d4c:	00878713          	addi	a4,a5,8
    80004d50:	00271693          	slli	a3,a4,0x2
    80004d54:	0001d717          	auipc	a4,0x1d
    80004d58:	00c70713          	addi	a4,a4,12 # 80021d60 <log>
    80004d5c:	9736                	add	a4,a4,a3
    80004d5e:	44d4                	lw	a3,12(s1)
    80004d60:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004d62:	faf608e3          	beq	a2,a5,80004d12 <log_write+0x76>
  }
  release(&log.lock);
    80004d66:	0001d517          	auipc	a0,0x1d
    80004d6a:	ffa50513          	addi	a0,a0,-6 # 80021d60 <log>
    80004d6e:	ffffc097          	auipc	ra,0xffffc
    80004d72:	f2a080e7          	jalr	-214(ra) # 80000c98 <release>
}
    80004d76:	60e2                	ld	ra,24(sp)
    80004d78:	6442                	ld	s0,16(sp)
    80004d7a:	64a2                	ld	s1,8(sp)
    80004d7c:	6902                	ld	s2,0(sp)
    80004d7e:	6105                	addi	sp,sp,32
    80004d80:	8082                	ret

0000000080004d82 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004d82:	1101                	addi	sp,sp,-32
    80004d84:	ec06                	sd	ra,24(sp)
    80004d86:	e822                	sd	s0,16(sp)
    80004d88:	e426                	sd	s1,8(sp)
    80004d8a:	e04a                	sd	s2,0(sp)
    80004d8c:	1000                	addi	s0,sp,32
    80004d8e:	84aa                	mv	s1,a0
    80004d90:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004d92:	00004597          	auipc	a1,0x4
    80004d96:	96658593          	addi	a1,a1,-1690 # 800086f8 <syscalls+0x240>
    80004d9a:	0521                	addi	a0,a0,8
    80004d9c:	ffffc097          	auipc	ra,0xffffc
    80004da0:	db8080e7          	jalr	-584(ra) # 80000b54 <initlock>
  lk->name = name;
    80004da4:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004da8:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004dac:	0204a423          	sw	zero,40(s1)
}
    80004db0:	60e2                	ld	ra,24(sp)
    80004db2:	6442                	ld	s0,16(sp)
    80004db4:	64a2                	ld	s1,8(sp)
    80004db6:	6902                	ld	s2,0(sp)
    80004db8:	6105                	addi	sp,sp,32
    80004dba:	8082                	ret

0000000080004dbc <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004dbc:	1101                	addi	sp,sp,-32
    80004dbe:	ec06                	sd	ra,24(sp)
    80004dc0:	e822                	sd	s0,16(sp)
    80004dc2:	e426                	sd	s1,8(sp)
    80004dc4:	e04a                	sd	s2,0(sp)
    80004dc6:	1000                	addi	s0,sp,32
    80004dc8:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004dca:	00850913          	addi	s2,a0,8
    80004dce:	854a                	mv	a0,s2
    80004dd0:	ffffc097          	auipc	ra,0xffffc
    80004dd4:	e14080e7          	jalr	-492(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004dd8:	409c                	lw	a5,0(s1)
    80004dda:	cb89                	beqz	a5,80004dec <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004ddc:	85ca                	mv	a1,s2
    80004dde:	8526                	mv	a0,s1
    80004de0:	ffffd097          	auipc	ra,0xffffd
    80004de4:	79a080e7          	jalr	1946(ra) # 8000257a <sleep>
  while (lk->locked) {
    80004de8:	409c                	lw	a5,0(s1)
    80004dea:	fbed                	bnez	a5,80004ddc <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004dec:	4785                	li	a5,1
    80004dee:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004df0:	ffffd097          	auipc	ra,0xffffd
    80004df4:	06e080e7          	jalr	110(ra) # 80001e5e <myproc>
    80004df8:	453c                	lw	a5,72(a0)
    80004dfa:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004dfc:	854a                	mv	a0,s2
    80004dfe:	ffffc097          	auipc	ra,0xffffc
    80004e02:	e9a080e7          	jalr	-358(ra) # 80000c98 <release>
}
    80004e06:	60e2                	ld	ra,24(sp)
    80004e08:	6442                	ld	s0,16(sp)
    80004e0a:	64a2                	ld	s1,8(sp)
    80004e0c:	6902                	ld	s2,0(sp)
    80004e0e:	6105                	addi	sp,sp,32
    80004e10:	8082                	ret

0000000080004e12 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004e12:	1101                	addi	sp,sp,-32
    80004e14:	ec06                	sd	ra,24(sp)
    80004e16:	e822                	sd	s0,16(sp)
    80004e18:	e426                	sd	s1,8(sp)
    80004e1a:	e04a                	sd	s2,0(sp)
    80004e1c:	1000                	addi	s0,sp,32
    80004e1e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004e20:	00850913          	addi	s2,a0,8
    80004e24:	854a                	mv	a0,s2
    80004e26:	ffffc097          	auipc	ra,0xffffc
    80004e2a:	dbe080e7          	jalr	-578(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004e2e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004e32:	0204a423          	sw	zero,40(s1)
  
  wakeup(lk);
    80004e36:	8526                	mv	a0,s1
    80004e38:	ffffe097          	auipc	ra,0xffffe
    80004e3c:	8e4080e7          	jalr	-1820(ra) # 8000271c <wakeup>
  release(&lk->lk);
    80004e40:	854a                	mv	a0,s2
    80004e42:	ffffc097          	auipc	ra,0xffffc
    80004e46:	e56080e7          	jalr	-426(ra) # 80000c98 <release>
}
    80004e4a:	60e2                	ld	ra,24(sp)
    80004e4c:	6442                	ld	s0,16(sp)
    80004e4e:	64a2                	ld	s1,8(sp)
    80004e50:	6902                	ld	s2,0(sp)
    80004e52:	6105                	addi	sp,sp,32
    80004e54:	8082                	ret

0000000080004e56 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004e56:	7179                	addi	sp,sp,-48
    80004e58:	f406                	sd	ra,40(sp)
    80004e5a:	f022                	sd	s0,32(sp)
    80004e5c:	ec26                	sd	s1,24(sp)
    80004e5e:	e84a                	sd	s2,16(sp)
    80004e60:	e44e                	sd	s3,8(sp)
    80004e62:	1800                	addi	s0,sp,48
    80004e64:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004e66:	00850913          	addi	s2,a0,8
    80004e6a:	854a                	mv	a0,s2
    80004e6c:	ffffc097          	auipc	ra,0xffffc
    80004e70:	d78080e7          	jalr	-648(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004e74:	409c                	lw	a5,0(s1)
    80004e76:	ef99                	bnez	a5,80004e94 <holdingsleep+0x3e>
    80004e78:	4481                	li	s1,0
  release(&lk->lk);
    80004e7a:	854a                	mv	a0,s2
    80004e7c:	ffffc097          	auipc	ra,0xffffc
    80004e80:	e1c080e7          	jalr	-484(ra) # 80000c98 <release>
  return r;
}
    80004e84:	8526                	mv	a0,s1
    80004e86:	70a2                	ld	ra,40(sp)
    80004e88:	7402                	ld	s0,32(sp)
    80004e8a:	64e2                	ld	s1,24(sp)
    80004e8c:	6942                	ld	s2,16(sp)
    80004e8e:	69a2                	ld	s3,8(sp)
    80004e90:	6145                	addi	sp,sp,48
    80004e92:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004e94:	0284a983          	lw	s3,40(s1)
    80004e98:	ffffd097          	auipc	ra,0xffffd
    80004e9c:	fc6080e7          	jalr	-58(ra) # 80001e5e <myproc>
    80004ea0:	4524                	lw	s1,72(a0)
    80004ea2:	413484b3          	sub	s1,s1,s3
    80004ea6:	0014b493          	seqz	s1,s1
    80004eaa:	bfc1                	j	80004e7a <holdingsleep+0x24>

0000000080004eac <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004eac:	1141                	addi	sp,sp,-16
    80004eae:	e406                	sd	ra,8(sp)
    80004eb0:	e022                	sd	s0,0(sp)
    80004eb2:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004eb4:	00004597          	auipc	a1,0x4
    80004eb8:	85458593          	addi	a1,a1,-1964 # 80008708 <syscalls+0x250>
    80004ebc:	0001d517          	auipc	a0,0x1d
    80004ec0:	fec50513          	addi	a0,a0,-20 # 80021ea8 <ftable>
    80004ec4:	ffffc097          	auipc	ra,0xffffc
    80004ec8:	c90080e7          	jalr	-880(ra) # 80000b54 <initlock>
}
    80004ecc:	60a2                	ld	ra,8(sp)
    80004ece:	6402                	ld	s0,0(sp)
    80004ed0:	0141                	addi	sp,sp,16
    80004ed2:	8082                	ret

0000000080004ed4 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004ed4:	1101                	addi	sp,sp,-32
    80004ed6:	ec06                	sd	ra,24(sp)
    80004ed8:	e822                	sd	s0,16(sp)
    80004eda:	e426                	sd	s1,8(sp)
    80004edc:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004ede:	0001d517          	auipc	a0,0x1d
    80004ee2:	fca50513          	addi	a0,a0,-54 # 80021ea8 <ftable>
    80004ee6:	ffffc097          	auipc	ra,0xffffc
    80004eea:	cfe080e7          	jalr	-770(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004eee:	0001d497          	auipc	s1,0x1d
    80004ef2:	fd248493          	addi	s1,s1,-46 # 80021ec0 <ftable+0x18>
    80004ef6:	0001e717          	auipc	a4,0x1e
    80004efa:	f6a70713          	addi	a4,a4,-150 # 80022e60 <ftable+0xfb8>
    if(f->ref == 0){
    80004efe:	40dc                	lw	a5,4(s1)
    80004f00:	cf99                	beqz	a5,80004f1e <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004f02:	02848493          	addi	s1,s1,40
    80004f06:	fee49ce3          	bne	s1,a4,80004efe <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004f0a:	0001d517          	auipc	a0,0x1d
    80004f0e:	f9e50513          	addi	a0,a0,-98 # 80021ea8 <ftable>
    80004f12:	ffffc097          	auipc	ra,0xffffc
    80004f16:	d86080e7          	jalr	-634(ra) # 80000c98 <release>
  return 0;
    80004f1a:	4481                	li	s1,0
    80004f1c:	a819                	j	80004f32 <filealloc+0x5e>
      f->ref = 1;
    80004f1e:	4785                	li	a5,1
    80004f20:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004f22:	0001d517          	auipc	a0,0x1d
    80004f26:	f8650513          	addi	a0,a0,-122 # 80021ea8 <ftable>
    80004f2a:	ffffc097          	auipc	ra,0xffffc
    80004f2e:	d6e080e7          	jalr	-658(ra) # 80000c98 <release>
}
    80004f32:	8526                	mv	a0,s1
    80004f34:	60e2                	ld	ra,24(sp)
    80004f36:	6442                	ld	s0,16(sp)
    80004f38:	64a2                	ld	s1,8(sp)
    80004f3a:	6105                	addi	sp,sp,32
    80004f3c:	8082                	ret

0000000080004f3e <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004f3e:	1101                	addi	sp,sp,-32
    80004f40:	ec06                	sd	ra,24(sp)
    80004f42:	e822                	sd	s0,16(sp)
    80004f44:	e426                	sd	s1,8(sp)
    80004f46:	1000                	addi	s0,sp,32
    80004f48:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004f4a:	0001d517          	auipc	a0,0x1d
    80004f4e:	f5e50513          	addi	a0,a0,-162 # 80021ea8 <ftable>
    80004f52:	ffffc097          	auipc	ra,0xffffc
    80004f56:	c92080e7          	jalr	-878(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004f5a:	40dc                	lw	a5,4(s1)
    80004f5c:	02f05263          	blez	a5,80004f80 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004f60:	2785                	addiw	a5,a5,1
    80004f62:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004f64:	0001d517          	auipc	a0,0x1d
    80004f68:	f4450513          	addi	a0,a0,-188 # 80021ea8 <ftable>
    80004f6c:	ffffc097          	auipc	ra,0xffffc
    80004f70:	d2c080e7          	jalr	-724(ra) # 80000c98 <release>
  return f;
}
    80004f74:	8526                	mv	a0,s1
    80004f76:	60e2                	ld	ra,24(sp)
    80004f78:	6442                	ld	s0,16(sp)
    80004f7a:	64a2                	ld	s1,8(sp)
    80004f7c:	6105                	addi	sp,sp,32
    80004f7e:	8082                	ret
    panic("filedup");
    80004f80:	00003517          	auipc	a0,0x3
    80004f84:	79050513          	addi	a0,a0,1936 # 80008710 <syscalls+0x258>
    80004f88:	ffffb097          	auipc	ra,0xffffb
    80004f8c:	5b6080e7          	jalr	1462(ra) # 8000053e <panic>

0000000080004f90 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004f90:	7139                	addi	sp,sp,-64
    80004f92:	fc06                	sd	ra,56(sp)
    80004f94:	f822                	sd	s0,48(sp)
    80004f96:	f426                	sd	s1,40(sp)
    80004f98:	f04a                	sd	s2,32(sp)
    80004f9a:	ec4e                	sd	s3,24(sp)
    80004f9c:	e852                	sd	s4,16(sp)
    80004f9e:	e456                	sd	s5,8(sp)
    80004fa0:	0080                	addi	s0,sp,64
    80004fa2:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004fa4:	0001d517          	auipc	a0,0x1d
    80004fa8:	f0450513          	addi	a0,a0,-252 # 80021ea8 <ftable>
    80004fac:	ffffc097          	auipc	ra,0xffffc
    80004fb0:	c38080e7          	jalr	-968(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004fb4:	40dc                	lw	a5,4(s1)
    80004fb6:	06f05163          	blez	a5,80005018 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004fba:	37fd                	addiw	a5,a5,-1
    80004fbc:	0007871b          	sext.w	a4,a5
    80004fc0:	c0dc                	sw	a5,4(s1)
    80004fc2:	06e04363          	bgtz	a4,80005028 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004fc6:	0004a903          	lw	s2,0(s1)
    80004fca:	0094ca83          	lbu	s5,9(s1)
    80004fce:	0104ba03          	ld	s4,16(s1)
    80004fd2:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004fd6:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004fda:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004fde:	0001d517          	auipc	a0,0x1d
    80004fe2:	eca50513          	addi	a0,a0,-310 # 80021ea8 <ftable>
    80004fe6:	ffffc097          	auipc	ra,0xffffc
    80004fea:	cb2080e7          	jalr	-846(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004fee:	4785                	li	a5,1
    80004ff0:	04f90d63          	beq	s2,a5,8000504a <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004ff4:	3979                	addiw	s2,s2,-2
    80004ff6:	4785                	li	a5,1
    80004ff8:	0527e063          	bltu	a5,s2,80005038 <fileclose+0xa8>
    begin_op();
    80004ffc:	00000097          	auipc	ra,0x0
    80005000:	ac8080e7          	jalr	-1336(ra) # 80004ac4 <begin_op>
    iput(ff.ip);
    80005004:	854e                	mv	a0,s3
    80005006:	fffff097          	auipc	ra,0xfffff
    8000500a:	2a6080e7          	jalr	678(ra) # 800042ac <iput>
    end_op();
    8000500e:	00000097          	auipc	ra,0x0
    80005012:	b36080e7          	jalr	-1226(ra) # 80004b44 <end_op>
    80005016:	a00d                	j	80005038 <fileclose+0xa8>
    panic("fileclose");
    80005018:	00003517          	auipc	a0,0x3
    8000501c:	70050513          	addi	a0,a0,1792 # 80008718 <syscalls+0x260>
    80005020:	ffffb097          	auipc	ra,0xffffb
    80005024:	51e080e7          	jalr	1310(ra) # 8000053e <panic>
    release(&ftable.lock);
    80005028:	0001d517          	auipc	a0,0x1d
    8000502c:	e8050513          	addi	a0,a0,-384 # 80021ea8 <ftable>
    80005030:	ffffc097          	auipc	ra,0xffffc
    80005034:	c68080e7          	jalr	-920(ra) # 80000c98 <release>
  }
}
    80005038:	70e2                	ld	ra,56(sp)
    8000503a:	7442                	ld	s0,48(sp)
    8000503c:	74a2                	ld	s1,40(sp)
    8000503e:	7902                	ld	s2,32(sp)
    80005040:	69e2                	ld	s3,24(sp)
    80005042:	6a42                	ld	s4,16(sp)
    80005044:	6aa2                	ld	s5,8(sp)
    80005046:	6121                	addi	sp,sp,64
    80005048:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000504a:	85d6                	mv	a1,s5
    8000504c:	8552                	mv	a0,s4
    8000504e:	00000097          	auipc	ra,0x0
    80005052:	34c080e7          	jalr	844(ra) # 8000539a <pipeclose>
    80005056:	b7cd                	j	80005038 <fileclose+0xa8>

0000000080005058 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80005058:	715d                	addi	sp,sp,-80
    8000505a:	e486                	sd	ra,72(sp)
    8000505c:	e0a2                	sd	s0,64(sp)
    8000505e:	fc26                	sd	s1,56(sp)
    80005060:	f84a                	sd	s2,48(sp)
    80005062:	f44e                	sd	s3,40(sp)
    80005064:	0880                	addi	s0,sp,80
    80005066:	84aa                	mv	s1,a0
    80005068:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000506a:	ffffd097          	auipc	ra,0xffffd
    8000506e:	df4080e7          	jalr	-524(ra) # 80001e5e <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80005072:	409c                	lw	a5,0(s1)
    80005074:	37f9                	addiw	a5,a5,-2
    80005076:	4705                	li	a4,1
    80005078:	04f76763          	bltu	a4,a5,800050c6 <filestat+0x6e>
    8000507c:	892a                	mv	s2,a0
    ilock(f->ip);
    8000507e:	6c88                	ld	a0,24(s1)
    80005080:	fffff097          	auipc	ra,0xfffff
    80005084:	072080e7          	jalr	114(ra) # 800040f2 <ilock>
    stati(f->ip, &st);
    80005088:	fb840593          	addi	a1,s0,-72
    8000508c:	6c88                	ld	a0,24(s1)
    8000508e:	fffff097          	auipc	ra,0xfffff
    80005092:	2ee080e7          	jalr	750(ra) # 8000437c <stati>
    iunlock(f->ip);
    80005096:	6c88                	ld	a0,24(s1)
    80005098:	fffff097          	auipc	ra,0xfffff
    8000509c:	11c080e7          	jalr	284(ra) # 800041b4 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800050a0:	46e1                	li	a3,24
    800050a2:	fb840613          	addi	a2,s0,-72
    800050a6:	85ce                	mv	a1,s3
    800050a8:	06893503          	ld	a0,104(s2)
    800050ac:	ffffc097          	auipc	ra,0xffffc
    800050b0:	5c6080e7          	jalr	1478(ra) # 80001672 <copyout>
    800050b4:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800050b8:	60a6                	ld	ra,72(sp)
    800050ba:	6406                	ld	s0,64(sp)
    800050bc:	74e2                	ld	s1,56(sp)
    800050be:	7942                	ld	s2,48(sp)
    800050c0:	79a2                	ld	s3,40(sp)
    800050c2:	6161                	addi	sp,sp,80
    800050c4:	8082                	ret
  return -1;
    800050c6:	557d                	li	a0,-1
    800050c8:	bfc5                	j	800050b8 <filestat+0x60>

00000000800050ca <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800050ca:	7179                	addi	sp,sp,-48
    800050cc:	f406                	sd	ra,40(sp)
    800050ce:	f022                	sd	s0,32(sp)
    800050d0:	ec26                	sd	s1,24(sp)
    800050d2:	e84a                	sd	s2,16(sp)
    800050d4:	e44e                	sd	s3,8(sp)
    800050d6:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800050d8:	00854783          	lbu	a5,8(a0)
    800050dc:	c3d5                	beqz	a5,80005180 <fileread+0xb6>
    800050de:	84aa                	mv	s1,a0
    800050e0:	89ae                	mv	s3,a1
    800050e2:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800050e4:	411c                	lw	a5,0(a0)
    800050e6:	4705                	li	a4,1
    800050e8:	04e78963          	beq	a5,a4,8000513a <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800050ec:	470d                	li	a4,3
    800050ee:	04e78d63          	beq	a5,a4,80005148 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800050f2:	4709                	li	a4,2
    800050f4:	06e79e63          	bne	a5,a4,80005170 <fileread+0xa6>
    ilock(f->ip);
    800050f8:	6d08                	ld	a0,24(a0)
    800050fa:	fffff097          	auipc	ra,0xfffff
    800050fe:	ff8080e7          	jalr	-8(ra) # 800040f2 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80005102:	874a                	mv	a4,s2
    80005104:	5094                	lw	a3,32(s1)
    80005106:	864e                	mv	a2,s3
    80005108:	4585                	li	a1,1
    8000510a:	6c88                	ld	a0,24(s1)
    8000510c:	fffff097          	auipc	ra,0xfffff
    80005110:	29a080e7          	jalr	666(ra) # 800043a6 <readi>
    80005114:	892a                	mv	s2,a0
    80005116:	00a05563          	blez	a0,80005120 <fileread+0x56>
      f->off += r;
    8000511a:	509c                	lw	a5,32(s1)
    8000511c:	9fa9                	addw	a5,a5,a0
    8000511e:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80005120:	6c88                	ld	a0,24(s1)
    80005122:	fffff097          	auipc	ra,0xfffff
    80005126:	092080e7          	jalr	146(ra) # 800041b4 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000512a:	854a                	mv	a0,s2
    8000512c:	70a2                	ld	ra,40(sp)
    8000512e:	7402                	ld	s0,32(sp)
    80005130:	64e2                	ld	s1,24(sp)
    80005132:	6942                	ld	s2,16(sp)
    80005134:	69a2                	ld	s3,8(sp)
    80005136:	6145                	addi	sp,sp,48
    80005138:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000513a:	6908                	ld	a0,16(a0)
    8000513c:	00000097          	auipc	ra,0x0
    80005140:	3c8080e7          	jalr	968(ra) # 80005504 <piperead>
    80005144:	892a                	mv	s2,a0
    80005146:	b7d5                	j	8000512a <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80005148:	02451783          	lh	a5,36(a0)
    8000514c:	03079693          	slli	a3,a5,0x30
    80005150:	92c1                	srli	a3,a3,0x30
    80005152:	4725                	li	a4,9
    80005154:	02d76863          	bltu	a4,a3,80005184 <fileread+0xba>
    80005158:	0792                	slli	a5,a5,0x4
    8000515a:	0001d717          	auipc	a4,0x1d
    8000515e:	cae70713          	addi	a4,a4,-850 # 80021e08 <devsw>
    80005162:	97ba                	add	a5,a5,a4
    80005164:	639c                	ld	a5,0(a5)
    80005166:	c38d                	beqz	a5,80005188 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80005168:	4505                	li	a0,1
    8000516a:	9782                	jalr	a5
    8000516c:	892a                	mv	s2,a0
    8000516e:	bf75                	j	8000512a <fileread+0x60>
    panic("fileread");
    80005170:	00003517          	auipc	a0,0x3
    80005174:	5b850513          	addi	a0,a0,1464 # 80008728 <syscalls+0x270>
    80005178:	ffffb097          	auipc	ra,0xffffb
    8000517c:	3c6080e7          	jalr	966(ra) # 8000053e <panic>
    return -1;
    80005180:	597d                	li	s2,-1
    80005182:	b765                	j	8000512a <fileread+0x60>
      return -1;
    80005184:	597d                	li	s2,-1
    80005186:	b755                	j	8000512a <fileread+0x60>
    80005188:	597d                	li	s2,-1
    8000518a:	b745                	j	8000512a <fileread+0x60>

000000008000518c <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    8000518c:	715d                	addi	sp,sp,-80
    8000518e:	e486                	sd	ra,72(sp)
    80005190:	e0a2                	sd	s0,64(sp)
    80005192:	fc26                	sd	s1,56(sp)
    80005194:	f84a                	sd	s2,48(sp)
    80005196:	f44e                	sd	s3,40(sp)
    80005198:	f052                	sd	s4,32(sp)
    8000519a:	ec56                	sd	s5,24(sp)
    8000519c:	e85a                	sd	s6,16(sp)
    8000519e:	e45e                	sd	s7,8(sp)
    800051a0:	e062                	sd	s8,0(sp)
    800051a2:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800051a4:	00954783          	lbu	a5,9(a0)
    800051a8:	10078663          	beqz	a5,800052b4 <filewrite+0x128>
    800051ac:	892a                	mv	s2,a0
    800051ae:	8aae                	mv	s5,a1
    800051b0:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800051b2:	411c                	lw	a5,0(a0)
    800051b4:	4705                	li	a4,1
    800051b6:	02e78263          	beq	a5,a4,800051da <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800051ba:	470d                	li	a4,3
    800051bc:	02e78663          	beq	a5,a4,800051e8 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800051c0:	4709                	li	a4,2
    800051c2:	0ee79163          	bne	a5,a4,800052a4 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800051c6:	0ac05d63          	blez	a2,80005280 <filewrite+0xf4>
    int i = 0;
    800051ca:	4981                	li	s3,0
    800051cc:	6b05                	lui	s6,0x1
    800051ce:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800051d2:	6b85                	lui	s7,0x1
    800051d4:	c00b8b9b          	addiw	s7,s7,-1024
    800051d8:	a861                	j	80005270 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800051da:	6908                	ld	a0,16(a0)
    800051dc:	00000097          	auipc	ra,0x0
    800051e0:	22e080e7          	jalr	558(ra) # 8000540a <pipewrite>
    800051e4:	8a2a                	mv	s4,a0
    800051e6:	a045                	j	80005286 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800051e8:	02451783          	lh	a5,36(a0)
    800051ec:	03079693          	slli	a3,a5,0x30
    800051f0:	92c1                	srli	a3,a3,0x30
    800051f2:	4725                	li	a4,9
    800051f4:	0cd76263          	bltu	a4,a3,800052b8 <filewrite+0x12c>
    800051f8:	0792                	slli	a5,a5,0x4
    800051fa:	0001d717          	auipc	a4,0x1d
    800051fe:	c0e70713          	addi	a4,a4,-1010 # 80021e08 <devsw>
    80005202:	97ba                	add	a5,a5,a4
    80005204:	679c                	ld	a5,8(a5)
    80005206:	cbdd                	beqz	a5,800052bc <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80005208:	4505                	li	a0,1
    8000520a:	9782                	jalr	a5
    8000520c:	8a2a                	mv	s4,a0
    8000520e:	a8a5                	j	80005286 <filewrite+0xfa>
    80005210:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80005214:	00000097          	auipc	ra,0x0
    80005218:	8b0080e7          	jalr	-1872(ra) # 80004ac4 <begin_op>
      ilock(f->ip);
    8000521c:	01893503          	ld	a0,24(s2)
    80005220:	fffff097          	auipc	ra,0xfffff
    80005224:	ed2080e7          	jalr	-302(ra) # 800040f2 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80005228:	8762                	mv	a4,s8
    8000522a:	02092683          	lw	a3,32(s2)
    8000522e:	01598633          	add	a2,s3,s5
    80005232:	4585                	li	a1,1
    80005234:	01893503          	ld	a0,24(s2)
    80005238:	fffff097          	auipc	ra,0xfffff
    8000523c:	266080e7          	jalr	614(ra) # 8000449e <writei>
    80005240:	84aa                	mv	s1,a0
    80005242:	00a05763          	blez	a0,80005250 <filewrite+0xc4>
        f->off += r;
    80005246:	02092783          	lw	a5,32(s2)
    8000524a:	9fa9                	addw	a5,a5,a0
    8000524c:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80005250:	01893503          	ld	a0,24(s2)
    80005254:	fffff097          	auipc	ra,0xfffff
    80005258:	f60080e7          	jalr	-160(ra) # 800041b4 <iunlock>
      end_op();
    8000525c:	00000097          	auipc	ra,0x0
    80005260:	8e8080e7          	jalr	-1816(ra) # 80004b44 <end_op>

      if(r != n1){
    80005264:	009c1f63          	bne	s8,s1,80005282 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80005268:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000526c:	0149db63          	bge	s3,s4,80005282 <filewrite+0xf6>
      int n1 = n - i;
    80005270:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80005274:	84be                	mv	s1,a5
    80005276:	2781                	sext.w	a5,a5
    80005278:	f8fb5ce3          	bge	s6,a5,80005210 <filewrite+0x84>
    8000527c:	84de                	mv	s1,s7
    8000527e:	bf49                	j	80005210 <filewrite+0x84>
    int i = 0;
    80005280:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80005282:	013a1f63          	bne	s4,s3,800052a0 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80005286:	8552                	mv	a0,s4
    80005288:	60a6                	ld	ra,72(sp)
    8000528a:	6406                	ld	s0,64(sp)
    8000528c:	74e2                	ld	s1,56(sp)
    8000528e:	7942                	ld	s2,48(sp)
    80005290:	79a2                	ld	s3,40(sp)
    80005292:	7a02                	ld	s4,32(sp)
    80005294:	6ae2                	ld	s5,24(sp)
    80005296:	6b42                	ld	s6,16(sp)
    80005298:	6ba2                	ld	s7,8(sp)
    8000529a:	6c02                	ld	s8,0(sp)
    8000529c:	6161                	addi	sp,sp,80
    8000529e:	8082                	ret
    ret = (i == n ? n : -1);
    800052a0:	5a7d                	li	s4,-1
    800052a2:	b7d5                	j	80005286 <filewrite+0xfa>
    panic("filewrite");
    800052a4:	00003517          	auipc	a0,0x3
    800052a8:	49450513          	addi	a0,a0,1172 # 80008738 <syscalls+0x280>
    800052ac:	ffffb097          	auipc	ra,0xffffb
    800052b0:	292080e7          	jalr	658(ra) # 8000053e <panic>
    return -1;
    800052b4:	5a7d                	li	s4,-1
    800052b6:	bfc1                	j	80005286 <filewrite+0xfa>
      return -1;
    800052b8:	5a7d                	li	s4,-1
    800052ba:	b7f1                	j	80005286 <filewrite+0xfa>
    800052bc:	5a7d                	li	s4,-1
    800052be:	b7e1                	j	80005286 <filewrite+0xfa>

00000000800052c0 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800052c0:	7179                	addi	sp,sp,-48
    800052c2:	f406                	sd	ra,40(sp)
    800052c4:	f022                	sd	s0,32(sp)
    800052c6:	ec26                	sd	s1,24(sp)
    800052c8:	e84a                	sd	s2,16(sp)
    800052ca:	e44e                	sd	s3,8(sp)
    800052cc:	e052                	sd	s4,0(sp)
    800052ce:	1800                	addi	s0,sp,48
    800052d0:	84aa                	mv	s1,a0
    800052d2:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800052d4:	0005b023          	sd	zero,0(a1)
    800052d8:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800052dc:	00000097          	auipc	ra,0x0
    800052e0:	bf8080e7          	jalr	-1032(ra) # 80004ed4 <filealloc>
    800052e4:	e088                	sd	a0,0(s1)
    800052e6:	c551                	beqz	a0,80005372 <pipealloc+0xb2>
    800052e8:	00000097          	auipc	ra,0x0
    800052ec:	bec080e7          	jalr	-1044(ra) # 80004ed4 <filealloc>
    800052f0:	00aa3023          	sd	a0,0(s4)
    800052f4:	c92d                	beqz	a0,80005366 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800052f6:	ffffb097          	auipc	ra,0xffffb
    800052fa:	7fe080e7          	jalr	2046(ra) # 80000af4 <kalloc>
    800052fe:	892a                	mv	s2,a0
    80005300:	c125                	beqz	a0,80005360 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80005302:	4985                	li	s3,1
    80005304:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80005308:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    8000530c:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80005310:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80005314:	00003597          	auipc	a1,0x3
    80005318:	43458593          	addi	a1,a1,1076 # 80008748 <syscalls+0x290>
    8000531c:	ffffc097          	auipc	ra,0xffffc
    80005320:	838080e7          	jalr	-1992(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80005324:	609c                	ld	a5,0(s1)
    80005326:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    8000532a:	609c                	ld	a5,0(s1)
    8000532c:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005330:	609c                	ld	a5,0(s1)
    80005332:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80005336:	609c                	ld	a5,0(s1)
    80005338:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000533c:	000a3783          	ld	a5,0(s4)
    80005340:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005344:	000a3783          	ld	a5,0(s4)
    80005348:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000534c:	000a3783          	ld	a5,0(s4)
    80005350:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005354:	000a3783          	ld	a5,0(s4)
    80005358:	0127b823          	sd	s2,16(a5)
  return 0;
    8000535c:	4501                	li	a0,0
    8000535e:	a025                	j	80005386 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80005360:	6088                	ld	a0,0(s1)
    80005362:	e501                	bnez	a0,8000536a <pipealloc+0xaa>
    80005364:	a039                	j	80005372 <pipealloc+0xb2>
    80005366:	6088                	ld	a0,0(s1)
    80005368:	c51d                	beqz	a0,80005396 <pipealloc+0xd6>
    fileclose(*f0);
    8000536a:	00000097          	auipc	ra,0x0
    8000536e:	c26080e7          	jalr	-986(ra) # 80004f90 <fileclose>
  if(*f1)
    80005372:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80005376:	557d                	li	a0,-1
  if(*f1)
    80005378:	c799                	beqz	a5,80005386 <pipealloc+0xc6>
    fileclose(*f1);
    8000537a:	853e                	mv	a0,a5
    8000537c:	00000097          	auipc	ra,0x0
    80005380:	c14080e7          	jalr	-1004(ra) # 80004f90 <fileclose>
  return -1;
    80005384:	557d                	li	a0,-1
}
    80005386:	70a2                	ld	ra,40(sp)
    80005388:	7402                	ld	s0,32(sp)
    8000538a:	64e2                	ld	s1,24(sp)
    8000538c:	6942                	ld	s2,16(sp)
    8000538e:	69a2                	ld	s3,8(sp)
    80005390:	6a02                	ld	s4,0(sp)
    80005392:	6145                	addi	sp,sp,48
    80005394:	8082                	ret
  return -1;
    80005396:	557d                	li	a0,-1
    80005398:	b7fd                	j	80005386 <pipealloc+0xc6>

000000008000539a <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    8000539a:	1101                	addi	sp,sp,-32
    8000539c:	ec06                	sd	ra,24(sp)
    8000539e:	e822                	sd	s0,16(sp)
    800053a0:	e426                	sd	s1,8(sp)
    800053a2:	e04a                	sd	s2,0(sp)
    800053a4:	1000                	addi	s0,sp,32
    800053a6:	84aa                	mv	s1,a0
    800053a8:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800053aa:	ffffc097          	auipc	ra,0xffffc
    800053ae:	83a080e7          	jalr	-1990(ra) # 80000be4 <acquire>
  if(writable){
    800053b2:	02090d63          	beqz	s2,800053ec <pipeclose+0x52>
    pi->writeopen = 0;
    800053b6:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800053ba:	21848513          	addi	a0,s1,536
    800053be:	ffffd097          	auipc	ra,0xffffd
    800053c2:	35e080e7          	jalr	862(ra) # 8000271c <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800053c6:	2204b783          	ld	a5,544(s1)
    800053ca:	eb95                	bnez	a5,800053fe <pipeclose+0x64>
    release(&pi->lock);
    800053cc:	8526                	mv	a0,s1
    800053ce:	ffffc097          	auipc	ra,0xffffc
    800053d2:	8ca080e7          	jalr	-1846(ra) # 80000c98 <release>
    kfree((char*)pi);
    800053d6:	8526                	mv	a0,s1
    800053d8:	ffffb097          	auipc	ra,0xffffb
    800053dc:	620080e7          	jalr	1568(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    800053e0:	60e2                	ld	ra,24(sp)
    800053e2:	6442                	ld	s0,16(sp)
    800053e4:	64a2                	ld	s1,8(sp)
    800053e6:	6902                	ld	s2,0(sp)
    800053e8:	6105                	addi	sp,sp,32
    800053ea:	8082                	ret
    pi->readopen = 0;
    800053ec:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800053f0:	21c48513          	addi	a0,s1,540
    800053f4:	ffffd097          	auipc	ra,0xffffd
    800053f8:	328080e7          	jalr	808(ra) # 8000271c <wakeup>
    800053fc:	b7e9                	j	800053c6 <pipeclose+0x2c>
    release(&pi->lock);
    800053fe:	8526                	mv	a0,s1
    80005400:	ffffc097          	auipc	ra,0xffffc
    80005404:	898080e7          	jalr	-1896(ra) # 80000c98 <release>
}
    80005408:	bfe1                	j	800053e0 <pipeclose+0x46>

000000008000540a <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    8000540a:	7159                	addi	sp,sp,-112
    8000540c:	f486                	sd	ra,104(sp)
    8000540e:	f0a2                	sd	s0,96(sp)
    80005410:	eca6                	sd	s1,88(sp)
    80005412:	e8ca                	sd	s2,80(sp)
    80005414:	e4ce                	sd	s3,72(sp)
    80005416:	e0d2                	sd	s4,64(sp)
    80005418:	fc56                	sd	s5,56(sp)
    8000541a:	f85a                	sd	s6,48(sp)
    8000541c:	f45e                	sd	s7,40(sp)
    8000541e:	f062                	sd	s8,32(sp)
    80005420:	ec66                	sd	s9,24(sp)
    80005422:	1880                	addi	s0,sp,112
    80005424:	84aa                	mv	s1,a0
    80005426:	8aae                	mv	s5,a1
    80005428:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    8000542a:	ffffd097          	auipc	ra,0xffffd
    8000542e:	a34080e7          	jalr	-1484(ra) # 80001e5e <myproc>
    80005432:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005434:	8526                	mv	a0,s1
    80005436:	ffffb097          	auipc	ra,0xffffb
    8000543a:	7ae080e7          	jalr	1966(ra) # 80000be4 <acquire>
  while(i < n){
    8000543e:	0d405163          	blez	s4,80005500 <pipewrite+0xf6>
    80005442:	8ba6                	mv	s7,s1
  int i = 0;
    80005444:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005446:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005448:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    8000544c:	21c48c13          	addi	s8,s1,540
    80005450:	a08d                	j	800054b2 <pipewrite+0xa8>
      release(&pi->lock);
    80005452:	8526                	mv	a0,s1
    80005454:	ffffc097          	auipc	ra,0xffffc
    80005458:	844080e7          	jalr	-1980(ra) # 80000c98 <release>
      return -1;
    8000545c:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    8000545e:	854a                	mv	a0,s2
    80005460:	70a6                	ld	ra,104(sp)
    80005462:	7406                	ld	s0,96(sp)
    80005464:	64e6                	ld	s1,88(sp)
    80005466:	6946                	ld	s2,80(sp)
    80005468:	69a6                	ld	s3,72(sp)
    8000546a:	6a06                	ld	s4,64(sp)
    8000546c:	7ae2                	ld	s5,56(sp)
    8000546e:	7b42                	ld	s6,48(sp)
    80005470:	7ba2                	ld	s7,40(sp)
    80005472:	7c02                	ld	s8,32(sp)
    80005474:	6ce2                	ld	s9,24(sp)
    80005476:	6165                	addi	sp,sp,112
    80005478:	8082                	ret
      wakeup(&pi->nread);
    8000547a:	8566                	mv	a0,s9
    8000547c:	ffffd097          	auipc	ra,0xffffd
    80005480:	2a0080e7          	jalr	672(ra) # 8000271c <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005484:	85de                	mv	a1,s7
    80005486:	8562                	mv	a0,s8
    80005488:	ffffd097          	auipc	ra,0xffffd
    8000548c:	0f2080e7          	jalr	242(ra) # 8000257a <sleep>
    80005490:	a839                	j	800054ae <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005492:	21c4a783          	lw	a5,540(s1)
    80005496:	0017871b          	addiw	a4,a5,1
    8000549a:	20e4ae23          	sw	a4,540(s1)
    8000549e:	1ff7f793          	andi	a5,a5,511
    800054a2:	97a6                	add	a5,a5,s1
    800054a4:	f9f44703          	lbu	a4,-97(s0)
    800054a8:	00e78c23          	sb	a4,24(a5)
      i++;
    800054ac:	2905                	addiw	s2,s2,1
  while(i < n){
    800054ae:	03495d63          	bge	s2,s4,800054e8 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    800054b2:	2204a783          	lw	a5,544(s1)
    800054b6:	dfd1                	beqz	a5,80005452 <pipewrite+0x48>
    800054b8:	0409a783          	lw	a5,64(s3)
    800054bc:	fbd9                	bnez	a5,80005452 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800054be:	2184a783          	lw	a5,536(s1)
    800054c2:	21c4a703          	lw	a4,540(s1)
    800054c6:	2007879b          	addiw	a5,a5,512
    800054ca:	faf708e3          	beq	a4,a5,8000547a <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800054ce:	4685                	li	a3,1
    800054d0:	01590633          	add	a2,s2,s5
    800054d4:	f9f40593          	addi	a1,s0,-97
    800054d8:	0689b503          	ld	a0,104(s3)
    800054dc:	ffffc097          	auipc	ra,0xffffc
    800054e0:	222080e7          	jalr	546(ra) # 800016fe <copyin>
    800054e4:	fb6517e3          	bne	a0,s6,80005492 <pipewrite+0x88>
  wakeup(&pi->nread);
    800054e8:	21848513          	addi	a0,s1,536
    800054ec:	ffffd097          	auipc	ra,0xffffd
    800054f0:	230080e7          	jalr	560(ra) # 8000271c <wakeup>
  release(&pi->lock);
    800054f4:	8526                	mv	a0,s1
    800054f6:	ffffb097          	auipc	ra,0xffffb
    800054fa:	7a2080e7          	jalr	1954(ra) # 80000c98 <release>
  return i;
    800054fe:	b785                	j	8000545e <pipewrite+0x54>
  int i = 0;
    80005500:	4901                	li	s2,0
    80005502:	b7dd                	j	800054e8 <pipewrite+0xde>

0000000080005504 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005504:	715d                	addi	sp,sp,-80
    80005506:	e486                	sd	ra,72(sp)
    80005508:	e0a2                	sd	s0,64(sp)
    8000550a:	fc26                	sd	s1,56(sp)
    8000550c:	f84a                	sd	s2,48(sp)
    8000550e:	f44e                	sd	s3,40(sp)
    80005510:	f052                	sd	s4,32(sp)
    80005512:	ec56                	sd	s5,24(sp)
    80005514:	e85a                	sd	s6,16(sp)
    80005516:	0880                	addi	s0,sp,80
    80005518:	84aa                	mv	s1,a0
    8000551a:	892e                	mv	s2,a1
    8000551c:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    8000551e:	ffffd097          	auipc	ra,0xffffd
    80005522:	940080e7          	jalr	-1728(ra) # 80001e5e <myproc>
    80005526:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005528:	8b26                	mv	s6,s1
    8000552a:	8526                	mv	a0,s1
    8000552c:	ffffb097          	auipc	ra,0xffffb
    80005530:	6b8080e7          	jalr	1720(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005534:	2184a703          	lw	a4,536(s1)
    80005538:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000553c:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005540:	02f71463          	bne	a4,a5,80005568 <piperead+0x64>
    80005544:	2244a783          	lw	a5,548(s1)
    80005548:	c385                	beqz	a5,80005568 <piperead+0x64>
    if(pr->killed){
    8000554a:	040a2783          	lw	a5,64(s4)
    8000554e:	ebc1                	bnez	a5,800055de <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005550:	85da                	mv	a1,s6
    80005552:	854e                	mv	a0,s3
    80005554:	ffffd097          	auipc	ra,0xffffd
    80005558:	026080e7          	jalr	38(ra) # 8000257a <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000555c:	2184a703          	lw	a4,536(s1)
    80005560:	21c4a783          	lw	a5,540(s1)
    80005564:	fef700e3          	beq	a4,a5,80005544 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005568:	09505263          	blez	s5,800055ec <piperead+0xe8>
    8000556c:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000556e:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80005570:	2184a783          	lw	a5,536(s1)
    80005574:	21c4a703          	lw	a4,540(s1)
    80005578:	02f70d63          	beq	a4,a5,800055b2 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    8000557c:	0017871b          	addiw	a4,a5,1
    80005580:	20e4ac23          	sw	a4,536(s1)
    80005584:	1ff7f793          	andi	a5,a5,511
    80005588:	97a6                	add	a5,a5,s1
    8000558a:	0187c783          	lbu	a5,24(a5)
    8000558e:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005592:	4685                	li	a3,1
    80005594:	fbf40613          	addi	a2,s0,-65
    80005598:	85ca                	mv	a1,s2
    8000559a:	068a3503          	ld	a0,104(s4)
    8000559e:	ffffc097          	auipc	ra,0xffffc
    800055a2:	0d4080e7          	jalr	212(ra) # 80001672 <copyout>
    800055a6:	01650663          	beq	a0,s6,800055b2 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800055aa:	2985                	addiw	s3,s3,1
    800055ac:	0905                	addi	s2,s2,1
    800055ae:	fd3a91e3          	bne	s5,s3,80005570 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800055b2:	21c48513          	addi	a0,s1,540
    800055b6:	ffffd097          	auipc	ra,0xffffd
    800055ba:	166080e7          	jalr	358(ra) # 8000271c <wakeup>
  release(&pi->lock);
    800055be:	8526                	mv	a0,s1
    800055c0:	ffffb097          	auipc	ra,0xffffb
    800055c4:	6d8080e7          	jalr	1752(ra) # 80000c98 <release>
  return i;
}
    800055c8:	854e                	mv	a0,s3
    800055ca:	60a6                	ld	ra,72(sp)
    800055cc:	6406                	ld	s0,64(sp)
    800055ce:	74e2                	ld	s1,56(sp)
    800055d0:	7942                	ld	s2,48(sp)
    800055d2:	79a2                	ld	s3,40(sp)
    800055d4:	7a02                	ld	s4,32(sp)
    800055d6:	6ae2                	ld	s5,24(sp)
    800055d8:	6b42                	ld	s6,16(sp)
    800055da:	6161                	addi	sp,sp,80
    800055dc:	8082                	ret
      release(&pi->lock);
    800055de:	8526                	mv	a0,s1
    800055e0:	ffffb097          	auipc	ra,0xffffb
    800055e4:	6b8080e7          	jalr	1720(ra) # 80000c98 <release>
      return -1;
    800055e8:	59fd                	li	s3,-1
    800055ea:	bff9                	j	800055c8 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800055ec:	4981                	li	s3,0
    800055ee:	b7d1                	j	800055b2 <piperead+0xae>

00000000800055f0 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    800055f0:	df010113          	addi	sp,sp,-528
    800055f4:	20113423          	sd	ra,520(sp)
    800055f8:	20813023          	sd	s0,512(sp)
    800055fc:	ffa6                	sd	s1,504(sp)
    800055fe:	fbca                	sd	s2,496(sp)
    80005600:	f7ce                	sd	s3,488(sp)
    80005602:	f3d2                	sd	s4,480(sp)
    80005604:	efd6                	sd	s5,472(sp)
    80005606:	ebda                	sd	s6,464(sp)
    80005608:	e7de                	sd	s7,456(sp)
    8000560a:	e3e2                	sd	s8,448(sp)
    8000560c:	ff66                	sd	s9,440(sp)
    8000560e:	fb6a                	sd	s10,432(sp)
    80005610:	f76e                	sd	s11,424(sp)
    80005612:	0c00                	addi	s0,sp,528
    80005614:	84aa                	mv	s1,a0
    80005616:	dea43c23          	sd	a0,-520(s0)
    8000561a:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    8000561e:	ffffd097          	auipc	ra,0xffffd
    80005622:	840080e7          	jalr	-1984(ra) # 80001e5e <myproc>
    80005626:	892a                	mv	s2,a0

  begin_op();
    80005628:	fffff097          	auipc	ra,0xfffff
    8000562c:	49c080e7          	jalr	1180(ra) # 80004ac4 <begin_op>

  if((ip = namei(path)) == 0){
    80005630:	8526                	mv	a0,s1
    80005632:	fffff097          	auipc	ra,0xfffff
    80005636:	276080e7          	jalr	630(ra) # 800048a8 <namei>
    8000563a:	c92d                	beqz	a0,800056ac <exec+0xbc>
    8000563c:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    8000563e:	fffff097          	auipc	ra,0xfffff
    80005642:	ab4080e7          	jalr	-1356(ra) # 800040f2 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005646:	04000713          	li	a4,64
    8000564a:	4681                	li	a3,0
    8000564c:	e5040613          	addi	a2,s0,-432
    80005650:	4581                	li	a1,0
    80005652:	8526                	mv	a0,s1
    80005654:	fffff097          	auipc	ra,0xfffff
    80005658:	d52080e7          	jalr	-686(ra) # 800043a6 <readi>
    8000565c:	04000793          	li	a5,64
    80005660:	00f51a63          	bne	a0,a5,80005674 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005664:	e5042703          	lw	a4,-432(s0)
    80005668:	464c47b7          	lui	a5,0x464c4
    8000566c:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005670:	04f70463          	beq	a4,a5,800056b8 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005674:	8526                	mv	a0,s1
    80005676:	fffff097          	auipc	ra,0xfffff
    8000567a:	cde080e7          	jalr	-802(ra) # 80004354 <iunlockput>
    end_op();
    8000567e:	fffff097          	auipc	ra,0xfffff
    80005682:	4c6080e7          	jalr	1222(ra) # 80004b44 <end_op>
  }
  return -1;
    80005686:	557d                	li	a0,-1
}
    80005688:	20813083          	ld	ra,520(sp)
    8000568c:	20013403          	ld	s0,512(sp)
    80005690:	74fe                	ld	s1,504(sp)
    80005692:	795e                	ld	s2,496(sp)
    80005694:	79be                	ld	s3,488(sp)
    80005696:	7a1e                	ld	s4,480(sp)
    80005698:	6afe                	ld	s5,472(sp)
    8000569a:	6b5e                	ld	s6,464(sp)
    8000569c:	6bbe                	ld	s7,456(sp)
    8000569e:	6c1e                	ld	s8,448(sp)
    800056a0:	7cfa                	ld	s9,440(sp)
    800056a2:	7d5a                	ld	s10,432(sp)
    800056a4:	7dba                	ld	s11,424(sp)
    800056a6:	21010113          	addi	sp,sp,528
    800056aa:	8082                	ret
    end_op();
    800056ac:	fffff097          	auipc	ra,0xfffff
    800056b0:	498080e7          	jalr	1176(ra) # 80004b44 <end_op>
    return -1;
    800056b4:	557d                	li	a0,-1
    800056b6:	bfc9                	j	80005688 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    800056b8:	854a                	mv	a0,s2
    800056ba:	ffffd097          	auipc	ra,0xffffd
    800056be:	85c080e7          	jalr	-1956(ra) # 80001f16 <proc_pagetable>
    800056c2:	8baa                	mv	s7,a0
    800056c4:	d945                	beqz	a0,80005674 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800056c6:	e7042983          	lw	s3,-400(s0)
    800056ca:	e8845783          	lhu	a5,-376(s0)
    800056ce:	c7ad                	beqz	a5,80005738 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800056d0:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800056d2:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    800056d4:	6c85                	lui	s9,0x1
    800056d6:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    800056da:	def43823          	sd	a5,-528(s0)
    800056de:	a42d                	j	80005908 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800056e0:	00003517          	auipc	a0,0x3
    800056e4:	07050513          	addi	a0,a0,112 # 80008750 <syscalls+0x298>
    800056e8:	ffffb097          	auipc	ra,0xffffb
    800056ec:	e56080e7          	jalr	-426(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800056f0:	8756                	mv	a4,s5
    800056f2:	012d86bb          	addw	a3,s11,s2
    800056f6:	4581                	li	a1,0
    800056f8:	8526                	mv	a0,s1
    800056fa:	fffff097          	auipc	ra,0xfffff
    800056fe:	cac080e7          	jalr	-852(ra) # 800043a6 <readi>
    80005702:	2501                	sext.w	a0,a0
    80005704:	1aaa9963          	bne	s5,a0,800058b6 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80005708:	6785                	lui	a5,0x1
    8000570a:	0127893b          	addw	s2,a5,s2
    8000570e:	77fd                	lui	a5,0xfffff
    80005710:	01478a3b          	addw	s4,a5,s4
    80005714:	1f897163          	bgeu	s2,s8,800058f6 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80005718:	02091593          	slli	a1,s2,0x20
    8000571c:	9181                	srli	a1,a1,0x20
    8000571e:	95ea                	add	a1,a1,s10
    80005720:	855e                	mv	a0,s7
    80005722:	ffffc097          	auipc	ra,0xffffc
    80005726:	94c080e7          	jalr	-1716(ra) # 8000106e <walkaddr>
    8000572a:	862a                	mv	a2,a0
    if(pa == 0)
    8000572c:	d955                	beqz	a0,800056e0 <exec+0xf0>
      n = PGSIZE;
    8000572e:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80005730:	fd9a70e3          	bgeu	s4,s9,800056f0 <exec+0x100>
      n = sz - i;
    80005734:	8ad2                	mv	s5,s4
    80005736:	bf6d                	j	800056f0 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005738:	4901                	li	s2,0
  iunlockput(ip);
    8000573a:	8526                	mv	a0,s1
    8000573c:	fffff097          	auipc	ra,0xfffff
    80005740:	c18080e7          	jalr	-1000(ra) # 80004354 <iunlockput>
  end_op();
    80005744:	fffff097          	auipc	ra,0xfffff
    80005748:	400080e7          	jalr	1024(ra) # 80004b44 <end_op>
  p = myproc();
    8000574c:	ffffc097          	auipc	ra,0xffffc
    80005750:	712080e7          	jalr	1810(ra) # 80001e5e <myproc>
    80005754:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005756:	06053d03          	ld	s10,96(a0)
  sz = PGROUNDUP(sz);
    8000575a:	6785                	lui	a5,0x1
    8000575c:	17fd                	addi	a5,a5,-1
    8000575e:	993e                	add	s2,s2,a5
    80005760:	757d                	lui	a0,0xfffff
    80005762:	00a977b3          	and	a5,s2,a0
    80005766:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000576a:	6609                	lui	a2,0x2
    8000576c:	963e                	add	a2,a2,a5
    8000576e:	85be                	mv	a1,a5
    80005770:	855e                	mv	a0,s7
    80005772:	ffffc097          	auipc	ra,0xffffc
    80005776:	cb0080e7          	jalr	-848(ra) # 80001422 <uvmalloc>
    8000577a:	8b2a                	mv	s6,a0
  ip = 0;
    8000577c:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000577e:	12050c63          	beqz	a0,800058b6 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005782:	75f9                	lui	a1,0xffffe
    80005784:	95aa                	add	a1,a1,a0
    80005786:	855e                	mv	a0,s7
    80005788:	ffffc097          	auipc	ra,0xffffc
    8000578c:	eb8080e7          	jalr	-328(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    80005790:	7c7d                	lui	s8,0xfffff
    80005792:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80005794:	e0043783          	ld	a5,-512(s0)
    80005798:	6388                	ld	a0,0(a5)
    8000579a:	c535                	beqz	a0,80005806 <exec+0x216>
    8000579c:	e9040993          	addi	s3,s0,-368
    800057a0:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800057a4:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    800057a6:	ffffb097          	auipc	ra,0xffffb
    800057aa:	6be080e7          	jalr	1726(ra) # 80000e64 <strlen>
    800057ae:	2505                	addiw	a0,a0,1
    800057b0:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800057b4:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800057b8:	13896363          	bltu	s2,s8,800058de <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800057bc:	e0043d83          	ld	s11,-512(s0)
    800057c0:	000dba03          	ld	s4,0(s11)
    800057c4:	8552                	mv	a0,s4
    800057c6:	ffffb097          	auipc	ra,0xffffb
    800057ca:	69e080e7          	jalr	1694(ra) # 80000e64 <strlen>
    800057ce:	0015069b          	addiw	a3,a0,1
    800057d2:	8652                	mv	a2,s4
    800057d4:	85ca                	mv	a1,s2
    800057d6:	855e                	mv	a0,s7
    800057d8:	ffffc097          	auipc	ra,0xffffc
    800057dc:	e9a080e7          	jalr	-358(ra) # 80001672 <copyout>
    800057e0:	10054363          	bltz	a0,800058e6 <exec+0x2f6>
    ustack[argc] = sp;
    800057e4:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800057e8:	0485                	addi	s1,s1,1
    800057ea:	008d8793          	addi	a5,s11,8
    800057ee:	e0f43023          	sd	a5,-512(s0)
    800057f2:	008db503          	ld	a0,8(s11)
    800057f6:	c911                	beqz	a0,8000580a <exec+0x21a>
    if(argc >= MAXARG)
    800057f8:	09a1                	addi	s3,s3,8
    800057fa:	fb3c96e3          	bne	s9,s3,800057a6 <exec+0x1b6>
  sz = sz1;
    800057fe:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005802:	4481                	li	s1,0
    80005804:	a84d                	j	800058b6 <exec+0x2c6>
  sp = sz;
    80005806:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005808:	4481                	li	s1,0
  ustack[argc] = 0;
    8000580a:	00349793          	slli	a5,s1,0x3
    8000580e:	f9040713          	addi	a4,s0,-112
    80005812:	97ba                	add	a5,a5,a4
    80005814:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80005818:	00148693          	addi	a3,s1,1
    8000581c:	068e                	slli	a3,a3,0x3
    8000581e:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005822:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005826:	01897663          	bgeu	s2,s8,80005832 <exec+0x242>
  sz = sz1;
    8000582a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000582e:	4481                	li	s1,0
    80005830:	a059                	j	800058b6 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005832:	e9040613          	addi	a2,s0,-368
    80005836:	85ca                	mv	a1,s2
    80005838:	855e                	mv	a0,s7
    8000583a:	ffffc097          	auipc	ra,0xffffc
    8000583e:	e38080e7          	jalr	-456(ra) # 80001672 <copyout>
    80005842:	0a054663          	bltz	a0,800058ee <exec+0x2fe>
  p->trapframe->a1 = sp;
    80005846:	070ab783          	ld	a5,112(s5)
    8000584a:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000584e:	df843783          	ld	a5,-520(s0)
    80005852:	0007c703          	lbu	a4,0(a5)
    80005856:	cf11                	beqz	a4,80005872 <exec+0x282>
    80005858:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000585a:	02f00693          	li	a3,47
    8000585e:	a039                	j	8000586c <exec+0x27c>
      last = s+1;
    80005860:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005864:	0785                	addi	a5,a5,1
    80005866:	fff7c703          	lbu	a4,-1(a5)
    8000586a:	c701                	beqz	a4,80005872 <exec+0x282>
    if(*s == '/')
    8000586c:	fed71ce3          	bne	a4,a3,80005864 <exec+0x274>
    80005870:	bfc5                	j	80005860 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005872:	4641                	li	a2,16
    80005874:	df843583          	ld	a1,-520(s0)
    80005878:	170a8513          	addi	a0,s5,368
    8000587c:	ffffb097          	auipc	ra,0xffffb
    80005880:	5b6080e7          	jalr	1462(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80005884:	068ab503          	ld	a0,104(s5)
  p->pagetable = pagetable;
    80005888:	077ab423          	sd	s7,104(s5)
  p->sz = sz;
    8000588c:	076ab023          	sd	s6,96(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005890:	070ab783          	ld	a5,112(s5)
    80005894:	e6843703          	ld	a4,-408(s0)
    80005898:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000589a:	070ab783          	ld	a5,112(s5)
    8000589e:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800058a2:	85ea                	mv	a1,s10
    800058a4:	ffffc097          	auipc	ra,0xffffc
    800058a8:	70e080e7          	jalr	1806(ra) # 80001fb2 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800058ac:	0004851b          	sext.w	a0,s1
    800058b0:	bbe1                	j	80005688 <exec+0x98>
    800058b2:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800058b6:	e0843583          	ld	a1,-504(s0)
    800058ba:	855e                	mv	a0,s7
    800058bc:	ffffc097          	auipc	ra,0xffffc
    800058c0:	6f6080e7          	jalr	1782(ra) # 80001fb2 <proc_freepagetable>
  if(ip){
    800058c4:	da0498e3          	bnez	s1,80005674 <exec+0x84>
  return -1;
    800058c8:	557d                	li	a0,-1
    800058ca:	bb7d                	j	80005688 <exec+0x98>
    800058cc:	e1243423          	sd	s2,-504(s0)
    800058d0:	b7dd                	j	800058b6 <exec+0x2c6>
    800058d2:	e1243423          	sd	s2,-504(s0)
    800058d6:	b7c5                	j	800058b6 <exec+0x2c6>
    800058d8:	e1243423          	sd	s2,-504(s0)
    800058dc:	bfe9                	j	800058b6 <exec+0x2c6>
  sz = sz1;
    800058de:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800058e2:	4481                	li	s1,0
    800058e4:	bfc9                	j	800058b6 <exec+0x2c6>
  sz = sz1;
    800058e6:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800058ea:	4481                	li	s1,0
    800058ec:	b7e9                	j	800058b6 <exec+0x2c6>
  sz = sz1;
    800058ee:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800058f2:	4481                	li	s1,0
    800058f4:	b7c9                	j	800058b6 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800058f6:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800058fa:	2b05                	addiw	s6,s6,1
    800058fc:	0389899b          	addiw	s3,s3,56
    80005900:	e8845783          	lhu	a5,-376(s0)
    80005904:	e2fb5be3          	bge	s6,a5,8000573a <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005908:	2981                	sext.w	s3,s3
    8000590a:	03800713          	li	a4,56
    8000590e:	86ce                	mv	a3,s3
    80005910:	e1840613          	addi	a2,s0,-488
    80005914:	4581                	li	a1,0
    80005916:	8526                	mv	a0,s1
    80005918:	fffff097          	auipc	ra,0xfffff
    8000591c:	a8e080e7          	jalr	-1394(ra) # 800043a6 <readi>
    80005920:	03800793          	li	a5,56
    80005924:	f8f517e3          	bne	a0,a5,800058b2 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005928:	e1842783          	lw	a5,-488(s0)
    8000592c:	4705                	li	a4,1
    8000592e:	fce796e3          	bne	a5,a4,800058fa <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005932:	e4043603          	ld	a2,-448(s0)
    80005936:	e3843783          	ld	a5,-456(s0)
    8000593a:	f8f669e3          	bltu	a2,a5,800058cc <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000593e:	e2843783          	ld	a5,-472(s0)
    80005942:	963e                	add	a2,a2,a5
    80005944:	f8f667e3          	bltu	a2,a5,800058d2 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005948:	85ca                	mv	a1,s2
    8000594a:	855e                	mv	a0,s7
    8000594c:	ffffc097          	auipc	ra,0xffffc
    80005950:	ad6080e7          	jalr	-1322(ra) # 80001422 <uvmalloc>
    80005954:	e0a43423          	sd	a0,-504(s0)
    80005958:	d141                	beqz	a0,800058d8 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    8000595a:	e2843d03          	ld	s10,-472(s0)
    8000595e:	df043783          	ld	a5,-528(s0)
    80005962:	00fd77b3          	and	a5,s10,a5
    80005966:	fba1                	bnez	a5,800058b6 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005968:	e2042d83          	lw	s11,-480(s0)
    8000596c:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005970:	f80c03e3          	beqz	s8,800058f6 <exec+0x306>
    80005974:	8a62                	mv	s4,s8
    80005976:	4901                	li	s2,0
    80005978:	b345                	j	80005718 <exec+0x128>

000000008000597a <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000597a:	7179                	addi	sp,sp,-48
    8000597c:	f406                	sd	ra,40(sp)
    8000597e:	f022                	sd	s0,32(sp)
    80005980:	ec26                	sd	s1,24(sp)
    80005982:	e84a                	sd	s2,16(sp)
    80005984:	1800                	addi	s0,sp,48
    80005986:	892e                	mv	s2,a1
    80005988:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000598a:	fdc40593          	addi	a1,s0,-36
    8000598e:	ffffe097          	auipc	ra,0xffffe
    80005992:	b76080e7          	jalr	-1162(ra) # 80003504 <argint>
    80005996:	04054063          	bltz	a0,800059d6 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000599a:	fdc42703          	lw	a4,-36(s0)
    8000599e:	47bd                	li	a5,15
    800059a0:	02e7ed63          	bltu	a5,a4,800059da <argfd+0x60>
    800059a4:	ffffc097          	auipc	ra,0xffffc
    800059a8:	4ba080e7          	jalr	1210(ra) # 80001e5e <myproc>
    800059ac:	fdc42703          	lw	a4,-36(s0)
    800059b0:	01c70793          	addi	a5,a4,28
    800059b4:	078e                	slli	a5,a5,0x3
    800059b6:	953e                	add	a0,a0,a5
    800059b8:	651c                	ld	a5,8(a0)
    800059ba:	c395                	beqz	a5,800059de <argfd+0x64>
    return -1;
  if(pfd)
    800059bc:	00090463          	beqz	s2,800059c4 <argfd+0x4a>
    *pfd = fd;
    800059c0:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800059c4:	4501                	li	a0,0
  if(pf)
    800059c6:	c091                	beqz	s1,800059ca <argfd+0x50>
    *pf = f;
    800059c8:	e09c                	sd	a5,0(s1)
}
    800059ca:	70a2                	ld	ra,40(sp)
    800059cc:	7402                	ld	s0,32(sp)
    800059ce:	64e2                	ld	s1,24(sp)
    800059d0:	6942                	ld	s2,16(sp)
    800059d2:	6145                	addi	sp,sp,48
    800059d4:	8082                	ret
    return -1;
    800059d6:	557d                	li	a0,-1
    800059d8:	bfcd                	j	800059ca <argfd+0x50>
    return -1;
    800059da:	557d                	li	a0,-1
    800059dc:	b7fd                	j	800059ca <argfd+0x50>
    800059de:	557d                	li	a0,-1
    800059e0:	b7ed                	j	800059ca <argfd+0x50>

00000000800059e2 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800059e2:	1101                	addi	sp,sp,-32
    800059e4:	ec06                	sd	ra,24(sp)
    800059e6:	e822                	sd	s0,16(sp)
    800059e8:	e426                	sd	s1,8(sp)
    800059ea:	1000                	addi	s0,sp,32
    800059ec:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800059ee:	ffffc097          	auipc	ra,0xffffc
    800059f2:	470080e7          	jalr	1136(ra) # 80001e5e <myproc>
    800059f6:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800059f8:	0e850793          	addi	a5,a0,232 # fffffffffffff0e8 <end+0xffffffff7ffd90e8>
    800059fc:	4501                	li	a0,0
    800059fe:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005a00:	6398                	ld	a4,0(a5)
    80005a02:	cb19                	beqz	a4,80005a18 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005a04:	2505                	addiw	a0,a0,1
    80005a06:	07a1                	addi	a5,a5,8
    80005a08:	fed51ce3          	bne	a0,a3,80005a00 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005a0c:	557d                	li	a0,-1
}
    80005a0e:	60e2                	ld	ra,24(sp)
    80005a10:	6442                	ld	s0,16(sp)
    80005a12:	64a2                	ld	s1,8(sp)
    80005a14:	6105                	addi	sp,sp,32
    80005a16:	8082                	ret
      p->ofile[fd] = f;
    80005a18:	01c50793          	addi	a5,a0,28
    80005a1c:	078e                	slli	a5,a5,0x3
    80005a1e:	963e                	add	a2,a2,a5
    80005a20:	e604                	sd	s1,8(a2)
      return fd;
    80005a22:	b7f5                	j	80005a0e <fdalloc+0x2c>

0000000080005a24 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005a24:	715d                	addi	sp,sp,-80
    80005a26:	e486                	sd	ra,72(sp)
    80005a28:	e0a2                	sd	s0,64(sp)
    80005a2a:	fc26                	sd	s1,56(sp)
    80005a2c:	f84a                	sd	s2,48(sp)
    80005a2e:	f44e                	sd	s3,40(sp)
    80005a30:	f052                	sd	s4,32(sp)
    80005a32:	ec56                	sd	s5,24(sp)
    80005a34:	0880                	addi	s0,sp,80
    80005a36:	89ae                	mv	s3,a1
    80005a38:	8ab2                	mv	s5,a2
    80005a3a:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005a3c:	fb040593          	addi	a1,s0,-80
    80005a40:	fffff097          	auipc	ra,0xfffff
    80005a44:	e86080e7          	jalr	-378(ra) # 800048c6 <nameiparent>
    80005a48:	892a                	mv	s2,a0
    80005a4a:	12050f63          	beqz	a0,80005b88 <create+0x164>
    return 0;

  ilock(dp);
    80005a4e:	ffffe097          	auipc	ra,0xffffe
    80005a52:	6a4080e7          	jalr	1700(ra) # 800040f2 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005a56:	4601                	li	a2,0
    80005a58:	fb040593          	addi	a1,s0,-80
    80005a5c:	854a                	mv	a0,s2
    80005a5e:	fffff097          	auipc	ra,0xfffff
    80005a62:	b78080e7          	jalr	-1160(ra) # 800045d6 <dirlookup>
    80005a66:	84aa                	mv	s1,a0
    80005a68:	c921                	beqz	a0,80005ab8 <create+0x94>
    iunlockput(dp);
    80005a6a:	854a                	mv	a0,s2
    80005a6c:	fffff097          	auipc	ra,0xfffff
    80005a70:	8e8080e7          	jalr	-1816(ra) # 80004354 <iunlockput>
    ilock(ip);
    80005a74:	8526                	mv	a0,s1
    80005a76:	ffffe097          	auipc	ra,0xffffe
    80005a7a:	67c080e7          	jalr	1660(ra) # 800040f2 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005a7e:	2981                	sext.w	s3,s3
    80005a80:	4789                	li	a5,2
    80005a82:	02f99463          	bne	s3,a5,80005aaa <create+0x86>
    80005a86:	0444d783          	lhu	a5,68(s1)
    80005a8a:	37f9                	addiw	a5,a5,-2
    80005a8c:	17c2                	slli	a5,a5,0x30
    80005a8e:	93c1                	srli	a5,a5,0x30
    80005a90:	4705                	li	a4,1
    80005a92:	00f76c63          	bltu	a4,a5,80005aaa <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005a96:	8526                	mv	a0,s1
    80005a98:	60a6                	ld	ra,72(sp)
    80005a9a:	6406                	ld	s0,64(sp)
    80005a9c:	74e2                	ld	s1,56(sp)
    80005a9e:	7942                	ld	s2,48(sp)
    80005aa0:	79a2                	ld	s3,40(sp)
    80005aa2:	7a02                	ld	s4,32(sp)
    80005aa4:	6ae2                	ld	s5,24(sp)
    80005aa6:	6161                	addi	sp,sp,80
    80005aa8:	8082                	ret
    iunlockput(ip);
    80005aaa:	8526                	mv	a0,s1
    80005aac:	fffff097          	auipc	ra,0xfffff
    80005ab0:	8a8080e7          	jalr	-1880(ra) # 80004354 <iunlockput>
    return 0;
    80005ab4:	4481                	li	s1,0
    80005ab6:	b7c5                	j	80005a96 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005ab8:	85ce                	mv	a1,s3
    80005aba:	00092503          	lw	a0,0(s2)
    80005abe:	ffffe097          	auipc	ra,0xffffe
    80005ac2:	49c080e7          	jalr	1180(ra) # 80003f5a <ialloc>
    80005ac6:	84aa                	mv	s1,a0
    80005ac8:	c529                	beqz	a0,80005b12 <create+0xee>
  ilock(ip);
    80005aca:	ffffe097          	auipc	ra,0xffffe
    80005ace:	628080e7          	jalr	1576(ra) # 800040f2 <ilock>
  ip->major = major;
    80005ad2:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005ad6:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005ada:	4785                	li	a5,1
    80005adc:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005ae0:	8526                	mv	a0,s1
    80005ae2:	ffffe097          	auipc	ra,0xffffe
    80005ae6:	546080e7          	jalr	1350(ra) # 80004028 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005aea:	2981                	sext.w	s3,s3
    80005aec:	4785                	li	a5,1
    80005aee:	02f98a63          	beq	s3,a5,80005b22 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005af2:	40d0                	lw	a2,4(s1)
    80005af4:	fb040593          	addi	a1,s0,-80
    80005af8:	854a                	mv	a0,s2
    80005afa:	fffff097          	auipc	ra,0xfffff
    80005afe:	cec080e7          	jalr	-788(ra) # 800047e6 <dirlink>
    80005b02:	06054b63          	bltz	a0,80005b78 <create+0x154>
  iunlockput(dp);
    80005b06:	854a                	mv	a0,s2
    80005b08:	fffff097          	auipc	ra,0xfffff
    80005b0c:	84c080e7          	jalr	-1972(ra) # 80004354 <iunlockput>
  return ip;
    80005b10:	b759                	j	80005a96 <create+0x72>
    panic("create: ialloc");
    80005b12:	00003517          	auipc	a0,0x3
    80005b16:	c5e50513          	addi	a0,a0,-930 # 80008770 <syscalls+0x2b8>
    80005b1a:	ffffb097          	auipc	ra,0xffffb
    80005b1e:	a24080e7          	jalr	-1500(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005b22:	04a95783          	lhu	a5,74(s2)
    80005b26:	2785                	addiw	a5,a5,1
    80005b28:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005b2c:	854a                	mv	a0,s2
    80005b2e:	ffffe097          	auipc	ra,0xffffe
    80005b32:	4fa080e7          	jalr	1274(ra) # 80004028 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005b36:	40d0                	lw	a2,4(s1)
    80005b38:	00003597          	auipc	a1,0x3
    80005b3c:	c4858593          	addi	a1,a1,-952 # 80008780 <syscalls+0x2c8>
    80005b40:	8526                	mv	a0,s1
    80005b42:	fffff097          	auipc	ra,0xfffff
    80005b46:	ca4080e7          	jalr	-860(ra) # 800047e6 <dirlink>
    80005b4a:	00054f63          	bltz	a0,80005b68 <create+0x144>
    80005b4e:	00492603          	lw	a2,4(s2)
    80005b52:	00003597          	auipc	a1,0x3
    80005b56:	c3658593          	addi	a1,a1,-970 # 80008788 <syscalls+0x2d0>
    80005b5a:	8526                	mv	a0,s1
    80005b5c:	fffff097          	auipc	ra,0xfffff
    80005b60:	c8a080e7          	jalr	-886(ra) # 800047e6 <dirlink>
    80005b64:	f80557e3          	bgez	a0,80005af2 <create+0xce>
      panic("create dots");
    80005b68:	00003517          	auipc	a0,0x3
    80005b6c:	c2850513          	addi	a0,a0,-984 # 80008790 <syscalls+0x2d8>
    80005b70:	ffffb097          	auipc	ra,0xffffb
    80005b74:	9ce080e7          	jalr	-1586(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005b78:	00003517          	auipc	a0,0x3
    80005b7c:	c2850513          	addi	a0,a0,-984 # 800087a0 <syscalls+0x2e8>
    80005b80:	ffffb097          	auipc	ra,0xffffb
    80005b84:	9be080e7          	jalr	-1602(ra) # 8000053e <panic>
    return 0;
    80005b88:	84aa                	mv	s1,a0
    80005b8a:	b731                	j	80005a96 <create+0x72>

0000000080005b8c <sys_dup>:
{
    80005b8c:	7179                	addi	sp,sp,-48
    80005b8e:	f406                	sd	ra,40(sp)
    80005b90:	f022                	sd	s0,32(sp)
    80005b92:	ec26                	sd	s1,24(sp)
    80005b94:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005b96:	fd840613          	addi	a2,s0,-40
    80005b9a:	4581                	li	a1,0
    80005b9c:	4501                	li	a0,0
    80005b9e:	00000097          	auipc	ra,0x0
    80005ba2:	ddc080e7          	jalr	-548(ra) # 8000597a <argfd>
    return -1;
    80005ba6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005ba8:	02054363          	bltz	a0,80005bce <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005bac:	fd843503          	ld	a0,-40(s0)
    80005bb0:	00000097          	auipc	ra,0x0
    80005bb4:	e32080e7          	jalr	-462(ra) # 800059e2 <fdalloc>
    80005bb8:	84aa                	mv	s1,a0
    return -1;
    80005bba:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005bbc:	00054963          	bltz	a0,80005bce <sys_dup+0x42>
  filedup(f);
    80005bc0:	fd843503          	ld	a0,-40(s0)
    80005bc4:	fffff097          	auipc	ra,0xfffff
    80005bc8:	37a080e7          	jalr	890(ra) # 80004f3e <filedup>
  return fd;
    80005bcc:	87a6                	mv	a5,s1
}
    80005bce:	853e                	mv	a0,a5
    80005bd0:	70a2                	ld	ra,40(sp)
    80005bd2:	7402                	ld	s0,32(sp)
    80005bd4:	64e2                	ld	s1,24(sp)
    80005bd6:	6145                	addi	sp,sp,48
    80005bd8:	8082                	ret

0000000080005bda <sys_read>:
{
    80005bda:	7179                	addi	sp,sp,-48
    80005bdc:	f406                	sd	ra,40(sp)
    80005bde:	f022                	sd	s0,32(sp)
    80005be0:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005be2:	fe840613          	addi	a2,s0,-24
    80005be6:	4581                	li	a1,0
    80005be8:	4501                	li	a0,0
    80005bea:	00000097          	auipc	ra,0x0
    80005bee:	d90080e7          	jalr	-624(ra) # 8000597a <argfd>
    return -1;
    80005bf2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005bf4:	04054163          	bltz	a0,80005c36 <sys_read+0x5c>
    80005bf8:	fe440593          	addi	a1,s0,-28
    80005bfc:	4509                	li	a0,2
    80005bfe:	ffffe097          	auipc	ra,0xffffe
    80005c02:	906080e7          	jalr	-1786(ra) # 80003504 <argint>
    return -1;
    80005c06:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005c08:	02054763          	bltz	a0,80005c36 <sys_read+0x5c>
    80005c0c:	fd840593          	addi	a1,s0,-40
    80005c10:	4505                	li	a0,1
    80005c12:	ffffe097          	auipc	ra,0xffffe
    80005c16:	914080e7          	jalr	-1772(ra) # 80003526 <argaddr>
    return -1;
    80005c1a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005c1c:	00054d63          	bltz	a0,80005c36 <sys_read+0x5c>
  return fileread(f, p, n);
    80005c20:	fe442603          	lw	a2,-28(s0)
    80005c24:	fd843583          	ld	a1,-40(s0)
    80005c28:	fe843503          	ld	a0,-24(s0)
    80005c2c:	fffff097          	auipc	ra,0xfffff
    80005c30:	49e080e7          	jalr	1182(ra) # 800050ca <fileread>
    80005c34:	87aa                	mv	a5,a0
}
    80005c36:	853e                	mv	a0,a5
    80005c38:	70a2                	ld	ra,40(sp)
    80005c3a:	7402                	ld	s0,32(sp)
    80005c3c:	6145                	addi	sp,sp,48
    80005c3e:	8082                	ret

0000000080005c40 <sys_write>:
{
    80005c40:	7179                	addi	sp,sp,-48
    80005c42:	f406                	sd	ra,40(sp)
    80005c44:	f022                	sd	s0,32(sp)
    80005c46:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005c48:	fe840613          	addi	a2,s0,-24
    80005c4c:	4581                	li	a1,0
    80005c4e:	4501                	li	a0,0
    80005c50:	00000097          	auipc	ra,0x0
    80005c54:	d2a080e7          	jalr	-726(ra) # 8000597a <argfd>
    return -1;
    80005c58:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005c5a:	04054163          	bltz	a0,80005c9c <sys_write+0x5c>
    80005c5e:	fe440593          	addi	a1,s0,-28
    80005c62:	4509                	li	a0,2
    80005c64:	ffffe097          	auipc	ra,0xffffe
    80005c68:	8a0080e7          	jalr	-1888(ra) # 80003504 <argint>
    return -1;
    80005c6c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005c6e:	02054763          	bltz	a0,80005c9c <sys_write+0x5c>
    80005c72:	fd840593          	addi	a1,s0,-40
    80005c76:	4505                	li	a0,1
    80005c78:	ffffe097          	auipc	ra,0xffffe
    80005c7c:	8ae080e7          	jalr	-1874(ra) # 80003526 <argaddr>
    return -1;
    80005c80:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005c82:	00054d63          	bltz	a0,80005c9c <sys_write+0x5c>
  return filewrite(f, p, n);
    80005c86:	fe442603          	lw	a2,-28(s0)
    80005c8a:	fd843583          	ld	a1,-40(s0)
    80005c8e:	fe843503          	ld	a0,-24(s0)
    80005c92:	fffff097          	auipc	ra,0xfffff
    80005c96:	4fa080e7          	jalr	1274(ra) # 8000518c <filewrite>
    80005c9a:	87aa                	mv	a5,a0
}
    80005c9c:	853e                	mv	a0,a5
    80005c9e:	70a2                	ld	ra,40(sp)
    80005ca0:	7402                	ld	s0,32(sp)
    80005ca2:	6145                	addi	sp,sp,48
    80005ca4:	8082                	ret

0000000080005ca6 <sys_close>:
{
    80005ca6:	1101                	addi	sp,sp,-32
    80005ca8:	ec06                	sd	ra,24(sp)
    80005caa:	e822                	sd	s0,16(sp)
    80005cac:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005cae:	fe040613          	addi	a2,s0,-32
    80005cb2:	fec40593          	addi	a1,s0,-20
    80005cb6:	4501                	li	a0,0
    80005cb8:	00000097          	auipc	ra,0x0
    80005cbc:	cc2080e7          	jalr	-830(ra) # 8000597a <argfd>
    return -1;
    80005cc0:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005cc2:	02054463          	bltz	a0,80005cea <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005cc6:	ffffc097          	auipc	ra,0xffffc
    80005cca:	198080e7          	jalr	408(ra) # 80001e5e <myproc>
    80005cce:	fec42783          	lw	a5,-20(s0)
    80005cd2:	07f1                	addi	a5,a5,28
    80005cd4:	078e                	slli	a5,a5,0x3
    80005cd6:	97aa                	add	a5,a5,a0
    80005cd8:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    80005cdc:	fe043503          	ld	a0,-32(s0)
    80005ce0:	fffff097          	auipc	ra,0xfffff
    80005ce4:	2b0080e7          	jalr	688(ra) # 80004f90 <fileclose>
  return 0;
    80005ce8:	4781                	li	a5,0
}
    80005cea:	853e                	mv	a0,a5
    80005cec:	60e2                	ld	ra,24(sp)
    80005cee:	6442                	ld	s0,16(sp)
    80005cf0:	6105                	addi	sp,sp,32
    80005cf2:	8082                	ret

0000000080005cf4 <sys_fstat>:
{
    80005cf4:	1101                	addi	sp,sp,-32
    80005cf6:	ec06                	sd	ra,24(sp)
    80005cf8:	e822                	sd	s0,16(sp)
    80005cfa:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005cfc:	fe840613          	addi	a2,s0,-24
    80005d00:	4581                	li	a1,0
    80005d02:	4501                	li	a0,0
    80005d04:	00000097          	auipc	ra,0x0
    80005d08:	c76080e7          	jalr	-906(ra) # 8000597a <argfd>
    return -1;
    80005d0c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005d0e:	02054563          	bltz	a0,80005d38 <sys_fstat+0x44>
    80005d12:	fe040593          	addi	a1,s0,-32
    80005d16:	4505                	li	a0,1
    80005d18:	ffffe097          	auipc	ra,0xffffe
    80005d1c:	80e080e7          	jalr	-2034(ra) # 80003526 <argaddr>
    return -1;
    80005d20:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005d22:	00054b63          	bltz	a0,80005d38 <sys_fstat+0x44>
  return filestat(f, st);
    80005d26:	fe043583          	ld	a1,-32(s0)
    80005d2a:	fe843503          	ld	a0,-24(s0)
    80005d2e:	fffff097          	auipc	ra,0xfffff
    80005d32:	32a080e7          	jalr	810(ra) # 80005058 <filestat>
    80005d36:	87aa                	mv	a5,a0
}
    80005d38:	853e                	mv	a0,a5
    80005d3a:	60e2                	ld	ra,24(sp)
    80005d3c:	6442                	ld	s0,16(sp)
    80005d3e:	6105                	addi	sp,sp,32
    80005d40:	8082                	ret

0000000080005d42 <sys_link>:
{
    80005d42:	7169                	addi	sp,sp,-304
    80005d44:	f606                	sd	ra,296(sp)
    80005d46:	f222                	sd	s0,288(sp)
    80005d48:	ee26                	sd	s1,280(sp)
    80005d4a:	ea4a                	sd	s2,272(sp)
    80005d4c:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005d4e:	08000613          	li	a2,128
    80005d52:	ed040593          	addi	a1,s0,-304
    80005d56:	4501                	li	a0,0
    80005d58:	ffffd097          	auipc	ra,0xffffd
    80005d5c:	7f0080e7          	jalr	2032(ra) # 80003548 <argstr>
    return -1;
    80005d60:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005d62:	10054e63          	bltz	a0,80005e7e <sys_link+0x13c>
    80005d66:	08000613          	li	a2,128
    80005d6a:	f5040593          	addi	a1,s0,-176
    80005d6e:	4505                	li	a0,1
    80005d70:	ffffd097          	auipc	ra,0xffffd
    80005d74:	7d8080e7          	jalr	2008(ra) # 80003548 <argstr>
    return -1;
    80005d78:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005d7a:	10054263          	bltz	a0,80005e7e <sys_link+0x13c>
  begin_op();
    80005d7e:	fffff097          	auipc	ra,0xfffff
    80005d82:	d46080e7          	jalr	-698(ra) # 80004ac4 <begin_op>
  if((ip = namei(old)) == 0){
    80005d86:	ed040513          	addi	a0,s0,-304
    80005d8a:	fffff097          	auipc	ra,0xfffff
    80005d8e:	b1e080e7          	jalr	-1250(ra) # 800048a8 <namei>
    80005d92:	84aa                	mv	s1,a0
    80005d94:	c551                	beqz	a0,80005e20 <sys_link+0xde>
  ilock(ip);
    80005d96:	ffffe097          	auipc	ra,0xffffe
    80005d9a:	35c080e7          	jalr	860(ra) # 800040f2 <ilock>
  if(ip->type == T_DIR){
    80005d9e:	04449703          	lh	a4,68(s1)
    80005da2:	4785                	li	a5,1
    80005da4:	08f70463          	beq	a4,a5,80005e2c <sys_link+0xea>
  ip->nlink++;
    80005da8:	04a4d783          	lhu	a5,74(s1)
    80005dac:	2785                	addiw	a5,a5,1
    80005dae:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005db2:	8526                	mv	a0,s1
    80005db4:	ffffe097          	auipc	ra,0xffffe
    80005db8:	274080e7          	jalr	628(ra) # 80004028 <iupdate>
  iunlock(ip);
    80005dbc:	8526                	mv	a0,s1
    80005dbe:	ffffe097          	auipc	ra,0xffffe
    80005dc2:	3f6080e7          	jalr	1014(ra) # 800041b4 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005dc6:	fd040593          	addi	a1,s0,-48
    80005dca:	f5040513          	addi	a0,s0,-176
    80005dce:	fffff097          	auipc	ra,0xfffff
    80005dd2:	af8080e7          	jalr	-1288(ra) # 800048c6 <nameiparent>
    80005dd6:	892a                	mv	s2,a0
    80005dd8:	c935                	beqz	a0,80005e4c <sys_link+0x10a>
  ilock(dp);
    80005dda:	ffffe097          	auipc	ra,0xffffe
    80005dde:	318080e7          	jalr	792(ra) # 800040f2 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005de2:	00092703          	lw	a4,0(s2)
    80005de6:	409c                	lw	a5,0(s1)
    80005de8:	04f71d63          	bne	a4,a5,80005e42 <sys_link+0x100>
    80005dec:	40d0                	lw	a2,4(s1)
    80005dee:	fd040593          	addi	a1,s0,-48
    80005df2:	854a                	mv	a0,s2
    80005df4:	fffff097          	auipc	ra,0xfffff
    80005df8:	9f2080e7          	jalr	-1550(ra) # 800047e6 <dirlink>
    80005dfc:	04054363          	bltz	a0,80005e42 <sys_link+0x100>
  iunlockput(dp);
    80005e00:	854a                	mv	a0,s2
    80005e02:	ffffe097          	auipc	ra,0xffffe
    80005e06:	552080e7          	jalr	1362(ra) # 80004354 <iunlockput>
  iput(ip);
    80005e0a:	8526                	mv	a0,s1
    80005e0c:	ffffe097          	auipc	ra,0xffffe
    80005e10:	4a0080e7          	jalr	1184(ra) # 800042ac <iput>
  end_op();
    80005e14:	fffff097          	auipc	ra,0xfffff
    80005e18:	d30080e7          	jalr	-720(ra) # 80004b44 <end_op>
  return 0;
    80005e1c:	4781                	li	a5,0
    80005e1e:	a085                	j	80005e7e <sys_link+0x13c>
    end_op();
    80005e20:	fffff097          	auipc	ra,0xfffff
    80005e24:	d24080e7          	jalr	-732(ra) # 80004b44 <end_op>
    return -1;
    80005e28:	57fd                	li	a5,-1
    80005e2a:	a891                	j	80005e7e <sys_link+0x13c>
    iunlockput(ip);
    80005e2c:	8526                	mv	a0,s1
    80005e2e:	ffffe097          	auipc	ra,0xffffe
    80005e32:	526080e7          	jalr	1318(ra) # 80004354 <iunlockput>
    end_op();
    80005e36:	fffff097          	auipc	ra,0xfffff
    80005e3a:	d0e080e7          	jalr	-754(ra) # 80004b44 <end_op>
    return -1;
    80005e3e:	57fd                	li	a5,-1
    80005e40:	a83d                	j	80005e7e <sys_link+0x13c>
    iunlockput(dp);
    80005e42:	854a                	mv	a0,s2
    80005e44:	ffffe097          	auipc	ra,0xffffe
    80005e48:	510080e7          	jalr	1296(ra) # 80004354 <iunlockput>
  ilock(ip);
    80005e4c:	8526                	mv	a0,s1
    80005e4e:	ffffe097          	auipc	ra,0xffffe
    80005e52:	2a4080e7          	jalr	676(ra) # 800040f2 <ilock>
  ip->nlink--;
    80005e56:	04a4d783          	lhu	a5,74(s1)
    80005e5a:	37fd                	addiw	a5,a5,-1
    80005e5c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005e60:	8526                	mv	a0,s1
    80005e62:	ffffe097          	auipc	ra,0xffffe
    80005e66:	1c6080e7          	jalr	454(ra) # 80004028 <iupdate>
  iunlockput(ip);
    80005e6a:	8526                	mv	a0,s1
    80005e6c:	ffffe097          	auipc	ra,0xffffe
    80005e70:	4e8080e7          	jalr	1256(ra) # 80004354 <iunlockput>
  end_op();
    80005e74:	fffff097          	auipc	ra,0xfffff
    80005e78:	cd0080e7          	jalr	-816(ra) # 80004b44 <end_op>
  return -1;
    80005e7c:	57fd                	li	a5,-1
}
    80005e7e:	853e                	mv	a0,a5
    80005e80:	70b2                	ld	ra,296(sp)
    80005e82:	7412                	ld	s0,288(sp)
    80005e84:	64f2                	ld	s1,280(sp)
    80005e86:	6952                	ld	s2,272(sp)
    80005e88:	6155                	addi	sp,sp,304
    80005e8a:	8082                	ret

0000000080005e8c <sys_unlink>:
{
    80005e8c:	7151                	addi	sp,sp,-240
    80005e8e:	f586                	sd	ra,232(sp)
    80005e90:	f1a2                	sd	s0,224(sp)
    80005e92:	eda6                	sd	s1,216(sp)
    80005e94:	e9ca                	sd	s2,208(sp)
    80005e96:	e5ce                	sd	s3,200(sp)
    80005e98:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005e9a:	08000613          	li	a2,128
    80005e9e:	f3040593          	addi	a1,s0,-208
    80005ea2:	4501                	li	a0,0
    80005ea4:	ffffd097          	auipc	ra,0xffffd
    80005ea8:	6a4080e7          	jalr	1700(ra) # 80003548 <argstr>
    80005eac:	18054163          	bltz	a0,8000602e <sys_unlink+0x1a2>
  begin_op();
    80005eb0:	fffff097          	auipc	ra,0xfffff
    80005eb4:	c14080e7          	jalr	-1004(ra) # 80004ac4 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005eb8:	fb040593          	addi	a1,s0,-80
    80005ebc:	f3040513          	addi	a0,s0,-208
    80005ec0:	fffff097          	auipc	ra,0xfffff
    80005ec4:	a06080e7          	jalr	-1530(ra) # 800048c6 <nameiparent>
    80005ec8:	84aa                	mv	s1,a0
    80005eca:	c979                	beqz	a0,80005fa0 <sys_unlink+0x114>
  ilock(dp);
    80005ecc:	ffffe097          	auipc	ra,0xffffe
    80005ed0:	226080e7          	jalr	550(ra) # 800040f2 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005ed4:	00003597          	auipc	a1,0x3
    80005ed8:	8ac58593          	addi	a1,a1,-1876 # 80008780 <syscalls+0x2c8>
    80005edc:	fb040513          	addi	a0,s0,-80
    80005ee0:	ffffe097          	auipc	ra,0xffffe
    80005ee4:	6dc080e7          	jalr	1756(ra) # 800045bc <namecmp>
    80005ee8:	14050a63          	beqz	a0,8000603c <sys_unlink+0x1b0>
    80005eec:	00003597          	auipc	a1,0x3
    80005ef0:	89c58593          	addi	a1,a1,-1892 # 80008788 <syscalls+0x2d0>
    80005ef4:	fb040513          	addi	a0,s0,-80
    80005ef8:	ffffe097          	auipc	ra,0xffffe
    80005efc:	6c4080e7          	jalr	1732(ra) # 800045bc <namecmp>
    80005f00:	12050e63          	beqz	a0,8000603c <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005f04:	f2c40613          	addi	a2,s0,-212
    80005f08:	fb040593          	addi	a1,s0,-80
    80005f0c:	8526                	mv	a0,s1
    80005f0e:	ffffe097          	auipc	ra,0xffffe
    80005f12:	6c8080e7          	jalr	1736(ra) # 800045d6 <dirlookup>
    80005f16:	892a                	mv	s2,a0
    80005f18:	12050263          	beqz	a0,8000603c <sys_unlink+0x1b0>
  ilock(ip);
    80005f1c:	ffffe097          	auipc	ra,0xffffe
    80005f20:	1d6080e7          	jalr	470(ra) # 800040f2 <ilock>
  if(ip->nlink < 1)
    80005f24:	04a91783          	lh	a5,74(s2)
    80005f28:	08f05263          	blez	a5,80005fac <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005f2c:	04491703          	lh	a4,68(s2)
    80005f30:	4785                	li	a5,1
    80005f32:	08f70563          	beq	a4,a5,80005fbc <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005f36:	4641                	li	a2,16
    80005f38:	4581                	li	a1,0
    80005f3a:	fc040513          	addi	a0,s0,-64
    80005f3e:	ffffb097          	auipc	ra,0xffffb
    80005f42:	da2080e7          	jalr	-606(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005f46:	4741                	li	a4,16
    80005f48:	f2c42683          	lw	a3,-212(s0)
    80005f4c:	fc040613          	addi	a2,s0,-64
    80005f50:	4581                	li	a1,0
    80005f52:	8526                	mv	a0,s1
    80005f54:	ffffe097          	auipc	ra,0xffffe
    80005f58:	54a080e7          	jalr	1354(ra) # 8000449e <writei>
    80005f5c:	47c1                	li	a5,16
    80005f5e:	0af51563          	bne	a0,a5,80006008 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005f62:	04491703          	lh	a4,68(s2)
    80005f66:	4785                	li	a5,1
    80005f68:	0af70863          	beq	a4,a5,80006018 <sys_unlink+0x18c>
  iunlockput(dp);
    80005f6c:	8526                	mv	a0,s1
    80005f6e:	ffffe097          	auipc	ra,0xffffe
    80005f72:	3e6080e7          	jalr	998(ra) # 80004354 <iunlockput>
  ip->nlink--;
    80005f76:	04a95783          	lhu	a5,74(s2)
    80005f7a:	37fd                	addiw	a5,a5,-1
    80005f7c:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005f80:	854a                	mv	a0,s2
    80005f82:	ffffe097          	auipc	ra,0xffffe
    80005f86:	0a6080e7          	jalr	166(ra) # 80004028 <iupdate>
  iunlockput(ip);
    80005f8a:	854a                	mv	a0,s2
    80005f8c:	ffffe097          	auipc	ra,0xffffe
    80005f90:	3c8080e7          	jalr	968(ra) # 80004354 <iunlockput>
  end_op();
    80005f94:	fffff097          	auipc	ra,0xfffff
    80005f98:	bb0080e7          	jalr	-1104(ra) # 80004b44 <end_op>
  return 0;
    80005f9c:	4501                	li	a0,0
    80005f9e:	a84d                	j	80006050 <sys_unlink+0x1c4>
    end_op();
    80005fa0:	fffff097          	auipc	ra,0xfffff
    80005fa4:	ba4080e7          	jalr	-1116(ra) # 80004b44 <end_op>
    return -1;
    80005fa8:	557d                	li	a0,-1
    80005faa:	a05d                	j	80006050 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005fac:	00003517          	auipc	a0,0x3
    80005fb0:	80450513          	addi	a0,a0,-2044 # 800087b0 <syscalls+0x2f8>
    80005fb4:	ffffa097          	auipc	ra,0xffffa
    80005fb8:	58a080e7          	jalr	1418(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005fbc:	04c92703          	lw	a4,76(s2)
    80005fc0:	02000793          	li	a5,32
    80005fc4:	f6e7f9e3          	bgeu	a5,a4,80005f36 <sys_unlink+0xaa>
    80005fc8:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005fcc:	4741                	li	a4,16
    80005fce:	86ce                	mv	a3,s3
    80005fd0:	f1840613          	addi	a2,s0,-232
    80005fd4:	4581                	li	a1,0
    80005fd6:	854a                	mv	a0,s2
    80005fd8:	ffffe097          	auipc	ra,0xffffe
    80005fdc:	3ce080e7          	jalr	974(ra) # 800043a6 <readi>
    80005fe0:	47c1                	li	a5,16
    80005fe2:	00f51b63          	bne	a0,a5,80005ff8 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005fe6:	f1845783          	lhu	a5,-232(s0)
    80005fea:	e7a1                	bnez	a5,80006032 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005fec:	29c1                	addiw	s3,s3,16
    80005fee:	04c92783          	lw	a5,76(s2)
    80005ff2:	fcf9ede3          	bltu	s3,a5,80005fcc <sys_unlink+0x140>
    80005ff6:	b781                	j	80005f36 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005ff8:	00002517          	auipc	a0,0x2
    80005ffc:	7d050513          	addi	a0,a0,2000 # 800087c8 <syscalls+0x310>
    80006000:	ffffa097          	auipc	ra,0xffffa
    80006004:	53e080e7          	jalr	1342(ra) # 8000053e <panic>
    panic("unlink: writei");
    80006008:	00002517          	auipc	a0,0x2
    8000600c:	7d850513          	addi	a0,a0,2008 # 800087e0 <syscalls+0x328>
    80006010:	ffffa097          	auipc	ra,0xffffa
    80006014:	52e080e7          	jalr	1326(ra) # 8000053e <panic>
    dp->nlink--;
    80006018:	04a4d783          	lhu	a5,74(s1)
    8000601c:	37fd                	addiw	a5,a5,-1
    8000601e:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80006022:	8526                	mv	a0,s1
    80006024:	ffffe097          	auipc	ra,0xffffe
    80006028:	004080e7          	jalr	4(ra) # 80004028 <iupdate>
    8000602c:	b781                	j	80005f6c <sys_unlink+0xe0>
    return -1;
    8000602e:	557d                	li	a0,-1
    80006030:	a005                	j	80006050 <sys_unlink+0x1c4>
    iunlockput(ip);
    80006032:	854a                	mv	a0,s2
    80006034:	ffffe097          	auipc	ra,0xffffe
    80006038:	320080e7          	jalr	800(ra) # 80004354 <iunlockput>
  iunlockput(dp);
    8000603c:	8526                	mv	a0,s1
    8000603e:	ffffe097          	auipc	ra,0xffffe
    80006042:	316080e7          	jalr	790(ra) # 80004354 <iunlockput>
  end_op();
    80006046:	fffff097          	auipc	ra,0xfffff
    8000604a:	afe080e7          	jalr	-1282(ra) # 80004b44 <end_op>
  return -1;
    8000604e:	557d                	li	a0,-1
}
    80006050:	70ae                	ld	ra,232(sp)
    80006052:	740e                	ld	s0,224(sp)
    80006054:	64ee                	ld	s1,216(sp)
    80006056:	694e                	ld	s2,208(sp)
    80006058:	69ae                	ld	s3,200(sp)
    8000605a:	616d                	addi	sp,sp,240
    8000605c:	8082                	ret

000000008000605e <sys_open>:

uint64
sys_open(void)
{
    8000605e:	7131                	addi	sp,sp,-192
    80006060:	fd06                	sd	ra,184(sp)
    80006062:	f922                	sd	s0,176(sp)
    80006064:	f526                	sd	s1,168(sp)
    80006066:	f14a                	sd	s2,160(sp)
    80006068:	ed4e                	sd	s3,152(sp)
    8000606a:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000606c:	08000613          	li	a2,128
    80006070:	f5040593          	addi	a1,s0,-176
    80006074:	4501                	li	a0,0
    80006076:	ffffd097          	auipc	ra,0xffffd
    8000607a:	4d2080e7          	jalr	1234(ra) # 80003548 <argstr>
    return -1;
    8000607e:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80006080:	0c054163          	bltz	a0,80006142 <sys_open+0xe4>
    80006084:	f4c40593          	addi	a1,s0,-180
    80006088:	4505                	li	a0,1
    8000608a:	ffffd097          	auipc	ra,0xffffd
    8000608e:	47a080e7          	jalr	1146(ra) # 80003504 <argint>
    80006092:	0a054863          	bltz	a0,80006142 <sys_open+0xe4>

  begin_op();
    80006096:	fffff097          	auipc	ra,0xfffff
    8000609a:	a2e080e7          	jalr	-1490(ra) # 80004ac4 <begin_op>

  if(omode & O_CREATE){
    8000609e:	f4c42783          	lw	a5,-180(s0)
    800060a2:	2007f793          	andi	a5,a5,512
    800060a6:	cbdd                	beqz	a5,8000615c <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800060a8:	4681                	li	a3,0
    800060aa:	4601                	li	a2,0
    800060ac:	4589                	li	a1,2
    800060ae:	f5040513          	addi	a0,s0,-176
    800060b2:	00000097          	auipc	ra,0x0
    800060b6:	972080e7          	jalr	-1678(ra) # 80005a24 <create>
    800060ba:	892a                	mv	s2,a0
    if(ip == 0){
    800060bc:	c959                	beqz	a0,80006152 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800060be:	04491703          	lh	a4,68(s2)
    800060c2:	478d                	li	a5,3
    800060c4:	00f71763          	bne	a4,a5,800060d2 <sys_open+0x74>
    800060c8:	04695703          	lhu	a4,70(s2)
    800060cc:	47a5                	li	a5,9
    800060ce:	0ce7ec63          	bltu	a5,a4,800061a6 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800060d2:	fffff097          	auipc	ra,0xfffff
    800060d6:	e02080e7          	jalr	-510(ra) # 80004ed4 <filealloc>
    800060da:	89aa                	mv	s3,a0
    800060dc:	10050263          	beqz	a0,800061e0 <sys_open+0x182>
    800060e0:	00000097          	auipc	ra,0x0
    800060e4:	902080e7          	jalr	-1790(ra) # 800059e2 <fdalloc>
    800060e8:	84aa                	mv	s1,a0
    800060ea:	0e054663          	bltz	a0,800061d6 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800060ee:	04491703          	lh	a4,68(s2)
    800060f2:	478d                	li	a5,3
    800060f4:	0cf70463          	beq	a4,a5,800061bc <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800060f8:	4789                	li	a5,2
    800060fa:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800060fe:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80006102:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80006106:	f4c42783          	lw	a5,-180(s0)
    8000610a:	0017c713          	xori	a4,a5,1
    8000610e:	8b05                	andi	a4,a4,1
    80006110:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80006114:	0037f713          	andi	a4,a5,3
    80006118:	00e03733          	snez	a4,a4
    8000611c:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80006120:	4007f793          	andi	a5,a5,1024
    80006124:	c791                	beqz	a5,80006130 <sys_open+0xd2>
    80006126:	04491703          	lh	a4,68(s2)
    8000612a:	4789                	li	a5,2
    8000612c:	08f70f63          	beq	a4,a5,800061ca <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80006130:	854a                	mv	a0,s2
    80006132:	ffffe097          	auipc	ra,0xffffe
    80006136:	082080e7          	jalr	130(ra) # 800041b4 <iunlock>
  end_op();
    8000613a:	fffff097          	auipc	ra,0xfffff
    8000613e:	a0a080e7          	jalr	-1526(ra) # 80004b44 <end_op>

  return fd;
}
    80006142:	8526                	mv	a0,s1
    80006144:	70ea                	ld	ra,184(sp)
    80006146:	744a                	ld	s0,176(sp)
    80006148:	74aa                	ld	s1,168(sp)
    8000614a:	790a                	ld	s2,160(sp)
    8000614c:	69ea                	ld	s3,152(sp)
    8000614e:	6129                	addi	sp,sp,192
    80006150:	8082                	ret
      end_op();
    80006152:	fffff097          	auipc	ra,0xfffff
    80006156:	9f2080e7          	jalr	-1550(ra) # 80004b44 <end_op>
      return -1;
    8000615a:	b7e5                	j	80006142 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000615c:	f5040513          	addi	a0,s0,-176
    80006160:	ffffe097          	auipc	ra,0xffffe
    80006164:	748080e7          	jalr	1864(ra) # 800048a8 <namei>
    80006168:	892a                	mv	s2,a0
    8000616a:	c905                	beqz	a0,8000619a <sys_open+0x13c>
    ilock(ip);
    8000616c:	ffffe097          	auipc	ra,0xffffe
    80006170:	f86080e7          	jalr	-122(ra) # 800040f2 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80006174:	04491703          	lh	a4,68(s2)
    80006178:	4785                	li	a5,1
    8000617a:	f4f712e3          	bne	a4,a5,800060be <sys_open+0x60>
    8000617e:	f4c42783          	lw	a5,-180(s0)
    80006182:	dba1                	beqz	a5,800060d2 <sys_open+0x74>
      iunlockput(ip);
    80006184:	854a                	mv	a0,s2
    80006186:	ffffe097          	auipc	ra,0xffffe
    8000618a:	1ce080e7          	jalr	462(ra) # 80004354 <iunlockput>
      end_op();
    8000618e:	fffff097          	auipc	ra,0xfffff
    80006192:	9b6080e7          	jalr	-1610(ra) # 80004b44 <end_op>
      return -1;
    80006196:	54fd                	li	s1,-1
    80006198:	b76d                	j	80006142 <sys_open+0xe4>
      end_op();
    8000619a:	fffff097          	auipc	ra,0xfffff
    8000619e:	9aa080e7          	jalr	-1622(ra) # 80004b44 <end_op>
      return -1;
    800061a2:	54fd                	li	s1,-1
    800061a4:	bf79                	j	80006142 <sys_open+0xe4>
    iunlockput(ip);
    800061a6:	854a                	mv	a0,s2
    800061a8:	ffffe097          	auipc	ra,0xffffe
    800061ac:	1ac080e7          	jalr	428(ra) # 80004354 <iunlockput>
    end_op();
    800061b0:	fffff097          	auipc	ra,0xfffff
    800061b4:	994080e7          	jalr	-1644(ra) # 80004b44 <end_op>
    return -1;
    800061b8:	54fd                	li	s1,-1
    800061ba:	b761                	j	80006142 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800061bc:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800061c0:	04691783          	lh	a5,70(s2)
    800061c4:	02f99223          	sh	a5,36(s3)
    800061c8:	bf2d                	j	80006102 <sys_open+0xa4>
    itrunc(ip);
    800061ca:	854a                	mv	a0,s2
    800061cc:	ffffe097          	auipc	ra,0xffffe
    800061d0:	034080e7          	jalr	52(ra) # 80004200 <itrunc>
    800061d4:	bfb1                	j	80006130 <sys_open+0xd2>
      fileclose(f);
    800061d6:	854e                	mv	a0,s3
    800061d8:	fffff097          	auipc	ra,0xfffff
    800061dc:	db8080e7          	jalr	-584(ra) # 80004f90 <fileclose>
    iunlockput(ip);
    800061e0:	854a                	mv	a0,s2
    800061e2:	ffffe097          	auipc	ra,0xffffe
    800061e6:	172080e7          	jalr	370(ra) # 80004354 <iunlockput>
    end_op();
    800061ea:	fffff097          	auipc	ra,0xfffff
    800061ee:	95a080e7          	jalr	-1702(ra) # 80004b44 <end_op>
    return -1;
    800061f2:	54fd                	li	s1,-1
    800061f4:	b7b9                	j	80006142 <sys_open+0xe4>

00000000800061f6 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800061f6:	7175                	addi	sp,sp,-144
    800061f8:	e506                	sd	ra,136(sp)
    800061fa:	e122                	sd	s0,128(sp)
    800061fc:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800061fe:	fffff097          	auipc	ra,0xfffff
    80006202:	8c6080e7          	jalr	-1850(ra) # 80004ac4 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80006206:	08000613          	li	a2,128
    8000620a:	f7040593          	addi	a1,s0,-144
    8000620e:	4501                	li	a0,0
    80006210:	ffffd097          	auipc	ra,0xffffd
    80006214:	338080e7          	jalr	824(ra) # 80003548 <argstr>
    80006218:	02054963          	bltz	a0,8000624a <sys_mkdir+0x54>
    8000621c:	4681                	li	a3,0
    8000621e:	4601                	li	a2,0
    80006220:	4585                	li	a1,1
    80006222:	f7040513          	addi	a0,s0,-144
    80006226:	fffff097          	auipc	ra,0xfffff
    8000622a:	7fe080e7          	jalr	2046(ra) # 80005a24 <create>
    8000622e:	cd11                	beqz	a0,8000624a <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006230:	ffffe097          	auipc	ra,0xffffe
    80006234:	124080e7          	jalr	292(ra) # 80004354 <iunlockput>
  end_op();
    80006238:	fffff097          	auipc	ra,0xfffff
    8000623c:	90c080e7          	jalr	-1780(ra) # 80004b44 <end_op>
  return 0;
    80006240:	4501                	li	a0,0
}
    80006242:	60aa                	ld	ra,136(sp)
    80006244:	640a                	ld	s0,128(sp)
    80006246:	6149                	addi	sp,sp,144
    80006248:	8082                	ret
    end_op();
    8000624a:	fffff097          	auipc	ra,0xfffff
    8000624e:	8fa080e7          	jalr	-1798(ra) # 80004b44 <end_op>
    return -1;
    80006252:	557d                	li	a0,-1
    80006254:	b7fd                	j	80006242 <sys_mkdir+0x4c>

0000000080006256 <sys_mknod>:

uint64
sys_mknod(void)
{
    80006256:	7135                	addi	sp,sp,-160
    80006258:	ed06                	sd	ra,152(sp)
    8000625a:	e922                	sd	s0,144(sp)
    8000625c:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000625e:	fffff097          	auipc	ra,0xfffff
    80006262:	866080e7          	jalr	-1946(ra) # 80004ac4 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006266:	08000613          	li	a2,128
    8000626a:	f7040593          	addi	a1,s0,-144
    8000626e:	4501                	li	a0,0
    80006270:	ffffd097          	auipc	ra,0xffffd
    80006274:	2d8080e7          	jalr	728(ra) # 80003548 <argstr>
    80006278:	04054a63          	bltz	a0,800062cc <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    8000627c:	f6c40593          	addi	a1,s0,-148
    80006280:	4505                	li	a0,1
    80006282:	ffffd097          	auipc	ra,0xffffd
    80006286:	282080e7          	jalr	642(ra) # 80003504 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000628a:	04054163          	bltz	a0,800062cc <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    8000628e:	f6840593          	addi	a1,s0,-152
    80006292:	4509                	li	a0,2
    80006294:	ffffd097          	auipc	ra,0xffffd
    80006298:	270080e7          	jalr	624(ra) # 80003504 <argint>
     argint(1, &major) < 0 ||
    8000629c:	02054863          	bltz	a0,800062cc <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800062a0:	f6841683          	lh	a3,-152(s0)
    800062a4:	f6c41603          	lh	a2,-148(s0)
    800062a8:	458d                	li	a1,3
    800062aa:	f7040513          	addi	a0,s0,-144
    800062ae:	fffff097          	auipc	ra,0xfffff
    800062b2:	776080e7          	jalr	1910(ra) # 80005a24 <create>
     argint(2, &minor) < 0 ||
    800062b6:	c919                	beqz	a0,800062cc <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800062b8:	ffffe097          	auipc	ra,0xffffe
    800062bc:	09c080e7          	jalr	156(ra) # 80004354 <iunlockput>
  end_op();
    800062c0:	fffff097          	auipc	ra,0xfffff
    800062c4:	884080e7          	jalr	-1916(ra) # 80004b44 <end_op>
  return 0;
    800062c8:	4501                	li	a0,0
    800062ca:	a031                	j	800062d6 <sys_mknod+0x80>
    end_op();
    800062cc:	fffff097          	auipc	ra,0xfffff
    800062d0:	878080e7          	jalr	-1928(ra) # 80004b44 <end_op>
    return -1;
    800062d4:	557d                	li	a0,-1
}
    800062d6:	60ea                	ld	ra,152(sp)
    800062d8:	644a                	ld	s0,144(sp)
    800062da:	610d                	addi	sp,sp,160
    800062dc:	8082                	ret

00000000800062de <sys_chdir>:

uint64
sys_chdir(void)
{
    800062de:	7135                	addi	sp,sp,-160
    800062e0:	ed06                	sd	ra,152(sp)
    800062e2:	e922                	sd	s0,144(sp)
    800062e4:	e526                	sd	s1,136(sp)
    800062e6:	e14a                	sd	s2,128(sp)
    800062e8:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800062ea:	ffffc097          	auipc	ra,0xffffc
    800062ee:	b74080e7          	jalr	-1164(ra) # 80001e5e <myproc>
    800062f2:	892a                	mv	s2,a0
  
  begin_op();
    800062f4:	ffffe097          	auipc	ra,0xffffe
    800062f8:	7d0080e7          	jalr	2000(ra) # 80004ac4 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800062fc:	08000613          	li	a2,128
    80006300:	f6040593          	addi	a1,s0,-160
    80006304:	4501                	li	a0,0
    80006306:	ffffd097          	auipc	ra,0xffffd
    8000630a:	242080e7          	jalr	578(ra) # 80003548 <argstr>
    8000630e:	04054b63          	bltz	a0,80006364 <sys_chdir+0x86>
    80006312:	f6040513          	addi	a0,s0,-160
    80006316:	ffffe097          	auipc	ra,0xffffe
    8000631a:	592080e7          	jalr	1426(ra) # 800048a8 <namei>
    8000631e:	84aa                	mv	s1,a0
    80006320:	c131                	beqz	a0,80006364 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006322:	ffffe097          	auipc	ra,0xffffe
    80006326:	dd0080e7          	jalr	-560(ra) # 800040f2 <ilock>
  if(ip->type != T_DIR){
    8000632a:	04449703          	lh	a4,68(s1)
    8000632e:	4785                	li	a5,1
    80006330:	04f71063          	bne	a4,a5,80006370 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006334:	8526                	mv	a0,s1
    80006336:	ffffe097          	auipc	ra,0xffffe
    8000633a:	e7e080e7          	jalr	-386(ra) # 800041b4 <iunlock>
  iput(p->cwd);
    8000633e:	16893503          	ld	a0,360(s2)
    80006342:	ffffe097          	auipc	ra,0xffffe
    80006346:	f6a080e7          	jalr	-150(ra) # 800042ac <iput>
  end_op();
    8000634a:	ffffe097          	auipc	ra,0xffffe
    8000634e:	7fa080e7          	jalr	2042(ra) # 80004b44 <end_op>
  p->cwd = ip;
    80006352:	16993423          	sd	s1,360(s2)
  return 0;
    80006356:	4501                	li	a0,0
}
    80006358:	60ea                	ld	ra,152(sp)
    8000635a:	644a                	ld	s0,144(sp)
    8000635c:	64aa                	ld	s1,136(sp)
    8000635e:	690a                	ld	s2,128(sp)
    80006360:	610d                	addi	sp,sp,160
    80006362:	8082                	ret
    end_op();
    80006364:	ffffe097          	auipc	ra,0xffffe
    80006368:	7e0080e7          	jalr	2016(ra) # 80004b44 <end_op>
    return -1;
    8000636c:	557d                	li	a0,-1
    8000636e:	b7ed                	j	80006358 <sys_chdir+0x7a>
    iunlockput(ip);
    80006370:	8526                	mv	a0,s1
    80006372:	ffffe097          	auipc	ra,0xffffe
    80006376:	fe2080e7          	jalr	-30(ra) # 80004354 <iunlockput>
    end_op();
    8000637a:	ffffe097          	auipc	ra,0xffffe
    8000637e:	7ca080e7          	jalr	1994(ra) # 80004b44 <end_op>
    return -1;
    80006382:	557d                	li	a0,-1
    80006384:	bfd1                	j	80006358 <sys_chdir+0x7a>

0000000080006386 <sys_exec>:

uint64
sys_exec(void)
{
    80006386:	7145                	addi	sp,sp,-464
    80006388:	e786                	sd	ra,456(sp)
    8000638a:	e3a2                	sd	s0,448(sp)
    8000638c:	ff26                	sd	s1,440(sp)
    8000638e:	fb4a                	sd	s2,432(sp)
    80006390:	f74e                	sd	s3,424(sp)
    80006392:	f352                	sd	s4,416(sp)
    80006394:	ef56                	sd	s5,408(sp)
    80006396:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006398:	08000613          	li	a2,128
    8000639c:	f4040593          	addi	a1,s0,-192
    800063a0:	4501                	li	a0,0
    800063a2:	ffffd097          	auipc	ra,0xffffd
    800063a6:	1a6080e7          	jalr	422(ra) # 80003548 <argstr>
    return -1;
    800063aa:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800063ac:	0c054a63          	bltz	a0,80006480 <sys_exec+0xfa>
    800063b0:	e3840593          	addi	a1,s0,-456
    800063b4:	4505                	li	a0,1
    800063b6:	ffffd097          	auipc	ra,0xffffd
    800063ba:	170080e7          	jalr	368(ra) # 80003526 <argaddr>
    800063be:	0c054163          	bltz	a0,80006480 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    800063c2:	10000613          	li	a2,256
    800063c6:	4581                	li	a1,0
    800063c8:	e4040513          	addi	a0,s0,-448
    800063cc:	ffffb097          	auipc	ra,0xffffb
    800063d0:	914080e7          	jalr	-1772(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800063d4:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800063d8:	89a6                	mv	s3,s1
    800063da:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800063dc:	02000a13          	li	s4,32
    800063e0:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800063e4:	00391513          	slli	a0,s2,0x3
    800063e8:	e3040593          	addi	a1,s0,-464
    800063ec:	e3843783          	ld	a5,-456(s0)
    800063f0:	953e                	add	a0,a0,a5
    800063f2:	ffffd097          	auipc	ra,0xffffd
    800063f6:	078080e7          	jalr	120(ra) # 8000346a <fetchaddr>
    800063fa:	02054a63          	bltz	a0,8000642e <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    800063fe:	e3043783          	ld	a5,-464(s0)
    80006402:	c3b9                	beqz	a5,80006448 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006404:	ffffa097          	auipc	ra,0xffffa
    80006408:	6f0080e7          	jalr	1776(ra) # 80000af4 <kalloc>
    8000640c:	85aa                	mv	a1,a0
    8000640e:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006412:	cd11                	beqz	a0,8000642e <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006414:	6605                	lui	a2,0x1
    80006416:	e3043503          	ld	a0,-464(s0)
    8000641a:	ffffd097          	auipc	ra,0xffffd
    8000641e:	0a2080e7          	jalr	162(ra) # 800034bc <fetchstr>
    80006422:	00054663          	bltz	a0,8000642e <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80006426:	0905                	addi	s2,s2,1
    80006428:	09a1                	addi	s3,s3,8
    8000642a:	fb491be3          	bne	s2,s4,800063e0 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000642e:	10048913          	addi	s2,s1,256
    80006432:	6088                	ld	a0,0(s1)
    80006434:	c529                	beqz	a0,8000647e <sys_exec+0xf8>
    kfree(argv[i]);
    80006436:	ffffa097          	auipc	ra,0xffffa
    8000643a:	5c2080e7          	jalr	1474(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000643e:	04a1                	addi	s1,s1,8
    80006440:	ff2499e3          	bne	s1,s2,80006432 <sys_exec+0xac>
  return -1;
    80006444:	597d                	li	s2,-1
    80006446:	a82d                	j	80006480 <sys_exec+0xfa>
      argv[i] = 0;
    80006448:	0a8e                	slli	s5,s5,0x3
    8000644a:	fc040793          	addi	a5,s0,-64
    8000644e:	9abe                	add	s5,s5,a5
    80006450:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80006454:	e4040593          	addi	a1,s0,-448
    80006458:	f4040513          	addi	a0,s0,-192
    8000645c:	fffff097          	auipc	ra,0xfffff
    80006460:	194080e7          	jalr	404(ra) # 800055f0 <exec>
    80006464:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006466:	10048993          	addi	s3,s1,256
    8000646a:	6088                	ld	a0,0(s1)
    8000646c:	c911                	beqz	a0,80006480 <sys_exec+0xfa>
    kfree(argv[i]);
    8000646e:	ffffa097          	auipc	ra,0xffffa
    80006472:	58a080e7          	jalr	1418(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006476:	04a1                	addi	s1,s1,8
    80006478:	ff3499e3          	bne	s1,s3,8000646a <sys_exec+0xe4>
    8000647c:	a011                	j	80006480 <sys_exec+0xfa>
  return -1;
    8000647e:	597d                	li	s2,-1
}
    80006480:	854a                	mv	a0,s2
    80006482:	60be                	ld	ra,456(sp)
    80006484:	641e                	ld	s0,448(sp)
    80006486:	74fa                	ld	s1,440(sp)
    80006488:	795a                	ld	s2,432(sp)
    8000648a:	79ba                	ld	s3,424(sp)
    8000648c:	7a1a                	ld	s4,416(sp)
    8000648e:	6afa                	ld	s5,408(sp)
    80006490:	6179                	addi	sp,sp,464
    80006492:	8082                	ret

0000000080006494 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006494:	7139                	addi	sp,sp,-64
    80006496:	fc06                	sd	ra,56(sp)
    80006498:	f822                	sd	s0,48(sp)
    8000649a:	f426                	sd	s1,40(sp)
    8000649c:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    8000649e:	ffffc097          	auipc	ra,0xffffc
    800064a2:	9c0080e7          	jalr	-1600(ra) # 80001e5e <myproc>
    800064a6:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    800064a8:	fd840593          	addi	a1,s0,-40
    800064ac:	4501                	li	a0,0
    800064ae:	ffffd097          	auipc	ra,0xffffd
    800064b2:	078080e7          	jalr	120(ra) # 80003526 <argaddr>
    return -1;
    800064b6:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    800064b8:	0e054063          	bltz	a0,80006598 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    800064bc:	fc840593          	addi	a1,s0,-56
    800064c0:	fd040513          	addi	a0,s0,-48
    800064c4:	fffff097          	auipc	ra,0xfffff
    800064c8:	dfc080e7          	jalr	-516(ra) # 800052c0 <pipealloc>
    return -1;
    800064cc:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800064ce:	0c054563          	bltz	a0,80006598 <sys_pipe+0x104>
  fd0 = -1;
    800064d2:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800064d6:	fd043503          	ld	a0,-48(s0)
    800064da:	fffff097          	auipc	ra,0xfffff
    800064de:	508080e7          	jalr	1288(ra) # 800059e2 <fdalloc>
    800064e2:	fca42223          	sw	a0,-60(s0)
    800064e6:	08054c63          	bltz	a0,8000657e <sys_pipe+0xea>
    800064ea:	fc843503          	ld	a0,-56(s0)
    800064ee:	fffff097          	auipc	ra,0xfffff
    800064f2:	4f4080e7          	jalr	1268(ra) # 800059e2 <fdalloc>
    800064f6:	fca42023          	sw	a0,-64(s0)
    800064fa:	06054863          	bltz	a0,8000656a <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800064fe:	4691                	li	a3,4
    80006500:	fc440613          	addi	a2,s0,-60
    80006504:	fd843583          	ld	a1,-40(s0)
    80006508:	74a8                	ld	a0,104(s1)
    8000650a:	ffffb097          	auipc	ra,0xffffb
    8000650e:	168080e7          	jalr	360(ra) # 80001672 <copyout>
    80006512:	02054063          	bltz	a0,80006532 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006516:	4691                	li	a3,4
    80006518:	fc040613          	addi	a2,s0,-64
    8000651c:	fd843583          	ld	a1,-40(s0)
    80006520:	0591                	addi	a1,a1,4
    80006522:	74a8                	ld	a0,104(s1)
    80006524:	ffffb097          	auipc	ra,0xffffb
    80006528:	14e080e7          	jalr	334(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    8000652c:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000652e:	06055563          	bgez	a0,80006598 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80006532:	fc442783          	lw	a5,-60(s0)
    80006536:	07f1                	addi	a5,a5,28
    80006538:	078e                	slli	a5,a5,0x3
    8000653a:	97a6                	add	a5,a5,s1
    8000653c:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80006540:	fc042503          	lw	a0,-64(s0)
    80006544:	0571                	addi	a0,a0,28
    80006546:	050e                	slli	a0,a0,0x3
    80006548:	9526                	add	a0,a0,s1
    8000654a:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    8000654e:	fd043503          	ld	a0,-48(s0)
    80006552:	fffff097          	auipc	ra,0xfffff
    80006556:	a3e080e7          	jalr	-1474(ra) # 80004f90 <fileclose>
    fileclose(wf);
    8000655a:	fc843503          	ld	a0,-56(s0)
    8000655e:	fffff097          	auipc	ra,0xfffff
    80006562:	a32080e7          	jalr	-1486(ra) # 80004f90 <fileclose>
    return -1;
    80006566:	57fd                	li	a5,-1
    80006568:	a805                	j	80006598 <sys_pipe+0x104>
    if(fd0 >= 0)
    8000656a:	fc442783          	lw	a5,-60(s0)
    8000656e:	0007c863          	bltz	a5,8000657e <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80006572:	01c78513          	addi	a0,a5,28
    80006576:	050e                	slli	a0,a0,0x3
    80006578:	9526                	add	a0,a0,s1
    8000657a:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    8000657e:	fd043503          	ld	a0,-48(s0)
    80006582:	fffff097          	auipc	ra,0xfffff
    80006586:	a0e080e7          	jalr	-1522(ra) # 80004f90 <fileclose>
    fileclose(wf);
    8000658a:	fc843503          	ld	a0,-56(s0)
    8000658e:	fffff097          	auipc	ra,0xfffff
    80006592:	a02080e7          	jalr	-1534(ra) # 80004f90 <fileclose>
    return -1;
    80006596:	57fd                	li	a5,-1
}
    80006598:	853e                	mv	a0,a5
    8000659a:	70e2                	ld	ra,56(sp)
    8000659c:	7442                	ld	s0,48(sp)
    8000659e:	74a2                	ld	s1,40(sp)
    800065a0:	6121                	addi	sp,sp,64
    800065a2:	8082                	ret
	...

00000000800065b0 <kernelvec>:
    800065b0:	7111                	addi	sp,sp,-256
    800065b2:	e006                	sd	ra,0(sp)
    800065b4:	e40a                	sd	sp,8(sp)
    800065b6:	e80e                	sd	gp,16(sp)
    800065b8:	ec12                	sd	tp,24(sp)
    800065ba:	f016                	sd	t0,32(sp)
    800065bc:	f41a                	sd	t1,40(sp)
    800065be:	f81e                	sd	t2,48(sp)
    800065c0:	fc22                	sd	s0,56(sp)
    800065c2:	e0a6                	sd	s1,64(sp)
    800065c4:	e4aa                	sd	a0,72(sp)
    800065c6:	e8ae                	sd	a1,80(sp)
    800065c8:	ecb2                	sd	a2,88(sp)
    800065ca:	f0b6                	sd	a3,96(sp)
    800065cc:	f4ba                	sd	a4,104(sp)
    800065ce:	f8be                	sd	a5,112(sp)
    800065d0:	fcc2                	sd	a6,120(sp)
    800065d2:	e146                	sd	a7,128(sp)
    800065d4:	e54a                	sd	s2,136(sp)
    800065d6:	e94e                	sd	s3,144(sp)
    800065d8:	ed52                	sd	s4,152(sp)
    800065da:	f156                	sd	s5,160(sp)
    800065dc:	f55a                	sd	s6,168(sp)
    800065de:	f95e                	sd	s7,176(sp)
    800065e0:	fd62                	sd	s8,184(sp)
    800065e2:	e1e6                	sd	s9,192(sp)
    800065e4:	e5ea                	sd	s10,200(sp)
    800065e6:	e9ee                	sd	s11,208(sp)
    800065e8:	edf2                	sd	t3,216(sp)
    800065ea:	f1f6                	sd	t4,224(sp)
    800065ec:	f5fa                	sd	t5,232(sp)
    800065ee:	f9fe                	sd	t6,240(sp)
    800065f0:	d47fc0ef          	jal	ra,80003336 <kerneltrap>
    800065f4:	6082                	ld	ra,0(sp)
    800065f6:	6122                	ld	sp,8(sp)
    800065f8:	61c2                	ld	gp,16(sp)
    800065fa:	7282                	ld	t0,32(sp)
    800065fc:	7322                	ld	t1,40(sp)
    800065fe:	73c2                	ld	t2,48(sp)
    80006600:	7462                	ld	s0,56(sp)
    80006602:	6486                	ld	s1,64(sp)
    80006604:	6526                	ld	a0,72(sp)
    80006606:	65c6                	ld	a1,80(sp)
    80006608:	6666                	ld	a2,88(sp)
    8000660a:	7686                	ld	a3,96(sp)
    8000660c:	7726                	ld	a4,104(sp)
    8000660e:	77c6                	ld	a5,112(sp)
    80006610:	7866                	ld	a6,120(sp)
    80006612:	688a                	ld	a7,128(sp)
    80006614:	692a                	ld	s2,136(sp)
    80006616:	69ca                	ld	s3,144(sp)
    80006618:	6a6a                	ld	s4,152(sp)
    8000661a:	7a8a                	ld	s5,160(sp)
    8000661c:	7b2a                	ld	s6,168(sp)
    8000661e:	7bca                	ld	s7,176(sp)
    80006620:	7c6a                	ld	s8,184(sp)
    80006622:	6c8e                	ld	s9,192(sp)
    80006624:	6d2e                	ld	s10,200(sp)
    80006626:	6dce                	ld	s11,208(sp)
    80006628:	6e6e                	ld	t3,216(sp)
    8000662a:	7e8e                	ld	t4,224(sp)
    8000662c:	7f2e                	ld	t5,232(sp)
    8000662e:	7fce                	ld	t6,240(sp)
    80006630:	6111                	addi	sp,sp,256
    80006632:	10200073          	sret
    80006636:	00000013          	nop
    8000663a:	00000013          	nop
    8000663e:	0001                	nop

0000000080006640 <timervec>:
    80006640:	34051573          	csrrw	a0,mscratch,a0
    80006644:	e10c                	sd	a1,0(a0)
    80006646:	e510                	sd	a2,8(a0)
    80006648:	e914                	sd	a3,16(a0)
    8000664a:	6d0c                	ld	a1,24(a0)
    8000664c:	7110                	ld	a2,32(a0)
    8000664e:	6194                	ld	a3,0(a1)
    80006650:	96b2                	add	a3,a3,a2
    80006652:	e194                	sd	a3,0(a1)
    80006654:	4589                	li	a1,2
    80006656:	14459073          	csrw	sip,a1
    8000665a:	6914                	ld	a3,16(a0)
    8000665c:	6510                	ld	a2,8(a0)
    8000665e:	610c                	ld	a1,0(a0)
    80006660:	34051573          	csrrw	a0,mscratch,a0
    80006664:	30200073          	mret
	...

000000008000666a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000666a:	1141                	addi	sp,sp,-16
    8000666c:	e422                	sd	s0,8(sp)
    8000666e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006670:	0c0007b7          	lui	a5,0xc000
    80006674:	4705                	li	a4,1
    80006676:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006678:	c3d8                	sw	a4,4(a5)
}
    8000667a:	6422                	ld	s0,8(sp)
    8000667c:	0141                	addi	sp,sp,16
    8000667e:	8082                	ret

0000000080006680 <plicinithart>:

void
plicinithart(void)
{
    80006680:	1141                	addi	sp,sp,-16
    80006682:	e406                	sd	ra,8(sp)
    80006684:	e022                	sd	s0,0(sp)
    80006686:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006688:	ffffb097          	auipc	ra,0xffffb
    8000668c:	7aa080e7          	jalr	1962(ra) # 80001e32 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006690:	0085171b          	slliw	a4,a0,0x8
    80006694:	0c0027b7          	lui	a5,0xc002
    80006698:	97ba                	add	a5,a5,a4
    8000669a:	40200713          	li	a4,1026
    8000669e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800066a2:	00d5151b          	slliw	a0,a0,0xd
    800066a6:	0c2017b7          	lui	a5,0xc201
    800066aa:	953e                	add	a0,a0,a5
    800066ac:	00052023          	sw	zero,0(a0)
}
    800066b0:	60a2                	ld	ra,8(sp)
    800066b2:	6402                	ld	s0,0(sp)
    800066b4:	0141                	addi	sp,sp,16
    800066b6:	8082                	ret

00000000800066b8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800066b8:	1141                	addi	sp,sp,-16
    800066ba:	e406                	sd	ra,8(sp)
    800066bc:	e022                	sd	s0,0(sp)
    800066be:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800066c0:	ffffb097          	auipc	ra,0xffffb
    800066c4:	772080e7          	jalr	1906(ra) # 80001e32 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800066c8:	00d5179b          	slliw	a5,a0,0xd
    800066cc:	0c201537          	lui	a0,0xc201
    800066d0:	953e                	add	a0,a0,a5
  return irq;
}
    800066d2:	4148                	lw	a0,4(a0)
    800066d4:	60a2                	ld	ra,8(sp)
    800066d6:	6402                	ld	s0,0(sp)
    800066d8:	0141                	addi	sp,sp,16
    800066da:	8082                	ret

00000000800066dc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800066dc:	1101                	addi	sp,sp,-32
    800066de:	ec06                	sd	ra,24(sp)
    800066e0:	e822                	sd	s0,16(sp)
    800066e2:	e426                	sd	s1,8(sp)
    800066e4:	1000                	addi	s0,sp,32
    800066e6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800066e8:	ffffb097          	auipc	ra,0xffffb
    800066ec:	74a080e7          	jalr	1866(ra) # 80001e32 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800066f0:	00d5151b          	slliw	a0,a0,0xd
    800066f4:	0c2017b7          	lui	a5,0xc201
    800066f8:	97aa                	add	a5,a5,a0
    800066fa:	c3c4                	sw	s1,4(a5)
}
    800066fc:	60e2                	ld	ra,24(sp)
    800066fe:	6442                	ld	s0,16(sp)
    80006700:	64a2                	ld	s1,8(sp)
    80006702:	6105                	addi	sp,sp,32
    80006704:	8082                	ret

0000000080006706 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006706:	1141                	addi	sp,sp,-16
    80006708:	e406                	sd	ra,8(sp)
    8000670a:	e022                	sd	s0,0(sp)
    8000670c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000670e:	479d                	li	a5,7
    80006710:	06a7c963          	blt	a5,a0,80006782 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006714:	0001d797          	auipc	a5,0x1d
    80006718:	8ec78793          	addi	a5,a5,-1812 # 80023000 <disk>
    8000671c:	00a78733          	add	a4,a5,a0
    80006720:	6789                	lui	a5,0x2
    80006722:	97ba                	add	a5,a5,a4
    80006724:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006728:	e7ad                	bnez	a5,80006792 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000672a:	00451793          	slli	a5,a0,0x4
    8000672e:	0001f717          	auipc	a4,0x1f
    80006732:	8d270713          	addi	a4,a4,-1838 # 80025000 <disk+0x2000>
    80006736:	6314                	ld	a3,0(a4)
    80006738:	96be                	add	a3,a3,a5
    8000673a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000673e:	6314                	ld	a3,0(a4)
    80006740:	96be                	add	a3,a3,a5
    80006742:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006746:	6314                	ld	a3,0(a4)
    80006748:	96be                	add	a3,a3,a5
    8000674a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000674e:	6318                	ld	a4,0(a4)
    80006750:	97ba                	add	a5,a5,a4
    80006752:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006756:	0001d797          	auipc	a5,0x1d
    8000675a:	8aa78793          	addi	a5,a5,-1878 # 80023000 <disk>
    8000675e:	97aa                	add	a5,a5,a0
    80006760:	6509                	lui	a0,0x2
    80006762:	953e                	add	a0,a0,a5
    80006764:	4785                	li	a5,1
    80006766:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000676a:	0001f517          	auipc	a0,0x1f
    8000676e:	8ae50513          	addi	a0,a0,-1874 # 80025018 <disk+0x2018>
    80006772:	ffffc097          	auipc	ra,0xffffc
    80006776:	faa080e7          	jalr	-86(ra) # 8000271c <wakeup>
}
    8000677a:	60a2                	ld	ra,8(sp)
    8000677c:	6402                	ld	s0,0(sp)
    8000677e:	0141                	addi	sp,sp,16
    80006780:	8082                	ret
    panic("free_desc 1");
    80006782:	00002517          	auipc	a0,0x2
    80006786:	06e50513          	addi	a0,a0,110 # 800087f0 <syscalls+0x338>
    8000678a:	ffffa097          	auipc	ra,0xffffa
    8000678e:	db4080e7          	jalr	-588(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006792:	00002517          	auipc	a0,0x2
    80006796:	06e50513          	addi	a0,a0,110 # 80008800 <syscalls+0x348>
    8000679a:	ffffa097          	auipc	ra,0xffffa
    8000679e:	da4080e7          	jalr	-604(ra) # 8000053e <panic>

00000000800067a2 <virtio_disk_init>:
{
    800067a2:	1101                	addi	sp,sp,-32
    800067a4:	ec06                	sd	ra,24(sp)
    800067a6:	e822                	sd	s0,16(sp)
    800067a8:	e426                	sd	s1,8(sp)
    800067aa:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800067ac:	00002597          	auipc	a1,0x2
    800067b0:	06458593          	addi	a1,a1,100 # 80008810 <syscalls+0x358>
    800067b4:	0001f517          	auipc	a0,0x1f
    800067b8:	97450513          	addi	a0,a0,-1676 # 80025128 <disk+0x2128>
    800067bc:	ffffa097          	auipc	ra,0xffffa
    800067c0:	398080e7          	jalr	920(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800067c4:	100017b7          	lui	a5,0x10001
    800067c8:	4398                	lw	a4,0(a5)
    800067ca:	2701                	sext.w	a4,a4
    800067cc:	747277b7          	lui	a5,0x74727
    800067d0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800067d4:	0ef71163          	bne	a4,a5,800068b6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800067d8:	100017b7          	lui	a5,0x10001
    800067dc:	43dc                	lw	a5,4(a5)
    800067de:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800067e0:	4705                	li	a4,1
    800067e2:	0ce79a63          	bne	a5,a4,800068b6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800067e6:	100017b7          	lui	a5,0x10001
    800067ea:	479c                	lw	a5,8(a5)
    800067ec:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800067ee:	4709                	li	a4,2
    800067f0:	0ce79363          	bne	a5,a4,800068b6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800067f4:	100017b7          	lui	a5,0x10001
    800067f8:	47d8                	lw	a4,12(a5)
    800067fa:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800067fc:	554d47b7          	lui	a5,0x554d4
    80006800:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006804:	0af71963          	bne	a4,a5,800068b6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006808:	100017b7          	lui	a5,0x10001
    8000680c:	4705                	li	a4,1
    8000680e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006810:	470d                	li	a4,3
    80006812:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006814:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006816:	c7ffe737          	lui	a4,0xc7ffe
    8000681a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000681e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006820:	2701                	sext.w	a4,a4
    80006822:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006824:	472d                	li	a4,11
    80006826:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006828:	473d                	li	a4,15
    8000682a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000682c:	6705                	lui	a4,0x1
    8000682e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006830:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006834:	5bdc                	lw	a5,52(a5)
    80006836:	2781                	sext.w	a5,a5
  if(max == 0)
    80006838:	c7d9                	beqz	a5,800068c6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000683a:	471d                	li	a4,7
    8000683c:	08f77d63          	bgeu	a4,a5,800068d6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006840:	100014b7          	lui	s1,0x10001
    80006844:	47a1                	li	a5,8
    80006846:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006848:	6609                	lui	a2,0x2
    8000684a:	4581                	li	a1,0
    8000684c:	0001c517          	auipc	a0,0x1c
    80006850:	7b450513          	addi	a0,a0,1972 # 80023000 <disk>
    80006854:	ffffa097          	auipc	ra,0xffffa
    80006858:	48c080e7          	jalr	1164(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000685c:	0001c717          	auipc	a4,0x1c
    80006860:	7a470713          	addi	a4,a4,1956 # 80023000 <disk>
    80006864:	00c75793          	srli	a5,a4,0xc
    80006868:	2781                	sext.w	a5,a5
    8000686a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000686c:	0001e797          	auipc	a5,0x1e
    80006870:	79478793          	addi	a5,a5,1940 # 80025000 <disk+0x2000>
    80006874:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006876:	0001d717          	auipc	a4,0x1d
    8000687a:	80a70713          	addi	a4,a4,-2038 # 80023080 <disk+0x80>
    8000687e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006880:	0001d717          	auipc	a4,0x1d
    80006884:	78070713          	addi	a4,a4,1920 # 80024000 <disk+0x1000>
    80006888:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000688a:	4705                	li	a4,1
    8000688c:	00e78c23          	sb	a4,24(a5)
    80006890:	00e78ca3          	sb	a4,25(a5)
    80006894:	00e78d23          	sb	a4,26(a5)
    80006898:	00e78da3          	sb	a4,27(a5)
    8000689c:	00e78e23          	sb	a4,28(a5)
    800068a0:	00e78ea3          	sb	a4,29(a5)
    800068a4:	00e78f23          	sb	a4,30(a5)
    800068a8:	00e78fa3          	sb	a4,31(a5)
}
    800068ac:	60e2                	ld	ra,24(sp)
    800068ae:	6442                	ld	s0,16(sp)
    800068b0:	64a2                	ld	s1,8(sp)
    800068b2:	6105                	addi	sp,sp,32
    800068b4:	8082                	ret
    panic("could not find virtio disk");
    800068b6:	00002517          	auipc	a0,0x2
    800068ba:	f6a50513          	addi	a0,a0,-150 # 80008820 <syscalls+0x368>
    800068be:	ffffa097          	auipc	ra,0xffffa
    800068c2:	c80080e7          	jalr	-896(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    800068c6:	00002517          	auipc	a0,0x2
    800068ca:	f7a50513          	addi	a0,a0,-134 # 80008840 <syscalls+0x388>
    800068ce:	ffffa097          	auipc	ra,0xffffa
    800068d2:	c70080e7          	jalr	-912(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    800068d6:	00002517          	auipc	a0,0x2
    800068da:	f8a50513          	addi	a0,a0,-118 # 80008860 <syscalls+0x3a8>
    800068de:	ffffa097          	auipc	ra,0xffffa
    800068e2:	c60080e7          	jalr	-928(ra) # 8000053e <panic>

00000000800068e6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800068e6:	7159                	addi	sp,sp,-112
    800068e8:	f486                	sd	ra,104(sp)
    800068ea:	f0a2                	sd	s0,96(sp)
    800068ec:	eca6                	sd	s1,88(sp)
    800068ee:	e8ca                	sd	s2,80(sp)
    800068f0:	e4ce                	sd	s3,72(sp)
    800068f2:	e0d2                	sd	s4,64(sp)
    800068f4:	fc56                	sd	s5,56(sp)
    800068f6:	f85a                	sd	s6,48(sp)
    800068f8:	f45e                	sd	s7,40(sp)
    800068fa:	f062                	sd	s8,32(sp)
    800068fc:	ec66                	sd	s9,24(sp)
    800068fe:	e86a                	sd	s10,16(sp)
    80006900:	1880                	addi	s0,sp,112
    80006902:	892a                	mv	s2,a0
    80006904:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006906:	00c52c83          	lw	s9,12(a0)
    8000690a:	001c9c9b          	slliw	s9,s9,0x1
    8000690e:	1c82                	slli	s9,s9,0x20
    80006910:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006914:	0001f517          	auipc	a0,0x1f
    80006918:	81450513          	addi	a0,a0,-2028 # 80025128 <disk+0x2128>
    8000691c:	ffffa097          	auipc	ra,0xffffa
    80006920:	2c8080e7          	jalr	712(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006924:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006926:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006928:	0001cb97          	auipc	s7,0x1c
    8000692c:	6d8b8b93          	addi	s7,s7,1752 # 80023000 <disk>
    80006930:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006932:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006934:	8a4e                	mv	s4,s3
    80006936:	a051                	j	800069ba <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006938:	00fb86b3          	add	a3,s7,a5
    8000693c:	96da                	add	a3,a3,s6
    8000693e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006942:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006944:	0207c563          	bltz	a5,8000696e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006948:	2485                	addiw	s1,s1,1
    8000694a:	0711                	addi	a4,a4,4
    8000694c:	25548063          	beq	s1,s5,80006b8c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006950:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006952:	0001e697          	auipc	a3,0x1e
    80006956:	6c668693          	addi	a3,a3,1734 # 80025018 <disk+0x2018>
    8000695a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000695c:	0006c583          	lbu	a1,0(a3)
    80006960:	fde1                	bnez	a1,80006938 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006962:	2785                	addiw	a5,a5,1
    80006964:	0685                	addi	a3,a3,1
    80006966:	ff879be3          	bne	a5,s8,8000695c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000696a:	57fd                	li	a5,-1
    8000696c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000696e:	02905a63          	blez	s1,800069a2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006972:	f9042503          	lw	a0,-112(s0)
    80006976:	00000097          	auipc	ra,0x0
    8000697a:	d90080e7          	jalr	-624(ra) # 80006706 <free_desc>
      for(int j = 0; j < i; j++)
    8000697e:	4785                	li	a5,1
    80006980:	0297d163          	bge	a5,s1,800069a2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006984:	f9442503          	lw	a0,-108(s0)
    80006988:	00000097          	auipc	ra,0x0
    8000698c:	d7e080e7          	jalr	-642(ra) # 80006706 <free_desc>
      for(int j = 0; j < i; j++)
    80006990:	4789                	li	a5,2
    80006992:	0097d863          	bge	a5,s1,800069a2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006996:	f9842503          	lw	a0,-104(s0)
    8000699a:	00000097          	auipc	ra,0x0
    8000699e:	d6c080e7          	jalr	-660(ra) # 80006706 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800069a2:	0001e597          	auipc	a1,0x1e
    800069a6:	78658593          	addi	a1,a1,1926 # 80025128 <disk+0x2128>
    800069aa:	0001e517          	auipc	a0,0x1e
    800069ae:	66e50513          	addi	a0,a0,1646 # 80025018 <disk+0x2018>
    800069b2:	ffffc097          	auipc	ra,0xffffc
    800069b6:	bc8080e7          	jalr	-1080(ra) # 8000257a <sleep>
  for(int i = 0; i < 3; i++){
    800069ba:	f9040713          	addi	a4,s0,-112
    800069be:	84ce                	mv	s1,s3
    800069c0:	bf41                	j	80006950 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800069c2:	20058713          	addi	a4,a1,512
    800069c6:	00471693          	slli	a3,a4,0x4
    800069ca:	0001c717          	auipc	a4,0x1c
    800069ce:	63670713          	addi	a4,a4,1590 # 80023000 <disk>
    800069d2:	9736                	add	a4,a4,a3
    800069d4:	4685                	li	a3,1
    800069d6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800069da:	20058713          	addi	a4,a1,512
    800069de:	00471693          	slli	a3,a4,0x4
    800069e2:	0001c717          	auipc	a4,0x1c
    800069e6:	61e70713          	addi	a4,a4,1566 # 80023000 <disk>
    800069ea:	9736                	add	a4,a4,a3
    800069ec:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800069f0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800069f4:	7679                	lui	a2,0xffffe
    800069f6:	963e                	add	a2,a2,a5
    800069f8:	0001e697          	auipc	a3,0x1e
    800069fc:	60868693          	addi	a3,a3,1544 # 80025000 <disk+0x2000>
    80006a00:	6298                	ld	a4,0(a3)
    80006a02:	9732                	add	a4,a4,a2
    80006a04:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006a06:	6298                	ld	a4,0(a3)
    80006a08:	9732                	add	a4,a4,a2
    80006a0a:	4541                	li	a0,16
    80006a0c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006a0e:	6298                	ld	a4,0(a3)
    80006a10:	9732                	add	a4,a4,a2
    80006a12:	4505                	li	a0,1
    80006a14:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006a18:	f9442703          	lw	a4,-108(s0)
    80006a1c:	6288                	ld	a0,0(a3)
    80006a1e:	962a                	add	a2,a2,a0
    80006a20:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006a24:	0712                	slli	a4,a4,0x4
    80006a26:	6290                	ld	a2,0(a3)
    80006a28:	963a                	add	a2,a2,a4
    80006a2a:	05890513          	addi	a0,s2,88
    80006a2e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006a30:	6294                	ld	a3,0(a3)
    80006a32:	96ba                	add	a3,a3,a4
    80006a34:	40000613          	li	a2,1024
    80006a38:	c690                	sw	a2,8(a3)
  if(write)
    80006a3a:	140d0063          	beqz	s10,80006b7a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006a3e:	0001e697          	auipc	a3,0x1e
    80006a42:	5c26b683          	ld	a3,1474(a3) # 80025000 <disk+0x2000>
    80006a46:	96ba                	add	a3,a3,a4
    80006a48:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006a4c:	0001c817          	auipc	a6,0x1c
    80006a50:	5b480813          	addi	a6,a6,1460 # 80023000 <disk>
    80006a54:	0001e517          	auipc	a0,0x1e
    80006a58:	5ac50513          	addi	a0,a0,1452 # 80025000 <disk+0x2000>
    80006a5c:	6114                	ld	a3,0(a0)
    80006a5e:	96ba                	add	a3,a3,a4
    80006a60:	00c6d603          	lhu	a2,12(a3)
    80006a64:	00166613          	ori	a2,a2,1
    80006a68:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006a6c:	f9842683          	lw	a3,-104(s0)
    80006a70:	6110                	ld	a2,0(a0)
    80006a72:	9732                	add	a4,a4,a2
    80006a74:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006a78:	20058613          	addi	a2,a1,512
    80006a7c:	0612                	slli	a2,a2,0x4
    80006a7e:	9642                	add	a2,a2,a6
    80006a80:	577d                	li	a4,-1
    80006a82:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006a86:	00469713          	slli	a4,a3,0x4
    80006a8a:	6114                	ld	a3,0(a0)
    80006a8c:	96ba                	add	a3,a3,a4
    80006a8e:	03078793          	addi	a5,a5,48
    80006a92:	97c2                	add	a5,a5,a6
    80006a94:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006a96:	611c                	ld	a5,0(a0)
    80006a98:	97ba                	add	a5,a5,a4
    80006a9a:	4685                	li	a3,1
    80006a9c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006a9e:	611c                	ld	a5,0(a0)
    80006aa0:	97ba                	add	a5,a5,a4
    80006aa2:	4809                	li	a6,2
    80006aa4:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006aa8:	611c                	ld	a5,0(a0)
    80006aaa:	973e                	add	a4,a4,a5
    80006aac:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006ab0:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006ab4:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006ab8:	6518                	ld	a4,8(a0)
    80006aba:	00275783          	lhu	a5,2(a4)
    80006abe:	8b9d                	andi	a5,a5,7
    80006ac0:	0786                	slli	a5,a5,0x1
    80006ac2:	97ba                	add	a5,a5,a4
    80006ac4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006ac8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006acc:	6518                	ld	a4,8(a0)
    80006ace:	00275783          	lhu	a5,2(a4)
    80006ad2:	2785                	addiw	a5,a5,1
    80006ad4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006ad8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006adc:	100017b7          	lui	a5,0x10001
    80006ae0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006ae4:	00492703          	lw	a4,4(s2)
    80006ae8:	4785                	li	a5,1
    80006aea:	02f71163          	bne	a4,a5,80006b0c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    80006aee:	0001e997          	auipc	s3,0x1e
    80006af2:	63a98993          	addi	s3,s3,1594 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006af6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006af8:	85ce                	mv	a1,s3
    80006afa:	854a                	mv	a0,s2
    80006afc:	ffffc097          	auipc	ra,0xffffc
    80006b00:	a7e080e7          	jalr	-1410(ra) # 8000257a <sleep>
  while(b->disk == 1) {
    80006b04:	00492783          	lw	a5,4(s2)
    80006b08:	fe9788e3          	beq	a5,s1,80006af8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    80006b0c:	f9042903          	lw	s2,-112(s0)
    80006b10:	20090793          	addi	a5,s2,512
    80006b14:	00479713          	slli	a4,a5,0x4
    80006b18:	0001c797          	auipc	a5,0x1c
    80006b1c:	4e878793          	addi	a5,a5,1256 # 80023000 <disk>
    80006b20:	97ba                	add	a5,a5,a4
    80006b22:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006b26:	0001e997          	auipc	s3,0x1e
    80006b2a:	4da98993          	addi	s3,s3,1242 # 80025000 <disk+0x2000>
    80006b2e:	00491713          	slli	a4,s2,0x4
    80006b32:	0009b783          	ld	a5,0(s3)
    80006b36:	97ba                	add	a5,a5,a4
    80006b38:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006b3c:	854a                	mv	a0,s2
    80006b3e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006b42:	00000097          	auipc	ra,0x0
    80006b46:	bc4080e7          	jalr	-1084(ra) # 80006706 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006b4a:	8885                	andi	s1,s1,1
    80006b4c:	f0ed                	bnez	s1,80006b2e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006b4e:	0001e517          	auipc	a0,0x1e
    80006b52:	5da50513          	addi	a0,a0,1498 # 80025128 <disk+0x2128>
    80006b56:	ffffa097          	auipc	ra,0xffffa
    80006b5a:	142080e7          	jalr	322(ra) # 80000c98 <release>
}
    80006b5e:	70a6                	ld	ra,104(sp)
    80006b60:	7406                	ld	s0,96(sp)
    80006b62:	64e6                	ld	s1,88(sp)
    80006b64:	6946                	ld	s2,80(sp)
    80006b66:	69a6                	ld	s3,72(sp)
    80006b68:	6a06                	ld	s4,64(sp)
    80006b6a:	7ae2                	ld	s5,56(sp)
    80006b6c:	7b42                	ld	s6,48(sp)
    80006b6e:	7ba2                	ld	s7,40(sp)
    80006b70:	7c02                	ld	s8,32(sp)
    80006b72:	6ce2                	ld	s9,24(sp)
    80006b74:	6d42                	ld	s10,16(sp)
    80006b76:	6165                	addi	sp,sp,112
    80006b78:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006b7a:	0001e697          	auipc	a3,0x1e
    80006b7e:	4866b683          	ld	a3,1158(a3) # 80025000 <disk+0x2000>
    80006b82:	96ba                	add	a3,a3,a4
    80006b84:	4609                	li	a2,2
    80006b86:	00c69623          	sh	a2,12(a3)
    80006b8a:	b5c9                	j	80006a4c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006b8c:	f9042583          	lw	a1,-112(s0)
    80006b90:	20058793          	addi	a5,a1,512
    80006b94:	0792                	slli	a5,a5,0x4
    80006b96:	0001c517          	auipc	a0,0x1c
    80006b9a:	51250513          	addi	a0,a0,1298 # 800230a8 <disk+0xa8>
    80006b9e:	953e                	add	a0,a0,a5
  if(write)
    80006ba0:	e20d11e3          	bnez	s10,800069c2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006ba4:	20058713          	addi	a4,a1,512
    80006ba8:	00471693          	slli	a3,a4,0x4
    80006bac:	0001c717          	auipc	a4,0x1c
    80006bb0:	45470713          	addi	a4,a4,1108 # 80023000 <disk>
    80006bb4:	9736                	add	a4,a4,a3
    80006bb6:	0a072423          	sw	zero,168(a4)
    80006bba:	b505                	j	800069da <virtio_disk_rw+0xf4>

0000000080006bbc <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006bbc:	1101                	addi	sp,sp,-32
    80006bbe:	ec06                	sd	ra,24(sp)
    80006bc0:	e822                	sd	s0,16(sp)
    80006bc2:	e426                	sd	s1,8(sp)
    80006bc4:	e04a                	sd	s2,0(sp)
    80006bc6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006bc8:	0001e517          	auipc	a0,0x1e
    80006bcc:	56050513          	addi	a0,a0,1376 # 80025128 <disk+0x2128>
    80006bd0:	ffffa097          	auipc	ra,0xffffa
    80006bd4:	014080e7          	jalr	20(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006bd8:	10001737          	lui	a4,0x10001
    80006bdc:	533c                	lw	a5,96(a4)
    80006bde:	8b8d                	andi	a5,a5,3
    80006be0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006be2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006be6:	0001e797          	auipc	a5,0x1e
    80006bea:	41a78793          	addi	a5,a5,1050 # 80025000 <disk+0x2000>
    80006bee:	6b94                	ld	a3,16(a5)
    80006bf0:	0207d703          	lhu	a4,32(a5)
    80006bf4:	0026d783          	lhu	a5,2(a3)
    80006bf8:	06f70163          	beq	a4,a5,80006c5a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006bfc:	0001c917          	auipc	s2,0x1c
    80006c00:	40490913          	addi	s2,s2,1028 # 80023000 <disk>
    80006c04:	0001e497          	auipc	s1,0x1e
    80006c08:	3fc48493          	addi	s1,s1,1020 # 80025000 <disk+0x2000>
    __sync_synchronize();
    80006c0c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006c10:	6898                	ld	a4,16(s1)
    80006c12:	0204d783          	lhu	a5,32(s1)
    80006c16:	8b9d                	andi	a5,a5,7
    80006c18:	078e                	slli	a5,a5,0x3
    80006c1a:	97ba                	add	a5,a5,a4
    80006c1c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006c1e:	20078713          	addi	a4,a5,512
    80006c22:	0712                	slli	a4,a4,0x4
    80006c24:	974a                	add	a4,a4,s2
    80006c26:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    80006c2a:	e731                	bnez	a4,80006c76 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006c2c:	20078793          	addi	a5,a5,512
    80006c30:	0792                	slli	a5,a5,0x4
    80006c32:	97ca                	add	a5,a5,s2
    80006c34:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006c36:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006c3a:	ffffc097          	auipc	ra,0xffffc
    80006c3e:	ae2080e7          	jalr	-1310(ra) # 8000271c <wakeup>

    disk.used_idx += 1;
    80006c42:	0204d783          	lhu	a5,32(s1)
    80006c46:	2785                	addiw	a5,a5,1
    80006c48:	17c2                	slli	a5,a5,0x30
    80006c4a:	93c1                	srli	a5,a5,0x30
    80006c4c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006c50:	6898                	ld	a4,16(s1)
    80006c52:	00275703          	lhu	a4,2(a4)
    80006c56:	faf71be3          	bne	a4,a5,80006c0c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    80006c5a:	0001e517          	auipc	a0,0x1e
    80006c5e:	4ce50513          	addi	a0,a0,1230 # 80025128 <disk+0x2128>
    80006c62:	ffffa097          	auipc	ra,0xffffa
    80006c66:	036080e7          	jalr	54(ra) # 80000c98 <release>
}
    80006c6a:	60e2                	ld	ra,24(sp)
    80006c6c:	6442                	ld	s0,16(sp)
    80006c6e:	64a2                	ld	s1,8(sp)
    80006c70:	6902                	ld	s2,0(sp)
    80006c72:	6105                	addi	sp,sp,32
    80006c74:	8082                	ret
      panic("virtio_disk_intr status");
    80006c76:	00002517          	auipc	a0,0x2
    80006c7a:	c0a50513          	addi	a0,a0,-1014 # 80008880 <syscalls+0x3c8>
    80006c7e:	ffffa097          	auipc	ra,0xffffa
    80006c82:	8c0080e7          	jalr	-1856(ra) # 8000053e <panic>

0000000080006c86 <cas>:
    80006c86:	100522af          	lr.w	t0,(a0)
    80006c8a:	00b29563          	bne	t0,a1,80006c94 <fail>
    80006c8e:	18c5252f          	sc.w	a0,a2,(a0)
    80006c92:	8082                	ret

0000000080006c94 <fail>:
    80006c94:	4505                	li	a0,1
    80006c96:	8082                	ret
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
