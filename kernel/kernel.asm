
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	b9013103          	ld	sp,-1136(sp) # 80008b90 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000068:	2cc78793          	addi	a5,a5,716 # 80006330 <timervec>
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
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	4ee080e7          	jalr	1262(ra) # 8000261a <either_copyin>
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
    800001c8:	b2e080e7          	jalr	-1234(ra) # 80001cf2 <myproc>
    800001cc:	413c                	lw	a5,64(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	194080e7          	jalr	404(ra) # 80002368 <sleep>
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
    80000210:	00002097          	auipc	ra,0x2
    80000214:	3b4080e7          	jalr	948(ra) # 800025c4 <either_copyout>
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
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	37e080e7          	jalr	894(ra) # 80002670 <procdump>
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
    8000044a:	2d8080e7          	jalr	728(ra) # 8000271e <wakeup>
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
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
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
    8000047c:	96078793          	addi	a5,a5,-1696 # 80021dd8 <devsw>
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
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	ecc50513          	addi	a0,a0,-308 # 80008438 <digits+0x3f8>
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
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
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
    8000070e:	91690913          	addi	s2,s2,-1770 # 80008020 <etext+0x20>
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
    80000784:	8b858593          	addi	a1,a1,-1864 # 80008038 <etext+0x38>
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
    800008a4:	e7e080e7          	jalr	-386(ra) # 8000271e <wakeup>
    
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
    80000930:	a3c080e7          	jalr	-1476(ra) # 80002368 <sleep>
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
    80000b82:	158080e7          	jalr	344(ra) # 80001cd6 <mycpu>
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
    80000bb4:	126080e7          	jalr	294(ra) # 80001cd6 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	11a080e7          	jalr	282(ra) # 80001cd6 <mycpu>
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
    80000bd8:	102080e7          	jalr	258(ra) # 80001cd6 <mycpu>
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
    80000c18:	0c2080e7          	jalr	194(ra) # 80001cd6 <mycpu>
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
    80000c44:	096080e7          	jalr	150(ra) # 80001cd6 <mycpu>
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
    80000e9a:	e30080e7          	jalr	-464(ra) # 80001cc6 <cpuid>
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
    80000eb6:	e14080e7          	jalr	-492(ra) # 80001cc6 <cpuid>
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
    80000ed8:	ef8080e7          	jalr	-264(ra) # 80002dcc <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	494080e7          	jalr	1172(ra) # 80006370 <plicinithart>
  }

  scheduler();        
    80000ee4:	00002097          	auipc	ra,0x2
    80000ee8:	d48080e7          	jalr	-696(ra) # 80002c2c <scheduler>
    consoleinit();
    80000eec:	fffff097          	auipc	ra,0xfffff
    80000ef0:	564080e7          	jalr	1380(ra) # 80000450 <consoleinit>
    printfinit();
    80000ef4:	00000097          	auipc	ra,0x0
    80000ef8:	87a080e7          	jalr	-1926(ra) # 8000076e <printfinit>
    printf("\n");
    80000efc:	00007517          	auipc	a0,0x7
    80000f00:	53c50513          	addi	a0,a0,1340 # 80008438 <digits+0x3f8>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	684080e7          	jalr	1668(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	19450513          	addi	a0,a0,404 # 800080a0 <digits+0x60>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	51c50513          	addi	a0,a0,1308 # 80008438 <digits+0x3f8>
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
    80000f48:	c7e080e7          	jalr	-898(ra) # 80001bc2 <procinit>
    trapinit();      // trap vectors
    80000f4c:	00002097          	auipc	ra,0x2
    80000f50:	e58080e7          	jalr	-424(ra) # 80002da4 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	e78080e7          	jalr	-392(ra) # 80002dcc <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	3fe080e7          	jalr	1022(ra) # 8000635a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	40c080e7          	jalr	1036(ra) # 80006370 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	5ec080e7          	jalr	1516(ra) # 80003558 <binit>
    iinit();         // inode table
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	c7c080e7          	jalr	-900(ra) # 80003bf0 <iinit>
    fileinit();      // file table
    80000f7c:	00004097          	auipc	ra,0x4
    80000f80:	c26080e7          	jalr	-986(ra) # 80004ba2 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	50e080e7          	jalr	1294(ra) # 80006492 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00002097          	auipc	ra,0x2
    80000f90:	bbe080e7          	jalr	-1090(ra) # 80002b4a <userinit>
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
    80001244:	8ec080e7          	jalr	-1812(ra) # 80001b2c <proc_mapstacks>
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
    80001848:	a5c78793          	addi	a5,a5,-1444 # 800112a0 <unused_list>
    8000184c:	577d                	li	a4,-1
    8000184e:	c398                	sw	a4,0(a5)
  unused_list.last = -1;
    80001850:	c3d8                	sw	a4,4(a5)
  sleeping_list.head = -1;
    80001852:	d398                	sw	a4,32(a5)
  sleeping_list.last = -1;
    80001854:	d3d8                	sw	a4,36(a5)
  zombie_list.head = -1;
    80001856:	c3b8                	sw	a4,64(a5)
  zombie_list.last = -1;
    80001858:	c3f8                	sw	a4,68(a5)
  struct processList* p;
  for (p = runnable_cpu_lists; p<&runnable_cpu_lists[3]; p++){
      p->head = -1;
    8000185a:	d3b8                	sw	a4,96(a5)
      p->last = -1;
    8000185c:	d3f8                	sw	a4,100(a5)
      p->head = -1;
    8000185e:	08e7a023          	sw	a4,128(a5)
      p->last = -1;
    80001862:	08e7a223          	sw	a4,132(a5)
      p->head = -1;
    80001866:	0ae7a023          	sw	a4,160(a5)
      p->last = -1;
    8000186a:	0ae7a223          	sw	a4,164(a5)
  }

}
    8000186e:	6422                	ld	s0,8(sp)
    80001870:	0141                	addi	sp,sp,16
    80001872:	8082                	ret

0000000080001874 <remove_link>:

void remove_link(struct processList* list, int index){  // index = the process index in proc
    80001874:	7179                	addi	sp,sp,-48
    80001876:	f406                	sd	ra,40(sp)
    80001878:	f022                	sd	s0,32(sp)
    8000187a:	ec26                	sd	s1,24(sp)
    8000187c:	e84a                	sd	s2,16(sp)
    8000187e:	e44e                	sd	s3,8(sp)
    80001880:	1800                	addi	s0,sp,48
    80001882:	84aa                	mv	s1,a0
    80001884:	892e                	mv	s2,a1

  acquire(&list->head_lock);
    80001886:	00850993          	addi	s3,a0,8
    8000188a:	854e                	mv	a0,s3
    8000188c:	fffff097          	auipc	ra,0xfffff
    80001890:	358080e7          	jalr	856(ra) # 80000be4 <acquire>
  if (list->head == -1){  //empty list
    80001894:	4088                	lw	a0,0(s1)
    80001896:	57fd                	li	a5,-1
    80001898:	06f50263          	beq	a0,a5,800018fc <remove_link+0x88>
    return;
  }
  acquire(&proc[list->head].list_lock);
    8000189c:	19000793          	li	a5,400
    800018a0:	02f50533          	mul	a0,a0,a5
    800018a4:	00010797          	auipc	a5,0x10
    800018a8:	f0478793          	addi	a5,a5,-252 # 800117a8 <proc+0x18>
    800018ac:	953e                	add	a0,a0,a5
    800018ae:	fffff097          	auipc	ra,0xfffff
    800018b2:	336080e7          	jalr	822(ra) # 80000be4 <acquire>
  struct proc* head = &proc[list->head];
    800018b6:	4088                	lw	a0,0(s1)
  if (list->head == list->last){  //list of size 1
    800018b8:	40dc                	lw	a5,4(s1)
    800018ba:	04a78863          	beq	a5,a0,8000190a <remove_link+0x96>
      release(&head->list_lock);
      release(&list->head_lock);
      return;
  }
  else{  //list of size > 1 and removing the head
    if (head->proc_index == index){
    800018be:	19000793          	li	a5,400
    800018c2:	02f50733          	mul	a4,a0,a5
    800018c6:	00010797          	auipc	a5,0x10
    800018ca:	eca78793          	addi	a5,a5,-310 # 80011790 <proc>
    800018ce:	97ba                	add	a5,a5,a4
    800018d0:	1847a783          	lw	a5,388(a5)
    800018d4:	09278a63          	beq	a5,s2,80001968 <remove_link+0xf4>
      list->head = head->next_proc_index;
      head->next_proc_index = -1;
    }
    release(&head->list_lock);
    800018d8:	19000793          	li	a5,400
    800018dc:	02f50533          	mul	a0,a0,a5
    800018e0:	00010797          	auipc	a5,0x10
    800018e4:	ec878793          	addi	a5,a5,-312 # 800117a8 <proc+0x18>
    800018e8:	953e                	add	a0,a0,a5
    800018ea:	fffff097          	auipc	ra,0xfffff
    800018ee:	3ae080e7          	jalr	942(ra) # 80000c98 <release>
    release(&list->head_lock);
    800018f2:	854e                	mv	a0,s3
    800018f4:	fffff097          	auipc	ra,0xfffff
    800018f8:	3a4080e7          	jalr	932(ra) # 80000c98 <release>
    }
  release(&head->list_lock);
  release(&next->list_lock);


}
    800018fc:	70a2                	ld	ra,40(sp)
    800018fe:	7402                	ld	s0,32(sp)
    80001900:	64e2                	ld	s1,24(sp)
    80001902:	6942                	ld	s2,16(sp)
    80001904:	69a2                	ld	s3,8(sp)
    80001906:	6145                	addi	sp,sp,48
    80001908:	8082                	ret
    if (head->proc_index == index){
    8000190a:	19000793          	li	a5,400
    8000190e:	02f50733          	mul	a4,a0,a5
    80001912:	00010797          	auipc	a5,0x10
    80001916:	e7e78793          	addi	a5,a5,-386 # 80011790 <proc>
    8000191a:	97ba                	add	a5,a5,a4
    8000191c:	1847a783          	lw	a5,388(a5)
    80001920:	03278563          	beq	a5,s2,8000194a <remove_link+0xd6>
      release(&head->list_lock);
    80001924:	19000793          	li	a5,400
    80001928:	02f50533          	mul	a0,a0,a5
    8000192c:	00010797          	auipc	a5,0x10
    80001930:	e7c78793          	addi	a5,a5,-388 # 800117a8 <proc+0x18>
    80001934:	953e                	add	a0,a0,a5
    80001936:	fffff097          	auipc	ra,0xfffff
    8000193a:	362080e7          	jalr	866(ra) # 80000c98 <release>
      release(&list->head_lock);
    8000193e:	854e                	mv	a0,s3
    80001940:	fffff097          	auipc	ra,0xfffff
    80001944:	358080e7          	jalr	856(ra) # 80000c98 <release>
      return;
    80001948:	bf55                	j	800018fc <remove_link+0x88>
      list->head = -1;
    8000194a:	577d                	li	a4,-1
    8000194c:	c098                	sw	a4,0(s1)
      list->last = -1;
    8000194e:	c0d8                	sw	a4,4(s1)
      head->next_proc_index = -1;
    80001950:	19000793          	li	a5,400
    80001954:	02f506b3          	mul	a3,a0,a5
    80001958:	00010797          	auipc	a5,0x10
    8000195c:	e3878793          	addi	a5,a5,-456 # 80011790 <proc>
    80001960:	97b6                	add	a5,a5,a3
    80001962:	18e7a023          	sw	a4,384(a5)
    80001966:	bf7d                	j	80001924 <remove_link+0xb0>
      list->head = head->next_proc_index;
    80001968:	00010797          	auipc	a5,0x10
    8000196c:	e2878793          	addi	a5,a5,-472 # 80011790 <proc>
    80001970:	97ba                	add	a5,a5,a4
    80001972:	1807a703          	lw	a4,384(a5)
    80001976:	c098                	sw	a4,0(s1)
      head->next_proc_index = -1;
    80001978:	577d                	li	a4,-1
    8000197a:	18e7a023          	sw	a4,384(a5)
    8000197e:	bfa9                	j	800018d8 <remove_link+0x64>

0000000080001980 <add_link>:

void add_link(struct processList* list, int index){ // index = the process index in proc
    80001980:	7139                	addi	sp,sp,-64
    80001982:	fc06                	sd	ra,56(sp)
    80001984:	f822                	sd	s0,48(sp)
    80001986:	f426                	sd	s1,40(sp)
    80001988:	f04a                	sd	s2,32(sp)
    8000198a:	ec4e                	sd	s3,24(sp)
    8000198c:	e852                	sd	s4,16(sp)
    8000198e:	e456                	sd	s5,8(sp)
    80001990:	e05a                	sd	s6,0(sp)
    80001992:	0080                	addi	s0,sp,64
    80001994:	84aa                	mv	s1,a0
    80001996:	8a2e                	mv	s4,a1
  printf("try to acquire list head lock\n");
    80001998:	00007517          	auipc	a0,0x7
    8000199c:	84050513          	addi	a0,a0,-1984 # 800081d8 <digits+0x198>
    800019a0:	fffff097          	auipc	ra,0xfffff
    800019a4:	be8080e7          	jalr	-1048(ra) # 80000588 <printf>
  acquire(&list->head_lock);
    800019a8:	00848b13          	addi	s6,s1,8
    800019ac:	855a                	mv	a0,s6
    800019ae:	fffff097          	auipc	ra,0xfffff
    800019b2:	236080e7          	jalr	566(ra) # 80000be4 <acquire>
  printf("try to acquire proc list lock\n");
    800019b6:	00007517          	auipc	a0,0x7
    800019ba:	84250513          	addi	a0,a0,-1982 # 800081f8 <digits+0x1b8>
    800019be:	fffff097          	auipc	ra,0xfffff
    800019c2:	bca080e7          	jalr	-1078(ra) # 80000588 <printf>
  acquire(&proc[index].list_lock);
    800019c6:	19000913          	li	s2,400
    800019ca:	032a0933          	mul	s2,s4,s2
    800019ce:	00010797          	auipc	a5,0x10
    800019d2:	dda78793          	addi	a5,a5,-550 # 800117a8 <proc+0x18>
    800019d6:	993e                	add	s2,s2,a5
    800019d8:	854a                	mv	a0,s2
    800019da:	fffff097          	auipc	ra,0xfffff
    800019de:	20a080e7          	jalr	522(ra) # 80000be4 <acquire>
  printf("index to insert is %d\n",index);
    800019e2:	85d2                	mv	a1,s4
    800019e4:	00007517          	auipc	a0,0x7
    800019e8:	83450513          	addi	a0,a0,-1996 # 80008218 <digits+0x1d8>
    800019ec:	fffff097          	auipc	ra,0xfffff
    800019f0:	b9c080e7          	jalr	-1124(ra) # 80000588 <printf>
  printf("list head is %d\n", list->head);
    800019f4:	408c                	lw	a1,0(s1)
    800019f6:	00007517          	auipc	a0,0x7
    800019fa:	83a50513          	addi	a0,a0,-1990 # 80008230 <digits+0x1f0>
    800019fe:	fffff097          	auipc	ra,0xfffff
    80001a02:	b8a080e7          	jalr	-1142(ra) # 80000588 <printf>
  printf("list last is %d\n", list->last);
    80001a06:	40cc                	lw	a1,4(s1)
    80001a08:	00007517          	auipc	a0,0x7
    80001a0c:	84050513          	addi	a0,a0,-1984 # 80008248 <digits+0x208>
    80001a10:	fffff097          	auipc	ra,0xfffff
    80001a14:	b78080e7          	jalr	-1160(ra) # 80000588 <printf>
  if (list->head == -1){  //empty list
    80001a18:	0004aa83          	lw	s5,0(s1)
    80001a1c:	57fd                	li	a5,-1
    80001a1e:	08fa8b63          	beq	s5,a5,80001ab4 <add_link+0x134>
    release(&list->head_lock);
    release(&proc[index].list_lock);
    return;
  }
  struct proc* head = &proc[list->head];
  acquire(&head->list_lock);
    80001a22:	19000993          	li	s3,400
    80001a26:	033a89b3          	mul	s3,s5,s3
    80001a2a:	00010797          	auipc	a5,0x10
    80001a2e:	d7e78793          	addi	a5,a5,-642 # 800117a8 <proc+0x18>
    80001a32:	99be                	add	s3,s3,a5
    80001a34:	854e                	mv	a0,s3
    80001a36:	fffff097          	auipc	ra,0xfffff
    80001a3a:	1ae080e7          	jalr	430(ra) # 80000be4 <acquire>
  if (list->head == list->last){  //list of size 1
    80001a3e:	4098                	lw	a4,0(s1)
    80001a40:	40dc                	lw	a5,4(s1)
    80001a42:	0af70063          	beq	a4,a5,80001ae2 <add_link+0x162>
      release(&head->list_lock);
      release(&list->head_lock);
      release(&proc[index].list_lock);
      return;
  }
  release(&list->head_lock);
    80001a46:	855a                	mv	a0,s6
    80001a48:	fffff097          	auipc	ra,0xfffff
    80001a4c:	250080e7          	jalr	592(ra) # 80000c98 <release>
  release(&head->list_lock);
    80001a50:	854e                	mv	a0,s3
    80001a52:	fffff097          	auipc	ra,0xfffff
    80001a56:	246080e7          	jalr	582(ra) # 80000c98 <release>
  acquire(&proc[list->last].list_lock);
    80001a5a:	40c8                	lw	a0,4(s1)
    80001a5c:	19000a93          	li	s5,400
    80001a60:	03550533          	mul	a0,a0,s5
    80001a64:	0561                	addi	a0,a0,24
    80001a66:	00010997          	auipc	s3,0x10
    80001a6a:	d2a98993          	addi	s3,s3,-726 # 80011790 <proc>
    80001a6e:	954e                	add	a0,a0,s3
    80001a70:	fffff097          	auipc	ra,0xfffff
    80001a74:	174080e7          	jalr	372(ra) # 80000be4 <acquire>
  struct proc* last = &proc[list->last];
    80001a78:	40c8                	lw	a0,4(s1)
  last->next_proc_index = index;
    80001a7a:	03550533          	mul	a0,a0,s5
    80001a7e:	00a987b3          	add	a5,s3,a0
    80001a82:	1947a023          	sw	s4,384(a5)
  list->last = index;
    80001a86:	0144a223          	sw	s4,4(s1)
  release(&last->list_lock);
    80001a8a:	0561                	addi	a0,a0,24
    80001a8c:	954e                	add	a0,a0,s3
    80001a8e:	fffff097          	auipc	ra,0xfffff
    80001a92:	20a080e7          	jalr	522(ra) # 80000c98 <release>
  release(&proc[index].list_lock);
    80001a96:	854a                	mv	a0,s2
    80001a98:	fffff097          	auipc	ra,0xfffff
    80001a9c:	200080e7          	jalr	512(ra) # 80000c98 <release>
  
  return;


}
    80001aa0:	70e2                	ld	ra,56(sp)
    80001aa2:	7442                	ld	s0,48(sp)
    80001aa4:	74a2                	ld	s1,40(sp)
    80001aa6:	7902                	ld	s2,32(sp)
    80001aa8:	69e2                	ld	s3,24(sp)
    80001aaa:	6a42                	ld	s4,16(sp)
    80001aac:	6aa2                	ld	s5,8(sp)
    80001aae:	6b02                	ld	s6,0(sp)
    80001ab0:	6121                	addi	sp,sp,64
    80001ab2:	8082                	ret
    printf("list is empty\n");
    80001ab4:	00006517          	auipc	a0,0x6
    80001ab8:	7ac50513          	addi	a0,a0,1964 # 80008260 <digits+0x220>
    80001abc:	fffff097          	auipc	ra,0xfffff
    80001ac0:	acc080e7          	jalr	-1332(ra) # 80000588 <printf>
    list->head = index;
    80001ac4:	0144a023          	sw	s4,0(s1)
    list->last = index;
    80001ac8:	0144a223          	sw	s4,4(s1)
    release(&list->head_lock);
    80001acc:	855a                	mv	a0,s6
    80001ace:	fffff097          	auipc	ra,0xfffff
    80001ad2:	1ca080e7          	jalr	458(ra) # 80000c98 <release>
    release(&proc[index].list_lock);
    80001ad6:	854a                	mv	a0,s2
    80001ad8:	fffff097          	auipc	ra,0xfffff
    80001adc:	1c0080e7          	jalr	448(ra) # 80000c98 <release>
    return;
    80001ae0:	b7c1                	j	80001aa0 <add_link+0x120>
      printf("try to insert second item\n");
    80001ae2:	00006517          	auipc	a0,0x6
    80001ae6:	78e50513          	addi	a0,a0,1934 # 80008270 <digits+0x230>
    80001aea:	fffff097          	auipc	ra,0xfffff
    80001aee:	a9e080e7          	jalr	-1378(ra) # 80000588 <printf>
      head->next_proc_index = index;
    80001af2:	19000793          	li	a5,400
    80001af6:	02fa87b3          	mul	a5,s5,a5
    80001afa:	00010717          	auipc	a4,0x10
    80001afe:	c9670713          	addi	a4,a4,-874 # 80011790 <proc>
    80001b02:	97ba                	add	a5,a5,a4
    80001b04:	1947a023          	sw	s4,384(a5)
      list->last = index;
    80001b08:	0144a223          	sw	s4,4(s1)
      release(&head->list_lock);
    80001b0c:	854e                	mv	a0,s3
    80001b0e:	fffff097          	auipc	ra,0xfffff
    80001b12:	18a080e7          	jalr	394(ra) # 80000c98 <release>
      release(&list->head_lock);
    80001b16:	855a                	mv	a0,s6
    80001b18:	fffff097          	auipc	ra,0xfffff
    80001b1c:	180080e7          	jalr	384(ra) # 80000c98 <release>
      release(&proc[index].list_lock);
    80001b20:	854a                	mv	a0,s2
    80001b22:	fffff097          	auipc	ra,0xfffff
    80001b26:	176080e7          	jalr	374(ra) # 80000c98 <release>
      return;
    80001b2a:	bf9d                	j	80001aa0 <add_link+0x120>

0000000080001b2c <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001b2c:	7139                	addi	sp,sp,-64
    80001b2e:	fc06                	sd	ra,56(sp)
    80001b30:	f822                	sd	s0,48(sp)
    80001b32:	f426                	sd	s1,40(sp)
    80001b34:	f04a                	sd	s2,32(sp)
    80001b36:	ec4e                	sd	s3,24(sp)
    80001b38:	e852                	sd	s4,16(sp)
    80001b3a:	e456                	sd	s5,8(sp)
    80001b3c:	e05a                	sd	s6,0(sp)
    80001b3e:	0080                	addi	s0,sp,64
    80001b40:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b42:	00010497          	auipc	s1,0x10
    80001b46:	c4e48493          	addi	s1,s1,-946 # 80011790 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001b4a:	8b26                	mv	s6,s1
    80001b4c:	00006a97          	auipc	s5,0x6
    80001b50:	4b4a8a93          	addi	s5,s5,1204 # 80008000 <etext>
    80001b54:	04000937          	lui	s2,0x4000
    80001b58:	197d                	addi	s2,s2,-1
    80001b5a:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b5c:	00016a17          	auipc	s4,0x16
    80001b60:	034a0a13          	addi	s4,s4,52 # 80017b90 <tickslock>
    char *pa = kalloc();
    80001b64:	fffff097          	auipc	ra,0xfffff
    80001b68:	f90080e7          	jalr	-112(ra) # 80000af4 <kalloc>
    80001b6c:	862a                	mv	a2,a0
    if(pa == 0)
    80001b6e:	c131                	beqz	a0,80001bb2 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001b70:	416485b3          	sub	a1,s1,s6
    80001b74:	8591                	srai	a1,a1,0x4
    80001b76:	000ab783          	ld	a5,0(s5)
    80001b7a:	02f585b3          	mul	a1,a1,a5
    80001b7e:	2585                	addiw	a1,a1,1
    80001b80:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001b84:	4719                	li	a4,6
    80001b86:	6685                	lui	a3,0x1
    80001b88:	40b905b3          	sub	a1,s2,a1
    80001b8c:	854e                	mv	a0,s3
    80001b8e:	fffff097          	auipc	ra,0xfffff
    80001b92:	5c2080e7          	jalr	1474(ra) # 80001150 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b96:	19048493          	addi	s1,s1,400
    80001b9a:	fd4495e3          	bne	s1,s4,80001b64 <proc_mapstacks+0x38>
  }
}
    80001b9e:	70e2                	ld	ra,56(sp)
    80001ba0:	7442                	ld	s0,48(sp)
    80001ba2:	74a2                	ld	s1,40(sp)
    80001ba4:	7902                	ld	s2,32(sp)
    80001ba6:	69e2                	ld	s3,24(sp)
    80001ba8:	6a42                	ld	s4,16(sp)
    80001baa:	6aa2                	ld	s5,8(sp)
    80001bac:	6b02                	ld	s6,0(sp)
    80001bae:	6121                	addi	sp,sp,64
    80001bb0:	8082                	ret
      panic("kalloc");
    80001bb2:	00006517          	auipc	a0,0x6
    80001bb6:	6de50513          	addi	a0,a0,1758 # 80008290 <digits+0x250>
    80001bba:	fffff097          	auipc	ra,0xfffff
    80001bbe:	984080e7          	jalr	-1660(ra) # 8000053e <panic>

0000000080001bc2 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    80001bc2:	711d                	addi	sp,sp,-96
    80001bc4:	ec86                	sd	ra,88(sp)
    80001bc6:	e8a2                	sd	s0,80(sp)
    80001bc8:	e4a6                	sd	s1,72(sp)
    80001bca:	e0ca                	sd	s2,64(sp)
    80001bcc:	fc4e                	sd	s3,56(sp)
    80001bce:	f852                	sd	s4,48(sp)
    80001bd0:	f456                	sd	s5,40(sp)
    80001bd2:	f05a                	sd	s6,32(sp)
    80001bd4:	ec5e                	sd	s7,24(sp)
    80001bd6:	e862                	sd	s8,16(sp)
    80001bd8:	e466                	sd	s9,8(sp)
    80001bda:	1080                	addi	s0,sp,96
  lists_init();
    80001bdc:	00000097          	auipc	ra,0x0
    80001be0:	c62080e7          	jalr	-926(ra) # 8000183e <lists_init>
  struct proc *p;
  int index = 0;
  initlock(&pid_lock, "nextpid");
    80001be4:	00006597          	auipc	a1,0x6
    80001be8:	6b458593          	addi	a1,a1,1716 # 80008298 <digits+0x258>
    80001bec:	0000f517          	auipc	a0,0xf
    80001bf0:	77450513          	addi	a0,a0,1908 # 80011360 <pid_lock>
    80001bf4:	fffff097          	auipc	ra,0xfffff
    80001bf8:	f60080e7          	jalr	-160(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001bfc:	00006597          	auipc	a1,0x6
    80001c00:	6a458593          	addi	a1,a1,1700 # 800082a0 <digits+0x260>
    80001c04:	0000f517          	auipc	a0,0xf
    80001c08:	77450513          	addi	a0,a0,1908 # 80011378 <wait_lock>
    80001c0c:	fffff097          	auipc	ra,0xfffff
    80001c10:	f48080e7          	jalr	-184(ra) # 80000b54 <initlock>
  printf("start procinit\n");
    80001c14:	00006517          	auipc	a0,0x6
    80001c18:	69c50513          	addi	a0,a0,1692 # 800082b0 <digits+0x270>
    80001c1c:	fffff097          	auipc	ra,0xfffff
    80001c20:	96c080e7          	jalr	-1684(ra) # 80000588 <printf>
  int index = 0;
    80001c24:	4901                	li	s2,0
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c26:	00010497          	auipc	s1,0x10
    80001c2a:	b6a48493          	addi	s1,s1,-1174 # 80011790 <proc>
      initlock(&p->lock, "proc");
    80001c2e:	00006c97          	auipc	s9,0x6
    80001c32:	692c8c93          	addi	s9,s9,1682 # 800082c0 <digits+0x280>
      p->kstack = KSTACK((int) (p - proc));
    80001c36:	8c26                	mv	s8,s1
    80001c38:	00006b97          	auipc	s7,0x6
    80001c3c:	3c8b8b93          	addi	s7,s7,968 # 80008000 <etext>
    80001c40:	040009b7          	lui	s3,0x4000
    80001c44:	19fd                	addi	s3,s3,-1
    80001c46:	09b2                	slli	s3,s3,0xc
      p->proc_index=index;
      printf("proc is %d\n", index);
    80001c48:	00006b17          	auipc	s6,0x6
    80001c4c:	680b0b13          	addi	s6,s6,1664 # 800082c8 <digits+0x288>
      add_link(&unused_list, index);
    80001c50:	0000fa97          	auipc	s5,0xf
    80001c54:	650a8a93          	addi	s5,s5,1616 # 800112a0 <unused_list>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c58:	00016a17          	auipc	s4,0x16
    80001c5c:	f38a0a13          	addi	s4,s4,-200 # 80017b90 <tickslock>
      initlock(&p->lock, "proc");
    80001c60:	85e6                	mv	a1,s9
    80001c62:	8526                	mv	a0,s1
    80001c64:	fffff097          	auipc	ra,0xfffff
    80001c68:	ef0080e7          	jalr	-272(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001c6c:	418487b3          	sub	a5,s1,s8
    80001c70:	8791                	srai	a5,a5,0x4
    80001c72:	000bb703          	ld	a4,0(s7)
    80001c76:	02e787b3          	mul	a5,a5,a4
    80001c7a:	2785                	addiw	a5,a5,1
    80001c7c:	00d7979b          	slliw	a5,a5,0xd
    80001c80:	40f987b3          	sub	a5,s3,a5
    80001c84:	ecbc                	sd	a5,88(s1)
      p->proc_index=index;
    80001c86:	1924a223          	sw	s2,388(s1)
      printf("proc is %d\n", index);
    80001c8a:	85ca                	mv	a1,s2
    80001c8c:	855a                	mv	a0,s6
    80001c8e:	fffff097          	auipc	ra,0xfffff
    80001c92:	8fa080e7          	jalr	-1798(ra) # 80000588 <printf>
      add_link(&unused_list, index);
    80001c96:	85ca                	mv	a1,s2
    80001c98:	8556                	mv	a0,s5
    80001c9a:	00000097          	auipc	ra,0x0
    80001c9e:	ce6080e7          	jalr	-794(ra) # 80001980 <add_link>
      index++;
    80001ca2:	2905                	addiw	s2,s2,1
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ca4:	19048493          	addi	s1,s1,400
    80001ca8:	fb449ce3          	bne	s1,s4,80001c60 <procinit+0x9e>
  }
}
    80001cac:	60e6                	ld	ra,88(sp)
    80001cae:	6446                	ld	s0,80(sp)
    80001cb0:	64a6                	ld	s1,72(sp)
    80001cb2:	6906                	ld	s2,64(sp)
    80001cb4:	79e2                	ld	s3,56(sp)
    80001cb6:	7a42                	ld	s4,48(sp)
    80001cb8:	7aa2                	ld	s5,40(sp)
    80001cba:	7b02                	ld	s6,32(sp)
    80001cbc:	6be2                	ld	s7,24(sp)
    80001cbe:	6c42                	ld	s8,16(sp)
    80001cc0:	6ca2                	ld	s9,8(sp)
    80001cc2:	6125                	addi	sp,sp,96
    80001cc4:	8082                	ret

0000000080001cc6 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001cc6:	1141                	addi	sp,sp,-16
    80001cc8:	e422                	sd	s0,8(sp)
    80001cca:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001ccc:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001cce:	2501                	sext.w	a0,a0
    80001cd0:	6422                	ld	s0,8(sp)
    80001cd2:	0141                	addi	sp,sp,16
    80001cd4:	8082                	ret

0000000080001cd6 <mycpu>:


// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001cd6:	1141                	addi	sp,sp,-16
    80001cd8:	e422                	sd	s0,8(sp)
    80001cda:	0800                	addi	s0,sp,16
    80001cdc:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001cde:	2781                	sext.w	a5,a5
    80001ce0:	079e                	slli	a5,a5,0x7
  return c;
}
    80001ce2:	0000f517          	auipc	a0,0xf
    80001ce6:	6ae50513          	addi	a0,a0,1710 # 80011390 <cpus>
    80001cea:	953e                	add	a0,a0,a5
    80001cec:	6422                	ld	s0,8(sp)
    80001cee:	0141                	addi	sp,sp,16
    80001cf0:	8082                	ret

0000000080001cf2 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001cf2:	1101                	addi	sp,sp,-32
    80001cf4:	ec06                	sd	ra,24(sp)
    80001cf6:	e822                	sd	s0,16(sp)
    80001cf8:	e426                	sd	s1,8(sp)
    80001cfa:	1000                	addi	s0,sp,32
  push_off();
    80001cfc:	fffff097          	auipc	ra,0xfffff
    80001d00:	e9c080e7          	jalr	-356(ra) # 80000b98 <push_off>
    80001d04:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001d06:	2781                	sext.w	a5,a5
    80001d08:	079e                	slli	a5,a5,0x7
    80001d0a:	0000f717          	auipc	a4,0xf
    80001d0e:	59670713          	addi	a4,a4,1430 # 800112a0 <unused_list>
    80001d12:	97ba                	add	a5,a5,a4
    80001d14:	7be4                	ld	s1,240(a5)
  pop_off();
    80001d16:	fffff097          	auipc	ra,0xfffff
    80001d1a:	f22080e7          	jalr	-222(ra) # 80000c38 <pop_off>
  return p;
}
    80001d1e:	8526                	mv	a0,s1
    80001d20:	60e2                	ld	ra,24(sp)
    80001d22:	6442                	ld	s0,16(sp)
    80001d24:	64a2                	ld	s1,8(sp)
    80001d26:	6105                	addi	sp,sp,32
    80001d28:	8082                	ret

0000000080001d2a <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001d2a:	1141                	addi	sp,sp,-16
    80001d2c:	e406                	sd	ra,8(sp)
    80001d2e:	e022                	sd	s0,0(sp)
    80001d30:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001d32:	00000097          	auipc	ra,0x0
    80001d36:	fc0080e7          	jalr	-64(ra) # 80001cf2 <myproc>
    80001d3a:	fffff097          	auipc	ra,0xfffff
    80001d3e:	f5e080e7          	jalr	-162(ra) # 80000c98 <release>

  if (first) {
    80001d42:	00007797          	auipc	a5,0x7
    80001d46:	dfe7a783          	lw	a5,-514(a5) # 80008b40 <first.1718>
    80001d4a:	eb89                	bnez	a5,80001d5c <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001d4c:	00001097          	auipc	ra,0x1
    80001d50:	098080e7          	jalr	152(ra) # 80002de4 <usertrapret>
}
    80001d54:	60a2                	ld	ra,8(sp)
    80001d56:	6402                	ld	s0,0(sp)
    80001d58:	0141                	addi	sp,sp,16
    80001d5a:	8082                	ret
    first = 0;
    80001d5c:	00007797          	auipc	a5,0x7
    80001d60:	de07a223          	sw	zero,-540(a5) # 80008b40 <first.1718>
    fsinit(ROOTDEV);
    80001d64:	4505                	li	a0,1
    80001d66:	00002097          	auipc	ra,0x2
    80001d6a:	e0a080e7          	jalr	-502(ra) # 80003b70 <fsinit>
    80001d6e:	bff9                	j	80001d4c <forkret+0x22>

0000000080001d70 <allocpid>:
allocpid() {
    80001d70:	1101                	addi	sp,sp,-32
    80001d72:	ec06                	sd	ra,24(sp)
    80001d74:	e822                	sd	s0,16(sp)
    80001d76:	e426                	sd	s1,8(sp)
    80001d78:	e04a                	sd	s2,0(sp)
    80001d7a:	1000                	addi	s0,sp,32
    pid = nextpid;
    80001d7c:	00007917          	auipc	s2,0x7
    80001d80:	dc890913          	addi	s2,s2,-568 # 80008b44 <nextpid>
    80001d84:	00092483          	lw	s1,0(s2)
  } while (cas(&nextpid, pid, pid+1));
    80001d88:	0014861b          	addiw	a2,s1,1
    80001d8c:	85a6                	mv	a1,s1
    80001d8e:	854a                	mv	a0,s2
    80001d90:	00005097          	auipc	ra,0x5
    80001d94:	be6080e7          	jalr	-1050(ra) # 80006976 <cas>
    80001d98:	f575                	bnez	a0,80001d84 <allocpid+0x14>
}
    80001d9a:	8526                	mv	a0,s1
    80001d9c:	60e2                	ld	ra,24(sp)
    80001d9e:	6442                	ld	s0,16(sp)
    80001da0:	64a2                	ld	s1,8(sp)
    80001da2:	6902                	ld	s2,0(sp)
    80001da4:	6105                	addi	sp,sp,32
    80001da6:	8082                	ret

0000000080001da8 <proc_pagetable>:
{
    80001da8:	1101                	addi	sp,sp,-32
    80001daa:	ec06                	sd	ra,24(sp)
    80001dac:	e822                	sd	s0,16(sp)
    80001dae:	e426                	sd	s1,8(sp)
    80001db0:	e04a                	sd	s2,0(sp)
    80001db2:	1000                	addi	s0,sp,32
    80001db4:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001db6:	fffff097          	auipc	ra,0xfffff
    80001dba:	584080e7          	jalr	1412(ra) # 8000133a <uvmcreate>
    80001dbe:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001dc0:	c121                	beqz	a0,80001e00 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001dc2:	4729                	li	a4,10
    80001dc4:	00005697          	auipc	a3,0x5
    80001dc8:	23c68693          	addi	a3,a3,572 # 80007000 <_trampoline>
    80001dcc:	6605                	lui	a2,0x1
    80001dce:	040005b7          	lui	a1,0x4000
    80001dd2:	15fd                	addi	a1,a1,-1
    80001dd4:	05b2                	slli	a1,a1,0xc
    80001dd6:	fffff097          	auipc	ra,0xfffff
    80001dda:	2da080e7          	jalr	730(ra) # 800010b0 <mappages>
    80001dde:	02054863          	bltz	a0,80001e0e <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001de2:	4719                	li	a4,6
    80001de4:	07093683          	ld	a3,112(s2)
    80001de8:	6605                	lui	a2,0x1
    80001dea:	020005b7          	lui	a1,0x2000
    80001dee:	15fd                	addi	a1,a1,-1
    80001df0:	05b6                	slli	a1,a1,0xd
    80001df2:	8526                	mv	a0,s1
    80001df4:	fffff097          	auipc	ra,0xfffff
    80001df8:	2bc080e7          	jalr	700(ra) # 800010b0 <mappages>
    80001dfc:	02054163          	bltz	a0,80001e1e <proc_pagetable+0x76>
}
    80001e00:	8526                	mv	a0,s1
    80001e02:	60e2                	ld	ra,24(sp)
    80001e04:	6442                	ld	s0,16(sp)
    80001e06:	64a2                	ld	s1,8(sp)
    80001e08:	6902                	ld	s2,0(sp)
    80001e0a:	6105                	addi	sp,sp,32
    80001e0c:	8082                	ret
    uvmfree(pagetable, 0);
    80001e0e:	4581                	li	a1,0
    80001e10:	8526                	mv	a0,s1
    80001e12:	fffff097          	auipc	ra,0xfffff
    80001e16:	724080e7          	jalr	1828(ra) # 80001536 <uvmfree>
    return 0;
    80001e1a:	4481                	li	s1,0
    80001e1c:	b7d5                	j	80001e00 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001e1e:	4681                	li	a3,0
    80001e20:	4605                	li	a2,1
    80001e22:	040005b7          	lui	a1,0x4000
    80001e26:	15fd                	addi	a1,a1,-1
    80001e28:	05b2                	slli	a1,a1,0xc
    80001e2a:	8526                	mv	a0,s1
    80001e2c:	fffff097          	auipc	ra,0xfffff
    80001e30:	44a080e7          	jalr	1098(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80001e34:	4581                	li	a1,0
    80001e36:	8526                	mv	a0,s1
    80001e38:	fffff097          	auipc	ra,0xfffff
    80001e3c:	6fe080e7          	jalr	1790(ra) # 80001536 <uvmfree>
    return 0;
    80001e40:	4481                	li	s1,0
    80001e42:	bf7d                	j	80001e00 <proc_pagetable+0x58>

0000000080001e44 <proc_freepagetable>:
{
    80001e44:	1101                	addi	sp,sp,-32
    80001e46:	ec06                	sd	ra,24(sp)
    80001e48:	e822                	sd	s0,16(sp)
    80001e4a:	e426                	sd	s1,8(sp)
    80001e4c:	e04a                	sd	s2,0(sp)
    80001e4e:	1000                	addi	s0,sp,32
    80001e50:	84aa                	mv	s1,a0
    80001e52:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001e54:	4681                	li	a3,0
    80001e56:	4605                	li	a2,1
    80001e58:	040005b7          	lui	a1,0x4000
    80001e5c:	15fd                	addi	a1,a1,-1
    80001e5e:	05b2                	slli	a1,a1,0xc
    80001e60:	fffff097          	auipc	ra,0xfffff
    80001e64:	416080e7          	jalr	1046(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001e68:	4681                	li	a3,0
    80001e6a:	4605                	li	a2,1
    80001e6c:	020005b7          	lui	a1,0x2000
    80001e70:	15fd                	addi	a1,a1,-1
    80001e72:	05b6                	slli	a1,a1,0xd
    80001e74:	8526                	mv	a0,s1
    80001e76:	fffff097          	auipc	ra,0xfffff
    80001e7a:	400080e7          	jalr	1024(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80001e7e:	85ca                	mv	a1,s2
    80001e80:	8526                	mv	a0,s1
    80001e82:	fffff097          	auipc	ra,0xfffff
    80001e86:	6b4080e7          	jalr	1716(ra) # 80001536 <uvmfree>
}
    80001e8a:	60e2                	ld	ra,24(sp)
    80001e8c:	6442                	ld	s0,16(sp)
    80001e8e:	64a2                	ld	s1,8(sp)
    80001e90:	6902                	ld	s2,0(sp)
    80001e92:	6105                	addi	sp,sp,32
    80001e94:	8082                	ret

0000000080001e96 <freeproc>:
{
    80001e96:	1101                	addi	sp,sp,-32
    80001e98:	ec06                	sd	ra,24(sp)
    80001e9a:	e822                	sd	s0,16(sp)
    80001e9c:	e426                	sd	s1,8(sp)
    80001e9e:	1000                	addi	s0,sp,32
    80001ea0:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001ea2:	7928                	ld	a0,112(a0)
    80001ea4:	c509                	beqz	a0,80001eae <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001ea6:	fffff097          	auipc	ra,0xfffff
    80001eaa:	b52080e7          	jalr	-1198(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001eae:	0604b823          	sd	zero,112(s1)
  if(p->pagetable)
    80001eb2:	74a8                	ld	a0,104(s1)
    80001eb4:	c511                	beqz	a0,80001ec0 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001eb6:	70ac                	ld	a1,96(s1)
    80001eb8:	00000097          	auipc	ra,0x0
    80001ebc:	f8c080e7          	jalr	-116(ra) # 80001e44 <proc_freepagetable>
  remove_link(&zombie_list, p->proc_index);
    80001ec0:	1844a583          	lw	a1,388(s1)
    80001ec4:	0000f517          	auipc	a0,0xf
    80001ec8:	41c50513          	addi	a0,a0,1052 # 800112e0 <zombie_list>
    80001ecc:	00000097          	auipc	ra,0x0
    80001ed0:	9a8080e7          	jalr	-1624(ra) # 80001874 <remove_link>
  add_link(&unused_list, p->proc_index);
    80001ed4:	1844a583          	lw	a1,388(s1)
    80001ed8:	0000f517          	auipc	a0,0xf
    80001edc:	3c850513          	addi	a0,a0,968 # 800112a0 <unused_list>
    80001ee0:	00000097          	auipc	ra,0x0
    80001ee4:	aa0080e7          	jalr	-1376(ra) # 80001980 <add_link>
  p->pagetable = 0;
    80001ee8:	0604b423          	sd	zero,104(s1)
  p->sz = 0;
    80001eec:	0604b023          	sd	zero,96(s1)
  p->pid = 0;
    80001ef0:	0404a423          	sw	zero,72(s1)
  p->parent = 0;
    80001ef4:	0404b823          	sd	zero,80(s1)
  p->name[0] = 0;
    80001ef8:	16048823          	sb	zero,368(s1)
  p->chan = 0;
    80001efc:	0204bc23          	sd	zero,56(s1)
  p->killed = 0;
    80001f00:	0404a023          	sw	zero,64(s1)
  p->xstate = 0;
    80001f04:	0404a223          	sw	zero,68(s1)
  p->state = UNUSED;
    80001f08:	0204a823          	sw	zero,48(s1)
}
    80001f0c:	60e2                	ld	ra,24(sp)
    80001f0e:	6442                	ld	s0,16(sp)
    80001f10:	64a2                	ld	s1,8(sp)
    80001f12:	6105                	addi	sp,sp,32
    80001f14:	8082                	ret

0000000080001f16 <allocproc>:
{
    80001f16:	7139                	addi	sp,sp,-64
    80001f18:	fc06                	sd	ra,56(sp)
    80001f1a:	f822                	sd	s0,48(sp)
    80001f1c:	f426                	sd	s1,40(sp)
    80001f1e:	f04a                	sd	s2,32(sp)
    80001f20:	ec4e                	sd	s3,24(sp)
    80001f22:	e852                	sd	s4,16(sp)
    80001f24:	e456                	sd	s5,8(sp)
    80001f26:	0080                	addi	s0,sp,64
  if (unused_list.head == -1)
    80001f28:	0000f497          	auipc	s1,0xf
    80001f2c:	3784a483          	lw	s1,888(s1) # 800112a0 <unused_list>
    80001f30:	57fd                	li	a5,-1
    80001f32:	0ef48b63          	beq	s1,a5,80002028 <allocproc+0x112>
  struct proc *p = &proc[unused_list.head];
    80001f36:	19000793          	li	a5,400
    80001f3a:	02f484b3          	mul	s1,s1,a5
    80001f3e:	00010797          	auipc	a5,0x10
    80001f42:	85278793          	addi	a5,a5,-1966 # 80011790 <proc>
    80001f46:	94be                	add	s1,s1,a5
  acquire(&p->lock);
    80001f48:	8526                	mv	a0,s1
    80001f4a:	fffff097          	auipc	ra,0xfffff
    80001f4e:	c9a080e7          	jalr	-870(ra) # 80000be4 <acquire>
  while(p->state != UNUSED){
    80001f52:	589c                	lw	a5,48(s1)
    80001f54:	cf9d                	beqz	a5,80001f92 <allocproc+0x7c>
    if (unused_list.head == -1)
    80001f56:	0000f997          	auipc	s3,0xf
    80001f5a:	34a98993          	addi	s3,s3,842 # 800112a0 <unused_list>
    80001f5e:	597d                	li	s2,-1
    p = &proc[unused_list.head];
    80001f60:	19000a93          	li	s5,400
    80001f64:	00010a17          	auipc	s4,0x10
    80001f68:	82ca0a13          	addi	s4,s4,-2004 # 80011790 <proc>
    release(&p->lock);
    80001f6c:	8526                	mv	a0,s1
    80001f6e:	fffff097          	auipc	ra,0xfffff
    80001f72:	d2a080e7          	jalr	-726(ra) # 80000c98 <release>
    if (unused_list.head == -1)
    80001f76:	0009a483          	lw	s1,0(s3)
    80001f7a:	0b248963          	beq	s1,s2,8000202c <allocproc+0x116>
    p = &proc[unused_list.head];
    80001f7e:	035484b3          	mul	s1,s1,s5
    80001f82:	94d2                	add	s1,s1,s4
    acquire(&p->lock);
    80001f84:	8526                	mv	a0,s1
    80001f86:	fffff097          	auipc	ra,0xfffff
    80001f8a:	c5e080e7          	jalr	-930(ra) # 80000be4 <acquire>
  while(p->state != UNUSED){
    80001f8e:	589c                	lw	a5,48(s1)
    80001f90:	fff1                	bnez	a5,80001f6c <allocproc+0x56>
  remove_link(&unused_list, p->proc_index);
    80001f92:	1844a583          	lw	a1,388(s1)
    80001f96:	0000f517          	auipc	a0,0xf
    80001f9a:	30a50513          	addi	a0,a0,778 # 800112a0 <unused_list>
    80001f9e:	00000097          	auipc	ra,0x0
    80001fa2:	8d6080e7          	jalr	-1834(ra) # 80001874 <remove_link>
  p->pid = allocpid();
    80001fa6:	00000097          	auipc	ra,0x0
    80001faa:	dca080e7          	jalr	-566(ra) # 80001d70 <allocpid>
    80001fae:	c4a8                	sw	a0,72(s1)
  p->state = USED;
    80001fb0:	4785                	li	a5,1
    80001fb2:	d89c                	sw	a5,48(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001fb4:	fffff097          	auipc	ra,0xfffff
    80001fb8:	b40080e7          	jalr	-1216(ra) # 80000af4 <kalloc>
    80001fbc:	892a                	mv	s2,a0
    80001fbe:	f8a8                	sd	a0,112(s1)
    80001fc0:	cd05                	beqz	a0,80001ff8 <allocproc+0xe2>
  p->pagetable = proc_pagetable(p);
    80001fc2:	8526                	mv	a0,s1
    80001fc4:	00000097          	auipc	ra,0x0
    80001fc8:	de4080e7          	jalr	-540(ra) # 80001da8 <proc_pagetable>
    80001fcc:	892a                	mv	s2,a0
    80001fce:	f4a8                	sd	a0,104(s1)
  if(p->pagetable == 0){
    80001fd0:	c121                	beqz	a0,80002010 <allocproc+0xfa>
  memset(&p->context, 0, sizeof(p->context));
    80001fd2:	07000613          	li	a2,112
    80001fd6:	4581                	li	a1,0
    80001fd8:	07848513          	addi	a0,s1,120
    80001fdc:	fffff097          	auipc	ra,0xfffff
    80001fe0:	d04080e7          	jalr	-764(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001fe4:	00000797          	auipc	a5,0x0
    80001fe8:	d4678793          	addi	a5,a5,-698 # 80001d2a <forkret>
    80001fec:	fcbc                	sd	a5,120(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001fee:	6cbc                	ld	a5,88(s1)
    80001ff0:	6705                	lui	a4,0x1
    80001ff2:	97ba                	add	a5,a5,a4
    80001ff4:	e0dc                	sd	a5,128(s1)
  return p;
    80001ff6:	a825                	j	8000202e <allocproc+0x118>
    freeproc(p);
    80001ff8:	8526                	mv	a0,s1
    80001ffa:	00000097          	auipc	ra,0x0
    80001ffe:	e9c080e7          	jalr	-356(ra) # 80001e96 <freeproc>
    release(&p->lock);
    80002002:	8526                	mv	a0,s1
    80002004:	fffff097          	auipc	ra,0xfffff
    80002008:	c94080e7          	jalr	-876(ra) # 80000c98 <release>
    return 0;
    8000200c:	84ca                	mv	s1,s2
    8000200e:	a005                	j	8000202e <allocproc+0x118>
    freeproc(p);
    80002010:	8526                	mv	a0,s1
    80002012:	00000097          	auipc	ra,0x0
    80002016:	e84080e7          	jalr	-380(ra) # 80001e96 <freeproc>
    release(&p->lock);
    8000201a:	8526                	mv	a0,s1
    8000201c:	fffff097          	auipc	ra,0xfffff
    80002020:	c7c080e7          	jalr	-900(ra) # 80000c98 <release>
    return 0;
    80002024:	84ca                	mv	s1,s2
    80002026:	a021                	j	8000202e <allocproc+0x118>
    return 0;
    80002028:	4481                	li	s1,0
    8000202a:	a011                	j	8000202e <allocproc+0x118>
      return 0;
    8000202c:	4481                	li	s1,0
}
    8000202e:	8526                	mv	a0,s1
    80002030:	70e2                	ld	ra,56(sp)
    80002032:	7442                	ld	s0,48(sp)
    80002034:	74a2                	ld	s1,40(sp)
    80002036:	7902                	ld	s2,32(sp)
    80002038:	69e2                	ld	s3,24(sp)
    8000203a:	6a42                	ld	s4,16(sp)
    8000203c:	6aa2                	ld	s5,8(sp)
    8000203e:	6121                	addi	sp,sp,64
    80002040:	8082                	ret

0000000080002042 <growproc>:
{
    80002042:	1101                	addi	sp,sp,-32
    80002044:	ec06                	sd	ra,24(sp)
    80002046:	e822                	sd	s0,16(sp)
    80002048:	e426                	sd	s1,8(sp)
    8000204a:	e04a                	sd	s2,0(sp)
    8000204c:	1000                	addi	s0,sp,32
    8000204e:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002050:	00000097          	auipc	ra,0x0
    80002054:	ca2080e7          	jalr	-862(ra) # 80001cf2 <myproc>
    80002058:	892a                	mv	s2,a0
  sz = p->sz;
    8000205a:	712c                	ld	a1,96(a0)
    8000205c:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80002060:	00904f63          	bgtz	s1,8000207e <growproc+0x3c>
  } else if(n < 0){
    80002064:	0204cc63          	bltz	s1,8000209c <growproc+0x5a>
  p->sz = sz;
    80002068:	1602                	slli	a2,a2,0x20
    8000206a:	9201                	srli	a2,a2,0x20
    8000206c:	06c93023          	sd	a2,96(s2)
  return 0;
    80002070:	4501                	li	a0,0
}
    80002072:	60e2                	ld	ra,24(sp)
    80002074:	6442                	ld	s0,16(sp)
    80002076:	64a2                	ld	s1,8(sp)
    80002078:	6902                	ld	s2,0(sp)
    8000207a:	6105                	addi	sp,sp,32
    8000207c:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    8000207e:	9e25                	addw	a2,a2,s1
    80002080:	1602                	slli	a2,a2,0x20
    80002082:	9201                	srli	a2,a2,0x20
    80002084:	1582                	slli	a1,a1,0x20
    80002086:	9181                	srli	a1,a1,0x20
    80002088:	7528                	ld	a0,104(a0)
    8000208a:	fffff097          	auipc	ra,0xfffff
    8000208e:	398080e7          	jalr	920(ra) # 80001422 <uvmalloc>
    80002092:	0005061b          	sext.w	a2,a0
    80002096:	fa69                	bnez	a2,80002068 <growproc+0x26>
      return -1;
    80002098:	557d                	li	a0,-1
    8000209a:	bfe1                	j	80002072 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    8000209c:	9e25                	addw	a2,a2,s1
    8000209e:	1602                	slli	a2,a2,0x20
    800020a0:	9201                	srli	a2,a2,0x20
    800020a2:	1582                	slli	a1,a1,0x20
    800020a4:	9181                	srli	a1,a1,0x20
    800020a6:	7528                	ld	a0,104(a0)
    800020a8:	fffff097          	auipc	ra,0xfffff
    800020ac:	332080e7          	jalr	818(ra) # 800013da <uvmdealloc>
    800020b0:	0005061b          	sext.w	a2,a0
    800020b4:	bf55                	j	80002068 <growproc+0x26>

00000000800020b6 <fork>:
{
    800020b6:	7179                	addi	sp,sp,-48
    800020b8:	f406                	sd	ra,40(sp)
    800020ba:	f022                	sd	s0,32(sp)
    800020bc:	ec26                	sd	s1,24(sp)
    800020be:	e84a                	sd	s2,16(sp)
    800020c0:	e44e                	sd	s3,8(sp)
    800020c2:	e052                	sd	s4,0(sp)
    800020c4:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800020c6:	00000097          	auipc	ra,0x0
    800020ca:	c2c080e7          	jalr	-980(ra) # 80001cf2 <myproc>
    800020ce:	892a                	mv	s2,a0
  printf("start fork\n");
    800020d0:	00006517          	auipc	a0,0x6
    800020d4:	20850513          	addi	a0,a0,520 # 800082d8 <digits+0x298>
    800020d8:	ffffe097          	auipc	ra,0xffffe
    800020dc:	4b0080e7          	jalr	1200(ra) # 80000588 <printf>
  if((np = allocproc()) == 0){
    800020e0:	00000097          	auipc	ra,0x0
    800020e4:	e36080e7          	jalr	-458(ra) # 80001f16 <allocproc>
    800020e8:	14050763          	beqz	a0,80002236 <fork+0x180>
    800020ec:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    800020ee:	06093603          	ld	a2,96(s2)
    800020f2:	752c                	ld	a1,104(a0)
    800020f4:	06893503          	ld	a0,104(s2)
    800020f8:	fffff097          	auipc	ra,0xfffff
    800020fc:	476080e7          	jalr	1142(ra) # 8000156e <uvmcopy>
    80002100:	04054663          	bltz	a0,8000214c <fork+0x96>
  np->sz = p->sz;
    80002104:	06093783          	ld	a5,96(s2)
    80002108:	06f9b023          	sd	a5,96(s3)
  *(np->trapframe) = *(p->trapframe);
    8000210c:	07093683          	ld	a3,112(s2)
    80002110:	87b6                	mv	a5,a3
    80002112:	0709b703          	ld	a4,112(s3)
    80002116:	12068693          	addi	a3,a3,288
    8000211a:	0007b803          	ld	a6,0(a5)
    8000211e:	6788                	ld	a0,8(a5)
    80002120:	6b8c                	ld	a1,16(a5)
    80002122:	6f90                	ld	a2,24(a5)
    80002124:	01073023          	sd	a6,0(a4) # 1000 <_entry-0x7ffff000>
    80002128:	e708                	sd	a0,8(a4)
    8000212a:	eb0c                	sd	a1,16(a4)
    8000212c:	ef10                	sd	a2,24(a4)
    8000212e:	02078793          	addi	a5,a5,32
    80002132:	02070713          	addi	a4,a4,32
    80002136:	fed792e3          	bne	a5,a3,8000211a <fork+0x64>
  np->trapframe->a0 = 0;
    8000213a:	0709b783          	ld	a5,112(s3)
    8000213e:	0607b823          	sd	zero,112(a5)
    80002142:	0e800493          	li	s1,232
  for(i = 0; i < NOFILE; i++)
    80002146:	16800a13          	li	s4,360
    8000214a:	a03d                	j	80002178 <fork+0xc2>
    freeproc(np);
    8000214c:	854e                	mv	a0,s3
    8000214e:	00000097          	auipc	ra,0x0
    80002152:	d48080e7          	jalr	-696(ra) # 80001e96 <freeproc>
    release(&np->lock);
    80002156:	854e                	mv	a0,s3
    80002158:	fffff097          	auipc	ra,0xfffff
    8000215c:	b40080e7          	jalr	-1216(ra) # 80000c98 <release>
    return -1;
    80002160:	5a7d                	li	s4,-1
    80002162:	a0c9                	j	80002224 <fork+0x16e>
      np->ofile[i] = filedup(p->ofile[i]);
    80002164:	00003097          	auipc	ra,0x3
    80002168:	ad0080e7          	jalr	-1328(ra) # 80004c34 <filedup>
    8000216c:	009987b3          	add	a5,s3,s1
    80002170:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80002172:	04a1                	addi	s1,s1,8
    80002174:	01448763          	beq	s1,s4,80002182 <fork+0xcc>
    if(p->ofile[i])
    80002178:	009907b3          	add	a5,s2,s1
    8000217c:	6388                	ld	a0,0(a5)
    8000217e:	f17d                	bnez	a0,80002164 <fork+0xae>
    80002180:	bfcd                	j	80002172 <fork+0xbc>
  np->cwd = idup(p->cwd);
    80002182:	16893503          	ld	a0,360(s2)
    80002186:	00002097          	auipc	ra,0x2
    8000218a:	c24080e7          	jalr	-988(ra) # 80003daa <idup>
    8000218e:	16a9b423          	sd	a0,360(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002192:	4641                	li	a2,16
    80002194:	17090593          	addi	a1,s2,368
    80002198:	17098513          	addi	a0,s3,368
    8000219c:	fffff097          	auipc	ra,0xfffff
    800021a0:	c96080e7          	jalr	-874(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    800021a4:	0489aa03          	lw	s4,72(s3)
  release(&np->lock);
    800021a8:	854e                	mv	a0,s3
    800021aa:	fffff097          	auipc	ra,0xfffff
    800021ae:	aee080e7          	jalr	-1298(ra) # 80000c98 <release>
  acquire(&wait_lock);
    800021b2:	0000f497          	auipc	s1,0xf
    800021b6:	1c648493          	addi	s1,s1,454 # 80011378 <wait_lock>
    800021ba:	8526                	mv	a0,s1
    800021bc:	fffff097          	auipc	ra,0xfffff
    800021c0:	a28080e7          	jalr	-1496(ra) # 80000be4 <acquire>
  np->parent = p;
    800021c4:	0529b823          	sd	s2,80(s3)
  release(&wait_lock);
    800021c8:	8526                	mv	a0,s1
    800021ca:	fffff097          	auipc	ra,0xfffff
    800021ce:	ace080e7          	jalr	-1330(ra) # 80000c98 <release>
  acquire(&np->lock);
    800021d2:	854e                	mv	a0,s3
    800021d4:	fffff097          	auipc	ra,0xfffff
    800021d8:	a10080e7          	jalr	-1520(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    800021dc:	478d                	li	a5,3
    800021de:	02f9a823          	sw	a5,48(s3)
  np-> affiliated_cpu = p-> affiliated_cpu;
    800021e2:	18892603          	lw	a2,392(s2)
    800021e6:	18c9a423          	sw	a2,392(s3)
  printf("in fork, try to insert proc %d to runnable list of cpu number %d", p->proc_index, p->affiliated_cpu);
    800021ea:	18492583          	lw	a1,388(s2)
    800021ee:	00006517          	auipc	a0,0x6
    800021f2:	0fa50513          	addi	a0,a0,250 # 800082e8 <digits+0x2a8>
    800021f6:	ffffe097          	auipc	ra,0xffffe
    800021fa:	392080e7          	jalr	914(ra) # 80000588 <printf>
  add_link(&runnable_cpu_lists[p->affiliated_cpu], p->proc_index);
    800021fe:	18892783          	lw	a5,392(s2)
    80002202:	0796                	slli	a5,a5,0x5
    80002204:	18492583          	lw	a1,388(s2)
    80002208:	0000f517          	auipc	a0,0xf
    8000220c:	0f850513          	addi	a0,a0,248 # 80011300 <runnable_cpu_lists>
    80002210:	953e                	add	a0,a0,a5
    80002212:	fffff097          	auipc	ra,0xfffff
    80002216:	76e080e7          	jalr	1902(ra) # 80001980 <add_link>
  release(&np->lock);
    8000221a:	854e                	mv	a0,s3
    8000221c:	fffff097          	auipc	ra,0xfffff
    80002220:	a7c080e7          	jalr	-1412(ra) # 80000c98 <release>
}
    80002224:	8552                	mv	a0,s4
    80002226:	70a2                	ld	ra,40(sp)
    80002228:	7402                	ld	s0,32(sp)
    8000222a:	64e2                	ld	s1,24(sp)
    8000222c:	6942                	ld	s2,16(sp)
    8000222e:	69a2                	ld	s3,8(sp)
    80002230:	6a02                	ld	s4,0(sp)
    80002232:	6145                	addi	sp,sp,48
    80002234:	8082                	ret
    return -1;
    80002236:	5a7d                	li	s4,-1
    80002238:	b7f5                	j	80002224 <fork+0x16e>

000000008000223a <sched>:
{
    8000223a:	7179                	addi	sp,sp,-48
    8000223c:	f406                	sd	ra,40(sp)
    8000223e:	f022                	sd	s0,32(sp)
    80002240:	ec26                	sd	s1,24(sp)
    80002242:	e84a                	sd	s2,16(sp)
    80002244:	e44e                	sd	s3,8(sp)
    80002246:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002248:	00000097          	auipc	ra,0x0
    8000224c:	aaa080e7          	jalr	-1366(ra) # 80001cf2 <myproc>
    80002250:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002252:	fffff097          	auipc	ra,0xfffff
    80002256:	918080e7          	jalr	-1768(ra) # 80000b6a <holding>
    8000225a:	c93d                	beqz	a0,800022d0 <sched+0x96>
    8000225c:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    8000225e:	2781                	sext.w	a5,a5
    80002260:	079e                	slli	a5,a5,0x7
    80002262:	0000f717          	auipc	a4,0xf
    80002266:	03e70713          	addi	a4,a4,62 # 800112a0 <unused_list>
    8000226a:	97ba                	add	a5,a5,a4
    8000226c:	1687a703          	lw	a4,360(a5)
    80002270:	4785                	li	a5,1
    80002272:	06f71763          	bne	a4,a5,800022e0 <sched+0xa6>
  if(p->state == RUNNING)
    80002276:	5898                	lw	a4,48(s1)
    80002278:	4791                	li	a5,4
    8000227a:	06f70b63          	beq	a4,a5,800022f0 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000227e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002282:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002284:	efb5                	bnez	a5,80002300 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002286:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002288:	0000f917          	auipc	s2,0xf
    8000228c:	01890913          	addi	s2,s2,24 # 800112a0 <unused_list>
    80002290:	2781                	sext.w	a5,a5
    80002292:	079e                	slli	a5,a5,0x7
    80002294:	97ca                	add	a5,a5,s2
    80002296:	16c7a983          	lw	s3,364(a5)
    8000229a:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000229c:	2781                	sext.w	a5,a5
    8000229e:	079e                	slli	a5,a5,0x7
    800022a0:	0000f597          	auipc	a1,0xf
    800022a4:	0f858593          	addi	a1,a1,248 # 80011398 <cpus+0x8>
    800022a8:	95be                	add	a1,a1,a5
    800022aa:	07848513          	addi	a0,s1,120
    800022ae:	00001097          	auipc	ra,0x1
    800022b2:	a8c080e7          	jalr	-1396(ra) # 80002d3a <swtch>
    800022b6:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800022b8:	2781                	sext.w	a5,a5
    800022ba:	079e                	slli	a5,a5,0x7
    800022bc:	97ca                	add	a5,a5,s2
    800022be:	1737a623          	sw	s3,364(a5)
}
    800022c2:	70a2                	ld	ra,40(sp)
    800022c4:	7402                	ld	s0,32(sp)
    800022c6:	64e2                	ld	s1,24(sp)
    800022c8:	6942                	ld	s2,16(sp)
    800022ca:	69a2                	ld	s3,8(sp)
    800022cc:	6145                	addi	sp,sp,48
    800022ce:	8082                	ret
    panic("sched p->lock");
    800022d0:	00006517          	auipc	a0,0x6
    800022d4:	06050513          	addi	a0,a0,96 # 80008330 <digits+0x2f0>
    800022d8:	ffffe097          	auipc	ra,0xffffe
    800022dc:	266080e7          	jalr	614(ra) # 8000053e <panic>
    panic("sched locks");
    800022e0:	00006517          	auipc	a0,0x6
    800022e4:	06050513          	addi	a0,a0,96 # 80008340 <digits+0x300>
    800022e8:	ffffe097          	auipc	ra,0xffffe
    800022ec:	256080e7          	jalr	598(ra) # 8000053e <panic>
    panic("sched running");
    800022f0:	00006517          	auipc	a0,0x6
    800022f4:	06050513          	addi	a0,a0,96 # 80008350 <digits+0x310>
    800022f8:	ffffe097          	auipc	ra,0xffffe
    800022fc:	246080e7          	jalr	582(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002300:	00006517          	auipc	a0,0x6
    80002304:	06050513          	addi	a0,a0,96 # 80008360 <digits+0x320>
    80002308:	ffffe097          	auipc	ra,0xffffe
    8000230c:	236080e7          	jalr	566(ra) # 8000053e <panic>

0000000080002310 <yield>:
{
    80002310:	1101                	addi	sp,sp,-32
    80002312:	ec06                	sd	ra,24(sp)
    80002314:	e822                	sd	s0,16(sp)
    80002316:	e426                	sd	s1,8(sp)
    80002318:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000231a:	00000097          	auipc	ra,0x0
    8000231e:	9d8080e7          	jalr	-1576(ra) # 80001cf2 <myproc>
    80002322:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002324:	fffff097          	auipc	ra,0xfffff
    80002328:	8c0080e7          	jalr	-1856(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    8000232c:	478d                	li	a5,3
    8000232e:	d89c                	sw	a5,48(s1)
  add_link(&runnable_cpu_lists[p->affiliated_cpu], p->proc_index);
    80002330:	1884a783          	lw	a5,392(s1)
    80002334:	0796                	slli	a5,a5,0x5
    80002336:	1844a583          	lw	a1,388(s1)
    8000233a:	0000f517          	auipc	a0,0xf
    8000233e:	fc650513          	addi	a0,a0,-58 # 80011300 <runnable_cpu_lists>
    80002342:	953e                	add	a0,a0,a5
    80002344:	fffff097          	auipc	ra,0xfffff
    80002348:	63c080e7          	jalr	1596(ra) # 80001980 <add_link>
  sched();
    8000234c:	00000097          	auipc	ra,0x0
    80002350:	eee080e7          	jalr	-274(ra) # 8000223a <sched>
  release(&p->lock);
    80002354:	8526                	mv	a0,s1
    80002356:	fffff097          	auipc	ra,0xfffff
    8000235a:	942080e7          	jalr	-1726(ra) # 80000c98 <release>
}
    8000235e:	60e2                	ld	ra,24(sp)
    80002360:	6442                	ld	s0,16(sp)
    80002362:	64a2                	ld	s1,8(sp)
    80002364:	6105                	addi	sp,sp,32
    80002366:	8082                	ret

0000000080002368 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002368:	7179                	addi	sp,sp,-48
    8000236a:	f406                	sd	ra,40(sp)
    8000236c:	f022                	sd	s0,32(sp)
    8000236e:	ec26                	sd	s1,24(sp)
    80002370:	e84a                	sd	s2,16(sp)
    80002372:	e44e                	sd	s3,8(sp)
    80002374:	1800                	addi	s0,sp,48
    80002376:	89aa                	mv	s3,a0
    80002378:	892e                	mv	s2,a1

  printf("start sleep\n");
    8000237a:	00006517          	auipc	a0,0x6
    8000237e:	ffe50513          	addi	a0,a0,-2 # 80008378 <digits+0x338>
    80002382:	ffffe097          	auipc	ra,0xffffe
    80002386:	206080e7          	jalr	518(ra) # 80000588 <printf>
  struct proc *p = myproc();
    8000238a:	00000097          	auipc	ra,0x0
    8000238e:	968080e7          	jalr	-1688(ra) # 80001cf2 <myproc>
    80002392:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002394:	fffff097          	auipc	ra,0xfffff
    80002398:	850080e7          	jalr	-1968(ra) # 80000be4 <acquire>
  release(lk);
    8000239c:	854a                	mv	a0,s2
    8000239e:	fffff097          	auipc	ra,0xfffff
    800023a2:	8fa080e7          	jalr	-1798(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    800023a6:	0334bc23          	sd	s3,56(s1)
  p->state = SLEEPING;
    800023aa:	4789                	li	a5,2
    800023ac:	d89c                	sw	a5,48(s1)
  
  add_link(&sleeping_list, p->proc_index);
    800023ae:	1844a583          	lw	a1,388(s1)
    800023b2:	0000f517          	auipc	a0,0xf
    800023b6:	f0e50513          	addi	a0,a0,-242 # 800112c0 <sleeping_list>
    800023ba:	fffff097          	auipc	ra,0xfffff
    800023be:	5c6080e7          	jalr	1478(ra) # 80001980 <add_link>
  printf("after adding link to sleeping list\n");
    800023c2:	00006517          	auipc	a0,0x6
    800023c6:	fc650513          	addi	a0,a0,-58 # 80008388 <digits+0x348>
    800023ca:	ffffe097          	auipc	ra,0xffffe
    800023ce:	1be080e7          	jalr	446(ra) # 80000588 <printf>
  sched();
    800023d2:	00000097          	auipc	ra,0x0
    800023d6:	e68080e7          	jalr	-408(ra) # 8000223a <sched>

  // Tidy up.
  p->chan = 0;
    800023da:	0204bc23          	sd	zero,56(s1)

  // Reacquire original lock.
  release(&p->lock);
    800023de:	8526                	mv	a0,s1
    800023e0:	fffff097          	auipc	ra,0xfffff
    800023e4:	8b8080e7          	jalr	-1864(ra) # 80000c98 <release>
  
  acquire(lk);
    800023e8:	854a                	mv	a0,s2
    800023ea:	ffffe097          	auipc	ra,0xffffe
    800023ee:	7fa080e7          	jalr	2042(ra) # 80000be4 <acquire>
  printf("finish sleep procedure\n");
    800023f2:	00006517          	auipc	a0,0x6
    800023f6:	fbe50513          	addi	a0,a0,-66 # 800083b0 <digits+0x370>
    800023fa:	ffffe097          	auipc	ra,0xffffe
    800023fe:	18e080e7          	jalr	398(ra) # 80000588 <printf>
}
    80002402:	70a2                	ld	ra,40(sp)
    80002404:	7402                	ld	s0,32(sp)
    80002406:	64e2                	ld	s1,24(sp)
    80002408:	6942                	ld	s2,16(sp)
    8000240a:	69a2                	ld	s3,8(sp)
    8000240c:	6145                	addi	sp,sp,48
    8000240e:	8082                	ret

0000000080002410 <wait>:
{
    80002410:	711d                	addi	sp,sp,-96
    80002412:	ec86                	sd	ra,88(sp)
    80002414:	e8a2                	sd	s0,80(sp)
    80002416:	e4a6                	sd	s1,72(sp)
    80002418:	e0ca                	sd	s2,64(sp)
    8000241a:	fc4e                	sd	s3,56(sp)
    8000241c:	f852                	sd	s4,48(sp)
    8000241e:	f456                	sd	s5,40(sp)
    80002420:	f05a                	sd	s6,32(sp)
    80002422:	ec5e                	sd	s7,24(sp)
    80002424:	e862                	sd	s8,16(sp)
    80002426:	e466                	sd	s9,8(sp)
    80002428:	1080                	addi	s0,sp,96
    8000242a:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000242c:	00000097          	auipc	ra,0x0
    80002430:	8c6080e7          	jalr	-1850(ra) # 80001cf2 <myproc>
    80002434:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002436:	0000f517          	auipc	a0,0xf
    8000243a:	f4250513          	addi	a0,a0,-190 # 80011378 <wait_lock>
    8000243e:	ffffe097          	auipc	ra,0xffffe
    80002442:	7a6080e7          	jalr	1958(ra) # 80000be4 <acquire>
    havekids = 0;
    80002446:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002448:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    8000244a:	00015997          	auipc	s3,0x15
    8000244e:	74698993          	addi	s3,s3,1862 # 80017b90 <tickslock>
        havekids = 1;
    80002452:	4a85                	li	s5,1
    printf("start sleep for process number %d",p->pid);
    80002454:	00006c97          	auipc	s9,0x6
    80002458:	f74c8c93          	addi	s9,s9,-140 # 800083c8 <digits+0x388>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000245c:	0000fc17          	auipc	s8,0xf
    80002460:	f1cc0c13          	addi	s8,s8,-228 # 80011378 <wait_lock>
    havekids = 0;
    80002464:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002466:	0000f497          	auipc	s1,0xf
    8000246a:	32a48493          	addi	s1,s1,810 # 80011790 <proc>
    8000246e:	a0bd                	j	800024dc <wait+0xcc>
          pid = np->pid;
    80002470:	0484a983          	lw	s3,72(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002474:	000b0e63          	beqz	s6,80002490 <wait+0x80>
    80002478:	4691                	li	a3,4
    8000247a:	04448613          	addi	a2,s1,68
    8000247e:	85da                	mv	a1,s6
    80002480:	06893503          	ld	a0,104(s2)
    80002484:	fffff097          	auipc	ra,0xfffff
    80002488:	1ee080e7          	jalr	494(ra) # 80001672 <copyout>
    8000248c:	02054563          	bltz	a0,800024b6 <wait+0xa6>
          freeproc(np);
    80002490:	8526                	mv	a0,s1
    80002492:	00000097          	auipc	ra,0x0
    80002496:	a04080e7          	jalr	-1532(ra) # 80001e96 <freeproc>
          release(&np->lock);
    8000249a:	8526                	mv	a0,s1
    8000249c:	ffffe097          	auipc	ra,0xffffe
    800024a0:	7fc080e7          	jalr	2044(ra) # 80000c98 <release>
          release(&wait_lock);
    800024a4:	0000f517          	auipc	a0,0xf
    800024a8:	ed450513          	addi	a0,a0,-300 # 80011378 <wait_lock>
    800024ac:	ffffe097          	auipc	ra,0xffffe
    800024b0:	7ec080e7          	jalr	2028(ra) # 80000c98 <release>
          return pid;
    800024b4:	a09d                	j	8000251a <wait+0x10a>
            release(&np->lock);
    800024b6:	8526                	mv	a0,s1
    800024b8:	ffffe097          	auipc	ra,0xffffe
    800024bc:	7e0080e7          	jalr	2016(ra) # 80000c98 <release>
            release(&wait_lock);
    800024c0:	0000f517          	auipc	a0,0xf
    800024c4:	eb850513          	addi	a0,a0,-328 # 80011378 <wait_lock>
    800024c8:	ffffe097          	auipc	ra,0xffffe
    800024cc:	7d0080e7          	jalr	2000(ra) # 80000c98 <release>
            return -1;
    800024d0:	59fd                	li	s3,-1
    800024d2:	a0a1                	j	8000251a <wait+0x10a>
    for(np = proc; np < &proc[NPROC]; np++){
    800024d4:	19048493          	addi	s1,s1,400
    800024d8:	03348463          	beq	s1,s3,80002500 <wait+0xf0>
      if(np->parent == p){
    800024dc:	68bc                	ld	a5,80(s1)
    800024de:	ff279be3          	bne	a5,s2,800024d4 <wait+0xc4>
        acquire(&np->lock);
    800024e2:	8526                	mv	a0,s1
    800024e4:	ffffe097          	auipc	ra,0xffffe
    800024e8:	700080e7          	jalr	1792(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    800024ec:	589c                	lw	a5,48(s1)
    800024ee:	f94781e3          	beq	a5,s4,80002470 <wait+0x60>
        release(&np->lock);
    800024f2:	8526                	mv	a0,s1
    800024f4:	ffffe097          	auipc	ra,0xffffe
    800024f8:	7a4080e7          	jalr	1956(ra) # 80000c98 <release>
        havekids = 1;
    800024fc:	8756                	mv	a4,s5
    800024fe:	bfd9                	j	800024d4 <wait+0xc4>
    if(!havekids || p->killed){
    80002500:	c701                	beqz	a4,80002508 <wait+0xf8>
    80002502:	04092783          	lw	a5,64(s2)
    80002506:	cb85                	beqz	a5,80002536 <wait+0x126>
      release(&wait_lock);
    80002508:	0000f517          	auipc	a0,0xf
    8000250c:	e7050513          	addi	a0,a0,-400 # 80011378 <wait_lock>
    80002510:	ffffe097          	auipc	ra,0xffffe
    80002514:	788080e7          	jalr	1928(ra) # 80000c98 <release>
      return -1;
    80002518:	59fd                	li	s3,-1
}
    8000251a:	854e                	mv	a0,s3
    8000251c:	60e6                	ld	ra,88(sp)
    8000251e:	6446                	ld	s0,80(sp)
    80002520:	64a6                	ld	s1,72(sp)
    80002522:	6906                	ld	s2,64(sp)
    80002524:	79e2                	ld	s3,56(sp)
    80002526:	7a42                	ld	s4,48(sp)
    80002528:	7aa2                	ld	s5,40(sp)
    8000252a:	7b02                	ld	s6,32(sp)
    8000252c:	6be2                	ld	s7,24(sp)
    8000252e:	6c42                	ld	s8,16(sp)
    80002530:	6ca2                	ld	s9,8(sp)
    80002532:	6125                	addi	sp,sp,96
    80002534:	8082                	ret
    printf("start sleep for process number %d",p->pid);
    80002536:	04892583          	lw	a1,72(s2)
    8000253a:	8566                	mv	a0,s9
    8000253c:	ffffe097          	auipc	ra,0xffffe
    80002540:	04c080e7          	jalr	76(ra) # 80000588 <printf>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002544:	85e2                	mv	a1,s8
    80002546:	854a                	mv	a0,s2
    80002548:	00000097          	auipc	ra,0x0
    8000254c:	e20080e7          	jalr	-480(ra) # 80002368 <sleep>
    havekids = 0;
    80002550:	bf11                	j	80002464 <wait+0x54>

0000000080002552 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002552:	7179                	addi	sp,sp,-48
    80002554:	f406                	sd	ra,40(sp)
    80002556:	f022                	sd	s0,32(sp)
    80002558:	ec26                	sd	s1,24(sp)
    8000255a:	e84a                	sd	s2,16(sp)
    8000255c:	e44e                	sd	s3,8(sp)
    8000255e:	1800                	addi	s0,sp,48
    80002560:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002562:	0000f497          	auipc	s1,0xf
    80002566:	22e48493          	addi	s1,s1,558 # 80011790 <proc>
    8000256a:	00015997          	auipc	s3,0x15
    8000256e:	62698993          	addi	s3,s3,1574 # 80017b90 <tickslock>
    acquire(&p->lock);
    80002572:	8526                	mv	a0,s1
    80002574:	ffffe097          	auipc	ra,0xffffe
    80002578:	670080e7          	jalr	1648(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    8000257c:	44bc                	lw	a5,72(s1)
    8000257e:	01278d63          	beq	a5,s2,80002598 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002582:	8526                	mv	a0,s1
    80002584:	ffffe097          	auipc	ra,0xffffe
    80002588:	714080e7          	jalr	1812(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000258c:	19048493          	addi	s1,s1,400
    80002590:	ff3491e3          	bne	s1,s3,80002572 <kill+0x20>
  }
  return -1;
    80002594:	557d                	li	a0,-1
    80002596:	a829                	j	800025b0 <kill+0x5e>
      p->killed = 1;
    80002598:	4785                	li	a5,1
    8000259a:	c0bc                	sw	a5,64(s1)
      if(p->state == SLEEPING){
    8000259c:	5898                	lw	a4,48(s1)
    8000259e:	4789                	li	a5,2
    800025a0:	00f70f63          	beq	a4,a5,800025be <kill+0x6c>
      release(&p->lock);
    800025a4:	8526                	mv	a0,s1
    800025a6:	ffffe097          	auipc	ra,0xffffe
    800025aa:	6f2080e7          	jalr	1778(ra) # 80000c98 <release>
      return 0;
    800025ae:	4501                	li	a0,0
}
    800025b0:	70a2                	ld	ra,40(sp)
    800025b2:	7402                	ld	s0,32(sp)
    800025b4:	64e2                	ld	s1,24(sp)
    800025b6:	6942                	ld	s2,16(sp)
    800025b8:	69a2                	ld	s3,8(sp)
    800025ba:	6145                	addi	sp,sp,48
    800025bc:	8082                	ret
        p->state = RUNNABLE;
    800025be:	478d                	li	a5,3
    800025c0:	d89c                	sw	a5,48(s1)
    800025c2:	b7cd                	j	800025a4 <kill+0x52>

00000000800025c4 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800025c4:	7179                	addi	sp,sp,-48
    800025c6:	f406                	sd	ra,40(sp)
    800025c8:	f022                	sd	s0,32(sp)
    800025ca:	ec26                	sd	s1,24(sp)
    800025cc:	e84a                	sd	s2,16(sp)
    800025ce:	e44e                	sd	s3,8(sp)
    800025d0:	e052                	sd	s4,0(sp)
    800025d2:	1800                	addi	s0,sp,48
    800025d4:	84aa                	mv	s1,a0
    800025d6:	892e                	mv	s2,a1
    800025d8:	89b2                	mv	s3,a2
    800025da:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800025dc:	fffff097          	auipc	ra,0xfffff
    800025e0:	716080e7          	jalr	1814(ra) # 80001cf2 <myproc>
  if(user_dst){
    800025e4:	c08d                	beqz	s1,80002606 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800025e6:	86d2                	mv	a3,s4
    800025e8:	864e                	mv	a2,s3
    800025ea:	85ca                	mv	a1,s2
    800025ec:	7528                	ld	a0,104(a0)
    800025ee:	fffff097          	auipc	ra,0xfffff
    800025f2:	084080e7          	jalr	132(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800025f6:	70a2                	ld	ra,40(sp)
    800025f8:	7402                	ld	s0,32(sp)
    800025fa:	64e2                	ld	s1,24(sp)
    800025fc:	6942                	ld	s2,16(sp)
    800025fe:	69a2                	ld	s3,8(sp)
    80002600:	6a02                	ld	s4,0(sp)
    80002602:	6145                	addi	sp,sp,48
    80002604:	8082                	ret
    memmove((char *)dst, src, len);
    80002606:	000a061b          	sext.w	a2,s4
    8000260a:	85ce                	mv	a1,s3
    8000260c:	854a                	mv	a0,s2
    8000260e:	ffffe097          	auipc	ra,0xffffe
    80002612:	732080e7          	jalr	1842(ra) # 80000d40 <memmove>
    return 0;
    80002616:	8526                	mv	a0,s1
    80002618:	bff9                	j	800025f6 <either_copyout+0x32>

000000008000261a <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000261a:	7179                	addi	sp,sp,-48
    8000261c:	f406                	sd	ra,40(sp)
    8000261e:	f022                	sd	s0,32(sp)
    80002620:	ec26                	sd	s1,24(sp)
    80002622:	e84a                	sd	s2,16(sp)
    80002624:	e44e                	sd	s3,8(sp)
    80002626:	e052                	sd	s4,0(sp)
    80002628:	1800                	addi	s0,sp,48
    8000262a:	892a                	mv	s2,a0
    8000262c:	84ae                	mv	s1,a1
    8000262e:	89b2                	mv	s3,a2
    80002630:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002632:	fffff097          	auipc	ra,0xfffff
    80002636:	6c0080e7          	jalr	1728(ra) # 80001cf2 <myproc>
  if(user_src){
    8000263a:	c08d                	beqz	s1,8000265c <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000263c:	86d2                	mv	a3,s4
    8000263e:	864e                	mv	a2,s3
    80002640:	85ca                	mv	a1,s2
    80002642:	7528                	ld	a0,104(a0)
    80002644:	fffff097          	auipc	ra,0xfffff
    80002648:	0ba080e7          	jalr	186(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000264c:	70a2                	ld	ra,40(sp)
    8000264e:	7402                	ld	s0,32(sp)
    80002650:	64e2                	ld	s1,24(sp)
    80002652:	6942                	ld	s2,16(sp)
    80002654:	69a2                	ld	s3,8(sp)
    80002656:	6a02                	ld	s4,0(sp)
    80002658:	6145                	addi	sp,sp,48
    8000265a:	8082                	ret
    memmove(dst, (char*)src, len);
    8000265c:	000a061b          	sext.w	a2,s4
    80002660:	85ce                	mv	a1,s3
    80002662:	854a                	mv	a0,s2
    80002664:	ffffe097          	auipc	ra,0xffffe
    80002668:	6dc080e7          	jalr	1756(ra) # 80000d40 <memmove>
    return 0;
    8000266c:	8526                	mv	a0,s1
    8000266e:	bff9                	j	8000264c <either_copyin+0x32>

0000000080002670 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002670:	715d                	addi	sp,sp,-80
    80002672:	e486                	sd	ra,72(sp)
    80002674:	e0a2                	sd	s0,64(sp)
    80002676:	fc26                	sd	s1,56(sp)
    80002678:	f84a                	sd	s2,48(sp)
    8000267a:	f44e                	sd	s3,40(sp)
    8000267c:	f052                	sd	s4,32(sp)
    8000267e:	ec56                	sd	s5,24(sp)
    80002680:	e85a                	sd	s6,16(sp)
    80002682:	e45e                	sd	s7,8(sp)
    80002684:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002686:	00006517          	auipc	a0,0x6
    8000268a:	db250513          	addi	a0,a0,-590 # 80008438 <digits+0x3f8>
    8000268e:	ffffe097          	auipc	ra,0xffffe
    80002692:	efa080e7          	jalr	-262(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002696:	0000f497          	auipc	s1,0xf
    8000269a:	26a48493          	addi	s1,s1,618 # 80011900 <proc+0x170>
    8000269e:	00015917          	auipc	s2,0x15
    800026a2:	66290913          	addi	s2,s2,1634 # 80017d00 <bcache+0x158>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026a6:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800026a8:	00006997          	auipc	s3,0x6
    800026ac:	d4898993          	addi	s3,s3,-696 # 800083f0 <digits+0x3b0>
    printf("%d %s %s", p->pid, state, p->name);
    800026b0:	00006a97          	auipc	s5,0x6
    800026b4:	d48a8a93          	addi	s5,s5,-696 # 800083f8 <digits+0x3b8>
    printf("\n");
    800026b8:	00006a17          	auipc	s4,0x6
    800026bc:	d80a0a13          	addi	s4,s4,-640 # 80008438 <digits+0x3f8>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026c0:	00006b97          	auipc	s7,0x6
    800026c4:	f18b8b93          	addi	s7,s7,-232 # 800085d8 <states.1756>
    800026c8:	a00d                	j	800026ea <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800026ca:	ed86a583          	lw	a1,-296(a3)
    800026ce:	8556                	mv	a0,s5
    800026d0:	ffffe097          	auipc	ra,0xffffe
    800026d4:	eb8080e7          	jalr	-328(ra) # 80000588 <printf>
    printf("\n");
    800026d8:	8552                	mv	a0,s4
    800026da:	ffffe097          	auipc	ra,0xffffe
    800026de:	eae080e7          	jalr	-338(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800026e2:	19048493          	addi	s1,s1,400
    800026e6:	03248163          	beq	s1,s2,80002708 <procdump+0x98>
    if(p->state == UNUSED)
    800026ea:	86a6                	mv	a3,s1
    800026ec:	ec04a783          	lw	a5,-320(s1)
    800026f0:	dbed                	beqz	a5,800026e2 <procdump+0x72>
      state = "???";
    800026f2:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026f4:	fcfb6be3          	bltu	s6,a5,800026ca <procdump+0x5a>
    800026f8:	1782                	slli	a5,a5,0x20
    800026fa:	9381                	srli	a5,a5,0x20
    800026fc:	078e                	slli	a5,a5,0x3
    800026fe:	97de                	add	a5,a5,s7
    80002700:	6390                	ld	a2,0(a5)
    80002702:	f661                	bnez	a2,800026ca <procdump+0x5a>
      state = "???";
    80002704:	864e                	mv	a2,s3
    80002706:	b7d1                	j	800026ca <procdump+0x5a>
  }
}
    80002708:	60a6                	ld	ra,72(sp)
    8000270a:	6406                	ld	s0,64(sp)
    8000270c:	74e2                	ld	s1,56(sp)
    8000270e:	7942                	ld	s2,48(sp)
    80002710:	79a2                	ld	s3,40(sp)
    80002712:	7a02                	ld	s4,32(sp)
    80002714:	6ae2                	ld	s5,24(sp)
    80002716:	6b42                	ld	s6,16(sp)
    80002718:	6ba2                	ld	s7,8(sp)
    8000271a:	6161                	addi	sp,sp,80
    8000271c:	8082                	ret

000000008000271e <wakeup>:
{
    8000271e:	7159                	addi	sp,sp,-112
    80002720:	f486                	sd	ra,104(sp)
    80002722:	f0a2                	sd	s0,96(sp)
    80002724:	eca6                	sd	s1,88(sp)
    80002726:	e8ca                	sd	s2,80(sp)
    80002728:	e4ce                	sd	s3,72(sp)
    8000272a:	e0d2                	sd	s4,64(sp)
    8000272c:	fc56                	sd	s5,56(sp)
    8000272e:	f85a                	sd	s6,48(sp)
    80002730:	f45e                	sd	s7,40(sp)
    80002732:	f062                	sd	s8,32(sp)
    80002734:	ec66                	sd	s9,24(sp)
    80002736:	e86a                	sd	s10,16(sp)
    80002738:	e46e                	sd	s11,8(sp)
    8000273a:	1880                	addi	s0,sp,112
    8000273c:	8b2a                	mv	s6,a0
 acquire(&sleeping_list.head_lock);
    8000273e:	0000f517          	auipc	a0,0xf
    80002742:	b8a50513          	addi	a0,a0,-1142 # 800112c8 <sleeping_list+0x8>
    80002746:	ffffe097          	auipc	ra,0xffffe
    8000274a:	49e080e7          	jalr	1182(ra) # 80000be4 <acquire>
  if (sleeping_list.head == -1){
    8000274e:	0000f797          	auipc	a5,0xf
    80002752:	b727a783          	lw	a5,-1166(a5) # 800112c0 <sleeping_list>
    80002756:	577d                	li	a4,-1
    80002758:	0ae78c63          	beq	a5,a4,80002810 <wakeup+0xf2>
  acquire(&proc[sleeping_list.head].list_lock);
    8000275c:	19000913          	li	s2,400
    80002760:	032787b3          	mul	a5,a5,s2
    80002764:	01878513          	addi	a0,a5,24
    80002768:	0000f997          	auipc	s3,0xf
    8000276c:	02898993          	addi	s3,s3,40 # 80011790 <proc>
    80002770:	954e                	add	a0,a0,s3
    80002772:	ffffe097          	auipc	ra,0xffffe
    80002776:	472080e7          	jalr	1138(ra) # 80000be4 <acquire>
  p = &proc[sleeping_list.head];
    8000277a:	0000f497          	auipc	s1,0xf
    8000277e:	b464a483          	lw	s1,-1210(s1) # 800112c0 <sleeping_list>
    80002782:	03248933          	mul	s2,s1,s2
    80002786:	994e                	add	s2,s2,s3
  acquire(&p->lock);
    80002788:	854a                	mv	a0,s2
    8000278a:	ffffe097          	auipc	ra,0xffffe
    8000278e:	45a080e7          	jalr	1114(ra) # 80000be4 <acquire>
  if(p!=myproc()&&p->chan == chan) {
    80002792:	fffff097          	auipc	ra,0xfffff
    80002796:	560080e7          	jalr	1376(ra) # 80001cf2 <myproc>
    8000279a:	00a90663          	beq	s2,a0,800027a6 <wakeup+0x88>
    8000279e:	03893783          	ld	a5,56(s2)
    800027a2:	09678c63          	beq	a5,s6,8000283a <wakeup+0x11c>
        release(&sleeping_list.head_lock);
    800027a6:	0000f517          	auipc	a0,0xf
    800027aa:	b2250513          	addi	a0,a0,-1246 # 800112c8 <sleeping_list+0x8>
    800027ae:	ffffe097          	auipc	ra,0xffffe
    800027b2:	4ea080e7          	jalr	1258(ra) # 80000c98 <release>
        release(&proc[sleeping_list.head].list_lock);
    800027b6:	0000f797          	auipc	a5,0xf
    800027ba:	b0a7a783          	lw	a5,-1270(a5) # 800112c0 <sleeping_list>
    800027be:	19000513          	li	a0,400
    800027c2:	02a787b3          	mul	a5,a5,a0
    800027c6:	0000f517          	auipc	a0,0xf
    800027ca:	fe250513          	addi	a0,a0,-30 # 800117a8 <proc+0x18>
    800027ce:	953e                	add	a0,a0,a5
    800027d0:	ffffe097          	auipc	ra,0xffffe
    800027d4:	4c8080e7          	jalr	1224(ra) # 80000c98 <release>
  release(&p->lock);
    800027d8:	854a                	mv	a0,s2
    800027da:	ffffe097          	auipc	ra,0xffffe
    800027de:	4be080e7          	jalr	1214(ra) # 80000c98 <release>
  printf("exiting wakeup\n");
    800027e2:	00006517          	auipc	a0,0x6
    800027e6:	c5e50513          	addi	a0,a0,-930 # 80008440 <digits+0x400>
    800027ea:	ffffe097          	auipc	ra,0xffffe
    800027ee:	d9e080e7          	jalr	-610(ra) # 80000588 <printf>
}
    800027f2:	70a6                	ld	ra,104(sp)
    800027f4:	7406                	ld	s0,96(sp)
    800027f6:	64e6                	ld	s1,88(sp)
    800027f8:	6946                	ld	s2,80(sp)
    800027fa:	69a6                	ld	s3,72(sp)
    800027fc:	6a06                	ld	s4,64(sp)
    800027fe:	7ae2                	ld	s5,56(sp)
    80002800:	7b42                	ld	s6,48(sp)
    80002802:	7ba2                	ld	s7,40(sp)
    80002804:	7c02                	ld	s8,32(sp)
    80002806:	6ce2                	ld	s9,24(sp)
    80002808:	6d42                	ld	s10,16(sp)
    8000280a:	6da2                	ld	s11,8(sp)
    8000280c:	6165                	addi	sp,sp,112
    8000280e:	8082                	ret
    printf("sleeping list is empty\n");
    80002810:	00006517          	auipc	a0,0x6
    80002814:	bf850513          	addi	a0,a0,-1032 # 80008408 <digits+0x3c8>
    80002818:	ffffe097          	auipc	ra,0xffffe
    8000281c:	d70080e7          	jalr	-656(ra) # 80000588 <printf>
    release(&sleeping_list.head_lock);
    80002820:	0000f517          	auipc	a0,0xf
    80002824:	aa850513          	addi	a0,a0,-1368 # 800112c8 <sleeping_list+0x8>
    80002828:	ffffe097          	auipc	ra,0xffffe
    8000282c:	470080e7          	jalr	1136(ra) # 80000c98 <release>
    procdump();
    80002830:	00000097          	auipc	ra,0x0
    80002834:	e40080e7          	jalr	-448(ra) # 80002670 <procdump>
    return;
    80002838:	bf6d                	j	800027f2 <wakeup+0xd4>
        printf("waking up proc number %d\n", p->pid);
    8000283a:	8a4e                	mv	s4,s3
    8000283c:	19000a93          	li	s5,400
    80002840:	04892583          	lw	a1,72(s2)
    80002844:	00006517          	auipc	a0,0x6
    80002848:	bdc50513          	addi	a0,a0,-1060 # 80008420 <digits+0x3e0>
    8000284c:	ffffe097          	auipc	ra,0xffffe
    80002850:	d3c080e7          	jalr	-708(ra) # 80000588 <printf>
        p->state = RUNNABLE;
    80002854:	478d                	li	a5,3
    80002856:	02f92823          	sw	a5,48(s2)
        next_link_index = p->next_proc_index;
    8000285a:	18092983          	lw	s3,384(s2)
        release(&sleeping_list.head_lock);
    8000285e:	0000f517          	auipc	a0,0xf
    80002862:	a6a50513          	addi	a0,a0,-1430 # 800112c8 <sleeping_list+0x8>
    80002866:	ffffe097          	auipc	ra,0xffffe
    8000286a:	432080e7          	jalr	1074(ra) # 80000c98 <release>
        release(&proc[sleeping_list.head].list_lock);
    8000286e:	0000f517          	auipc	a0,0xf
    80002872:	a5252503          	lw	a0,-1454(a0) # 800112c0 <sleeping_list>
    80002876:	03550533          	mul	a0,a0,s5
    8000287a:	0561                	addi	a0,a0,24
    8000287c:	9552                	add	a0,a0,s4
    8000287e:	ffffe097          	auipc	ra,0xffffe
    80002882:	41a080e7          	jalr	1050(ra) # 80000c98 <release>
        remove_link(&sleeping_list, p->proc_index);
    80002886:	18492583          	lw	a1,388(s2)
    8000288a:	0000f517          	auipc	a0,0xf
    8000288e:	a3650513          	addi	a0,a0,-1482 # 800112c0 <sleeping_list>
    80002892:	fffff097          	auipc	ra,0xfffff
    80002896:	fe2080e7          	jalr	-30(ra) # 80001874 <remove_link>
        add_link(&runnable_cpu_lists[p->affiliated_cpu], p->proc_index);
    8000289a:	18892783          	lw	a5,392(s2)
    8000289e:	0796                	slli	a5,a5,0x5
    800028a0:	18492583          	lw	a1,388(s2)
    800028a4:	0000f517          	auipc	a0,0xf
    800028a8:	a5c50513          	addi	a0,a0,-1444 # 80011300 <runnable_cpu_lists>
    800028ac:	953e                	add	a0,a0,a5
    800028ae:	fffff097          	auipc	ra,0xfffff
    800028b2:	0d2080e7          	jalr	210(ra) # 80001980 <add_link>
  release(&p->lock);
    800028b6:	854a                	mv	a0,s2
    800028b8:	ffffe097          	auipc	ra,0xffffe
    800028bc:	3e0080e7          	jalr	992(ra) # 80000c98 <release>
  while(next_link_index != -1){   // TODO: NOT SAFE!!
    800028c0:	57fd                	li	a5,-1
    800028c2:	f2f980e3          	beq	s3,a5,800027e2 <wakeup+0xc4>
        p->state = RUNNABLE;
    800028c6:	4d0d                	li	s10,3
        remove_link(&sleeping_list, p->proc_index);
    800028c8:	0000fc97          	auipc	s9,0xf
    800028cc:	9f8c8c93          	addi	s9,s9,-1544 # 800112c0 <sleeping_list>
        add_link(&runnable_cpu_lists[p->affiliated_cpu], p->proc_index);
    800028d0:	0000fc17          	auipc	s8,0xf
    800028d4:	a30c0c13          	addi	s8,s8,-1488 # 80011300 <runnable_cpu_lists>
  while(next_link_index != -1){   // TODO: NOT SAFE!!
    800028d8:	5bfd                	li	s7,-1
    800028da:	a829                	j	800028f4 <wakeup+0x1d6>
        release(&proc[next_link_index].list_lock);
    800028dc:	854a                	mv	a0,s2
    800028de:	ffffe097          	auipc	ra,0xffffe
    800028e2:	3ba080e7          	jalr	954(ra) # 80000c98 <release>
    release(&p->lock);
    800028e6:	8526                	mv	a0,s1
    800028e8:	ffffe097          	auipc	ra,0xffffe
    800028ec:	3b0080e7          	jalr	944(ra) # 80000c98 <release>
  while(next_link_index != -1){   // TODO: NOT SAFE!!
    800028f0:	ef7989e3          	beq	s3,s7,800027e2 <wakeup+0xc4>
    acquire(&proc[next_link_index].list_lock);
    800028f4:	035984b3          	mul	s1,s3,s5
    800028f8:	01848913          	addi	s2,s1,24
    800028fc:	9952                	add	s2,s2,s4
    800028fe:	854a                	mv	a0,s2
    80002900:	ffffe097          	auipc	ra,0xffffe
    80002904:	2e4080e7          	jalr	740(ra) # 80000be4 <acquire>
    p = &proc[next_link_index];
    80002908:	94d2                	add	s1,s1,s4
    acquire(&p->lock);
    8000290a:	8526                	mv	a0,s1
    8000290c:	ffffe097          	auipc	ra,0xffffe
    80002910:	2d8080e7          	jalr	728(ra) # 80000be4 <acquire>
      if(p!=myproc()&&p->chan == chan) {
    80002914:	fffff097          	auipc	ra,0xfffff
    80002918:	3de080e7          	jalr	990(ra) # 80001cf2 <myproc>
    8000291c:	fca480e3          	beq	s1,a0,800028dc <wakeup+0x1be>
    80002920:	7c9c                	ld	a5,56(s1)
    80002922:	fb679de3          	bne	a5,s6,800028dc <wakeup+0x1be>
        p->state = RUNNABLE;
    80002926:	03a4a823          	sw	s10,48(s1)
        release(&proc[next_link_index].list_lock);
    8000292a:	854a                	mv	a0,s2
    8000292c:	ffffe097          	auipc	ra,0xffffe
    80002930:	36c080e7          	jalr	876(ra) # 80000c98 <release>
        next_link_index = p->next_proc_index;
    80002934:	1804a983          	lw	s3,384(s1)
        remove_link(&sleeping_list, p->proc_index);
    80002938:	1844a583          	lw	a1,388(s1)
    8000293c:	8566                	mv	a0,s9
    8000293e:	fffff097          	auipc	ra,0xfffff
    80002942:	f36080e7          	jalr	-202(ra) # 80001874 <remove_link>
        add_link(&runnable_cpu_lists[p->affiliated_cpu], p->proc_index);
    80002946:	1884a503          	lw	a0,392(s1)
    8000294a:	0516                	slli	a0,a0,0x5
    8000294c:	1844a583          	lw	a1,388(s1)
    80002950:	9562                	add	a0,a0,s8
    80002952:	fffff097          	auipc	ra,0xfffff
    80002956:	02e080e7          	jalr	46(ra) # 80001980 <add_link>
    8000295a:	b771                	j	800028e6 <wakeup+0x1c8>

000000008000295c <reparent>:
{
    8000295c:	7139                	addi	sp,sp,-64
    8000295e:	fc06                	sd	ra,56(sp)
    80002960:	f822                	sd	s0,48(sp)
    80002962:	f426                	sd	s1,40(sp)
    80002964:	f04a                	sd	s2,32(sp)
    80002966:	ec4e                	sd	s3,24(sp)
    80002968:	e852                	sd	s4,16(sp)
    8000296a:	e456                	sd	s5,8(sp)
    8000296c:	0080                	addi	s0,sp,64
    8000296e:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002970:	0000f497          	auipc	s1,0xf
    80002974:	e2048493          	addi	s1,s1,-480 # 80011790 <proc>
      pp->parent = initproc;
    80002978:	00006a17          	auipc	s4,0x6
    8000297c:	6b0a0a13          	addi	s4,s4,1712 # 80009028 <initproc>
      printf("reparent\n");
    80002980:	00006a97          	auipc	s5,0x6
    80002984:	ad0a8a93          	addi	s5,s5,-1328 # 80008450 <digits+0x410>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002988:	00015997          	auipc	s3,0x15
    8000298c:	20898993          	addi	s3,s3,520 # 80017b90 <tickslock>
    80002990:	a029                	j	8000299a <reparent+0x3e>
    80002992:	19048493          	addi	s1,s1,400
    80002996:	03348463          	beq	s1,s3,800029be <reparent+0x62>
    if(pp->parent == p){
    8000299a:	68bc                	ld	a5,80(s1)
    8000299c:	ff279be3          	bne	a5,s2,80002992 <reparent+0x36>
      pp->parent = initproc;
    800029a0:	000a3783          	ld	a5,0(s4)
    800029a4:	e8bc                	sd	a5,80(s1)
      printf("reparent\n");
    800029a6:	8556                	mv	a0,s5
    800029a8:	ffffe097          	auipc	ra,0xffffe
    800029ac:	be0080e7          	jalr	-1056(ra) # 80000588 <printf>
      wakeup(initproc);
    800029b0:	000a3503          	ld	a0,0(s4)
    800029b4:	00000097          	auipc	ra,0x0
    800029b8:	d6a080e7          	jalr	-662(ra) # 8000271e <wakeup>
    800029bc:	bfd9                	j	80002992 <reparent+0x36>
}
    800029be:	70e2                	ld	ra,56(sp)
    800029c0:	7442                	ld	s0,48(sp)
    800029c2:	74a2                	ld	s1,40(sp)
    800029c4:	7902                	ld	s2,32(sp)
    800029c6:	69e2                	ld	s3,24(sp)
    800029c8:	6a42                	ld	s4,16(sp)
    800029ca:	6aa2                	ld	s5,8(sp)
    800029cc:	6121                	addi	sp,sp,64
    800029ce:	8082                	ret

00000000800029d0 <exit>:
{
    800029d0:	7179                	addi	sp,sp,-48
    800029d2:	f406                	sd	ra,40(sp)
    800029d4:	f022                	sd	s0,32(sp)
    800029d6:	ec26                	sd	s1,24(sp)
    800029d8:	e84a                	sd	s2,16(sp)
    800029da:	e44e                	sd	s3,8(sp)
    800029dc:	e052                	sd	s4,0(sp)
    800029de:	1800                	addi	s0,sp,48
    800029e0:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800029e2:	fffff097          	auipc	ra,0xfffff
    800029e6:	310080e7          	jalr	784(ra) # 80001cf2 <myproc>
    800029ea:	89aa                	mv	s3,a0
  if(p == initproc)
    800029ec:	00006797          	auipc	a5,0x6
    800029f0:	63c7b783          	ld	a5,1596(a5) # 80009028 <initproc>
    800029f4:	0e850493          	addi	s1,a0,232
    800029f8:	16850913          	addi	s2,a0,360
    800029fc:	02a79363          	bne	a5,a0,80002a22 <exit+0x52>
    panic("init exiting");
    80002a00:	00006517          	auipc	a0,0x6
    80002a04:	a6050513          	addi	a0,a0,-1440 # 80008460 <digits+0x420>
    80002a08:	ffffe097          	auipc	ra,0xffffe
    80002a0c:	b36080e7          	jalr	-1226(ra) # 8000053e <panic>
      fileclose(f);
    80002a10:	00002097          	auipc	ra,0x2
    80002a14:	276080e7          	jalr	630(ra) # 80004c86 <fileclose>
      p->ofile[fd] = 0;
    80002a18:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002a1c:	04a1                	addi	s1,s1,8
    80002a1e:	01248563          	beq	s1,s2,80002a28 <exit+0x58>
    if(p->ofile[fd]){
    80002a22:	6088                	ld	a0,0(s1)
    80002a24:	f575                	bnez	a0,80002a10 <exit+0x40>
    80002a26:	bfdd                	j	80002a1c <exit+0x4c>
  begin_op();
    80002a28:	00002097          	auipc	ra,0x2
    80002a2c:	d92080e7          	jalr	-622(ra) # 800047ba <begin_op>
  iput(p->cwd);
    80002a30:	1689b503          	ld	a0,360(s3)
    80002a34:	00001097          	auipc	ra,0x1
    80002a38:	56e080e7          	jalr	1390(ra) # 80003fa2 <iput>
  end_op();
    80002a3c:	00002097          	auipc	ra,0x2
    80002a40:	dfe080e7          	jalr	-514(ra) # 8000483a <end_op>
  p->cwd = 0;
    80002a44:	1609b423          	sd	zero,360(s3)
  acquire(&wait_lock);
    80002a48:	0000f497          	auipc	s1,0xf
    80002a4c:	93048493          	addi	s1,s1,-1744 # 80011378 <wait_lock>
    80002a50:	8526                	mv	a0,s1
    80002a52:	ffffe097          	auipc	ra,0xffffe
    80002a56:	192080e7          	jalr	402(ra) # 80000be4 <acquire>
  reparent(p);
    80002a5a:	854e                	mv	a0,s3
    80002a5c:	00000097          	auipc	ra,0x0
    80002a60:	f00080e7          	jalr	-256(ra) # 8000295c <reparent>
  wakeup(p->parent);
    80002a64:	0509b503          	ld	a0,80(s3)
    80002a68:	00000097          	auipc	ra,0x0
    80002a6c:	cb6080e7          	jalr	-842(ra) # 8000271e <wakeup>
  acquire(&p->lock);
    80002a70:	854e                	mv	a0,s3
    80002a72:	ffffe097          	auipc	ra,0xffffe
    80002a76:	172080e7          	jalr	370(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002a7a:	0549a223          	sw	s4,68(s3)
  p->state = ZOMBIE;
    80002a7e:	4795                	li	a5,5
    80002a80:	02f9a823          	sw	a5,48(s3)
  add_link(&zombie_list, p->proc_index);
    80002a84:	1849a583          	lw	a1,388(s3)
    80002a88:	0000f517          	auipc	a0,0xf
    80002a8c:	85850513          	addi	a0,a0,-1960 # 800112e0 <zombie_list>
    80002a90:	fffff097          	auipc	ra,0xfffff
    80002a94:	ef0080e7          	jalr	-272(ra) # 80001980 <add_link>
  release(&wait_lock);
    80002a98:	8526                	mv	a0,s1
    80002a9a:	ffffe097          	auipc	ra,0xffffe
    80002a9e:	1fe080e7          	jalr	510(ra) # 80000c98 <release>
  sched();
    80002aa2:	fffff097          	auipc	ra,0xfffff
    80002aa6:	798080e7          	jalr	1944(ra) # 8000223a <sched>
  panic("zombie exit");
    80002aaa:	00006517          	auipc	a0,0x6
    80002aae:	9c650513          	addi	a0,a0,-1594 # 80008470 <digits+0x430>
    80002ab2:	ffffe097          	auipc	ra,0xffffe
    80002ab6:	a8c080e7          	jalr	-1396(ra) # 8000053e <panic>

0000000080002aba <set_cpu>:

int set_cpu(int cpu_num){
  if (cpu_num >= NCPU)
    80002aba:	479d                	li	a5,7
    80002abc:	04a7c463          	blt	a5,a0,80002b04 <set_cpu+0x4a>
int set_cpu(int cpu_num){
    80002ac0:	1101                	addi	sp,sp,-32
    80002ac2:	ec06                	sd	ra,24(sp)
    80002ac4:	e822                	sd	s0,16(sp)
    80002ac6:	e426                	sd	s1,8(sp)
    80002ac8:	e04a                	sd	s2,0(sp)
    80002aca:	1000                	addi	s0,sp,32
    80002acc:	84aa                	mv	s1,a0
    return -1;
  
  struct proc* my_proc = myproc();
    80002ace:	fffff097          	auipc	ra,0xfffff
    80002ad2:	224080e7          	jalr	548(ra) # 80001cf2 <myproc>
    80002ad6:	892a                	mv	s2,a0
  acquire(&my_proc->lock);
    80002ad8:	ffffe097          	auipc	ra,0xffffe
    80002adc:	10c080e7          	jalr	268(ra) # 80000be4 <acquire>
  my_proc -> affiliated_cpu = cpu_num; 
    80002ae0:	18992423          	sw	s1,392(s2)
  release(&my_proc->lock);
    80002ae4:	854a                	mv	a0,s2
    80002ae6:	ffffe097          	auipc	ra,0xffffe
    80002aea:	1b2080e7          	jalr	434(ra) # 80000c98 <release>
  yield();
    80002aee:	00000097          	auipc	ra,0x0
    80002af2:	822080e7          	jalr	-2014(ra) # 80002310 <yield>

  return cpu_num;
    80002af6:	8526                	mv	a0,s1

}
    80002af8:	60e2                	ld	ra,24(sp)
    80002afa:	6442                	ld	s0,16(sp)
    80002afc:	64a2                	ld	s1,8(sp)
    80002afe:	6902                	ld	s2,0(sp)
    80002b00:	6105                	addi	sp,sp,32
    80002b02:	8082                	ret
    return -1;
    80002b04:	557d                	li	a0,-1
}
    80002b06:	8082                	ret

0000000080002b08 <get_cpu>:

int get_cpu(void){
    80002b08:	1101                	addi	sp,sp,-32
    80002b0a:	ec06                	sd	ra,24(sp)
    80002b0c:	e822                	sd	s0,16(sp)
    80002b0e:	e426                	sd	s1,8(sp)
    80002b10:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b12:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002b16:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b18:	10079073          	csrw	sstatus,a5
  asm volatile("mv %0, tp" : "=r" (x) );
    80002b1c:	8492                	mv	s1,tp
  int id = r_tp();
    80002b1e:	2481                	sext.w	s1,s1
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b20:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b24:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b28:	10079073          	csrw	sstatus,a5
  */
  
  intr_off();
  int res = cpuid();
  intr_on();
  printf("cpuid is %d\n", res);
    80002b2c:	85a6                	mv	a1,s1
    80002b2e:	00006517          	auipc	a0,0x6
    80002b32:	95250513          	addi	a0,a0,-1710 # 80008480 <digits+0x440>
    80002b36:	ffffe097          	auipc	ra,0xffffe
    80002b3a:	a52080e7          	jalr	-1454(ra) # 80000588 <printf>
  return res;
}
    80002b3e:	8526                	mv	a0,s1
    80002b40:	60e2                	ld	ra,24(sp)
    80002b42:	6442                	ld	s0,16(sp)
    80002b44:	64a2                	ld	s1,8(sp)
    80002b46:	6105                	addi	sp,sp,32
    80002b48:	8082                	ret

0000000080002b4a <userinit>:
{
    80002b4a:	1101                	addi	sp,sp,-32
    80002b4c:	ec06                	sd	ra,24(sp)
    80002b4e:	e822                	sd	s0,16(sp)
    80002b50:	e426                	sd	s1,8(sp)
    80002b52:	1000                	addi	s0,sp,32
  printf("started first allocproc\n");
    80002b54:	00006517          	auipc	a0,0x6
    80002b58:	93c50513          	addi	a0,a0,-1732 # 80008490 <digits+0x450>
    80002b5c:	ffffe097          	auipc	ra,0xffffe
    80002b60:	a2c080e7          	jalr	-1492(ra) # 80000588 <printf>
  p = allocproc();
    80002b64:	fffff097          	auipc	ra,0xfffff
    80002b68:	3b2080e7          	jalr	946(ra) # 80001f16 <allocproc>
    80002b6c:	84aa                	mv	s1,a0
  initproc = p;
    80002b6e:	00006797          	auipc	a5,0x6
    80002b72:	4aa7bd23          	sd	a0,1210(a5) # 80009028 <initproc>
  printf("ended first allocproc\n");
    80002b76:	00006517          	auipc	a0,0x6
    80002b7a:	93a50513          	addi	a0,a0,-1734 # 800084b0 <digits+0x470>
    80002b7e:	ffffe097          	auipc	ra,0xffffe
    80002b82:	a0a080e7          	jalr	-1526(ra) # 80000588 <printf>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80002b86:	03400613          	li	a2,52
    80002b8a:	00006597          	auipc	a1,0x6
    80002b8e:	fc658593          	addi	a1,a1,-58 # 80008b50 <initcode>
    80002b92:	74a8                	ld	a0,104(s1)
    80002b94:	ffffe097          	auipc	ra,0xffffe
    80002b98:	7d4080e7          	jalr	2004(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    80002b9c:	6785                	lui	a5,0x1
    80002b9e:	f0bc                	sd	a5,96(s1)
  p->trapframe->epc = 0;      // user program counter
    80002ba0:	78b8                	ld	a4,112(s1)
    80002ba2:	00073c23          	sd	zero,24(a4)
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80002ba6:	78b8                	ld	a4,112(s1)
    80002ba8:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80002baa:	4641                	li	a2,16
    80002bac:	00006597          	auipc	a1,0x6
    80002bb0:	91c58593          	addi	a1,a1,-1764 # 800084c8 <digits+0x488>
    80002bb4:	17048513          	addi	a0,s1,368
    80002bb8:	ffffe097          	auipc	ra,0xffffe
    80002bbc:	27a080e7          	jalr	634(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80002bc0:	00006517          	auipc	a0,0x6
    80002bc4:	91850513          	addi	a0,a0,-1768 # 800084d8 <digits+0x498>
    80002bc8:	00002097          	auipc	ra,0x2
    80002bcc:	9d6080e7          	jalr	-1578(ra) # 8000459e <namei>
    80002bd0:	16a4b423          	sd	a0,360(s1)
  p->state = RUNNABLE;
    80002bd4:	478d                	li	a5,3
    80002bd6:	d89c                	sw	a5,48(s1)
  printf("try to insert init proc to runnable list\n");
    80002bd8:	00006517          	auipc	a0,0x6
    80002bdc:	90850513          	addi	a0,a0,-1784 # 800084e0 <digits+0x4a0>
    80002be0:	ffffe097          	auipc	ra,0xffffe
    80002be4:	9a8080e7          	jalr	-1624(ra) # 80000588 <printf>
  add_link(&runnable_cpu_lists[get_cpu()], p->proc_index); // init_proc index is 0
    80002be8:	00000097          	auipc	ra,0x0
    80002bec:	f20080e7          	jalr	-224(ra) # 80002b08 <get_cpu>
    80002bf0:	0516                	slli	a0,a0,0x5
    80002bf2:	1844a583          	lw	a1,388(s1)
    80002bf6:	0000e797          	auipc	a5,0xe
    80002bfa:	70a78793          	addi	a5,a5,1802 # 80011300 <runnable_cpu_lists>
    80002bfe:	953e                	add	a0,a0,a5
    80002c00:	fffff097          	auipc	ra,0xfffff
    80002c04:	d80080e7          	jalr	-640(ra) # 80001980 <add_link>
  printf("inserted init proc to runnable list\n");
    80002c08:	00006517          	auipc	a0,0x6
    80002c0c:	90850513          	addi	a0,a0,-1784 # 80008510 <digits+0x4d0>
    80002c10:	ffffe097          	auipc	ra,0xffffe
    80002c14:	978080e7          	jalr	-1672(ra) # 80000588 <printf>
  release(&p->lock);
    80002c18:	8526                	mv	a0,s1
    80002c1a:	ffffe097          	auipc	ra,0xffffe
    80002c1e:	07e080e7          	jalr	126(ra) # 80000c98 <release>
}
    80002c22:	60e2                	ld	ra,24(sp)
    80002c24:	6442                	ld	s0,16(sp)
    80002c26:	64a2                	ld	s1,8(sp)
    80002c28:	6105                	addi	sp,sp,32
    80002c2a:	8082                	ret

0000000080002c2c <scheduler>:
{
    80002c2c:	7119                	addi	sp,sp,-128
    80002c2e:	fc86                	sd	ra,120(sp)
    80002c30:	f8a2                	sd	s0,112(sp)
    80002c32:	f4a6                	sd	s1,104(sp)
    80002c34:	f0ca                	sd	s2,96(sp)
    80002c36:	ecce                	sd	s3,88(sp)
    80002c38:	e8d2                	sd	s4,80(sp)
    80002c3a:	e4d6                	sd	s5,72(sp)
    80002c3c:	e0da                	sd	s6,64(sp)
    80002c3e:	fc5e                	sd	s7,56(sp)
    80002c40:	f862                	sd	s8,48(sp)
    80002c42:	f466                	sd	s9,40(sp)
    80002c44:	f06a                	sd	s10,32(sp)
    80002c46:	ec6e                	sd	s11,24(sp)
    80002c48:	0100                	addi	s0,sp,128
  asm volatile("mv %0, tp" : "=r" (x) );
    80002c4a:	8492                	mv	s1,tp
  int id = r_tp();
    80002c4c:	2481                	sext.w	s1,s1
  int cpu_id = get_cpu();
    80002c4e:	00000097          	auipc	ra,0x0
    80002c52:	eba080e7          	jalr	-326(ra) # 80002b08 <get_cpu>
    80002c56:	8b2a                	mv	s6,a0
  c->proc = 0;
    80002c58:	00749713          	slli	a4,s1,0x7
    80002c5c:	0000e797          	auipc	a5,0xe
    80002c60:	64478793          	addi	a5,a5,1604 # 800112a0 <unused_list>
    80002c64:	97ba                	add	a5,a5,a4
    80002c66:	0e07b823          	sd	zero,240(a5)
        remove_link(&runnable_cpu_lists[cpu_id], p->proc_index);
    80002c6a:	00551793          	slli	a5,a0,0x5
    80002c6e:	0000ed97          	auipc	s11,0xe
    80002c72:	692d8d93          	addi	s11,s11,1682 # 80011300 <runnable_cpu_lists>
    80002c76:	9dbe                	add	s11,s11,a5
        swtch(&c->context, &p->context);
    80002c78:	0000e797          	auipc	a5,0xe
    80002c7c:	72078793          	addi	a5,a5,1824 # 80011398 <cpus+0x8>
    80002c80:	97ba                	add	a5,a5,a4
    80002c82:	f8f43423          	sd	a5,-120(s0)
    printf("before checking if list is empty, cpu is %d\n", cpu_id);
    80002c86:	00006d17          	auipc	s10,0x6
    80002c8a:	8b2d0d13          	addi	s10,s10,-1870 # 80008538 <digits+0x4f8>
    while (runnable_cpu_lists[cpu_id].head == -1); // TODO: CHECK IT OUT
    80002c8e:	0000ec17          	auipc	s8,0xe
    80002c92:	612c0c13          	addi	s8,s8,1554 # 800112a0 <unused_list>
    80002c96:	00551c93          	slli	s9,a0,0x5
    80002c9a:	9ce2                	add	s9,s9,s8
    80002c9c:	597d                	li	s2,-1
    80002c9e:	19000b93          	li	s7,400
    p = &proc[runnable_cpu_lists[cpu_id].head];
    80002ca2:	0000fa97          	auipc	s5,0xf
    80002ca6:	aeea8a93          	addi	s5,s5,-1298 # 80011790 <proc>
        c->proc = p;
    80002caa:	9c3a                	add	s8,s8,a4
    80002cac:	a031                	j	80002cb8 <scheduler+0x8c>
    release(&p->lock);
    80002cae:	854e                	mv	a0,s3
    80002cb0:	ffffe097          	auipc	ra,0xffffe
    80002cb4:	fe8080e7          	jalr	-24(ra) # 80000c98 <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cb8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002cbc:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002cc0:	10079073          	csrw	sstatus,a5
    printf("before checking if list is empty, cpu is %d\n", cpu_id);
    80002cc4:	85da                	mv	a1,s6
    80002cc6:	856a                	mv	a0,s10
    80002cc8:	ffffe097          	auipc	ra,0xffffe
    80002ccc:	8c0080e7          	jalr	-1856(ra) # 80000588 <printf>
    while (runnable_cpu_lists[cpu_id].head == -1); // TODO: CHECK IT OUT
    80002cd0:	060ca483          	lw	s1,96(s9)
    80002cd4:	01248063          	beq	s1,s2,80002cd4 <scheduler+0xa8>
    p = &proc[runnable_cpu_lists[cpu_id].head];
    80002cd8:	03748a33          	mul	s4,s1,s7
    80002cdc:	015a09b3          	add	s3,s4,s5
    acquire(&p->lock);
    80002ce0:	854e                	mv	a0,s3
    80002ce2:	ffffe097          	auipc	ra,0xffffe
    80002ce6:	f02080e7          	jalr	-254(ra) # 80000be4 <acquire>
    if(p->state == RUNNABLE) {
    80002cea:	0309a703          	lw	a4,48(s3)
    80002cee:	478d                	li	a5,3
    80002cf0:	faf71fe3          	bne	a4,a5,80002cae <scheduler+0x82>
        p->state = RUNNING;
    80002cf4:	4791                	li	a5,4
    80002cf6:	02f9a823          	sw	a5,48(s3)
        remove_link(&runnable_cpu_lists[cpu_id], p->proc_index);
    80002cfa:	1849a583          	lw	a1,388(s3)
    80002cfe:	856e                	mv	a0,s11
    80002d00:	fffff097          	auipc	ra,0xfffff
    80002d04:	b74080e7          	jalr	-1164(ra) # 80001874 <remove_link>
        c->proc = p;
    80002d08:	0f3c3823          	sd	s3,240(s8)
        swtch(&c->context, &p->context);
    80002d0c:	078a0593          	addi	a1,s4,120
    80002d10:	95d6                	add	a1,a1,s5
    80002d12:	f8843503          	ld	a0,-120(s0)
    80002d16:	00000097          	auipc	ra,0x0
    80002d1a:	024080e7          	jalr	36(ra) # 80002d3a <swtch>
        printf("after run time, inserting proc %d to end of runnable list number %d\n", p->proc_index, cpu_id);
    80002d1e:	865a                	mv	a2,s6
    80002d20:	1849a583          	lw	a1,388(s3)
    80002d24:	00006517          	auipc	a0,0x6
    80002d28:	84450513          	addi	a0,a0,-1980 # 80008568 <digits+0x528>
    80002d2c:	ffffe097          	auipc	ra,0xffffe
    80002d30:	85c080e7          	jalr	-1956(ra) # 80000588 <printf>
        c->proc = 0;
    80002d34:	0e0c3823          	sd	zero,240(s8)
    80002d38:	bf9d                	j	80002cae <scheduler+0x82>

0000000080002d3a <swtch>:
    80002d3a:	00153023          	sd	ra,0(a0)
    80002d3e:	00253423          	sd	sp,8(a0)
    80002d42:	e900                	sd	s0,16(a0)
    80002d44:	ed04                	sd	s1,24(a0)
    80002d46:	03253023          	sd	s2,32(a0)
    80002d4a:	03353423          	sd	s3,40(a0)
    80002d4e:	03453823          	sd	s4,48(a0)
    80002d52:	03553c23          	sd	s5,56(a0)
    80002d56:	05653023          	sd	s6,64(a0)
    80002d5a:	05753423          	sd	s7,72(a0)
    80002d5e:	05853823          	sd	s8,80(a0)
    80002d62:	05953c23          	sd	s9,88(a0)
    80002d66:	07a53023          	sd	s10,96(a0)
    80002d6a:	07b53423          	sd	s11,104(a0)
    80002d6e:	0005b083          	ld	ra,0(a1)
    80002d72:	0085b103          	ld	sp,8(a1)
    80002d76:	6980                	ld	s0,16(a1)
    80002d78:	6d84                	ld	s1,24(a1)
    80002d7a:	0205b903          	ld	s2,32(a1)
    80002d7e:	0285b983          	ld	s3,40(a1)
    80002d82:	0305ba03          	ld	s4,48(a1)
    80002d86:	0385ba83          	ld	s5,56(a1)
    80002d8a:	0405bb03          	ld	s6,64(a1)
    80002d8e:	0485bb83          	ld	s7,72(a1)
    80002d92:	0505bc03          	ld	s8,80(a1)
    80002d96:	0585bc83          	ld	s9,88(a1)
    80002d9a:	0605bd03          	ld	s10,96(a1)
    80002d9e:	0685bd83          	ld	s11,104(a1)
    80002da2:	8082                	ret

0000000080002da4 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002da4:	1141                	addi	sp,sp,-16
    80002da6:	e406                	sd	ra,8(sp)
    80002da8:	e022                	sd	s0,0(sp)
    80002daa:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002dac:	00006597          	auipc	a1,0x6
    80002db0:	85c58593          	addi	a1,a1,-1956 # 80008608 <states.1756+0x30>
    80002db4:	00015517          	auipc	a0,0x15
    80002db8:	ddc50513          	addi	a0,a0,-548 # 80017b90 <tickslock>
    80002dbc:	ffffe097          	auipc	ra,0xffffe
    80002dc0:	d98080e7          	jalr	-616(ra) # 80000b54 <initlock>
}
    80002dc4:	60a2                	ld	ra,8(sp)
    80002dc6:	6402                	ld	s0,0(sp)
    80002dc8:	0141                	addi	sp,sp,16
    80002dca:	8082                	ret

0000000080002dcc <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002dcc:	1141                	addi	sp,sp,-16
    80002dce:	e422                	sd	s0,8(sp)
    80002dd0:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002dd2:	00003797          	auipc	a5,0x3
    80002dd6:	4ce78793          	addi	a5,a5,1230 # 800062a0 <kernelvec>
    80002dda:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002dde:	6422                	ld	s0,8(sp)
    80002de0:	0141                	addi	sp,sp,16
    80002de2:	8082                	ret

0000000080002de4 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002de4:	1141                	addi	sp,sp,-16
    80002de6:	e406                	sd	ra,8(sp)
    80002de8:	e022                	sd	s0,0(sp)
    80002dea:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002dec:	fffff097          	auipc	ra,0xfffff
    80002df0:	f06080e7          	jalr	-250(ra) # 80001cf2 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002df4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002df8:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002dfa:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002dfe:	00004617          	auipc	a2,0x4
    80002e02:	20260613          	addi	a2,a2,514 # 80007000 <_trampoline>
    80002e06:	00004697          	auipc	a3,0x4
    80002e0a:	1fa68693          	addi	a3,a3,506 # 80007000 <_trampoline>
    80002e0e:	8e91                	sub	a3,a3,a2
    80002e10:	040007b7          	lui	a5,0x4000
    80002e14:	17fd                	addi	a5,a5,-1
    80002e16:	07b2                	slli	a5,a5,0xc
    80002e18:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002e1a:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002e1e:	7938                	ld	a4,112(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002e20:	180026f3          	csrr	a3,satp
    80002e24:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002e26:	7938                	ld	a4,112(a0)
    80002e28:	6d34                	ld	a3,88(a0)
    80002e2a:	6585                	lui	a1,0x1
    80002e2c:	96ae                	add	a3,a3,a1
    80002e2e:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002e30:	7938                	ld	a4,112(a0)
    80002e32:	00000697          	auipc	a3,0x0
    80002e36:	13868693          	addi	a3,a3,312 # 80002f6a <usertrap>
    80002e3a:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002e3c:	7938                	ld	a4,112(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002e3e:	8692                	mv	a3,tp
    80002e40:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e42:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002e46:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002e4a:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e4e:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002e52:	7938                	ld	a4,112(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002e54:	6f18                	ld	a4,24(a4)
    80002e56:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002e5a:	752c                	ld	a1,104(a0)
    80002e5c:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002e5e:	00004717          	auipc	a4,0x4
    80002e62:	23270713          	addi	a4,a4,562 # 80007090 <userret>
    80002e66:	8f11                	sub	a4,a4,a2
    80002e68:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002e6a:	577d                	li	a4,-1
    80002e6c:	177e                	slli	a4,a4,0x3f
    80002e6e:	8dd9                	or	a1,a1,a4
    80002e70:	02000537          	lui	a0,0x2000
    80002e74:	157d                	addi	a0,a0,-1
    80002e76:	0536                	slli	a0,a0,0xd
    80002e78:	9782                	jalr	a5
}
    80002e7a:	60a2                	ld	ra,8(sp)
    80002e7c:	6402                	ld	s0,0(sp)
    80002e7e:	0141                	addi	sp,sp,16
    80002e80:	8082                	ret

0000000080002e82 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002e82:	1101                	addi	sp,sp,-32
    80002e84:	ec06                	sd	ra,24(sp)
    80002e86:	e822                	sd	s0,16(sp)
    80002e88:	e426                	sd	s1,8(sp)
    80002e8a:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002e8c:	00015497          	auipc	s1,0x15
    80002e90:	d0448493          	addi	s1,s1,-764 # 80017b90 <tickslock>
    80002e94:	8526                	mv	a0,s1
    80002e96:	ffffe097          	auipc	ra,0xffffe
    80002e9a:	d4e080e7          	jalr	-690(ra) # 80000be4 <acquire>
  ticks++;
    80002e9e:	00006517          	auipc	a0,0x6
    80002ea2:	19250513          	addi	a0,a0,402 # 80009030 <ticks>
    80002ea6:	411c                	lw	a5,0(a0)
    80002ea8:	2785                	addiw	a5,a5,1
    80002eaa:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002eac:	00000097          	auipc	ra,0x0
    80002eb0:	872080e7          	jalr	-1934(ra) # 8000271e <wakeup>
  release(&tickslock);
    80002eb4:	8526                	mv	a0,s1
    80002eb6:	ffffe097          	auipc	ra,0xffffe
    80002eba:	de2080e7          	jalr	-542(ra) # 80000c98 <release>
}
    80002ebe:	60e2                	ld	ra,24(sp)
    80002ec0:	6442                	ld	s0,16(sp)
    80002ec2:	64a2                	ld	s1,8(sp)
    80002ec4:	6105                	addi	sp,sp,32
    80002ec6:	8082                	ret

0000000080002ec8 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002ec8:	1101                	addi	sp,sp,-32
    80002eca:	ec06                	sd	ra,24(sp)
    80002ecc:	e822                	sd	s0,16(sp)
    80002ece:	e426                	sd	s1,8(sp)
    80002ed0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ed2:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002ed6:	00074d63          	bltz	a4,80002ef0 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002eda:	57fd                	li	a5,-1
    80002edc:	17fe                	slli	a5,a5,0x3f
    80002ede:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002ee0:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002ee2:	06f70363          	beq	a4,a5,80002f48 <devintr+0x80>
  }
}
    80002ee6:	60e2                	ld	ra,24(sp)
    80002ee8:	6442                	ld	s0,16(sp)
    80002eea:	64a2                	ld	s1,8(sp)
    80002eec:	6105                	addi	sp,sp,32
    80002eee:	8082                	ret
     (scause & 0xff) == 9){
    80002ef0:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002ef4:	46a5                	li	a3,9
    80002ef6:	fed792e3          	bne	a5,a3,80002eda <devintr+0x12>
    int irq = plic_claim();
    80002efa:	00003097          	auipc	ra,0x3
    80002efe:	4ae080e7          	jalr	1198(ra) # 800063a8 <plic_claim>
    80002f02:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002f04:	47a9                	li	a5,10
    80002f06:	02f50763          	beq	a0,a5,80002f34 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002f0a:	4785                	li	a5,1
    80002f0c:	02f50963          	beq	a0,a5,80002f3e <devintr+0x76>
    return 1;
    80002f10:	4505                	li	a0,1
    } else if(irq){
    80002f12:	d8f1                	beqz	s1,80002ee6 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002f14:	85a6                	mv	a1,s1
    80002f16:	00005517          	auipc	a0,0x5
    80002f1a:	6fa50513          	addi	a0,a0,1786 # 80008610 <states.1756+0x38>
    80002f1e:	ffffd097          	auipc	ra,0xffffd
    80002f22:	66a080e7          	jalr	1642(ra) # 80000588 <printf>
      plic_complete(irq);
    80002f26:	8526                	mv	a0,s1
    80002f28:	00003097          	auipc	ra,0x3
    80002f2c:	4a4080e7          	jalr	1188(ra) # 800063cc <plic_complete>
    return 1;
    80002f30:	4505                	li	a0,1
    80002f32:	bf55                	j	80002ee6 <devintr+0x1e>
      uartintr();
    80002f34:	ffffe097          	auipc	ra,0xffffe
    80002f38:	a74080e7          	jalr	-1420(ra) # 800009a8 <uartintr>
    80002f3c:	b7ed                	j	80002f26 <devintr+0x5e>
      virtio_disk_intr();
    80002f3e:	00004097          	auipc	ra,0x4
    80002f42:	96e080e7          	jalr	-1682(ra) # 800068ac <virtio_disk_intr>
    80002f46:	b7c5                	j	80002f26 <devintr+0x5e>
    if(cpuid() == 0){
    80002f48:	fffff097          	auipc	ra,0xfffff
    80002f4c:	d7e080e7          	jalr	-642(ra) # 80001cc6 <cpuid>
    80002f50:	c901                	beqz	a0,80002f60 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002f52:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002f56:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002f58:	14479073          	csrw	sip,a5
    return 2;
    80002f5c:	4509                	li	a0,2
    80002f5e:	b761                	j	80002ee6 <devintr+0x1e>
      clockintr();
    80002f60:	00000097          	auipc	ra,0x0
    80002f64:	f22080e7          	jalr	-222(ra) # 80002e82 <clockintr>
    80002f68:	b7ed                	j	80002f52 <devintr+0x8a>

0000000080002f6a <usertrap>:
{
    80002f6a:	1101                	addi	sp,sp,-32
    80002f6c:	ec06                	sd	ra,24(sp)
    80002f6e:	e822                	sd	s0,16(sp)
    80002f70:	e426                	sd	s1,8(sp)
    80002f72:	e04a                	sd	s2,0(sp)
    80002f74:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f76:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002f7a:	1007f793          	andi	a5,a5,256
    80002f7e:	e3ad                	bnez	a5,80002fe0 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002f80:	00003797          	auipc	a5,0x3
    80002f84:	32078793          	addi	a5,a5,800 # 800062a0 <kernelvec>
    80002f88:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002f8c:	fffff097          	auipc	ra,0xfffff
    80002f90:	d66080e7          	jalr	-666(ra) # 80001cf2 <myproc>
    80002f94:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002f96:	793c                	ld	a5,112(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f98:	14102773          	csrr	a4,sepc
    80002f9c:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f9e:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002fa2:	47a1                	li	a5,8
    80002fa4:	04f71c63          	bne	a4,a5,80002ffc <usertrap+0x92>
    if(p->killed)
    80002fa8:	413c                	lw	a5,64(a0)
    80002faa:	e3b9                	bnez	a5,80002ff0 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002fac:	78b8                	ld	a4,112(s1)
    80002fae:	6f1c                	ld	a5,24(a4)
    80002fb0:	0791                	addi	a5,a5,4
    80002fb2:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fb4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002fb8:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002fbc:	10079073          	csrw	sstatus,a5
    syscall();
    80002fc0:	00000097          	auipc	ra,0x0
    80002fc4:	2e0080e7          	jalr	736(ra) # 800032a0 <syscall>
  if(p->killed)
    80002fc8:	40bc                	lw	a5,64(s1)
    80002fca:	ebc1                	bnez	a5,8000305a <usertrap+0xf0>
  usertrapret();
    80002fcc:	00000097          	auipc	ra,0x0
    80002fd0:	e18080e7          	jalr	-488(ra) # 80002de4 <usertrapret>
}
    80002fd4:	60e2                	ld	ra,24(sp)
    80002fd6:	6442                	ld	s0,16(sp)
    80002fd8:	64a2                	ld	s1,8(sp)
    80002fda:	6902                	ld	s2,0(sp)
    80002fdc:	6105                	addi	sp,sp,32
    80002fde:	8082                	ret
    panic("usertrap: not from user mode");
    80002fe0:	00005517          	auipc	a0,0x5
    80002fe4:	65050513          	addi	a0,a0,1616 # 80008630 <states.1756+0x58>
    80002fe8:	ffffd097          	auipc	ra,0xffffd
    80002fec:	556080e7          	jalr	1366(ra) # 8000053e <panic>
      exit(-1);
    80002ff0:	557d                	li	a0,-1
    80002ff2:	00000097          	auipc	ra,0x0
    80002ff6:	9de080e7          	jalr	-1570(ra) # 800029d0 <exit>
    80002ffa:	bf4d                	j	80002fac <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002ffc:	00000097          	auipc	ra,0x0
    80003000:	ecc080e7          	jalr	-308(ra) # 80002ec8 <devintr>
    80003004:	892a                	mv	s2,a0
    80003006:	c501                	beqz	a0,8000300e <usertrap+0xa4>
  if(p->killed)
    80003008:	40bc                	lw	a5,64(s1)
    8000300a:	c3a1                	beqz	a5,8000304a <usertrap+0xe0>
    8000300c:	a815                	j	80003040 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000300e:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80003012:	44b0                	lw	a2,72(s1)
    80003014:	00005517          	auipc	a0,0x5
    80003018:	63c50513          	addi	a0,a0,1596 # 80008650 <states.1756+0x78>
    8000301c:	ffffd097          	auipc	ra,0xffffd
    80003020:	56c080e7          	jalr	1388(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003024:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003028:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000302c:	00005517          	auipc	a0,0x5
    80003030:	65450513          	addi	a0,a0,1620 # 80008680 <states.1756+0xa8>
    80003034:	ffffd097          	auipc	ra,0xffffd
    80003038:	554080e7          	jalr	1364(ra) # 80000588 <printf>
    p->killed = 1;
    8000303c:	4785                	li	a5,1
    8000303e:	c0bc                	sw	a5,64(s1)
    exit(-1);
    80003040:	557d                	li	a0,-1
    80003042:	00000097          	auipc	ra,0x0
    80003046:	98e080e7          	jalr	-1650(ra) # 800029d0 <exit>
  if(which_dev == 2)
    8000304a:	4789                	li	a5,2
    8000304c:	f8f910e3          	bne	s2,a5,80002fcc <usertrap+0x62>
    yield();
    80003050:	fffff097          	auipc	ra,0xfffff
    80003054:	2c0080e7          	jalr	704(ra) # 80002310 <yield>
    80003058:	bf95                	j	80002fcc <usertrap+0x62>
  int which_dev = 0;
    8000305a:	4901                	li	s2,0
    8000305c:	b7d5                	j	80003040 <usertrap+0xd6>

000000008000305e <kerneltrap>:
{
    8000305e:	7179                	addi	sp,sp,-48
    80003060:	f406                	sd	ra,40(sp)
    80003062:	f022                	sd	s0,32(sp)
    80003064:	ec26                	sd	s1,24(sp)
    80003066:	e84a                	sd	s2,16(sp)
    80003068:	e44e                	sd	s3,8(sp)
    8000306a:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000306c:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003070:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003074:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80003078:	1004f793          	andi	a5,s1,256
    8000307c:	cb85                	beqz	a5,800030ac <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000307e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80003082:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80003084:	ef85                	bnez	a5,800030bc <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80003086:	00000097          	auipc	ra,0x0
    8000308a:	e42080e7          	jalr	-446(ra) # 80002ec8 <devintr>
    8000308e:	cd1d                	beqz	a0,800030cc <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003090:	4789                	li	a5,2
    80003092:	06f50a63          	beq	a0,a5,80003106 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80003096:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000309a:	10049073          	csrw	sstatus,s1
}
    8000309e:	70a2                	ld	ra,40(sp)
    800030a0:	7402                	ld	s0,32(sp)
    800030a2:	64e2                	ld	s1,24(sp)
    800030a4:	6942                	ld	s2,16(sp)
    800030a6:	69a2                	ld	s3,8(sp)
    800030a8:	6145                	addi	sp,sp,48
    800030aa:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800030ac:	00005517          	auipc	a0,0x5
    800030b0:	5f450513          	addi	a0,a0,1524 # 800086a0 <states.1756+0xc8>
    800030b4:	ffffd097          	auipc	ra,0xffffd
    800030b8:	48a080e7          	jalr	1162(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    800030bc:	00005517          	auipc	a0,0x5
    800030c0:	60c50513          	addi	a0,a0,1548 # 800086c8 <states.1756+0xf0>
    800030c4:	ffffd097          	auipc	ra,0xffffd
    800030c8:	47a080e7          	jalr	1146(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    800030cc:	85ce                	mv	a1,s3
    800030ce:	00005517          	auipc	a0,0x5
    800030d2:	61a50513          	addi	a0,a0,1562 # 800086e8 <states.1756+0x110>
    800030d6:	ffffd097          	auipc	ra,0xffffd
    800030da:	4b2080e7          	jalr	1202(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800030de:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800030e2:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    800030e6:	00005517          	auipc	a0,0x5
    800030ea:	61250513          	addi	a0,a0,1554 # 800086f8 <states.1756+0x120>
    800030ee:	ffffd097          	auipc	ra,0xffffd
    800030f2:	49a080e7          	jalr	1178(ra) # 80000588 <printf>
    panic("kerneltrap");
    800030f6:	00005517          	auipc	a0,0x5
    800030fa:	61a50513          	addi	a0,a0,1562 # 80008710 <states.1756+0x138>
    800030fe:	ffffd097          	auipc	ra,0xffffd
    80003102:	440080e7          	jalr	1088(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003106:	fffff097          	auipc	ra,0xfffff
    8000310a:	bec080e7          	jalr	-1044(ra) # 80001cf2 <myproc>
    8000310e:	d541                	beqz	a0,80003096 <kerneltrap+0x38>
    80003110:	fffff097          	auipc	ra,0xfffff
    80003114:	be2080e7          	jalr	-1054(ra) # 80001cf2 <myproc>
    80003118:	5918                	lw	a4,48(a0)
    8000311a:	4791                	li	a5,4
    8000311c:	f6f71de3          	bne	a4,a5,80003096 <kerneltrap+0x38>
    yield();
    80003120:	fffff097          	auipc	ra,0xfffff
    80003124:	1f0080e7          	jalr	496(ra) # 80002310 <yield>
    80003128:	b7bd                	j	80003096 <kerneltrap+0x38>

000000008000312a <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    8000312a:	1101                	addi	sp,sp,-32
    8000312c:	ec06                	sd	ra,24(sp)
    8000312e:	e822                	sd	s0,16(sp)
    80003130:	e426                	sd	s1,8(sp)
    80003132:	1000                	addi	s0,sp,32
    80003134:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80003136:	fffff097          	auipc	ra,0xfffff
    8000313a:	bbc080e7          	jalr	-1092(ra) # 80001cf2 <myproc>
  switch (n) {
    8000313e:	4795                	li	a5,5
    80003140:	0497e163          	bltu	a5,s1,80003182 <argraw+0x58>
    80003144:	048a                	slli	s1,s1,0x2
    80003146:	00005717          	auipc	a4,0x5
    8000314a:	60270713          	addi	a4,a4,1538 # 80008748 <states.1756+0x170>
    8000314e:	94ba                	add	s1,s1,a4
    80003150:	409c                	lw	a5,0(s1)
    80003152:	97ba                	add	a5,a5,a4
    80003154:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80003156:	793c                	ld	a5,112(a0)
    80003158:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    8000315a:	60e2                	ld	ra,24(sp)
    8000315c:	6442                	ld	s0,16(sp)
    8000315e:	64a2                	ld	s1,8(sp)
    80003160:	6105                	addi	sp,sp,32
    80003162:	8082                	ret
    return p->trapframe->a1;
    80003164:	793c                	ld	a5,112(a0)
    80003166:	7fa8                	ld	a0,120(a5)
    80003168:	bfcd                	j	8000315a <argraw+0x30>
    return p->trapframe->a2;
    8000316a:	793c                	ld	a5,112(a0)
    8000316c:	63c8                	ld	a0,128(a5)
    8000316e:	b7f5                	j	8000315a <argraw+0x30>
    return p->trapframe->a3;
    80003170:	793c                	ld	a5,112(a0)
    80003172:	67c8                	ld	a0,136(a5)
    80003174:	b7dd                	j	8000315a <argraw+0x30>
    return p->trapframe->a4;
    80003176:	793c                	ld	a5,112(a0)
    80003178:	6bc8                	ld	a0,144(a5)
    8000317a:	b7c5                	j	8000315a <argraw+0x30>
    return p->trapframe->a5;
    8000317c:	793c                	ld	a5,112(a0)
    8000317e:	6fc8                	ld	a0,152(a5)
    80003180:	bfe9                	j	8000315a <argraw+0x30>
  panic("argraw");
    80003182:	00005517          	auipc	a0,0x5
    80003186:	59e50513          	addi	a0,a0,1438 # 80008720 <states.1756+0x148>
    8000318a:	ffffd097          	auipc	ra,0xffffd
    8000318e:	3b4080e7          	jalr	948(ra) # 8000053e <panic>

0000000080003192 <fetchaddr>:
{
    80003192:	1101                	addi	sp,sp,-32
    80003194:	ec06                	sd	ra,24(sp)
    80003196:	e822                	sd	s0,16(sp)
    80003198:	e426                	sd	s1,8(sp)
    8000319a:	e04a                	sd	s2,0(sp)
    8000319c:	1000                	addi	s0,sp,32
    8000319e:	84aa                	mv	s1,a0
    800031a0:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800031a2:	fffff097          	auipc	ra,0xfffff
    800031a6:	b50080e7          	jalr	-1200(ra) # 80001cf2 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    800031aa:	713c                	ld	a5,96(a0)
    800031ac:	02f4f863          	bgeu	s1,a5,800031dc <fetchaddr+0x4a>
    800031b0:	00848713          	addi	a4,s1,8
    800031b4:	02e7e663          	bltu	a5,a4,800031e0 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800031b8:	46a1                	li	a3,8
    800031ba:	8626                	mv	a2,s1
    800031bc:	85ca                	mv	a1,s2
    800031be:	7528                	ld	a0,104(a0)
    800031c0:	ffffe097          	auipc	ra,0xffffe
    800031c4:	53e080e7          	jalr	1342(ra) # 800016fe <copyin>
    800031c8:	00a03533          	snez	a0,a0
    800031cc:	40a00533          	neg	a0,a0
}
    800031d0:	60e2                	ld	ra,24(sp)
    800031d2:	6442                	ld	s0,16(sp)
    800031d4:	64a2                	ld	s1,8(sp)
    800031d6:	6902                	ld	s2,0(sp)
    800031d8:	6105                	addi	sp,sp,32
    800031da:	8082                	ret
    return -1;
    800031dc:	557d                	li	a0,-1
    800031de:	bfcd                	j	800031d0 <fetchaddr+0x3e>
    800031e0:	557d                	li	a0,-1
    800031e2:	b7fd                	j	800031d0 <fetchaddr+0x3e>

00000000800031e4 <fetchstr>:
{
    800031e4:	7179                	addi	sp,sp,-48
    800031e6:	f406                	sd	ra,40(sp)
    800031e8:	f022                	sd	s0,32(sp)
    800031ea:	ec26                	sd	s1,24(sp)
    800031ec:	e84a                	sd	s2,16(sp)
    800031ee:	e44e                	sd	s3,8(sp)
    800031f0:	1800                	addi	s0,sp,48
    800031f2:	892a                	mv	s2,a0
    800031f4:	84ae                	mv	s1,a1
    800031f6:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    800031f8:	fffff097          	auipc	ra,0xfffff
    800031fc:	afa080e7          	jalr	-1286(ra) # 80001cf2 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80003200:	86ce                	mv	a3,s3
    80003202:	864a                	mv	a2,s2
    80003204:	85a6                	mv	a1,s1
    80003206:	7528                	ld	a0,104(a0)
    80003208:	ffffe097          	auipc	ra,0xffffe
    8000320c:	582080e7          	jalr	1410(ra) # 8000178a <copyinstr>
  if(err < 0)
    80003210:	00054763          	bltz	a0,8000321e <fetchstr+0x3a>
  return strlen(buf);
    80003214:	8526                	mv	a0,s1
    80003216:	ffffe097          	auipc	ra,0xffffe
    8000321a:	c4e080e7          	jalr	-946(ra) # 80000e64 <strlen>
}
    8000321e:	70a2                	ld	ra,40(sp)
    80003220:	7402                	ld	s0,32(sp)
    80003222:	64e2                	ld	s1,24(sp)
    80003224:	6942                	ld	s2,16(sp)
    80003226:	69a2                	ld	s3,8(sp)
    80003228:	6145                	addi	sp,sp,48
    8000322a:	8082                	ret

000000008000322c <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    8000322c:	1101                	addi	sp,sp,-32
    8000322e:	ec06                	sd	ra,24(sp)
    80003230:	e822                	sd	s0,16(sp)
    80003232:	e426                	sd	s1,8(sp)
    80003234:	1000                	addi	s0,sp,32
    80003236:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003238:	00000097          	auipc	ra,0x0
    8000323c:	ef2080e7          	jalr	-270(ra) # 8000312a <argraw>
    80003240:	c088                	sw	a0,0(s1)
  return 0;
}
    80003242:	4501                	li	a0,0
    80003244:	60e2                	ld	ra,24(sp)
    80003246:	6442                	ld	s0,16(sp)
    80003248:	64a2                	ld	s1,8(sp)
    8000324a:	6105                	addi	sp,sp,32
    8000324c:	8082                	ret

000000008000324e <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    8000324e:	1101                	addi	sp,sp,-32
    80003250:	ec06                	sd	ra,24(sp)
    80003252:	e822                	sd	s0,16(sp)
    80003254:	e426                	sd	s1,8(sp)
    80003256:	1000                	addi	s0,sp,32
    80003258:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000325a:	00000097          	auipc	ra,0x0
    8000325e:	ed0080e7          	jalr	-304(ra) # 8000312a <argraw>
    80003262:	e088                	sd	a0,0(s1)
  return 0;
}
    80003264:	4501                	li	a0,0
    80003266:	60e2                	ld	ra,24(sp)
    80003268:	6442                	ld	s0,16(sp)
    8000326a:	64a2                	ld	s1,8(sp)
    8000326c:	6105                	addi	sp,sp,32
    8000326e:	8082                	ret

0000000080003270 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80003270:	1101                	addi	sp,sp,-32
    80003272:	ec06                	sd	ra,24(sp)
    80003274:	e822                	sd	s0,16(sp)
    80003276:	e426                	sd	s1,8(sp)
    80003278:	e04a                	sd	s2,0(sp)
    8000327a:	1000                	addi	s0,sp,32
    8000327c:	84ae                	mv	s1,a1
    8000327e:	8932                	mv	s2,a2
  *ip = argraw(n);
    80003280:	00000097          	auipc	ra,0x0
    80003284:	eaa080e7          	jalr	-342(ra) # 8000312a <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80003288:	864a                	mv	a2,s2
    8000328a:	85a6                	mv	a1,s1
    8000328c:	00000097          	auipc	ra,0x0
    80003290:	f58080e7          	jalr	-168(ra) # 800031e4 <fetchstr>
}
    80003294:	60e2                	ld	ra,24(sp)
    80003296:	6442                	ld	s0,16(sp)
    80003298:	64a2                	ld	s1,8(sp)
    8000329a:	6902                	ld	s2,0(sp)
    8000329c:	6105                	addi	sp,sp,32
    8000329e:	8082                	ret

00000000800032a0 <syscall>:
[SYS_getcpu] sys_getcpu,
};

void
syscall(void)
{
    800032a0:	1101                	addi	sp,sp,-32
    800032a2:	ec06                	sd	ra,24(sp)
    800032a4:	e822                	sd	s0,16(sp)
    800032a6:	e426                	sd	s1,8(sp)
    800032a8:	e04a                	sd	s2,0(sp)
    800032aa:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    800032ac:	fffff097          	auipc	ra,0xfffff
    800032b0:	a46080e7          	jalr	-1466(ra) # 80001cf2 <myproc>
    800032b4:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    800032b6:	07053903          	ld	s2,112(a0)
    800032ba:	0a893783          	ld	a5,168(s2)
    800032be:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    800032c2:	37fd                	addiw	a5,a5,-1
    800032c4:	4759                	li	a4,22
    800032c6:	00f76f63          	bltu	a4,a5,800032e4 <syscall+0x44>
    800032ca:	00369713          	slli	a4,a3,0x3
    800032ce:	00005797          	auipc	a5,0x5
    800032d2:	49278793          	addi	a5,a5,1170 # 80008760 <syscalls>
    800032d6:	97ba                	add	a5,a5,a4
    800032d8:	639c                	ld	a5,0(a5)
    800032da:	c789                	beqz	a5,800032e4 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    800032dc:	9782                	jalr	a5
    800032de:	06a93823          	sd	a0,112(s2)
    800032e2:	a839                	j	80003300 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    800032e4:	17048613          	addi	a2,s1,368
    800032e8:	44ac                	lw	a1,72(s1)
    800032ea:	00005517          	auipc	a0,0x5
    800032ee:	43e50513          	addi	a0,a0,1086 # 80008728 <states.1756+0x150>
    800032f2:	ffffd097          	auipc	ra,0xffffd
    800032f6:	296080e7          	jalr	662(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    800032fa:	78bc                	ld	a5,112(s1)
    800032fc:	577d                	li	a4,-1
    800032fe:	fbb8                	sd	a4,112(a5)
  }
}
    80003300:	60e2                	ld	ra,24(sp)
    80003302:	6442                	ld	s0,16(sp)
    80003304:	64a2                	ld	s1,8(sp)
    80003306:	6902                	ld	s2,0(sp)
    80003308:	6105                	addi	sp,sp,32
    8000330a:	8082                	ret

000000008000330c <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    8000330c:	1101                	addi	sp,sp,-32
    8000330e:	ec06                	sd	ra,24(sp)
    80003310:	e822                	sd	s0,16(sp)
    80003312:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80003314:	fec40593          	addi	a1,s0,-20
    80003318:	4501                	li	a0,0
    8000331a:	00000097          	auipc	ra,0x0
    8000331e:	f12080e7          	jalr	-238(ra) # 8000322c <argint>
    return -1;
    80003322:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003324:	00054963          	bltz	a0,80003336 <sys_exit+0x2a>
  exit(n);
    80003328:	fec42503          	lw	a0,-20(s0)
    8000332c:	fffff097          	auipc	ra,0xfffff
    80003330:	6a4080e7          	jalr	1700(ra) # 800029d0 <exit>
  return 0;  // not reached
    80003334:	4781                	li	a5,0
}
    80003336:	853e                	mv	a0,a5
    80003338:	60e2                	ld	ra,24(sp)
    8000333a:	6442                	ld	s0,16(sp)
    8000333c:	6105                	addi	sp,sp,32
    8000333e:	8082                	ret

0000000080003340 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003340:	1141                	addi	sp,sp,-16
    80003342:	e406                	sd	ra,8(sp)
    80003344:	e022                	sd	s0,0(sp)
    80003346:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003348:	fffff097          	auipc	ra,0xfffff
    8000334c:	9aa080e7          	jalr	-1622(ra) # 80001cf2 <myproc>
}
    80003350:	4528                	lw	a0,72(a0)
    80003352:	60a2                	ld	ra,8(sp)
    80003354:	6402                	ld	s0,0(sp)
    80003356:	0141                	addi	sp,sp,16
    80003358:	8082                	ret

000000008000335a <sys_fork>:

uint64
sys_fork(void)
{
    8000335a:	1141                	addi	sp,sp,-16
    8000335c:	e406                	sd	ra,8(sp)
    8000335e:	e022                	sd	s0,0(sp)
    80003360:	0800                	addi	s0,sp,16
  return fork();
    80003362:	fffff097          	auipc	ra,0xfffff
    80003366:	d54080e7          	jalr	-684(ra) # 800020b6 <fork>
}
    8000336a:	60a2                	ld	ra,8(sp)
    8000336c:	6402                	ld	s0,0(sp)
    8000336e:	0141                	addi	sp,sp,16
    80003370:	8082                	ret

0000000080003372 <sys_wait>:

uint64
sys_wait(void)
{
    80003372:	1101                	addi	sp,sp,-32
    80003374:	ec06                	sd	ra,24(sp)
    80003376:	e822                	sd	s0,16(sp)
    80003378:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    8000337a:	fe840593          	addi	a1,s0,-24
    8000337e:	4501                	li	a0,0
    80003380:	00000097          	auipc	ra,0x0
    80003384:	ece080e7          	jalr	-306(ra) # 8000324e <argaddr>
    80003388:	87aa                	mv	a5,a0
    return -1;
    8000338a:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    8000338c:	0007c863          	bltz	a5,8000339c <sys_wait+0x2a>
  return wait(p);
    80003390:	fe843503          	ld	a0,-24(s0)
    80003394:	fffff097          	auipc	ra,0xfffff
    80003398:	07c080e7          	jalr	124(ra) # 80002410 <wait>
}
    8000339c:	60e2                	ld	ra,24(sp)
    8000339e:	6442                	ld	s0,16(sp)
    800033a0:	6105                	addi	sp,sp,32
    800033a2:	8082                	ret

00000000800033a4 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800033a4:	7179                	addi	sp,sp,-48
    800033a6:	f406                	sd	ra,40(sp)
    800033a8:	f022                	sd	s0,32(sp)
    800033aa:	ec26                	sd	s1,24(sp)
    800033ac:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    800033ae:	fdc40593          	addi	a1,s0,-36
    800033b2:	4501                	li	a0,0
    800033b4:	00000097          	auipc	ra,0x0
    800033b8:	e78080e7          	jalr	-392(ra) # 8000322c <argint>
    800033bc:	87aa                	mv	a5,a0
    return -1;
    800033be:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    800033c0:	0207c063          	bltz	a5,800033e0 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    800033c4:	fffff097          	auipc	ra,0xfffff
    800033c8:	92e080e7          	jalr	-1746(ra) # 80001cf2 <myproc>
    800033cc:	5124                	lw	s1,96(a0)
  if(growproc(n) < 0)
    800033ce:	fdc42503          	lw	a0,-36(s0)
    800033d2:	fffff097          	auipc	ra,0xfffff
    800033d6:	c70080e7          	jalr	-912(ra) # 80002042 <growproc>
    800033da:	00054863          	bltz	a0,800033ea <sys_sbrk+0x46>
    return -1;
  return addr;
    800033de:	8526                	mv	a0,s1
}
    800033e0:	70a2                	ld	ra,40(sp)
    800033e2:	7402                	ld	s0,32(sp)
    800033e4:	64e2                	ld	s1,24(sp)
    800033e6:	6145                	addi	sp,sp,48
    800033e8:	8082                	ret
    return -1;
    800033ea:	557d                	li	a0,-1
    800033ec:	bfd5                	j	800033e0 <sys_sbrk+0x3c>

00000000800033ee <sys_sleep>:

uint64
sys_sleep(void)
{
    800033ee:	7139                	addi	sp,sp,-64
    800033f0:	fc06                	sd	ra,56(sp)
    800033f2:	f822                	sd	s0,48(sp)
    800033f4:	f426                	sd	s1,40(sp)
    800033f6:	f04a                	sd	s2,32(sp)
    800033f8:	ec4e                	sd	s3,24(sp)
    800033fa:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    800033fc:	fcc40593          	addi	a1,s0,-52
    80003400:	4501                	li	a0,0
    80003402:	00000097          	auipc	ra,0x0
    80003406:	e2a080e7          	jalr	-470(ra) # 8000322c <argint>
    return -1;
    8000340a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    8000340c:	06054563          	bltz	a0,80003476 <sys_sleep+0x88>
  acquire(&tickslock);
    80003410:	00014517          	auipc	a0,0x14
    80003414:	78050513          	addi	a0,a0,1920 # 80017b90 <tickslock>
    80003418:	ffffd097          	auipc	ra,0xffffd
    8000341c:	7cc080e7          	jalr	1996(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80003420:	00006917          	auipc	s2,0x6
    80003424:	c1092903          	lw	s2,-1008(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80003428:	fcc42783          	lw	a5,-52(s0)
    8000342c:	cf85                	beqz	a5,80003464 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000342e:	00014997          	auipc	s3,0x14
    80003432:	76298993          	addi	s3,s3,1890 # 80017b90 <tickslock>
    80003436:	00006497          	auipc	s1,0x6
    8000343a:	bfa48493          	addi	s1,s1,-1030 # 80009030 <ticks>
    if(myproc()->killed){
    8000343e:	fffff097          	auipc	ra,0xfffff
    80003442:	8b4080e7          	jalr	-1868(ra) # 80001cf2 <myproc>
    80003446:	413c                	lw	a5,64(a0)
    80003448:	ef9d                	bnez	a5,80003486 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    8000344a:	85ce                	mv	a1,s3
    8000344c:	8526                	mv	a0,s1
    8000344e:	fffff097          	auipc	ra,0xfffff
    80003452:	f1a080e7          	jalr	-230(ra) # 80002368 <sleep>
  while(ticks - ticks0 < n){
    80003456:	409c                	lw	a5,0(s1)
    80003458:	412787bb          	subw	a5,a5,s2
    8000345c:	fcc42703          	lw	a4,-52(s0)
    80003460:	fce7efe3          	bltu	a5,a4,8000343e <sys_sleep+0x50>
  }
  release(&tickslock);
    80003464:	00014517          	auipc	a0,0x14
    80003468:	72c50513          	addi	a0,a0,1836 # 80017b90 <tickslock>
    8000346c:	ffffe097          	auipc	ra,0xffffe
    80003470:	82c080e7          	jalr	-2004(ra) # 80000c98 <release>
  return 0;
    80003474:	4781                	li	a5,0
}
    80003476:	853e                	mv	a0,a5
    80003478:	70e2                	ld	ra,56(sp)
    8000347a:	7442                	ld	s0,48(sp)
    8000347c:	74a2                	ld	s1,40(sp)
    8000347e:	7902                	ld	s2,32(sp)
    80003480:	69e2                	ld	s3,24(sp)
    80003482:	6121                	addi	sp,sp,64
    80003484:	8082                	ret
      release(&tickslock);
    80003486:	00014517          	auipc	a0,0x14
    8000348a:	70a50513          	addi	a0,a0,1802 # 80017b90 <tickslock>
    8000348e:	ffffe097          	auipc	ra,0xffffe
    80003492:	80a080e7          	jalr	-2038(ra) # 80000c98 <release>
      return -1;
    80003496:	57fd                	li	a5,-1
    80003498:	bff9                	j	80003476 <sys_sleep+0x88>

000000008000349a <sys_kill>:

uint64
sys_kill(void)
{
    8000349a:	1101                	addi	sp,sp,-32
    8000349c:	ec06                	sd	ra,24(sp)
    8000349e:	e822                	sd	s0,16(sp)
    800034a0:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    800034a2:	fec40593          	addi	a1,s0,-20
    800034a6:	4501                	li	a0,0
    800034a8:	00000097          	auipc	ra,0x0
    800034ac:	d84080e7          	jalr	-636(ra) # 8000322c <argint>
    800034b0:	87aa                	mv	a5,a0
    return -1;
    800034b2:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800034b4:	0007c863          	bltz	a5,800034c4 <sys_kill+0x2a>
  return kill(pid);
    800034b8:	fec42503          	lw	a0,-20(s0)
    800034bc:	fffff097          	auipc	ra,0xfffff
    800034c0:	096080e7          	jalr	150(ra) # 80002552 <kill>
}
    800034c4:	60e2                	ld	ra,24(sp)
    800034c6:	6442                	ld	s0,16(sp)
    800034c8:	6105                	addi	sp,sp,32
    800034ca:	8082                	ret

00000000800034cc <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800034cc:	1101                	addi	sp,sp,-32
    800034ce:	ec06                	sd	ra,24(sp)
    800034d0:	e822                	sd	s0,16(sp)
    800034d2:	e426                	sd	s1,8(sp)
    800034d4:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800034d6:	00014517          	auipc	a0,0x14
    800034da:	6ba50513          	addi	a0,a0,1722 # 80017b90 <tickslock>
    800034de:	ffffd097          	auipc	ra,0xffffd
    800034e2:	706080e7          	jalr	1798(ra) # 80000be4 <acquire>
  xticks = ticks;
    800034e6:	00006497          	auipc	s1,0x6
    800034ea:	b4a4a483          	lw	s1,-1206(s1) # 80009030 <ticks>
  release(&tickslock);
    800034ee:	00014517          	auipc	a0,0x14
    800034f2:	6a250513          	addi	a0,a0,1698 # 80017b90 <tickslock>
    800034f6:	ffffd097          	auipc	ra,0xffffd
    800034fa:	7a2080e7          	jalr	1954(ra) # 80000c98 <release>
  return xticks;
}
    800034fe:	02049513          	slli	a0,s1,0x20
    80003502:	9101                	srli	a0,a0,0x20
    80003504:	60e2                	ld	ra,24(sp)
    80003506:	6442                	ld	s0,16(sp)
    80003508:	64a2                	ld	s1,8(sp)
    8000350a:	6105                	addi	sp,sp,32
    8000350c:	8082                	ret

000000008000350e <sys_setcpu>:

uint64
sys_setcpu(void){
    8000350e:	1101                	addi	sp,sp,-32
    80003510:	ec06                	sd	ra,24(sp)
    80003512:	e822                	sd	s0,16(sp)
    80003514:	1000                	addi	s0,sp,32
  int cpid;
  if(argint(0, &cpid) < 0)
    80003516:	fec40593          	addi	a1,s0,-20
    8000351a:	4501                	li	a0,0
    8000351c:	00000097          	auipc	ra,0x0
    80003520:	d10080e7          	jalr	-752(ra) # 8000322c <argint>
    80003524:	87aa                	mv	a5,a0
    return -1;
    80003526:	557d                	li	a0,-1
  if(argint(0, &cpid) < 0)
    80003528:	0007c863          	bltz	a5,80003538 <sys_setcpu+0x2a>

  return set_cpu(cpid);
    8000352c:	fec42503          	lw	a0,-20(s0)
    80003530:	fffff097          	auipc	ra,0xfffff
    80003534:	58a080e7          	jalr	1418(ra) # 80002aba <set_cpu>

}
    80003538:	60e2                	ld	ra,24(sp)
    8000353a:	6442                	ld	s0,16(sp)
    8000353c:	6105                	addi	sp,sp,32
    8000353e:	8082                	ret

0000000080003540 <sys_getcpu>:

uint64
sys_getcpu(void){
    80003540:	1141                	addi	sp,sp,-16
    80003542:	e406                	sd	ra,8(sp)
    80003544:	e022                	sd	s0,0(sp)
    80003546:	0800                	addi	s0,sp,16
  return get_cpu();
    80003548:	fffff097          	auipc	ra,0xfffff
    8000354c:	5c0080e7          	jalr	1472(ra) # 80002b08 <get_cpu>
}
    80003550:	60a2                	ld	ra,8(sp)
    80003552:	6402                	ld	s0,0(sp)
    80003554:	0141                	addi	sp,sp,16
    80003556:	8082                	ret

0000000080003558 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003558:	7179                	addi	sp,sp,-48
    8000355a:	f406                	sd	ra,40(sp)
    8000355c:	f022                	sd	s0,32(sp)
    8000355e:	ec26                	sd	s1,24(sp)
    80003560:	e84a                	sd	s2,16(sp)
    80003562:	e44e                	sd	s3,8(sp)
    80003564:	e052                	sd	s4,0(sp)
    80003566:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003568:	00005597          	auipc	a1,0x5
    8000356c:	2b858593          	addi	a1,a1,696 # 80008820 <syscalls+0xc0>
    80003570:	00014517          	auipc	a0,0x14
    80003574:	63850513          	addi	a0,a0,1592 # 80017ba8 <bcache>
    80003578:	ffffd097          	auipc	ra,0xffffd
    8000357c:	5dc080e7          	jalr	1500(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003580:	0001c797          	auipc	a5,0x1c
    80003584:	62878793          	addi	a5,a5,1576 # 8001fba8 <bcache+0x8000>
    80003588:	0001d717          	auipc	a4,0x1d
    8000358c:	88870713          	addi	a4,a4,-1912 # 8001fe10 <bcache+0x8268>
    80003590:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003594:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003598:	00014497          	auipc	s1,0x14
    8000359c:	62848493          	addi	s1,s1,1576 # 80017bc0 <bcache+0x18>
    b->next = bcache.head.next;
    800035a0:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800035a2:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800035a4:	00005a17          	auipc	s4,0x5
    800035a8:	284a0a13          	addi	s4,s4,644 # 80008828 <syscalls+0xc8>
    b->next = bcache.head.next;
    800035ac:	2b893783          	ld	a5,696(s2)
    800035b0:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800035b2:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800035b6:	85d2                	mv	a1,s4
    800035b8:	01048513          	addi	a0,s1,16
    800035bc:	00001097          	auipc	ra,0x1
    800035c0:	4bc080e7          	jalr	1212(ra) # 80004a78 <initsleeplock>
    bcache.head.next->prev = b;
    800035c4:	2b893783          	ld	a5,696(s2)
    800035c8:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800035ca:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800035ce:	45848493          	addi	s1,s1,1112
    800035d2:	fd349de3          	bne	s1,s3,800035ac <binit+0x54>
  }
}
    800035d6:	70a2                	ld	ra,40(sp)
    800035d8:	7402                	ld	s0,32(sp)
    800035da:	64e2                	ld	s1,24(sp)
    800035dc:	6942                	ld	s2,16(sp)
    800035de:	69a2                	ld	s3,8(sp)
    800035e0:	6a02                	ld	s4,0(sp)
    800035e2:	6145                	addi	sp,sp,48
    800035e4:	8082                	ret

00000000800035e6 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800035e6:	7179                	addi	sp,sp,-48
    800035e8:	f406                	sd	ra,40(sp)
    800035ea:	f022                	sd	s0,32(sp)
    800035ec:	ec26                	sd	s1,24(sp)
    800035ee:	e84a                	sd	s2,16(sp)
    800035f0:	e44e                	sd	s3,8(sp)
    800035f2:	1800                	addi	s0,sp,48
    800035f4:	89aa                	mv	s3,a0
    800035f6:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800035f8:	00014517          	auipc	a0,0x14
    800035fc:	5b050513          	addi	a0,a0,1456 # 80017ba8 <bcache>
    80003600:	ffffd097          	auipc	ra,0xffffd
    80003604:	5e4080e7          	jalr	1508(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003608:	0001d497          	auipc	s1,0x1d
    8000360c:	8584b483          	ld	s1,-1960(s1) # 8001fe60 <bcache+0x82b8>
    80003610:	0001d797          	auipc	a5,0x1d
    80003614:	80078793          	addi	a5,a5,-2048 # 8001fe10 <bcache+0x8268>
    80003618:	02f48f63          	beq	s1,a5,80003656 <bread+0x70>
    8000361c:	873e                	mv	a4,a5
    8000361e:	a021                	j	80003626 <bread+0x40>
    80003620:	68a4                	ld	s1,80(s1)
    80003622:	02e48a63          	beq	s1,a4,80003656 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003626:	449c                	lw	a5,8(s1)
    80003628:	ff379ce3          	bne	a5,s3,80003620 <bread+0x3a>
    8000362c:	44dc                	lw	a5,12(s1)
    8000362e:	ff2799e3          	bne	a5,s2,80003620 <bread+0x3a>
      b->refcnt++;
    80003632:	40bc                	lw	a5,64(s1)
    80003634:	2785                	addiw	a5,a5,1
    80003636:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003638:	00014517          	auipc	a0,0x14
    8000363c:	57050513          	addi	a0,a0,1392 # 80017ba8 <bcache>
    80003640:	ffffd097          	auipc	ra,0xffffd
    80003644:	658080e7          	jalr	1624(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003648:	01048513          	addi	a0,s1,16
    8000364c:	00001097          	auipc	ra,0x1
    80003650:	466080e7          	jalr	1126(ra) # 80004ab2 <acquiresleep>
      return b;
    80003654:	a8b9                	j	800036b2 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003656:	0001d497          	auipc	s1,0x1d
    8000365a:	8024b483          	ld	s1,-2046(s1) # 8001fe58 <bcache+0x82b0>
    8000365e:	0001c797          	auipc	a5,0x1c
    80003662:	7b278793          	addi	a5,a5,1970 # 8001fe10 <bcache+0x8268>
    80003666:	00f48863          	beq	s1,a5,80003676 <bread+0x90>
    8000366a:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000366c:	40bc                	lw	a5,64(s1)
    8000366e:	cf81                	beqz	a5,80003686 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003670:	64a4                	ld	s1,72(s1)
    80003672:	fee49de3          	bne	s1,a4,8000366c <bread+0x86>
  panic("bget: no buffers");
    80003676:	00005517          	auipc	a0,0x5
    8000367a:	1ba50513          	addi	a0,a0,442 # 80008830 <syscalls+0xd0>
    8000367e:	ffffd097          	auipc	ra,0xffffd
    80003682:	ec0080e7          	jalr	-320(ra) # 8000053e <panic>
      b->dev = dev;
    80003686:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    8000368a:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    8000368e:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003692:	4785                	li	a5,1
    80003694:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003696:	00014517          	auipc	a0,0x14
    8000369a:	51250513          	addi	a0,a0,1298 # 80017ba8 <bcache>
    8000369e:	ffffd097          	auipc	ra,0xffffd
    800036a2:	5fa080e7          	jalr	1530(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800036a6:	01048513          	addi	a0,s1,16
    800036aa:	00001097          	auipc	ra,0x1
    800036ae:	408080e7          	jalr	1032(ra) # 80004ab2 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800036b2:	409c                	lw	a5,0(s1)
    800036b4:	cb89                	beqz	a5,800036c6 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800036b6:	8526                	mv	a0,s1
    800036b8:	70a2                	ld	ra,40(sp)
    800036ba:	7402                	ld	s0,32(sp)
    800036bc:	64e2                	ld	s1,24(sp)
    800036be:	6942                	ld	s2,16(sp)
    800036c0:	69a2                	ld	s3,8(sp)
    800036c2:	6145                	addi	sp,sp,48
    800036c4:	8082                	ret
    virtio_disk_rw(b, 0);
    800036c6:	4581                	li	a1,0
    800036c8:	8526                	mv	a0,s1
    800036ca:	00003097          	auipc	ra,0x3
    800036ce:	f0c080e7          	jalr	-244(ra) # 800065d6 <virtio_disk_rw>
    b->valid = 1;
    800036d2:	4785                	li	a5,1
    800036d4:	c09c                	sw	a5,0(s1)
  return b;
    800036d6:	b7c5                	j	800036b6 <bread+0xd0>

00000000800036d8 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800036d8:	1101                	addi	sp,sp,-32
    800036da:	ec06                	sd	ra,24(sp)
    800036dc:	e822                	sd	s0,16(sp)
    800036de:	e426                	sd	s1,8(sp)
    800036e0:	1000                	addi	s0,sp,32
    800036e2:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800036e4:	0541                	addi	a0,a0,16
    800036e6:	00001097          	auipc	ra,0x1
    800036ea:	466080e7          	jalr	1126(ra) # 80004b4c <holdingsleep>
    800036ee:	cd01                	beqz	a0,80003706 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800036f0:	4585                	li	a1,1
    800036f2:	8526                	mv	a0,s1
    800036f4:	00003097          	auipc	ra,0x3
    800036f8:	ee2080e7          	jalr	-286(ra) # 800065d6 <virtio_disk_rw>
}
    800036fc:	60e2                	ld	ra,24(sp)
    800036fe:	6442                	ld	s0,16(sp)
    80003700:	64a2                	ld	s1,8(sp)
    80003702:	6105                	addi	sp,sp,32
    80003704:	8082                	ret
    panic("bwrite");
    80003706:	00005517          	auipc	a0,0x5
    8000370a:	14250513          	addi	a0,a0,322 # 80008848 <syscalls+0xe8>
    8000370e:	ffffd097          	auipc	ra,0xffffd
    80003712:	e30080e7          	jalr	-464(ra) # 8000053e <panic>

0000000080003716 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003716:	1101                	addi	sp,sp,-32
    80003718:	ec06                	sd	ra,24(sp)
    8000371a:	e822                	sd	s0,16(sp)
    8000371c:	e426                	sd	s1,8(sp)
    8000371e:	e04a                	sd	s2,0(sp)
    80003720:	1000                	addi	s0,sp,32
    80003722:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003724:	01050913          	addi	s2,a0,16
    80003728:	854a                	mv	a0,s2
    8000372a:	00001097          	auipc	ra,0x1
    8000372e:	422080e7          	jalr	1058(ra) # 80004b4c <holdingsleep>
    80003732:	c92d                	beqz	a0,800037a4 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003734:	854a                	mv	a0,s2
    80003736:	00001097          	auipc	ra,0x1
    8000373a:	3d2080e7          	jalr	978(ra) # 80004b08 <releasesleep>

  acquire(&bcache.lock);
    8000373e:	00014517          	auipc	a0,0x14
    80003742:	46a50513          	addi	a0,a0,1130 # 80017ba8 <bcache>
    80003746:	ffffd097          	auipc	ra,0xffffd
    8000374a:	49e080e7          	jalr	1182(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000374e:	40bc                	lw	a5,64(s1)
    80003750:	37fd                	addiw	a5,a5,-1
    80003752:	0007871b          	sext.w	a4,a5
    80003756:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003758:	eb05                	bnez	a4,80003788 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000375a:	68bc                	ld	a5,80(s1)
    8000375c:	64b8                	ld	a4,72(s1)
    8000375e:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003760:	64bc                	ld	a5,72(s1)
    80003762:	68b8                	ld	a4,80(s1)
    80003764:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003766:	0001c797          	auipc	a5,0x1c
    8000376a:	44278793          	addi	a5,a5,1090 # 8001fba8 <bcache+0x8000>
    8000376e:	2b87b703          	ld	a4,696(a5)
    80003772:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003774:	0001c717          	auipc	a4,0x1c
    80003778:	69c70713          	addi	a4,a4,1692 # 8001fe10 <bcache+0x8268>
    8000377c:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000377e:	2b87b703          	ld	a4,696(a5)
    80003782:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003784:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003788:	00014517          	auipc	a0,0x14
    8000378c:	42050513          	addi	a0,a0,1056 # 80017ba8 <bcache>
    80003790:	ffffd097          	auipc	ra,0xffffd
    80003794:	508080e7          	jalr	1288(ra) # 80000c98 <release>
}
    80003798:	60e2                	ld	ra,24(sp)
    8000379a:	6442                	ld	s0,16(sp)
    8000379c:	64a2                	ld	s1,8(sp)
    8000379e:	6902                	ld	s2,0(sp)
    800037a0:	6105                	addi	sp,sp,32
    800037a2:	8082                	ret
    panic("brelse");
    800037a4:	00005517          	auipc	a0,0x5
    800037a8:	0ac50513          	addi	a0,a0,172 # 80008850 <syscalls+0xf0>
    800037ac:	ffffd097          	auipc	ra,0xffffd
    800037b0:	d92080e7          	jalr	-622(ra) # 8000053e <panic>

00000000800037b4 <bpin>:

void
bpin(struct buf *b) {
    800037b4:	1101                	addi	sp,sp,-32
    800037b6:	ec06                	sd	ra,24(sp)
    800037b8:	e822                	sd	s0,16(sp)
    800037ba:	e426                	sd	s1,8(sp)
    800037bc:	1000                	addi	s0,sp,32
    800037be:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800037c0:	00014517          	auipc	a0,0x14
    800037c4:	3e850513          	addi	a0,a0,1000 # 80017ba8 <bcache>
    800037c8:	ffffd097          	auipc	ra,0xffffd
    800037cc:	41c080e7          	jalr	1052(ra) # 80000be4 <acquire>
  b->refcnt++;
    800037d0:	40bc                	lw	a5,64(s1)
    800037d2:	2785                	addiw	a5,a5,1
    800037d4:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800037d6:	00014517          	auipc	a0,0x14
    800037da:	3d250513          	addi	a0,a0,978 # 80017ba8 <bcache>
    800037de:	ffffd097          	auipc	ra,0xffffd
    800037e2:	4ba080e7          	jalr	1210(ra) # 80000c98 <release>
}
    800037e6:	60e2                	ld	ra,24(sp)
    800037e8:	6442                	ld	s0,16(sp)
    800037ea:	64a2                	ld	s1,8(sp)
    800037ec:	6105                	addi	sp,sp,32
    800037ee:	8082                	ret

00000000800037f0 <bunpin>:

void
bunpin(struct buf *b) {
    800037f0:	1101                	addi	sp,sp,-32
    800037f2:	ec06                	sd	ra,24(sp)
    800037f4:	e822                	sd	s0,16(sp)
    800037f6:	e426                	sd	s1,8(sp)
    800037f8:	1000                	addi	s0,sp,32
    800037fa:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800037fc:	00014517          	auipc	a0,0x14
    80003800:	3ac50513          	addi	a0,a0,940 # 80017ba8 <bcache>
    80003804:	ffffd097          	auipc	ra,0xffffd
    80003808:	3e0080e7          	jalr	992(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000380c:	40bc                	lw	a5,64(s1)
    8000380e:	37fd                	addiw	a5,a5,-1
    80003810:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003812:	00014517          	auipc	a0,0x14
    80003816:	39650513          	addi	a0,a0,918 # 80017ba8 <bcache>
    8000381a:	ffffd097          	auipc	ra,0xffffd
    8000381e:	47e080e7          	jalr	1150(ra) # 80000c98 <release>
}
    80003822:	60e2                	ld	ra,24(sp)
    80003824:	6442                	ld	s0,16(sp)
    80003826:	64a2                	ld	s1,8(sp)
    80003828:	6105                	addi	sp,sp,32
    8000382a:	8082                	ret

000000008000382c <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000382c:	1101                	addi	sp,sp,-32
    8000382e:	ec06                	sd	ra,24(sp)
    80003830:	e822                	sd	s0,16(sp)
    80003832:	e426                	sd	s1,8(sp)
    80003834:	e04a                	sd	s2,0(sp)
    80003836:	1000                	addi	s0,sp,32
    80003838:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000383a:	00d5d59b          	srliw	a1,a1,0xd
    8000383e:	0001d797          	auipc	a5,0x1d
    80003842:	a467a783          	lw	a5,-1466(a5) # 80020284 <sb+0x1c>
    80003846:	9dbd                	addw	a1,a1,a5
    80003848:	00000097          	auipc	ra,0x0
    8000384c:	d9e080e7          	jalr	-610(ra) # 800035e6 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003850:	0074f713          	andi	a4,s1,7
    80003854:	4785                	li	a5,1
    80003856:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000385a:	14ce                	slli	s1,s1,0x33
    8000385c:	90d9                	srli	s1,s1,0x36
    8000385e:	00950733          	add	a4,a0,s1
    80003862:	05874703          	lbu	a4,88(a4)
    80003866:	00e7f6b3          	and	a3,a5,a4
    8000386a:	c69d                	beqz	a3,80003898 <bfree+0x6c>
    8000386c:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000386e:	94aa                	add	s1,s1,a0
    80003870:	fff7c793          	not	a5,a5
    80003874:	8ff9                	and	a5,a5,a4
    80003876:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000387a:	00001097          	auipc	ra,0x1
    8000387e:	118080e7          	jalr	280(ra) # 80004992 <log_write>
  brelse(bp);
    80003882:	854a                	mv	a0,s2
    80003884:	00000097          	auipc	ra,0x0
    80003888:	e92080e7          	jalr	-366(ra) # 80003716 <brelse>
}
    8000388c:	60e2                	ld	ra,24(sp)
    8000388e:	6442                	ld	s0,16(sp)
    80003890:	64a2                	ld	s1,8(sp)
    80003892:	6902                	ld	s2,0(sp)
    80003894:	6105                	addi	sp,sp,32
    80003896:	8082                	ret
    panic("freeing free block");
    80003898:	00005517          	auipc	a0,0x5
    8000389c:	fc050513          	addi	a0,a0,-64 # 80008858 <syscalls+0xf8>
    800038a0:	ffffd097          	auipc	ra,0xffffd
    800038a4:	c9e080e7          	jalr	-866(ra) # 8000053e <panic>

00000000800038a8 <balloc>:
{
    800038a8:	711d                	addi	sp,sp,-96
    800038aa:	ec86                	sd	ra,88(sp)
    800038ac:	e8a2                	sd	s0,80(sp)
    800038ae:	e4a6                	sd	s1,72(sp)
    800038b0:	e0ca                	sd	s2,64(sp)
    800038b2:	fc4e                	sd	s3,56(sp)
    800038b4:	f852                	sd	s4,48(sp)
    800038b6:	f456                	sd	s5,40(sp)
    800038b8:	f05a                	sd	s6,32(sp)
    800038ba:	ec5e                	sd	s7,24(sp)
    800038bc:	e862                	sd	s8,16(sp)
    800038be:	e466                	sd	s9,8(sp)
    800038c0:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800038c2:	0001d797          	auipc	a5,0x1d
    800038c6:	9aa7a783          	lw	a5,-1622(a5) # 8002026c <sb+0x4>
    800038ca:	cbd1                	beqz	a5,8000395e <balloc+0xb6>
    800038cc:	8baa                	mv	s7,a0
    800038ce:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800038d0:	0001db17          	auipc	s6,0x1d
    800038d4:	998b0b13          	addi	s6,s6,-1640 # 80020268 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800038d8:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800038da:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800038dc:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800038de:	6c89                	lui	s9,0x2
    800038e0:	a831                	j	800038fc <balloc+0x54>
    brelse(bp);
    800038e2:	854a                	mv	a0,s2
    800038e4:	00000097          	auipc	ra,0x0
    800038e8:	e32080e7          	jalr	-462(ra) # 80003716 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800038ec:	015c87bb          	addw	a5,s9,s5
    800038f0:	00078a9b          	sext.w	s5,a5
    800038f4:	004b2703          	lw	a4,4(s6)
    800038f8:	06eaf363          	bgeu	s5,a4,8000395e <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800038fc:	41fad79b          	sraiw	a5,s5,0x1f
    80003900:	0137d79b          	srliw	a5,a5,0x13
    80003904:	015787bb          	addw	a5,a5,s5
    80003908:	40d7d79b          	sraiw	a5,a5,0xd
    8000390c:	01cb2583          	lw	a1,28(s6)
    80003910:	9dbd                	addw	a1,a1,a5
    80003912:	855e                	mv	a0,s7
    80003914:	00000097          	auipc	ra,0x0
    80003918:	cd2080e7          	jalr	-814(ra) # 800035e6 <bread>
    8000391c:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000391e:	004b2503          	lw	a0,4(s6)
    80003922:	000a849b          	sext.w	s1,s5
    80003926:	8662                	mv	a2,s8
    80003928:	faa4fde3          	bgeu	s1,a0,800038e2 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000392c:	41f6579b          	sraiw	a5,a2,0x1f
    80003930:	01d7d69b          	srliw	a3,a5,0x1d
    80003934:	00c6873b          	addw	a4,a3,a2
    80003938:	00777793          	andi	a5,a4,7
    8000393c:	9f95                	subw	a5,a5,a3
    8000393e:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003942:	4037571b          	sraiw	a4,a4,0x3
    80003946:	00e906b3          	add	a3,s2,a4
    8000394a:	0586c683          	lbu	a3,88(a3)
    8000394e:	00d7f5b3          	and	a1,a5,a3
    80003952:	cd91                	beqz	a1,8000396e <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003954:	2605                	addiw	a2,a2,1
    80003956:	2485                	addiw	s1,s1,1
    80003958:	fd4618e3          	bne	a2,s4,80003928 <balloc+0x80>
    8000395c:	b759                	j	800038e2 <balloc+0x3a>
  panic("balloc: out of blocks");
    8000395e:	00005517          	auipc	a0,0x5
    80003962:	f1250513          	addi	a0,a0,-238 # 80008870 <syscalls+0x110>
    80003966:	ffffd097          	auipc	ra,0xffffd
    8000396a:	bd8080e7          	jalr	-1064(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000396e:	974a                	add	a4,a4,s2
    80003970:	8fd5                	or	a5,a5,a3
    80003972:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003976:	854a                	mv	a0,s2
    80003978:	00001097          	auipc	ra,0x1
    8000397c:	01a080e7          	jalr	26(ra) # 80004992 <log_write>
        brelse(bp);
    80003980:	854a                	mv	a0,s2
    80003982:	00000097          	auipc	ra,0x0
    80003986:	d94080e7          	jalr	-620(ra) # 80003716 <brelse>
  bp = bread(dev, bno);
    8000398a:	85a6                	mv	a1,s1
    8000398c:	855e                	mv	a0,s7
    8000398e:	00000097          	auipc	ra,0x0
    80003992:	c58080e7          	jalr	-936(ra) # 800035e6 <bread>
    80003996:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003998:	40000613          	li	a2,1024
    8000399c:	4581                	li	a1,0
    8000399e:	05850513          	addi	a0,a0,88
    800039a2:	ffffd097          	auipc	ra,0xffffd
    800039a6:	33e080e7          	jalr	830(ra) # 80000ce0 <memset>
  log_write(bp);
    800039aa:	854a                	mv	a0,s2
    800039ac:	00001097          	auipc	ra,0x1
    800039b0:	fe6080e7          	jalr	-26(ra) # 80004992 <log_write>
  brelse(bp);
    800039b4:	854a                	mv	a0,s2
    800039b6:	00000097          	auipc	ra,0x0
    800039ba:	d60080e7          	jalr	-672(ra) # 80003716 <brelse>
}
    800039be:	8526                	mv	a0,s1
    800039c0:	60e6                	ld	ra,88(sp)
    800039c2:	6446                	ld	s0,80(sp)
    800039c4:	64a6                	ld	s1,72(sp)
    800039c6:	6906                	ld	s2,64(sp)
    800039c8:	79e2                	ld	s3,56(sp)
    800039ca:	7a42                	ld	s4,48(sp)
    800039cc:	7aa2                	ld	s5,40(sp)
    800039ce:	7b02                	ld	s6,32(sp)
    800039d0:	6be2                	ld	s7,24(sp)
    800039d2:	6c42                	ld	s8,16(sp)
    800039d4:	6ca2                	ld	s9,8(sp)
    800039d6:	6125                	addi	sp,sp,96
    800039d8:	8082                	ret

00000000800039da <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800039da:	7179                	addi	sp,sp,-48
    800039dc:	f406                	sd	ra,40(sp)
    800039de:	f022                	sd	s0,32(sp)
    800039e0:	ec26                	sd	s1,24(sp)
    800039e2:	e84a                	sd	s2,16(sp)
    800039e4:	e44e                	sd	s3,8(sp)
    800039e6:	e052                	sd	s4,0(sp)
    800039e8:	1800                	addi	s0,sp,48
    800039ea:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800039ec:	47ad                	li	a5,11
    800039ee:	04b7fe63          	bgeu	a5,a1,80003a4a <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800039f2:	ff45849b          	addiw	s1,a1,-12
    800039f6:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800039fa:	0ff00793          	li	a5,255
    800039fe:	0ae7e363          	bltu	a5,a4,80003aa4 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003a02:	08052583          	lw	a1,128(a0)
    80003a06:	c5ad                	beqz	a1,80003a70 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003a08:	00092503          	lw	a0,0(s2)
    80003a0c:	00000097          	auipc	ra,0x0
    80003a10:	bda080e7          	jalr	-1062(ra) # 800035e6 <bread>
    80003a14:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003a16:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003a1a:	02049593          	slli	a1,s1,0x20
    80003a1e:	9181                	srli	a1,a1,0x20
    80003a20:	058a                	slli	a1,a1,0x2
    80003a22:	00b784b3          	add	s1,a5,a1
    80003a26:	0004a983          	lw	s3,0(s1)
    80003a2a:	04098d63          	beqz	s3,80003a84 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003a2e:	8552                	mv	a0,s4
    80003a30:	00000097          	auipc	ra,0x0
    80003a34:	ce6080e7          	jalr	-794(ra) # 80003716 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003a38:	854e                	mv	a0,s3
    80003a3a:	70a2                	ld	ra,40(sp)
    80003a3c:	7402                	ld	s0,32(sp)
    80003a3e:	64e2                	ld	s1,24(sp)
    80003a40:	6942                	ld	s2,16(sp)
    80003a42:	69a2                	ld	s3,8(sp)
    80003a44:	6a02                	ld	s4,0(sp)
    80003a46:	6145                	addi	sp,sp,48
    80003a48:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003a4a:	02059493          	slli	s1,a1,0x20
    80003a4e:	9081                	srli	s1,s1,0x20
    80003a50:	048a                	slli	s1,s1,0x2
    80003a52:	94aa                	add	s1,s1,a0
    80003a54:	0504a983          	lw	s3,80(s1)
    80003a58:	fe0990e3          	bnez	s3,80003a38 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003a5c:	4108                	lw	a0,0(a0)
    80003a5e:	00000097          	auipc	ra,0x0
    80003a62:	e4a080e7          	jalr	-438(ra) # 800038a8 <balloc>
    80003a66:	0005099b          	sext.w	s3,a0
    80003a6a:	0534a823          	sw	s3,80(s1)
    80003a6e:	b7e9                	j	80003a38 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003a70:	4108                	lw	a0,0(a0)
    80003a72:	00000097          	auipc	ra,0x0
    80003a76:	e36080e7          	jalr	-458(ra) # 800038a8 <balloc>
    80003a7a:	0005059b          	sext.w	a1,a0
    80003a7e:	08b92023          	sw	a1,128(s2)
    80003a82:	b759                	j	80003a08 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003a84:	00092503          	lw	a0,0(s2)
    80003a88:	00000097          	auipc	ra,0x0
    80003a8c:	e20080e7          	jalr	-480(ra) # 800038a8 <balloc>
    80003a90:	0005099b          	sext.w	s3,a0
    80003a94:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003a98:	8552                	mv	a0,s4
    80003a9a:	00001097          	auipc	ra,0x1
    80003a9e:	ef8080e7          	jalr	-264(ra) # 80004992 <log_write>
    80003aa2:	b771                	j	80003a2e <bmap+0x54>
  panic("bmap: out of range");
    80003aa4:	00005517          	auipc	a0,0x5
    80003aa8:	de450513          	addi	a0,a0,-540 # 80008888 <syscalls+0x128>
    80003aac:	ffffd097          	auipc	ra,0xffffd
    80003ab0:	a92080e7          	jalr	-1390(ra) # 8000053e <panic>

0000000080003ab4 <iget>:
{
    80003ab4:	7179                	addi	sp,sp,-48
    80003ab6:	f406                	sd	ra,40(sp)
    80003ab8:	f022                	sd	s0,32(sp)
    80003aba:	ec26                	sd	s1,24(sp)
    80003abc:	e84a                	sd	s2,16(sp)
    80003abe:	e44e                	sd	s3,8(sp)
    80003ac0:	e052                	sd	s4,0(sp)
    80003ac2:	1800                	addi	s0,sp,48
    80003ac4:	89aa                	mv	s3,a0
    80003ac6:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003ac8:	0001c517          	auipc	a0,0x1c
    80003acc:	7c050513          	addi	a0,a0,1984 # 80020288 <itable>
    80003ad0:	ffffd097          	auipc	ra,0xffffd
    80003ad4:	114080e7          	jalr	276(ra) # 80000be4 <acquire>
  empty = 0;
    80003ad8:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003ada:	0001c497          	auipc	s1,0x1c
    80003ade:	7c648493          	addi	s1,s1,1990 # 800202a0 <itable+0x18>
    80003ae2:	0001e697          	auipc	a3,0x1e
    80003ae6:	24e68693          	addi	a3,a3,590 # 80021d30 <log>
    80003aea:	a039                	j	80003af8 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003aec:	02090b63          	beqz	s2,80003b22 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003af0:	08848493          	addi	s1,s1,136
    80003af4:	02d48a63          	beq	s1,a3,80003b28 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003af8:	449c                	lw	a5,8(s1)
    80003afa:	fef059e3          	blez	a5,80003aec <iget+0x38>
    80003afe:	4098                	lw	a4,0(s1)
    80003b00:	ff3716e3          	bne	a4,s3,80003aec <iget+0x38>
    80003b04:	40d8                	lw	a4,4(s1)
    80003b06:	ff4713e3          	bne	a4,s4,80003aec <iget+0x38>
      ip->ref++;
    80003b0a:	2785                	addiw	a5,a5,1
    80003b0c:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003b0e:	0001c517          	auipc	a0,0x1c
    80003b12:	77a50513          	addi	a0,a0,1914 # 80020288 <itable>
    80003b16:	ffffd097          	auipc	ra,0xffffd
    80003b1a:	182080e7          	jalr	386(ra) # 80000c98 <release>
      return ip;
    80003b1e:	8926                	mv	s2,s1
    80003b20:	a03d                	j	80003b4e <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003b22:	f7f9                	bnez	a5,80003af0 <iget+0x3c>
    80003b24:	8926                	mv	s2,s1
    80003b26:	b7e9                	j	80003af0 <iget+0x3c>
  if(empty == 0)
    80003b28:	02090c63          	beqz	s2,80003b60 <iget+0xac>
  ip->dev = dev;
    80003b2c:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003b30:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003b34:	4785                	li	a5,1
    80003b36:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003b3a:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003b3e:	0001c517          	auipc	a0,0x1c
    80003b42:	74a50513          	addi	a0,a0,1866 # 80020288 <itable>
    80003b46:	ffffd097          	auipc	ra,0xffffd
    80003b4a:	152080e7          	jalr	338(ra) # 80000c98 <release>
}
    80003b4e:	854a                	mv	a0,s2
    80003b50:	70a2                	ld	ra,40(sp)
    80003b52:	7402                	ld	s0,32(sp)
    80003b54:	64e2                	ld	s1,24(sp)
    80003b56:	6942                	ld	s2,16(sp)
    80003b58:	69a2                	ld	s3,8(sp)
    80003b5a:	6a02                	ld	s4,0(sp)
    80003b5c:	6145                	addi	sp,sp,48
    80003b5e:	8082                	ret
    panic("iget: no inodes");
    80003b60:	00005517          	auipc	a0,0x5
    80003b64:	d4050513          	addi	a0,a0,-704 # 800088a0 <syscalls+0x140>
    80003b68:	ffffd097          	auipc	ra,0xffffd
    80003b6c:	9d6080e7          	jalr	-1578(ra) # 8000053e <panic>

0000000080003b70 <fsinit>:
fsinit(int dev) {
    80003b70:	7179                	addi	sp,sp,-48
    80003b72:	f406                	sd	ra,40(sp)
    80003b74:	f022                	sd	s0,32(sp)
    80003b76:	ec26                	sd	s1,24(sp)
    80003b78:	e84a                	sd	s2,16(sp)
    80003b7a:	e44e                	sd	s3,8(sp)
    80003b7c:	1800                	addi	s0,sp,48
    80003b7e:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003b80:	4585                	li	a1,1
    80003b82:	00000097          	auipc	ra,0x0
    80003b86:	a64080e7          	jalr	-1436(ra) # 800035e6 <bread>
    80003b8a:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003b8c:	0001c997          	auipc	s3,0x1c
    80003b90:	6dc98993          	addi	s3,s3,1756 # 80020268 <sb>
    80003b94:	02000613          	li	a2,32
    80003b98:	05850593          	addi	a1,a0,88
    80003b9c:	854e                	mv	a0,s3
    80003b9e:	ffffd097          	auipc	ra,0xffffd
    80003ba2:	1a2080e7          	jalr	418(ra) # 80000d40 <memmove>
  brelse(bp);
    80003ba6:	8526                	mv	a0,s1
    80003ba8:	00000097          	auipc	ra,0x0
    80003bac:	b6e080e7          	jalr	-1170(ra) # 80003716 <brelse>
  if(sb.magic != FSMAGIC)
    80003bb0:	0009a703          	lw	a4,0(s3)
    80003bb4:	102037b7          	lui	a5,0x10203
    80003bb8:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003bbc:	02f71263          	bne	a4,a5,80003be0 <fsinit+0x70>
  initlog(dev, &sb);
    80003bc0:	0001c597          	auipc	a1,0x1c
    80003bc4:	6a858593          	addi	a1,a1,1704 # 80020268 <sb>
    80003bc8:	854a                	mv	a0,s2
    80003bca:	00001097          	auipc	ra,0x1
    80003bce:	b4c080e7          	jalr	-1204(ra) # 80004716 <initlog>
}
    80003bd2:	70a2                	ld	ra,40(sp)
    80003bd4:	7402                	ld	s0,32(sp)
    80003bd6:	64e2                	ld	s1,24(sp)
    80003bd8:	6942                	ld	s2,16(sp)
    80003bda:	69a2                	ld	s3,8(sp)
    80003bdc:	6145                	addi	sp,sp,48
    80003bde:	8082                	ret
    panic("invalid file system");
    80003be0:	00005517          	auipc	a0,0x5
    80003be4:	cd050513          	addi	a0,a0,-816 # 800088b0 <syscalls+0x150>
    80003be8:	ffffd097          	auipc	ra,0xffffd
    80003bec:	956080e7          	jalr	-1706(ra) # 8000053e <panic>

0000000080003bf0 <iinit>:
{
    80003bf0:	7179                	addi	sp,sp,-48
    80003bf2:	f406                	sd	ra,40(sp)
    80003bf4:	f022                	sd	s0,32(sp)
    80003bf6:	ec26                	sd	s1,24(sp)
    80003bf8:	e84a                	sd	s2,16(sp)
    80003bfa:	e44e                	sd	s3,8(sp)
    80003bfc:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003bfe:	00005597          	auipc	a1,0x5
    80003c02:	cca58593          	addi	a1,a1,-822 # 800088c8 <syscalls+0x168>
    80003c06:	0001c517          	auipc	a0,0x1c
    80003c0a:	68250513          	addi	a0,a0,1666 # 80020288 <itable>
    80003c0e:	ffffd097          	auipc	ra,0xffffd
    80003c12:	f46080e7          	jalr	-186(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003c16:	0001c497          	auipc	s1,0x1c
    80003c1a:	69a48493          	addi	s1,s1,1690 # 800202b0 <itable+0x28>
    80003c1e:	0001e997          	auipc	s3,0x1e
    80003c22:	12298993          	addi	s3,s3,290 # 80021d40 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003c26:	00005917          	auipc	s2,0x5
    80003c2a:	caa90913          	addi	s2,s2,-854 # 800088d0 <syscalls+0x170>
    80003c2e:	85ca                	mv	a1,s2
    80003c30:	8526                	mv	a0,s1
    80003c32:	00001097          	auipc	ra,0x1
    80003c36:	e46080e7          	jalr	-442(ra) # 80004a78 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003c3a:	08848493          	addi	s1,s1,136
    80003c3e:	ff3498e3          	bne	s1,s3,80003c2e <iinit+0x3e>
}
    80003c42:	70a2                	ld	ra,40(sp)
    80003c44:	7402                	ld	s0,32(sp)
    80003c46:	64e2                	ld	s1,24(sp)
    80003c48:	6942                	ld	s2,16(sp)
    80003c4a:	69a2                	ld	s3,8(sp)
    80003c4c:	6145                	addi	sp,sp,48
    80003c4e:	8082                	ret

0000000080003c50 <ialloc>:
{
    80003c50:	715d                	addi	sp,sp,-80
    80003c52:	e486                	sd	ra,72(sp)
    80003c54:	e0a2                	sd	s0,64(sp)
    80003c56:	fc26                	sd	s1,56(sp)
    80003c58:	f84a                	sd	s2,48(sp)
    80003c5a:	f44e                	sd	s3,40(sp)
    80003c5c:	f052                	sd	s4,32(sp)
    80003c5e:	ec56                	sd	s5,24(sp)
    80003c60:	e85a                	sd	s6,16(sp)
    80003c62:	e45e                	sd	s7,8(sp)
    80003c64:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003c66:	0001c717          	auipc	a4,0x1c
    80003c6a:	60e72703          	lw	a4,1550(a4) # 80020274 <sb+0xc>
    80003c6e:	4785                	li	a5,1
    80003c70:	04e7fa63          	bgeu	a5,a4,80003cc4 <ialloc+0x74>
    80003c74:	8aaa                	mv	s5,a0
    80003c76:	8bae                	mv	s7,a1
    80003c78:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003c7a:	0001ca17          	auipc	s4,0x1c
    80003c7e:	5eea0a13          	addi	s4,s4,1518 # 80020268 <sb>
    80003c82:	00048b1b          	sext.w	s6,s1
    80003c86:	0044d593          	srli	a1,s1,0x4
    80003c8a:	018a2783          	lw	a5,24(s4)
    80003c8e:	9dbd                	addw	a1,a1,a5
    80003c90:	8556                	mv	a0,s5
    80003c92:	00000097          	auipc	ra,0x0
    80003c96:	954080e7          	jalr	-1708(ra) # 800035e6 <bread>
    80003c9a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003c9c:	05850993          	addi	s3,a0,88
    80003ca0:	00f4f793          	andi	a5,s1,15
    80003ca4:	079a                	slli	a5,a5,0x6
    80003ca6:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003ca8:	00099783          	lh	a5,0(s3)
    80003cac:	c785                	beqz	a5,80003cd4 <ialloc+0x84>
    brelse(bp);
    80003cae:	00000097          	auipc	ra,0x0
    80003cb2:	a68080e7          	jalr	-1432(ra) # 80003716 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003cb6:	0485                	addi	s1,s1,1
    80003cb8:	00ca2703          	lw	a4,12(s4)
    80003cbc:	0004879b          	sext.w	a5,s1
    80003cc0:	fce7e1e3          	bltu	a5,a4,80003c82 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003cc4:	00005517          	auipc	a0,0x5
    80003cc8:	c1450513          	addi	a0,a0,-1004 # 800088d8 <syscalls+0x178>
    80003ccc:	ffffd097          	auipc	ra,0xffffd
    80003cd0:	872080e7          	jalr	-1934(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003cd4:	04000613          	li	a2,64
    80003cd8:	4581                	li	a1,0
    80003cda:	854e                	mv	a0,s3
    80003cdc:	ffffd097          	auipc	ra,0xffffd
    80003ce0:	004080e7          	jalr	4(ra) # 80000ce0 <memset>
      dip->type = type;
    80003ce4:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003ce8:	854a                	mv	a0,s2
    80003cea:	00001097          	auipc	ra,0x1
    80003cee:	ca8080e7          	jalr	-856(ra) # 80004992 <log_write>
      brelse(bp);
    80003cf2:	854a                	mv	a0,s2
    80003cf4:	00000097          	auipc	ra,0x0
    80003cf8:	a22080e7          	jalr	-1502(ra) # 80003716 <brelse>
      return iget(dev, inum);
    80003cfc:	85da                	mv	a1,s6
    80003cfe:	8556                	mv	a0,s5
    80003d00:	00000097          	auipc	ra,0x0
    80003d04:	db4080e7          	jalr	-588(ra) # 80003ab4 <iget>
}
    80003d08:	60a6                	ld	ra,72(sp)
    80003d0a:	6406                	ld	s0,64(sp)
    80003d0c:	74e2                	ld	s1,56(sp)
    80003d0e:	7942                	ld	s2,48(sp)
    80003d10:	79a2                	ld	s3,40(sp)
    80003d12:	7a02                	ld	s4,32(sp)
    80003d14:	6ae2                	ld	s5,24(sp)
    80003d16:	6b42                	ld	s6,16(sp)
    80003d18:	6ba2                	ld	s7,8(sp)
    80003d1a:	6161                	addi	sp,sp,80
    80003d1c:	8082                	ret

0000000080003d1e <iupdate>:
{
    80003d1e:	1101                	addi	sp,sp,-32
    80003d20:	ec06                	sd	ra,24(sp)
    80003d22:	e822                	sd	s0,16(sp)
    80003d24:	e426                	sd	s1,8(sp)
    80003d26:	e04a                	sd	s2,0(sp)
    80003d28:	1000                	addi	s0,sp,32
    80003d2a:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003d2c:	415c                	lw	a5,4(a0)
    80003d2e:	0047d79b          	srliw	a5,a5,0x4
    80003d32:	0001c597          	auipc	a1,0x1c
    80003d36:	54e5a583          	lw	a1,1358(a1) # 80020280 <sb+0x18>
    80003d3a:	9dbd                	addw	a1,a1,a5
    80003d3c:	4108                	lw	a0,0(a0)
    80003d3e:	00000097          	auipc	ra,0x0
    80003d42:	8a8080e7          	jalr	-1880(ra) # 800035e6 <bread>
    80003d46:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003d48:	05850793          	addi	a5,a0,88
    80003d4c:	40c8                	lw	a0,4(s1)
    80003d4e:	893d                	andi	a0,a0,15
    80003d50:	051a                	slli	a0,a0,0x6
    80003d52:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003d54:	04449703          	lh	a4,68(s1)
    80003d58:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003d5c:	04649703          	lh	a4,70(s1)
    80003d60:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003d64:	04849703          	lh	a4,72(s1)
    80003d68:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003d6c:	04a49703          	lh	a4,74(s1)
    80003d70:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003d74:	44f8                	lw	a4,76(s1)
    80003d76:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003d78:	03400613          	li	a2,52
    80003d7c:	05048593          	addi	a1,s1,80
    80003d80:	0531                	addi	a0,a0,12
    80003d82:	ffffd097          	auipc	ra,0xffffd
    80003d86:	fbe080e7          	jalr	-66(ra) # 80000d40 <memmove>
  log_write(bp);
    80003d8a:	854a                	mv	a0,s2
    80003d8c:	00001097          	auipc	ra,0x1
    80003d90:	c06080e7          	jalr	-1018(ra) # 80004992 <log_write>
  brelse(bp);
    80003d94:	854a                	mv	a0,s2
    80003d96:	00000097          	auipc	ra,0x0
    80003d9a:	980080e7          	jalr	-1664(ra) # 80003716 <brelse>
}
    80003d9e:	60e2                	ld	ra,24(sp)
    80003da0:	6442                	ld	s0,16(sp)
    80003da2:	64a2                	ld	s1,8(sp)
    80003da4:	6902                	ld	s2,0(sp)
    80003da6:	6105                	addi	sp,sp,32
    80003da8:	8082                	ret

0000000080003daa <idup>:
{
    80003daa:	1101                	addi	sp,sp,-32
    80003dac:	ec06                	sd	ra,24(sp)
    80003dae:	e822                	sd	s0,16(sp)
    80003db0:	e426                	sd	s1,8(sp)
    80003db2:	1000                	addi	s0,sp,32
    80003db4:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003db6:	0001c517          	auipc	a0,0x1c
    80003dba:	4d250513          	addi	a0,a0,1234 # 80020288 <itable>
    80003dbe:	ffffd097          	auipc	ra,0xffffd
    80003dc2:	e26080e7          	jalr	-474(ra) # 80000be4 <acquire>
  ip->ref++;
    80003dc6:	449c                	lw	a5,8(s1)
    80003dc8:	2785                	addiw	a5,a5,1
    80003dca:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003dcc:	0001c517          	auipc	a0,0x1c
    80003dd0:	4bc50513          	addi	a0,a0,1212 # 80020288 <itable>
    80003dd4:	ffffd097          	auipc	ra,0xffffd
    80003dd8:	ec4080e7          	jalr	-316(ra) # 80000c98 <release>
}
    80003ddc:	8526                	mv	a0,s1
    80003dde:	60e2                	ld	ra,24(sp)
    80003de0:	6442                	ld	s0,16(sp)
    80003de2:	64a2                	ld	s1,8(sp)
    80003de4:	6105                	addi	sp,sp,32
    80003de6:	8082                	ret

0000000080003de8 <ilock>:
{
    80003de8:	1101                	addi	sp,sp,-32
    80003dea:	ec06                	sd	ra,24(sp)
    80003dec:	e822                	sd	s0,16(sp)
    80003dee:	e426                	sd	s1,8(sp)
    80003df0:	e04a                	sd	s2,0(sp)
    80003df2:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003df4:	c115                	beqz	a0,80003e18 <ilock+0x30>
    80003df6:	84aa                	mv	s1,a0
    80003df8:	451c                	lw	a5,8(a0)
    80003dfa:	00f05f63          	blez	a5,80003e18 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003dfe:	0541                	addi	a0,a0,16
    80003e00:	00001097          	auipc	ra,0x1
    80003e04:	cb2080e7          	jalr	-846(ra) # 80004ab2 <acquiresleep>
  if(ip->valid == 0){
    80003e08:	40bc                	lw	a5,64(s1)
    80003e0a:	cf99                	beqz	a5,80003e28 <ilock+0x40>
}
    80003e0c:	60e2                	ld	ra,24(sp)
    80003e0e:	6442                	ld	s0,16(sp)
    80003e10:	64a2                	ld	s1,8(sp)
    80003e12:	6902                	ld	s2,0(sp)
    80003e14:	6105                	addi	sp,sp,32
    80003e16:	8082                	ret
    panic("ilock");
    80003e18:	00005517          	auipc	a0,0x5
    80003e1c:	ad850513          	addi	a0,a0,-1320 # 800088f0 <syscalls+0x190>
    80003e20:	ffffc097          	auipc	ra,0xffffc
    80003e24:	71e080e7          	jalr	1822(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003e28:	40dc                	lw	a5,4(s1)
    80003e2a:	0047d79b          	srliw	a5,a5,0x4
    80003e2e:	0001c597          	auipc	a1,0x1c
    80003e32:	4525a583          	lw	a1,1106(a1) # 80020280 <sb+0x18>
    80003e36:	9dbd                	addw	a1,a1,a5
    80003e38:	4088                	lw	a0,0(s1)
    80003e3a:	fffff097          	auipc	ra,0xfffff
    80003e3e:	7ac080e7          	jalr	1964(ra) # 800035e6 <bread>
    80003e42:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003e44:	05850593          	addi	a1,a0,88
    80003e48:	40dc                	lw	a5,4(s1)
    80003e4a:	8bbd                	andi	a5,a5,15
    80003e4c:	079a                	slli	a5,a5,0x6
    80003e4e:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003e50:	00059783          	lh	a5,0(a1)
    80003e54:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003e58:	00259783          	lh	a5,2(a1)
    80003e5c:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003e60:	00459783          	lh	a5,4(a1)
    80003e64:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003e68:	00659783          	lh	a5,6(a1)
    80003e6c:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003e70:	459c                	lw	a5,8(a1)
    80003e72:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003e74:	03400613          	li	a2,52
    80003e78:	05b1                	addi	a1,a1,12
    80003e7a:	05048513          	addi	a0,s1,80
    80003e7e:	ffffd097          	auipc	ra,0xffffd
    80003e82:	ec2080e7          	jalr	-318(ra) # 80000d40 <memmove>
    brelse(bp);
    80003e86:	854a                	mv	a0,s2
    80003e88:	00000097          	auipc	ra,0x0
    80003e8c:	88e080e7          	jalr	-1906(ra) # 80003716 <brelse>
    ip->valid = 1;
    80003e90:	4785                	li	a5,1
    80003e92:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003e94:	04449783          	lh	a5,68(s1)
    80003e98:	fbb5                	bnez	a5,80003e0c <ilock+0x24>
      panic("ilock: no type");
    80003e9a:	00005517          	auipc	a0,0x5
    80003e9e:	a5e50513          	addi	a0,a0,-1442 # 800088f8 <syscalls+0x198>
    80003ea2:	ffffc097          	auipc	ra,0xffffc
    80003ea6:	69c080e7          	jalr	1692(ra) # 8000053e <panic>

0000000080003eaa <iunlock>:
{
    80003eaa:	1101                	addi	sp,sp,-32
    80003eac:	ec06                	sd	ra,24(sp)
    80003eae:	e822                	sd	s0,16(sp)
    80003eb0:	e426                	sd	s1,8(sp)
    80003eb2:	e04a                	sd	s2,0(sp)
    80003eb4:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003eb6:	c905                	beqz	a0,80003ee6 <iunlock+0x3c>
    80003eb8:	84aa                	mv	s1,a0
    80003eba:	01050913          	addi	s2,a0,16
    80003ebe:	854a                	mv	a0,s2
    80003ec0:	00001097          	auipc	ra,0x1
    80003ec4:	c8c080e7          	jalr	-884(ra) # 80004b4c <holdingsleep>
    80003ec8:	cd19                	beqz	a0,80003ee6 <iunlock+0x3c>
    80003eca:	449c                	lw	a5,8(s1)
    80003ecc:	00f05d63          	blez	a5,80003ee6 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003ed0:	854a                	mv	a0,s2
    80003ed2:	00001097          	auipc	ra,0x1
    80003ed6:	c36080e7          	jalr	-970(ra) # 80004b08 <releasesleep>
}
    80003eda:	60e2                	ld	ra,24(sp)
    80003edc:	6442                	ld	s0,16(sp)
    80003ede:	64a2                	ld	s1,8(sp)
    80003ee0:	6902                	ld	s2,0(sp)
    80003ee2:	6105                	addi	sp,sp,32
    80003ee4:	8082                	ret
    panic("iunlock");
    80003ee6:	00005517          	auipc	a0,0x5
    80003eea:	a2250513          	addi	a0,a0,-1502 # 80008908 <syscalls+0x1a8>
    80003eee:	ffffc097          	auipc	ra,0xffffc
    80003ef2:	650080e7          	jalr	1616(ra) # 8000053e <panic>

0000000080003ef6 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003ef6:	7179                	addi	sp,sp,-48
    80003ef8:	f406                	sd	ra,40(sp)
    80003efa:	f022                	sd	s0,32(sp)
    80003efc:	ec26                	sd	s1,24(sp)
    80003efe:	e84a                	sd	s2,16(sp)
    80003f00:	e44e                	sd	s3,8(sp)
    80003f02:	e052                	sd	s4,0(sp)
    80003f04:	1800                	addi	s0,sp,48
    80003f06:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003f08:	05050493          	addi	s1,a0,80
    80003f0c:	08050913          	addi	s2,a0,128
    80003f10:	a021                	j	80003f18 <itrunc+0x22>
    80003f12:	0491                	addi	s1,s1,4
    80003f14:	01248d63          	beq	s1,s2,80003f2e <itrunc+0x38>
    if(ip->addrs[i]){
    80003f18:	408c                	lw	a1,0(s1)
    80003f1a:	dde5                	beqz	a1,80003f12 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003f1c:	0009a503          	lw	a0,0(s3)
    80003f20:	00000097          	auipc	ra,0x0
    80003f24:	90c080e7          	jalr	-1780(ra) # 8000382c <bfree>
      ip->addrs[i] = 0;
    80003f28:	0004a023          	sw	zero,0(s1)
    80003f2c:	b7dd                	j	80003f12 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003f2e:	0809a583          	lw	a1,128(s3)
    80003f32:	e185                	bnez	a1,80003f52 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003f34:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003f38:	854e                	mv	a0,s3
    80003f3a:	00000097          	auipc	ra,0x0
    80003f3e:	de4080e7          	jalr	-540(ra) # 80003d1e <iupdate>
}
    80003f42:	70a2                	ld	ra,40(sp)
    80003f44:	7402                	ld	s0,32(sp)
    80003f46:	64e2                	ld	s1,24(sp)
    80003f48:	6942                	ld	s2,16(sp)
    80003f4a:	69a2                	ld	s3,8(sp)
    80003f4c:	6a02                	ld	s4,0(sp)
    80003f4e:	6145                	addi	sp,sp,48
    80003f50:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003f52:	0009a503          	lw	a0,0(s3)
    80003f56:	fffff097          	auipc	ra,0xfffff
    80003f5a:	690080e7          	jalr	1680(ra) # 800035e6 <bread>
    80003f5e:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003f60:	05850493          	addi	s1,a0,88
    80003f64:	45850913          	addi	s2,a0,1112
    80003f68:	a811                	j	80003f7c <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003f6a:	0009a503          	lw	a0,0(s3)
    80003f6e:	00000097          	auipc	ra,0x0
    80003f72:	8be080e7          	jalr	-1858(ra) # 8000382c <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003f76:	0491                	addi	s1,s1,4
    80003f78:	01248563          	beq	s1,s2,80003f82 <itrunc+0x8c>
      if(a[j])
    80003f7c:	408c                	lw	a1,0(s1)
    80003f7e:	dde5                	beqz	a1,80003f76 <itrunc+0x80>
    80003f80:	b7ed                	j	80003f6a <itrunc+0x74>
    brelse(bp);
    80003f82:	8552                	mv	a0,s4
    80003f84:	fffff097          	auipc	ra,0xfffff
    80003f88:	792080e7          	jalr	1938(ra) # 80003716 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003f8c:	0809a583          	lw	a1,128(s3)
    80003f90:	0009a503          	lw	a0,0(s3)
    80003f94:	00000097          	auipc	ra,0x0
    80003f98:	898080e7          	jalr	-1896(ra) # 8000382c <bfree>
    ip->addrs[NDIRECT] = 0;
    80003f9c:	0809a023          	sw	zero,128(s3)
    80003fa0:	bf51                	j	80003f34 <itrunc+0x3e>

0000000080003fa2 <iput>:
{
    80003fa2:	1101                	addi	sp,sp,-32
    80003fa4:	ec06                	sd	ra,24(sp)
    80003fa6:	e822                	sd	s0,16(sp)
    80003fa8:	e426                	sd	s1,8(sp)
    80003faa:	e04a                	sd	s2,0(sp)
    80003fac:	1000                	addi	s0,sp,32
    80003fae:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003fb0:	0001c517          	auipc	a0,0x1c
    80003fb4:	2d850513          	addi	a0,a0,728 # 80020288 <itable>
    80003fb8:	ffffd097          	auipc	ra,0xffffd
    80003fbc:	c2c080e7          	jalr	-980(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003fc0:	4498                	lw	a4,8(s1)
    80003fc2:	4785                	li	a5,1
    80003fc4:	02f70363          	beq	a4,a5,80003fea <iput+0x48>
  ip->ref--;
    80003fc8:	449c                	lw	a5,8(s1)
    80003fca:	37fd                	addiw	a5,a5,-1
    80003fcc:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003fce:	0001c517          	auipc	a0,0x1c
    80003fd2:	2ba50513          	addi	a0,a0,698 # 80020288 <itable>
    80003fd6:	ffffd097          	auipc	ra,0xffffd
    80003fda:	cc2080e7          	jalr	-830(ra) # 80000c98 <release>
}
    80003fde:	60e2                	ld	ra,24(sp)
    80003fe0:	6442                	ld	s0,16(sp)
    80003fe2:	64a2                	ld	s1,8(sp)
    80003fe4:	6902                	ld	s2,0(sp)
    80003fe6:	6105                	addi	sp,sp,32
    80003fe8:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003fea:	40bc                	lw	a5,64(s1)
    80003fec:	dff1                	beqz	a5,80003fc8 <iput+0x26>
    80003fee:	04a49783          	lh	a5,74(s1)
    80003ff2:	fbf9                	bnez	a5,80003fc8 <iput+0x26>
    acquiresleep(&ip->lock);
    80003ff4:	01048913          	addi	s2,s1,16
    80003ff8:	854a                	mv	a0,s2
    80003ffa:	00001097          	auipc	ra,0x1
    80003ffe:	ab8080e7          	jalr	-1352(ra) # 80004ab2 <acquiresleep>
    release(&itable.lock);
    80004002:	0001c517          	auipc	a0,0x1c
    80004006:	28650513          	addi	a0,a0,646 # 80020288 <itable>
    8000400a:	ffffd097          	auipc	ra,0xffffd
    8000400e:	c8e080e7          	jalr	-882(ra) # 80000c98 <release>
    itrunc(ip);
    80004012:	8526                	mv	a0,s1
    80004014:	00000097          	auipc	ra,0x0
    80004018:	ee2080e7          	jalr	-286(ra) # 80003ef6 <itrunc>
    ip->type = 0;
    8000401c:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80004020:	8526                	mv	a0,s1
    80004022:	00000097          	auipc	ra,0x0
    80004026:	cfc080e7          	jalr	-772(ra) # 80003d1e <iupdate>
    ip->valid = 0;
    8000402a:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000402e:	854a                	mv	a0,s2
    80004030:	00001097          	auipc	ra,0x1
    80004034:	ad8080e7          	jalr	-1320(ra) # 80004b08 <releasesleep>
    acquire(&itable.lock);
    80004038:	0001c517          	auipc	a0,0x1c
    8000403c:	25050513          	addi	a0,a0,592 # 80020288 <itable>
    80004040:	ffffd097          	auipc	ra,0xffffd
    80004044:	ba4080e7          	jalr	-1116(ra) # 80000be4 <acquire>
    80004048:	b741                	j	80003fc8 <iput+0x26>

000000008000404a <iunlockput>:
{
    8000404a:	1101                	addi	sp,sp,-32
    8000404c:	ec06                	sd	ra,24(sp)
    8000404e:	e822                	sd	s0,16(sp)
    80004050:	e426                	sd	s1,8(sp)
    80004052:	1000                	addi	s0,sp,32
    80004054:	84aa                	mv	s1,a0
  iunlock(ip);
    80004056:	00000097          	auipc	ra,0x0
    8000405a:	e54080e7          	jalr	-428(ra) # 80003eaa <iunlock>
  iput(ip);
    8000405e:	8526                	mv	a0,s1
    80004060:	00000097          	auipc	ra,0x0
    80004064:	f42080e7          	jalr	-190(ra) # 80003fa2 <iput>
}
    80004068:	60e2                	ld	ra,24(sp)
    8000406a:	6442                	ld	s0,16(sp)
    8000406c:	64a2                	ld	s1,8(sp)
    8000406e:	6105                	addi	sp,sp,32
    80004070:	8082                	ret

0000000080004072 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80004072:	1141                	addi	sp,sp,-16
    80004074:	e422                	sd	s0,8(sp)
    80004076:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80004078:	411c                	lw	a5,0(a0)
    8000407a:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    8000407c:	415c                	lw	a5,4(a0)
    8000407e:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80004080:	04451783          	lh	a5,68(a0)
    80004084:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80004088:	04a51783          	lh	a5,74(a0)
    8000408c:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80004090:	04c56783          	lwu	a5,76(a0)
    80004094:	e99c                	sd	a5,16(a1)
}
    80004096:	6422                	ld	s0,8(sp)
    80004098:	0141                	addi	sp,sp,16
    8000409a:	8082                	ret

000000008000409c <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000409c:	457c                	lw	a5,76(a0)
    8000409e:	0ed7e963          	bltu	a5,a3,80004190 <readi+0xf4>
{
    800040a2:	7159                	addi	sp,sp,-112
    800040a4:	f486                	sd	ra,104(sp)
    800040a6:	f0a2                	sd	s0,96(sp)
    800040a8:	eca6                	sd	s1,88(sp)
    800040aa:	e8ca                	sd	s2,80(sp)
    800040ac:	e4ce                	sd	s3,72(sp)
    800040ae:	e0d2                	sd	s4,64(sp)
    800040b0:	fc56                	sd	s5,56(sp)
    800040b2:	f85a                	sd	s6,48(sp)
    800040b4:	f45e                	sd	s7,40(sp)
    800040b6:	f062                	sd	s8,32(sp)
    800040b8:	ec66                	sd	s9,24(sp)
    800040ba:	e86a                	sd	s10,16(sp)
    800040bc:	e46e                	sd	s11,8(sp)
    800040be:	1880                	addi	s0,sp,112
    800040c0:	8baa                	mv	s7,a0
    800040c2:	8c2e                	mv	s8,a1
    800040c4:	8ab2                	mv	s5,a2
    800040c6:	84b6                	mv	s1,a3
    800040c8:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800040ca:	9f35                	addw	a4,a4,a3
    return 0;
    800040cc:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800040ce:	0ad76063          	bltu	a4,a3,8000416e <readi+0xd2>
  if(off + n > ip->size)
    800040d2:	00e7f463          	bgeu	a5,a4,800040da <readi+0x3e>
    n = ip->size - off;
    800040d6:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800040da:	0a0b0963          	beqz	s6,8000418c <readi+0xf0>
    800040de:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800040e0:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800040e4:	5cfd                	li	s9,-1
    800040e6:	a82d                	j	80004120 <readi+0x84>
    800040e8:	020a1d93          	slli	s11,s4,0x20
    800040ec:	020ddd93          	srli	s11,s11,0x20
    800040f0:	05890613          	addi	a2,s2,88
    800040f4:	86ee                	mv	a3,s11
    800040f6:	963a                	add	a2,a2,a4
    800040f8:	85d6                	mv	a1,s5
    800040fa:	8562                	mv	a0,s8
    800040fc:	ffffe097          	auipc	ra,0xffffe
    80004100:	4c8080e7          	jalr	1224(ra) # 800025c4 <either_copyout>
    80004104:	05950d63          	beq	a0,s9,8000415e <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004108:	854a                	mv	a0,s2
    8000410a:	fffff097          	auipc	ra,0xfffff
    8000410e:	60c080e7          	jalr	1548(ra) # 80003716 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004112:	013a09bb          	addw	s3,s4,s3
    80004116:	009a04bb          	addw	s1,s4,s1
    8000411a:	9aee                	add	s5,s5,s11
    8000411c:	0569f763          	bgeu	s3,s6,8000416a <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004120:	000ba903          	lw	s2,0(s7)
    80004124:	00a4d59b          	srliw	a1,s1,0xa
    80004128:	855e                	mv	a0,s7
    8000412a:	00000097          	auipc	ra,0x0
    8000412e:	8b0080e7          	jalr	-1872(ra) # 800039da <bmap>
    80004132:	0005059b          	sext.w	a1,a0
    80004136:	854a                	mv	a0,s2
    80004138:	fffff097          	auipc	ra,0xfffff
    8000413c:	4ae080e7          	jalr	1198(ra) # 800035e6 <bread>
    80004140:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004142:	3ff4f713          	andi	a4,s1,1023
    80004146:	40ed07bb          	subw	a5,s10,a4
    8000414a:	413b06bb          	subw	a3,s6,s3
    8000414e:	8a3e                	mv	s4,a5
    80004150:	2781                	sext.w	a5,a5
    80004152:	0006861b          	sext.w	a2,a3
    80004156:	f8f679e3          	bgeu	a2,a5,800040e8 <readi+0x4c>
    8000415a:	8a36                	mv	s4,a3
    8000415c:	b771                	j	800040e8 <readi+0x4c>
      brelse(bp);
    8000415e:	854a                	mv	a0,s2
    80004160:	fffff097          	auipc	ra,0xfffff
    80004164:	5b6080e7          	jalr	1462(ra) # 80003716 <brelse>
      tot = -1;
    80004168:	59fd                	li	s3,-1
  }
  return tot;
    8000416a:	0009851b          	sext.w	a0,s3
}
    8000416e:	70a6                	ld	ra,104(sp)
    80004170:	7406                	ld	s0,96(sp)
    80004172:	64e6                	ld	s1,88(sp)
    80004174:	6946                	ld	s2,80(sp)
    80004176:	69a6                	ld	s3,72(sp)
    80004178:	6a06                	ld	s4,64(sp)
    8000417a:	7ae2                	ld	s5,56(sp)
    8000417c:	7b42                	ld	s6,48(sp)
    8000417e:	7ba2                	ld	s7,40(sp)
    80004180:	7c02                	ld	s8,32(sp)
    80004182:	6ce2                	ld	s9,24(sp)
    80004184:	6d42                	ld	s10,16(sp)
    80004186:	6da2                	ld	s11,8(sp)
    80004188:	6165                	addi	sp,sp,112
    8000418a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000418c:	89da                	mv	s3,s6
    8000418e:	bff1                	j	8000416a <readi+0xce>
    return 0;
    80004190:	4501                	li	a0,0
}
    80004192:	8082                	ret

0000000080004194 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004194:	457c                	lw	a5,76(a0)
    80004196:	10d7e863          	bltu	a5,a3,800042a6 <writei+0x112>
{
    8000419a:	7159                	addi	sp,sp,-112
    8000419c:	f486                	sd	ra,104(sp)
    8000419e:	f0a2                	sd	s0,96(sp)
    800041a0:	eca6                	sd	s1,88(sp)
    800041a2:	e8ca                	sd	s2,80(sp)
    800041a4:	e4ce                	sd	s3,72(sp)
    800041a6:	e0d2                	sd	s4,64(sp)
    800041a8:	fc56                	sd	s5,56(sp)
    800041aa:	f85a                	sd	s6,48(sp)
    800041ac:	f45e                	sd	s7,40(sp)
    800041ae:	f062                	sd	s8,32(sp)
    800041b0:	ec66                	sd	s9,24(sp)
    800041b2:	e86a                	sd	s10,16(sp)
    800041b4:	e46e                	sd	s11,8(sp)
    800041b6:	1880                	addi	s0,sp,112
    800041b8:	8b2a                	mv	s6,a0
    800041ba:	8c2e                	mv	s8,a1
    800041bc:	8ab2                	mv	s5,a2
    800041be:	8936                	mv	s2,a3
    800041c0:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    800041c2:	00e687bb          	addw	a5,a3,a4
    800041c6:	0ed7e263          	bltu	a5,a3,800042aa <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800041ca:	00043737          	lui	a4,0x43
    800041ce:	0ef76063          	bltu	a4,a5,800042ae <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800041d2:	0c0b8863          	beqz	s7,800042a2 <writei+0x10e>
    800041d6:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800041d8:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800041dc:	5cfd                	li	s9,-1
    800041de:	a091                	j	80004222 <writei+0x8e>
    800041e0:	02099d93          	slli	s11,s3,0x20
    800041e4:	020ddd93          	srli	s11,s11,0x20
    800041e8:	05848513          	addi	a0,s1,88
    800041ec:	86ee                	mv	a3,s11
    800041ee:	8656                	mv	a2,s5
    800041f0:	85e2                	mv	a1,s8
    800041f2:	953a                	add	a0,a0,a4
    800041f4:	ffffe097          	auipc	ra,0xffffe
    800041f8:	426080e7          	jalr	1062(ra) # 8000261a <either_copyin>
    800041fc:	07950263          	beq	a0,s9,80004260 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004200:	8526                	mv	a0,s1
    80004202:	00000097          	auipc	ra,0x0
    80004206:	790080e7          	jalr	1936(ra) # 80004992 <log_write>
    brelse(bp);
    8000420a:	8526                	mv	a0,s1
    8000420c:	fffff097          	auipc	ra,0xfffff
    80004210:	50a080e7          	jalr	1290(ra) # 80003716 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004214:	01498a3b          	addw	s4,s3,s4
    80004218:	0129893b          	addw	s2,s3,s2
    8000421c:	9aee                	add	s5,s5,s11
    8000421e:	057a7663          	bgeu	s4,s7,8000426a <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004222:	000b2483          	lw	s1,0(s6)
    80004226:	00a9559b          	srliw	a1,s2,0xa
    8000422a:	855a                	mv	a0,s6
    8000422c:	fffff097          	auipc	ra,0xfffff
    80004230:	7ae080e7          	jalr	1966(ra) # 800039da <bmap>
    80004234:	0005059b          	sext.w	a1,a0
    80004238:	8526                	mv	a0,s1
    8000423a:	fffff097          	auipc	ra,0xfffff
    8000423e:	3ac080e7          	jalr	940(ra) # 800035e6 <bread>
    80004242:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004244:	3ff97713          	andi	a4,s2,1023
    80004248:	40ed07bb          	subw	a5,s10,a4
    8000424c:	414b86bb          	subw	a3,s7,s4
    80004250:	89be                	mv	s3,a5
    80004252:	2781                	sext.w	a5,a5
    80004254:	0006861b          	sext.w	a2,a3
    80004258:	f8f674e3          	bgeu	a2,a5,800041e0 <writei+0x4c>
    8000425c:	89b6                	mv	s3,a3
    8000425e:	b749                	j	800041e0 <writei+0x4c>
      brelse(bp);
    80004260:	8526                	mv	a0,s1
    80004262:	fffff097          	auipc	ra,0xfffff
    80004266:	4b4080e7          	jalr	1204(ra) # 80003716 <brelse>
  }

  if(off > ip->size)
    8000426a:	04cb2783          	lw	a5,76(s6)
    8000426e:	0127f463          	bgeu	a5,s2,80004276 <writei+0xe2>
    ip->size = off;
    80004272:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004276:	855a                	mv	a0,s6
    80004278:	00000097          	auipc	ra,0x0
    8000427c:	aa6080e7          	jalr	-1370(ra) # 80003d1e <iupdate>

  return tot;
    80004280:	000a051b          	sext.w	a0,s4
}
    80004284:	70a6                	ld	ra,104(sp)
    80004286:	7406                	ld	s0,96(sp)
    80004288:	64e6                	ld	s1,88(sp)
    8000428a:	6946                	ld	s2,80(sp)
    8000428c:	69a6                	ld	s3,72(sp)
    8000428e:	6a06                	ld	s4,64(sp)
    80004290:	7ae2                	ld	s5,56(sp)
    80004292:	7b42                	ld	s6,48(sp)
    80004294:	7ba2                	ld	s7,40(sp)
    80004296:	7c02                	ld	s8,32(sp)
    80004298:	6ce2                	ld	s9,24(sp)
    8000429a:	6d42                	ld	s10,16(sp)
    8000429c:	6da2                	ld	s11,8(sp)
    8000429e:	6165                	addi	sp,sp,112
    800042a0:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800042a2:	8a5e                	mv	s4,s7
    800042a4:	bfc9                	j	80004276 <writei+0xe2>
    return -1;
    800042a6:	557d                	li	a0,-1
}
    800042a8:	8082                	ret
    return -1;
    800042aa:	557d                	li	a0,-1
    800042ac:	bfe1                	j	80004284 <writei+0xf0>
    return -1;
    800042ae:	557d                	li	a0,-1
    800042b0:	bfd1                	j	80004284 <writei+0xf0>

00000000800042b2 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800042b2:	1141                	addi	sp,sp,-16
    800042b4:	e406                	sd	ra,8(sp)
    800042b6:	e022                	sd	s0,0(sp)
    800042b8:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800042ba:	4639                	li	a2,14
    800042bc:	ffffd097          	auipc	ra,0xffffd
    800042c0:	afc080e7          	jalr	-1284(ra) # 80000db8 <strncmp>
}
    800042c4:	60a2                	ld	ra,8(sp)
    800042c6:	6402                	ld	s0,0(sp)
    800042c8:	0141                	addi	sp,sp,16
    800042ca:	8082                	ret

00000000800042cc <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800042cc:	7139                	addi	sp,sp,-64
    800042ce:	fc06                	sd	ra,56(sp)
    800042d0:	f822                	sd	s0,48(sp)
    800042d2:	f426                	sd	s1,40(sp)
    800042d4:	f04a                	sd	s2,32(sp)
    800042d6:	ec4e                	sd	s3,24(sp)
    800042d8:	e852                	sd	s4,16(sp)
    800042da:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800042dc:	04451703          	lh	a4,68(a0)
    800042e0:	4785                	li	a5,1
    800042e2:	00f71a63          	bne	a4,a5,800042f6 <dirlookup+0x2a>
    800042e6:	892a                	mv	s2,a0
    800042e8:	89ae                	mv	s3,a1
    800042ea:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800042ec:	457c                	lw	a5,76(a0)
    800042ee:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800042f0:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042f2:	e79d                	bnez	a5,80004320 <dirlookup+0x54>
    800042f4:	a8a5                	j	8000436c <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800042f6:	00004517          	auipc	a0,0x4
    800042fa:	61a50513          	addi	a0,a0,1562 # 80008910 <syscalls+0x1b0>
    800042fe:	ffffc097          	auipc	ra,0xffffc
    80004302:	240080e7          	jalr	576(ra) # 8000053e <panic>
      panic("dirlookup read");
    80004306:	00004517          	auipc	a0,0x4
    8000430a:	62250513          	addi	a0,a0,1570 # 80008928 <syscalls+0x1c8>
    8000430e:	ffffc097          	auipc	ra,0xffffc
    80004312:	230080e7          	jalr	560(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004316:	24c1                	addiw	s1,s1,16
    80004318:	04c92783          	lw	a5,76(s2)
    8000431c:	04f4f763          	bgeu	s1,a5,8000436a <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004320:	4741                	li	a4,16
    80004322:	86a6                	mv	a3,s1
    80004324:	fc040613          	addi	a2,s0,-64
    80004328:	4581                	li	a1,0
    8000432a:	854a                	mv	a0,s2
    8000432c:	00000097          	auipc	ra,0x0
    80004330:	d70080e7          	jalr	-656(ra) # 8000409c <readi>
    80004334:	47c1                	li	a5,16
    80004336:	fcf518e3          	bne	a0,a5,80004306 <dirlookup+0x3a>
    if(de.inum == 0)
    8000433a:	fc045783          	lhu	a5,-64(s0)
    8000433e:	dfe1                	beqz	a5,80004316 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004340:	fc240593          	addi	a1,s0,-62
    80004344:	854e                	mv	a0,s3
    80004346:	00000097          	auipc	ra,0x0
    8000434a:	f6c080e7          	jalr	-148(ra) # 800042b2 <namecmp>
    8000434e:	f561                	bnez	a0,80004316 <dirlookup+0x4a>
      if(poff)
    80004350:	000a0463          	beqz	s4,80004358 <dirlookup+0x8c>
        *poff = off;
    80004354:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004358:	fc045583          	lhu	a1,-64(s0)
    8000435c:	00092503          	lw	a0,0(s2)
    80004360:	fffff097          	auipc	ra,0xfffff
    80004364:	754080e7          	jalr	1876(ra) # 80003ab4 <iget>
    80004368:	a011                	j	8000436c <dirlookup+0xa0>
  return 0;
    8000436a:	4501                	li	a0,0
}
    8000436c:	70e2                	ld	ra,56(sp)
    8000436e:	7442                	ld	s0,48(sp)
    80004370:	74a2                	ld	s1,40(sp)
    80004372:	7902                	ld	s2,32(sp)
    80004374:	69e2                	ld	s3,24(sp)
    80004376:	6a42                	ld	s4,16(sp)
    80004378:	6121                	addi	sp,sp,64
    8000437a:	8082                	ret

000000008000437c <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    8000437c:	711d                	addi	sp,sp,-96
    8000437e:	ec86                	sd	ra,88(sp)
    80004380:	e8a2                	sd	s0,80(sp)
    80004382:	e4a6                	sd	s1,72(sp)
    80004384:	e0ca                	sd	s2,64(sp)
    80004386:	fc4e                	sd	s3,56(sp)
    80004388:	f852                	sd	s4,48(sp)
    8000438a:	f456                	sd	s5,40(sp)
    8000438c:	f05a                	sd	s6,32(sp)
    8000438e:	ec5e                	sd	s7,24(sp)
    80004390:	e862                	sd	s8,16(sp)
    80004392:	e466                	sd	s9,8(sp)
    80004394:	1080                	addi	s0,sp,96
    80004396:	84aa                	mv	s1,a0
    80004398:	8b2e                	mv	s6,a1
    8000439a:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000439c:	00054703          	lbu	a4,0(a0)
    800043a0:	02f00793          	li	a5,47
    800043a4:	02f70363          	beq	a4,a5,800043ca <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800043a8:	ffffe097          	auipc	ra,0xffffe
    800043ac:	94a080e7          	jalr	-1718(ra) # 80001cf2 <myproc>
    800043b0:	16853503          	ld	a0,360(a0)
    800043b4:	00000097          	auipc	ra,0x0
    800043b8:	9f6080e7          	jalr	-1546(ra) # 80003daa <idup>
    800043bc:	89aa                	mv	s3,a0
  while(*path == '/')
    800043be:	02f00913          	li	s2,47
  len = path - s;
    800043c2:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    800043c4:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800043c6:	4c05                	li	s8,1
    800043c8:	a865                	j	80004480 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800043ca:	4585                	li	a1,1
    800043cc:	4505                	li	a0,1
    800043ce:	fffff097          	auipc	ra,0xfffff
    800043d2:	6e6080e7          	jalr	1766(ra) # 80003ab4 <iget>
    800043d6:	89aa                	mv	s3,a0
    800043d8:	b7dd                	j	800043be <namex+0x42>
      iunlockput(ip);
    800043da:	854e                	mv	a0,s3
    800043dc:	00000097          	auipc	ra,0x0
    800043e0:	c6e080e7          	jalr	-914(ra) # 8000404a <iunlockput>
      return 0;
    800043e4:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800043e6:	854e                	mv	a0,s3
    800043e8:	60e6                	ld	ra,88(sp)
    800043ea:	6446                	ld	s0,80(sp)
    800043ec:	64a6                	ld	s1,72(sp)
    800043ee:	6906                	ld	s2,64(sp)
    800043f0:	79e2                	ld	s3,56(sp)
    800043f2:	7a42                	ld	s4,48(sp)
    800043f4:	7aa2                	ld	s5,40(sp)
    800043f6:	7b02                	ld	s6,32(sp)
    800043f8:	6be2                	ld	s7,24(sp)
    800043fa:	6c42                	ld	s8,16(sp)
    800043fc:	6ca2                	ld	s9,8(sp)
    800043fe:	6125                	addi	sp,sp,96
    80004400:	8082                	ret
      iunlock(ip);
    80004402:	854e                	mv	a0,s3
    80004404:	00000097          	auipc	ra,0x0
    80004408:	aa6080e7          	jalr	-1370(ra) # 80003eaa <iunlock>
      return ip;
    8000440c:	bfe9                	j	800043e6 <namex+0x6a>
      iunlockput(ip);
    8000440e:	854e                	mv	a0,s3
    80004410:	00000097          	auipc	ra,0x0
    80004414:	c3a080e7          	jalr	-966(ra) # 8000404a <iunlockput>
      return 0;
    80004418:	89d2                	mv	s3,s4
    8000441a:	b7f1                	j	800043e6 <namex+0x6a>
  len = path - s;
    8000441c:	40b48633          	sub	a2,s1,a1
    80004420:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80004424:	094cd463          	bge	s9,s4,800044ac <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004428:	4639                	li	a2,14
    8000442a:	8556                	mv	a0,s5
    8000442c:	ffffd097          	auipc	ra,0xffffd
    80004430:	914080e7          	jalr	-1772(ra) # 80000d40 <memmove>
  while(*path == '/')
    80004434:	0004c783          	lbu	a5,0(s1)
    80004438:	01279763          	bne	a5,s2,80004446 <namex+0xca>
    path++;
    8000443c:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000443e:	0004c783          	lbu	a5,0(s1)
    80004442:	ff278de3          	beq	a5,s2,8000443c <namex+0xc0>
    ilock(ip);
    80004446:	854e                	mv	a0,s3
    80004448:	00000097          	auipc	ra,0x0
    8000444c:	9a0080e7          	jalr	-1632(ra) # 80003de8 <ilock>
    if(ip->type != T_DIR){
    80004450:	04499783          	lh	a5,68(s3)
    80004454:	f98793e3          	bne	a5,s8,800043da <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004458:	000b0563          	beqz	s6,80004462 <namex+0xe6>
    8000445c:	0004c783          	lbu	a5,0(s1)
    80004460:	d3cd                	beqz	a5,80004402 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004462:	865e                	mv	a2,s7
    80004464:	85d6                	mv	a1,s5
    80004466:	854e                	mv	a0,s3
    80004468:	00000097          	auipc	ra,0x0
    8000446c:	e64080e7          	jalr	-412(ra) # 800042cc <dirlookup>
    80004470:	8a2a                	mv	s4,a0
    80004472:	dd51                	beqz	a0,8000440e <namex+0x92>
    iunlockput(ip);
    80004474:	854e                	mv	a0,s3
    80004476:	00000097          	auipc	ra,0x0
    8000447a:	bd4080e7          	jalr	-1068(ra) # 8000404a <iunlockput>
    ip = next;
    8000447e:	89d2                	mv	s3,s4
  while(*path == '/')
    80004480:	0004c783          	lbu	a5,0(s1)
    80004484:	05279763          	bne	a5,s2,800044d2 <namex+0x156>
    path++;
    80004488:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000448a:	0004c783          	lbu	a5,0(s1)
    8000448e:	ff278de3          	beq	a5,s2,80004488 <namex+0x10c>
  if(*path == 0)
    80004492:	c79d                	beqz	a5,800044c0 <namex+0x144>
    path++;
    80004494:	85a6                	mv	a1,s1
  len = path - s;
    80004496:	8a5e                	mv	s4,s7
    80004498:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    8000449a:	01278963          	beq	a5,s2,800044ac <namex+0x130>
    8000449e:	dfbd                	beqz	a5,8000441c <namex+0xa0>
    path++;
    800044a0:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800044a2:	0004c783          	lbu	a5,0(s1)
    800044a6:	ff279ce3          	bne	a5,s2,8000449e <namex+0x122>
    800044aa:	bf8d                	j	8000441c <namex+0xa0>
    memmove(name, s, len);
    800044ac:	2601                	sext.w	a2,a2
    800044ae:	8556                	mv	a0,s5
    800044b0:	ffffd097          	auipc	ra,0xffffd
    800044b4:	890080e7          	jalr	-1904(ra) # 80000d40 <memmove>
    name[len] = 0;
    800044b8:	9a56                	add	s4,s4,s5
    800044ba:	000a0023          	sb	zero,0(s4)
    800044be:	bf9d                	j	80004434 <namex+0xb8>
  if(nameiparent){
    800044c0:	f20b03e3          	beqz	s6,800043e6 <namex+0x6a>
    iput(ip);
    800044c4:	854e                	mv	a0,s3
    800044c6:	00000097          	auipc	ra,0x0
    800044ca:	adc080e7          	jalr	-1316(ra) # 80003fa2 <iput>
    return 0;
    800044ce:	4981                	li	s3,0
    800044d0:	bf19                	j	800043e6 <namex+0x6a>
  if(*path == 0)
    800044d2:	d7fd                	beqz	a5,800044c0 <namex+0x144>
  while(*path != '/' && *path != 0)
    800044d4:	0004c783          	lbu	a5,0(s1)
    800044d8:	85a6                	mv	a1,s1
    800044da:	b7d1                	j	8000449e <namex+0x122>

00000000800044dc <dirlink>:
{
    800044dc:	7139                	addi	sp,sp,-64
    800044de:	fc06                	sd	ra,56(sp)
    800044e0:	f822                	sd	s0,48(sp)
    800044e2:	f426                	sd	s1,40(sp)
    800044e4:	f04a                	sd	s2,32(sp)
    800044e6:	ec4e                	sd	s3,24(sp)
    800044e8:	e852                	sd	s4,16(sp)
    800044ea:	0080                	addi	s0,sp,64
    800044ec:	892a                	mv	s2,a0
    800044ee:	8a2e                	mv	s4,a1
    800044f0:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800044f2:	4601                	li	a2,0
    800044f4:	00000097          	auipc	ra,0x0
    800044f8:	dd8080e7          	jalr	-552(ra) # 800042cc <dirlookup>
    800044fc:	e93d                	bnez	a0,80004572 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800044fe:	04c92483          	lw	s1,76(s2)
    80004502:	c49d                	beqz	s1,80004530 <dirlink+0x54>
    80004504:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004506:	4741                	li	a4,16
    80004508:	86a6                	mv	a3,s1
    8000450a:	fc040613          	addi	a2,s0,-64
    8000450e:	4581                	li	a1,0
    80004510:	854a                	mv	a0,s2
    80004512:	00000097          	auipc	ra,0x0
    80004516:	b8a080e7          	jalr	-1142(ra) # 8000409c <readi>
    8000451a:	47c1                	li	a5,16
    8000451c:	06f51163          	bne	a0,a5,8000457e <dirlink+0xa2>
    if(de.inum == 0)
    80004520:	fc045783          	lhu	a5,-64(s0)
    80004524:	c791                	beqz	a5,80004530 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004526:	24c1                	addiw	s1,s1,16
    80004528:	04c92783          	lw	a5,76(s2)
    8000452c:	fcf4ede3          	bltu	s1,a5,80004506 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004530:	4639                	li	a2,14
    80004532:	85d2                	mv	a1,s4
    80004534:	fc240513          	addi	a0,s0,-62
    80004538:	ffffd097          	auipc	ra,0xffffd
    8000453c:	8bc080e7          	jalr	-1860(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80004540:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004544:	4741                	li	a4,16
    80004546:	86a6                	mv	a3,s1
    80004548:	fc040613          	addi	a2,s0,-64
    8000454c:	4581                	li	a1,0
    8000454e:	854a                	mv	a0,s2
    80004550:	00000097          	auipc	ra,0x0
    80004554:	c44080e7          	jalr	-956(ra) # 80004194 <writei>
    80004558:	872a                	mv	a4,a0
    8000455a:	47c1                	li	a5,16
  return 0;
    8000455c:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000455e:	02f71863          	bne	a4,a5,8000458e <dirlink+0xb2>
}
    80004562:	70e2                	ld	ra,56(sp)
    80004564:	7442                	ld	s0,48(sp)
    80004566:	74a2                	ld	s1,40(sp)
    80004568:	7902                	ld	s2,32(sp)
    8000456a:	69e2                	ld	s3,24(sp)
    8000456c:	6a42                	ld	s4,16(sp)
    8000456e:	6121                	addi	sp,sp,64
    80004570:	8082                	ret
    iput(ip);
    80004572:	00000097          	auipc	ra,0x0
    80004576:	a30080e7          	jalr	-1488(ra) # 80003fa2 <iput>
    return -1;
    8000457a:	557d                	li	a0,-1
    8000457c:	b7dd                	j	80004562 <dirlink+0x86>
      panic("dirlink read");
    8000457e:	00004517          	auipc	a0,0x4
    80004582:	3ba50513          	addi	a0,a0,954 # 80008938 <syscalls+0x1d8>
    80004586:	ffffc097          	auipc	ra,0xffffc
    8000458a:	fb8080e7          	jalr	-72(ra) # 8000053e <panic>
    panic("dirlink");
    8000458e:	00004517          	auipc	a0,0x4
    80004592:	4ba50513          	addi	a0,a0,1210 # 80008a48 <syscalls+0x2e8>
    80004596:	ffffc097          	auipc	ra,0xffffc
    8000459a:	fa8080e7          	jalr	-88(ra) # 8000053e <panic>

000000008000459e <namei>:

struct inode*
namei(char *path)
{
    8000459e:	1101                	addi	sp,sp,-32
    800045a0:	ec06                	sd	ra,24(sp)
    800045a2:	e822                	sd	s0,16(sp)
    800045a4:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800045a6:	fe040613          	addi	a2,s0,-32
    800045aa:	4581                	li	a1,0
    800045ac:	00000097          	auipc	ra,0x0
    800045b0:	dd0080e7          	jalr	-560(ra) # 8000437c <namex>
}
    800045b4:	60e2                	ld	ra,24(sp)
    800045b6:	6442                	ld	s0,16(sp)
    800045b8:	6105                	addi	sp,sp,32
    800045ba:	8082                	ret

00000000800045bc <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800045bc:	1141                	addi	sp,sp,-16
    800045be:	e406                	sd	ra,8(sp)
    800045c0:	e022                	sd	s0,0(sp)
    800045c2:	0800                	addi	s0,sp,16
    800045c4:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800045c6:	4585                	li	a1,1
    800045c8:	00000097          	auipc	ra,0x0
    800045cc:	db4080e7          	jalr	-588(ra) # 8000437c <namex>
}
    800045d0:	60a2                	ld	ra,8(sp)
    800045d2:	6402                	ld	s0,0(sp)
    800045d4:	0141                	addi	sp,sp,16
    800045d6:	8082                	ret

00000000800045d8 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800045d8:	1101                	addi	sp,sp,-32
    800045da:	ec06                	sd	ra,24(sp)
    800045dc:	e822                	sd	s0,16(sp)
    800045de:	e426                	sd	s1,8(sp)
    800045e0:	e04a                	sd	s2,0(sp)
    800045e2:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800045e4:	0001d917          	auipc	s2,0x1d
    800045e8:	74c90913          	addi	s2,s2,1868 # 80021d30 <log>
    800045ec:	01892583          	lw	a1,24(s2)
    800045f0:	02892503          	lw	a0,40(s2)
    800045f4:	fffff097          	auipc	ra,0xfffff
    800045f8:	ff2080e7          	jalr	-14(ra) # 800035e6 <bread>
    800045fc:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800045fe:	02c92683          	lw	a3,44(s2)
    80004602:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004604:	02d05763          	blez	a3,80004632 <write_head+0x5a>
    80004608:	0001d797          	auipc	a5,0x1d
    8000460c:	75878793          	addi	a5,a5,1880 # 80021d60 <log+0x30>
    80004610:	05c50713          	addi	a4,a0,92
    80004614:	36fd                	addiw	a3,a3,-1
    80004616:	1682                	slli	a3,a3,0x20
    80004618:	9281                	srli	a3,a3,0x20
    8000461a:	068a                	slli	a3,a3,0x2
    8000461c:	0001d617          	auipc	a2,0x1d
    80004620:	74860613          	addi	a2,a2,1864 # 80021d64 <log+0x34>
    80004624:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004626:	4390                	lw	a2,0(a5)
    80004628:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000462a:	0791                	addi	a5,a5,4
    8000462c:	0711                	addi	a4,a4,4
    8000462e:	fed79ce3          	bne	a5,a3,80004626 <write_head+0x4e>
  }
  bwrite(buf);
    80004632:	8526                	mv	a0,s1
    80004634:	fffff097          	auipc	ra,0xfffff
    80004638:	0a4080e7          	jalr	164(ra) # 800036d8 <bwrite>
  brelse(buf);
    8000463c:	8526                	mv	a0,s1
    8000463e:	fffff097          	auipc	ra,0xfffff
    80004642:	0d8080e7          	jalr	216(ra) # 80003716 <brelse>
}
    80004646:	60e2                	ld	ra,24(sp)
    80004648:	6442                	ld	s0,16(sp)
    8000464a:	64a2                	ld	s1,8(sp)
    8000464c:	6902                	ld	s2,0(sp)
    8000464e:	6105                	addi	sp,sp,32
    80004650:	8082                	ret

0000000080004652 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004652:	0001d797          	auipc	a5,0x1d
    80004656:	70a7a783          	lw	a5,1802(a5) # 80021d5c <log+0x2c>
    8000465a:	0af05d63          	blez	a5,80004714 <install_trans+0xc2>
{
    8000465e:	7139                	addi	sp,sp,-64
    80004660:	fc06                	sd	ra,56(sp)
    80004662:	f822                	sd	s0,48(sp)
    80004664:	f426                	sd	s1,40(sp)
    80004666:	f04a                	sd	s2,32(sp)
    80004668:	ec4e                	sd	s3,24(sp)
    8000466a:	e852                	sd	s4,16(sp)
    8000466c:	e456                	sd	s5,8(sp)
    8000466e:	e05a                	sd	s6,0(sp)
    80004670:	0080                	addi	s0,sp,64
    80004672:	8b2a                	mv	s6,a0
    80004674:	0001da97          	auipc	s5,0x1d
    80004678:	6eca8a93          	addi	s5,s5,1772 # 80021d60 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000467c:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000467e:	0001d997          	auipc	s3,0x1d
    80004682:	6b298993          	addi	s3,s3,1714 # 80021d30 <log>
    80004686:	a035                	j	800046b2 <install_trans+0x60>
      bunpin(dbuf);
    80004688:	8526                	mv	a0,s1
    8000468a:	fffff097          	auipc	ra,0xfffff
    8000468e:	166080e7          	jalr	358(ra) # 800037f0 <bunpin>
    brelse(lbuf);
    80004692:	854a                	mv	a0,s2
    80004694:	fffff097          	auipc	ra,0xfffff
    80004698:	082080e7          	jalr	130(ra) # 80003716 <brelse>
    brelse(dbuf);
    8000469c:	8526                	mv	a0,s1
    8000469e:	fffff097          	auipc	ra,0xfffff
    800046a2:	078080e7          	jalr	120(ra) # 80003716 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800046a6:	2a05                	addiw	s4,s4,1
    800046a8:	0a91                	addi	s5,s5,4
    800046aa:	02c9a783          	lw	a5,44(s3)
    800046ae:	04fa5963          	bge	s4,a5,80004700 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800046b2:	0189a583          	lw	a1,24(s3)
    800046b6:	014585bb          	addw	a1,a1,s4
    800046ba:	2585                	addiw	a1,a1,1
    800046bc:	0289a503          	lw	a0,40(s3)
    800046c0:	fffff097          	auipc	ra,0xfffff
    800046c4:	f26080e7          	jalr	-218(ra) # 800035e6 <bread>
    800046c8:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800046ca:	000aa583          	lw	a1,0(s5)
    800046ce:	0289a503          	lw	a0,40(s3)
    800046d2:	fffff097          	auipc	ra,0xfffff
    800046d6:	f14080e7          	jalr	-236(ra) # 800035e6 <bread>
    800046da:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800046dc:	40000613          	li	a2,1024
    800046e0:	05890593          	addi	a1,s2,88
    800046e4:	05850513          	addi	a0,a0,88
    800046e8:	ffffc097          	auipc	ra,0xffffc
    800046ec:	658080e7          	jalr	1624(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    800046f0:	8526                	mv	a0,s1
    800046f2:	fffff097          	auipc	ra,0xfffff
    800046f6:	fe6080e7          	jalr	-26(ra) # 800036d8 <bwrite>
    if(recovering == 0)
    800046fa:	f80b1ce3          	bnez	s6,80004692 <install_trans+0x40>
    800046fe:	b769                	j	80004688 <install_trans+0x36>
}
    80004700:	70e2                	ld	ra,56(sp)
    80004702:	7442                	ld	s0,48(sp)
    80004704:	74a2                	ld	s1,40(sp)
    80004706:	7902                	ld	s2,32(sp)
    80004708:	69e2                	ld	s3,24(sp)
    8000470a:	6a42                	ld	s4,16(sp)
    8000470c:	6aa2                	ld	s5,8(sp)
    8000470e:	6b02                	ld	s6,0(sp)
    80004710:	6121                	addi	sp,sp,64
    80004712:	8082                	ret
    80004714:	8082                	ret

0000000080004716 <initlog>:
{
    80004716:	7179                	addi	sp,sp,-48
    80004718:	f406                	sd	ra,40(sp)
    8000471a:	f022                	sd	s0,32(sp)
    8000471c:	ec26                	sd	s1,24(sp)
    8000471e:	e84a                	sd	s2,16(sp)
    80004720:	e44e                	sd	s3,8(sp)
    80004722:	1800                	addi	s0,sp,48
    80004724:	892a                	mv	s2,a0
    80004726:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004728:	0001d497          	auipc	s1,0x1d
    8000472c:	60848493          	addi	s1,s1,1544 # 80021d30 <log>
    80004730:	00004597          	auipc	a1,0x4
    80004734:	21858593          	addi	a1,a1,536 # 80008948 <syscalls+0x1e8>
    80004738:	8526                	mv	a0,s1
    8000473a:	ffffc097          	auipc	ra,0xffffc
    8000473e:	41a080e7          	jalr	1050(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80004742:	0149a583          	lw	a1,20(s3)
    80004746:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004748:	0109a783          	lw	a5,16(s3)
    8000474c:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000474e:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004752:	854a                	mv	a0,s2
    80004754:	fffff097          	auipc	ra,0xfffff
    80004758:	e92080e7          	jalr	-366(ra) # 800035e6 <bread>
  log.lh.n = lh->n;
    8000475c:	4d3c                	lw	a5,88(a0)
    8000475e:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004760:	02f05563          	blez	a5,8000478a <initlog+0x74>
    80004764:	05c50713          	addi	a4,a0,92
    80004768:	0001d697          	auipc	a3,0x1d
    8000476c:	5f868693          	addi	a3,a3,1528 # 80021d60 <log+0x30>
    80004770:	37fd                	addiw	a5,a5,-1
    80004772:	1782                	slli	a5,a5,0x20
    80004774:	9381                	srli	a5,a5,0x20
    80004776:	078a                	slli	a5,a5,0x2
    80004778:	06050613          	addi	a2,a0,96
    8000477c:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    8000477e:	4310                	lw	a2,0(a4)
    80004780:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004782:	0711                	addi	a4,a4,4
    80004784:	0691                	addi	a3,a3,4
    80004786:	fef71ce3          	bne	a4,a5,8000477e <initlog+0x68>
  brelse(buf);
    8000478a:	fffff097          	auipc	ra,0xfffff
    8000478e:	f8c080e7          	jalr	-116(ra) # 80003716 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004792:	4505                	li	a0,1
    80004794:	00000097          	auipc	ra,0x0
    80004798:	ebe080e7          	jalr	-322(ra) # 80004652 <install_trans>
  log.lh.n = 0;
    8000479c:	0001d797          	auipc	a5,0x1d
    800047a0:	5c07a023          	sw	zero,1472(a5) # 80021d5c <log+0x2c>
  write_head(); // clear the log
    800047a4:	00000097          	auipc	ra,0x0
    800047a8:	e34080e7          	jalr	-460(ra) # 800045d8 <write_head>
}
    800047ac:	70a2                	ld	ra,40(sp)
    800047ae:	7402                	ld	s0,32(sp)
    800047b0:	64e2                	ld	s1,24(sp)
    800047b2:	6942                	ld	s2,16(sp)
    800047b4:	69a2                	ld	s3,8(sp)
    800047b6:	6145                	addi	sp,sp,48
    800047b8:	8082                	ret

00000000800047ba <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800047ba:	1101                	addi	sp,sp,-32
    800047bc:	ec06                	sd	ra,24(sp)
    800047be:	e822                	sd	s0,16(sp)
    800047c0:	e426                	sd	s1,8(sp)
    800047c2:	e04a                	sd	s2,0(sp)
    800047c4:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800047c6:	0001d517          	auipc	a0,0x1d
    800047ca:	56a50513          	addi	a0,a0,1386 # 80021d30 <log>
    800047ce:	ffffc097          	auipc	ra,0xffffc
    800047d2:	416080e7          	jalr	1046(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    800047d6:	0001d497          	auipc	s1,0x1d
    800047da:	55a48493          	addi	s1,s1,1370 # 80021d30 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800047de:	4979                	li	s2,30
    800047e0:	a039                	j	800047ee <begin_op+0x34>
      sleep(&log, &log.lock);
    800047e2:	85a6                	mv	a1,s1
    800047e4:	8526                	mv	a0,s1
    800047e6:	ffffe097          	auipc	ra,0xffffe
    800047ea:	b82080e7          	jalr	-1150(ra) # 80002368 <sleep>
    if(log.committing){
    800047ee:	50dc                	lw	a5,36(s1)
    800047f0:	fbed                	bnez	a5,800047e2 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800047f2:	509c                	lw	a5,32(s1)
    800047f4:	0017871b          	addiw	a4,a5,1
    800047f8:	0007069b          	sext.w	a3,a4
    800047fc:	0027179b          	slliw	a5,a4,0x2
    80004800:	9fb9                	addw	a5,a5,a4
    80004802:	0017979b          	slliw	a5,a5,0x1
    80004806:	54d8                	lw	a4,44(s1)
    80004808:	9fb9                	addw	a5,a5,a4
    8000480a:	00f95963          	bge	s2,a5,8000481c <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000480e:	85a6                	mv	a1,s1
    80004810:	8526                	mv	a0,s1
    80004812:	ffffe097          	auipc	ra,0xffffe
    80004816:	b56080e7          	jalr	-1194(ra) # 80002368 <sleep>
    8000481a:	bfd1                	j	800047ee <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000481c:	0001d517          	auipc	a0,0x1d
    80004820:	51450513          	addi	a0,a0,1300 # 80021d30 <log>
    80004824:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004826:	ffffc097          	auipc	ra,0xffffc
    8000482a:	472080e7          	jalr	1138(ra) # 80000c98 <release>
      break;
    }
  }
}
    8000482e:	60e2                	ld	ra,24(sp)
    80004830:	6442                	ld	s0,16(sp)
    80004832:	64a2                	ld	s1,8(sp)
    80004834:	6902                	ld	s2,0(sp)
    80004836:	6105                	addi	sp,sp,32
    80004838:	8082                	ret

000000008000483a <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000483a:	7139                	addi	sp,sp,-64
    8000483c:	fc06                	sd	ra,56(sp)
    8000483e:	f822                	sd	s0,48(sp)
    80004840:	f426                	sd	s1,40(sp)
    80004842:	f04a                	sd	s2,32(sp)
    80004844:	ec4e                	sd	s3,24(sp)
    80004846:	e852                	sd	s4,16(sp)
    80004848:	e456                	sd	s5,8(sp)
    8000484a:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000484c:	0001d497          	auipc	s1,0x1d
    80004850:	4e448493          	addi	s1,s1,1252 # 80021d30 <log>
    80004854:	8526                	mv	a0,s1
    80004856:	ffffc097          	auipc	ra,0xffffc
    8000485a:	38e080e7          	jalr	910(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    8000485e:	509c                	lw	a5,32(s1)
    80004860:	37fd                	addiw	a5,a5,-1
    80004862:	0007891b          	sext.w	s2,a5
    80004866:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004868:	50dc                	lw	a5,36(s1)
    8000486a:	efb9                	bnez	a5,800048c8 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000486c:	06091663          	bnez	s2,800048d8 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004870:	0001d497          	auipc	s1,0x1d
    80004874:	4c048493          	addi	s1,s1,1216 # 80021d30 <log>
    80004878:	4785                	li	a5,1
    8000487a:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000487c:	8526                	mv	a0,s1
    8000487e:	ffffc097          	auipc	ra,0xffffc
    80004882:	41a080e7          	jalr	1050(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004886:	54dc                	lw	a5,44(s1)
    80004888:	06f04763          	bgtz	a5,800048f6 <end_op+0xbc>
    acquire(&log.lock);
    8000488c:	0001d497          	auipc	s1,0x1d
    80004890:	4a448493          	addi	s1,s1,1188 # 80021d30 <log>
    80004894:	8526                	mv	a0,s1
    80004896:	ffffc097          	auipc	ra,0xffffc
    8000489a:	34e080e7          	jalr	846(ra) # 80000be4 <acquire>
    log.committing = 0;
    8000489e:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800048a2:	8526                	mv	a0,s1
    800048a4:	ffffe097          	auipc	ra,0xffffe
    800048a8:	e7a080e7          	jalr	-390(ra) # 8000271e <wakeup>
    release(&log.lock);
    800048ac:	8526                	mv	a0,s1
    800048ae:	ffffc097          	auipc	ra,0xffffc
    800048b2:	3ea080e7          	jalr	1002(ra) # 80000c98 <release>
}
    800048b6:	70e2                	ld	ra,56(sp)
    800048b8:	7442                	ld	s0,48(sp)
    800048ba:	74a2                	ld	s1,40(sp)
    800048bc:	7902                	ld	s2,32(sp)
    800048be:	69e2                	ld	s3,24(sp)
    800048c0:	6a42                	ld	s4,16(sp)
    800048c2:	6aa2                	ld	s5,8(sp)
    800048c4:	6121                	addi	sp,sp,64
    800048c6:	8082                	ret
    panic("log.committing");
    800048c8:	00004517          	auipc	a0,0x4
    800048cc:	08850513          	addi	a0,a0,136 # 80008950 <syscalls+0x1f0>
    800048d0:	ffffc097          	auipc	ra,0xffffc
    800048d4:	c6e080e7          	jalr	-914(ra) # 8000053e <panic>
    wakeup(&log);
    800048d8:	0001d497          	auipc	s1,0x1d
    800048dc:	45848493          	addi	s1,s1,1112 # 80021d30 <log>
    800048e0:	8526                	mv	a0,s1
    800048e2:	ffffe097          	auipc	ra,0xffffe
    800048e6:	e3c080e7          	jalr	-452(ra) # 8000271e <wakeup>
  release(&log.lock);
    800048ea:	8526                	mv	a0,s1
    800048ec:	ffffc097          	auipc	ra,0xffffc
    800048f0:	3ac080e7          	jalr	940(ra) # 80000c98 <release>
  if(do_commit){
    800048f4:	b7c9                	j	800048b6 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800048f6:	0001da97          	auipc	s5,0x1d
    800048fa:	46aa8a93          	addi	s5,s5,1130 # 80021d60 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800048fe:	0001da17          	auipc	s4,0x1d
    80004902:	432a0a13          	addi	s4,s4,1074 # 80021d30 <log>
    80004906:	018a2583          	lw	a1,24(s4)
    8000490a:	012585bb          	addw	a1,a1,s2
    8000490e:	2585                	addiw	a1,a1,1
    80004910:	028a2503          	lw	a0,40(s4)
    80004914:	fffff097          	auipc	ra,0xfffff
    80004918:	cd2080e7          	jalr	-814(ra) # 800035e6 <bread>
    8000491c:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000491e:	000aa583          	lw	a1,0(s5)
    80004922:	028a2503          	lw	a0,40(s4)
    80004926:	fffff097          	auipc	ra,0xfffff
    8000492a:	cc0080e7          	jalr	-832(ra) # 800035e6 <bread>
    8000492e:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004930:	40000613          	li	a2,1024
    80004934:	05850593          	addi	a1,a0,88
    80004938:	05848513          	addi	a0,s1,88
    8000493c:	ffffc097          	auipc	ra,0xffffc
    80004940:	404080e7          	jalr	1028(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    80004944:	8526                	mv	a0,s1
    80004946:	fffff097          	auipc	ra,0xfffff
    8000494a:	d92080e7          	jalr	-622(ra) # 800036d8 <bwrite>
    brelse(from);
    8000494e:	854e                	mv	a0,s3
    80004950:	fffff097          	auipc	ra,0xfffff
    80004954:	dc6080e7          	jalr	-570(ra) # 80003716 <brelse>
    brelse(to);
    80004958:	8526                	mv	a0,s1
    8000495a:	fffff097          	auipc	ra,0xfffff
    8000495e:	dbc080e7          	jalr	-580(ra) # 80003716 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004962:	2905                	addiw	s2,s2,1
    80004964:	0a91                	addi	s5,s5,4
    80004966:	02ca2783          	lw	a5,44(s4)
    8000496a:	f8f94ee3          	blt	s2,a5,80004906 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000496e:	00000097          	auipc	ra,0x0
    80004972:	c6a080e7          	jalr	-918(ra) # 800045d8 <write_head>
    install_trans(0); // Now install writes to home locations
    80004976:	4501                	li	a0,0
    80004978:	00000097          	auipc	ra,0x0
    8000497c:	cda080e7          	jalr	-806(ra) # 80004652 <install_trans>
    log.lh.n = 0;
    80004980:	0001d797          	auipc	a5,0x1d
    80004984:	3c07ae23          	sw	zero,988(a5) # 80021d5c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004988:	00000097          	auipc	ra,0x0
    8000498c:	c50080e7          	jalr	-944(ra) # 800045d8 <write_head>
    80004990:	bdf5                	j	8000488c <end_op+0x52>

0000000080004992 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004992:	1101                	addi	sp,sp,-32
    80004994:	ec06                	sd	ra,24(sp)
    80004996:	e822                	sd	s0,16(sp)
    80004998:	e426                	sd	s1,8(sp)
    8000499a:	e04a                	sd	s2,0(sp)
    8000499c:	1000                	addi	s0,sp,32
    8000499e:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800049a0:	0001d917          	auipc	s2,0x1d
    800049a4:	39090913          	addi	s2,s2,912 # 80021d30 <log>
    800049a8:	854a                	mv	a0,s2
    800049aa:	ffffc097          	auipc	ra,0xffffc
    800049ae:	23a080e7          	jalr	570(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800049b2:	02c92603          	lw	a2,44(s2)
    800049b6:	47f5                	li	a5,29
    800049b8:	06c7c563          	blt	a5,a2,80004a22 <log_write+0x90>
    800049bc:	0001d797          	auipc	a5,0x1d
    800049c0:	3907a783          	lw	a5,912(a5) # 80021d4c <log+0x1c>
    800049c4:	37fd                	addiw	a5,a5,-1
    800049c6:	04f65e63          	bge	a2,a5,80004a22 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800049ca:	0001d797          	auipc	a5,0x1d
    800049ce:	3867a783          	lw	a5,902(a5) # 80021d50 <log+0x20>
    800049d2:	06f05063          	blez	a5,80004a32 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800049d6:	4781                	li	a5,0
    800049d8:	06c05563          	blez	a2,80004a42 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800049dc:	44cc                	lw	a1,12(s1)
    800049de:	0001d717          	auipc	a4,0x1d
    800049e2:	38270713          	addi	a4,a4,898 # 80021d60 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800049e6:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800049e8:	4314                	lw	a3,0(a4)
    800049ea:	04b68c63          	beq	a3,a1,80004a42 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800049ee:	2785                	addiw	a5,a5,1
    800049f0:	0711                	addi	a4,a4,4
    800049f2:	fef61be3          	bne	a2,a5,800049e8 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800049f6:	0621                	addi	a2,a2,8
    800049f8:	060a                	slli	a2,a2,0x2
    800049fa:	0001d797          	auipc	a5,0x1d
    800049fe:	33678793          	addi	a5,a5,822 # 80021d30 <log>
    80004a02:	963e                	add	a2,a2,a5
    80004a04:	44dc                	lw	a5,12(s1)
    80004a06:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004a08:	8526                	mv	a0,s1
    80004a0a:	fffff097          	auipc	ra,0xfffff
    80004a0e:	daa080e7          	jalr	-598(ra) # 800037b4 <bpin>
    log.lh.n++;
    80004a12:	0001d717          	auipc	a4,0x1d
    80004a16:	31e70713          	addi	a4,a4,798 # 80021d30 <log>
    80004a1a:	575c                	lw	a5,44(a4)
    80004a1c:	2785                	addiw	a5,a5,1
    80004a1e:	d75c                	sw	a5,44(a4)
    80004a20:	a835                	j	80004a5c <log_write+0xca>
    panic("too big a transaction");
    80004a22:	00004517          	auipc	a0,0x4
    80004a26:	f3e50513          	addi	a0,a0,-194 # 80008960 <syscalls+0x200>
    80004a2a:	ffffc097          	auipc	ra,0xffffc
    80004a2e:	b14080e7          	jalr	-1260(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004a32:	00004517          	auipc	a0,0x4
    80004a36:	f4650513          	addi	a0,a0,-186 # 80008978 <syscalls+0x218>
    80004a3a:	ffffc097          	auipc	ra,0xffffc
    80004a3e:	b04080e7          	jalr	-1276(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004a42:	00878713          	addi	a4,a5,8
    80004a46:	00271693          	slli	a3,a4,0x2
    80004a4a:	0001d717          	auipc	a4,0x1d
    80004a4e:	2e670713          	addi	a4,a4,742 # 80021d30 <log>
    80004a52:	9736                	add	a4,a4,a3
    80004a54:	44d4                	lw	a3,12(s1)
    80004a56:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004a58:	faf608e3          	beq	a2,a5,80004a08 <log_write+0x76>
  }
  release(&log.lock);
    80004a5c:	0001d517          	auipc	a0,0x1d
    80004a60:	2d450513          	addi	a0,a0,724 # 80021d30 <log>
    80004a64:	ffffc097          	auipc	ra,0xffffc
    80004a68:	234080e7          	jalr	564(ra) # 80000c98 <release>
}
    80004a6c:	60e2                	ld	ra,24(sp)
    80004a6e:	6442                	ld	s0,16(sp)
    80004a70:	64a2                	ld	s1,8(sp)
    80004a72:	6902                	ld	s2,0(sp)
    80004a74:	6105                	addi	sp,sp,32
    80004a76:	8082                	ret

0000000080004a78 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004a78:	1101                	addi	sp,sp,-32
    80004a7a:	ec06                	sd	ra,24(sp)
    80004a7c:	e822                	sd	s0,16(sp)
    80004a7e:	e426                	sd	s1,8(sp)
    80004a80:	e04a                	sd	s2,0(sp)
    80004a82:	1000                	addi	s0,sp,32
    80004a84:	84aa                	mv	s1,a0
    80004a86:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004a88:	00004597          	auipc	a1,0x4
    80004a8c:	f1058593          	addi	a1,a1,-240 # 80008998 <syscalls+0x238>
    80004a90:	0521                	addi	a0,a0,8
    80004a92:	ffffc097          	auipc	ra,0xffffc
    80004a96:	0c2080e7          	jalr	194(ra) # 80000b54 <initlock>
  lk->name = name;
    80004a9a:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004a9e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004aa2:	0204a423          	sw	zero,40(s1)
}
    80004aa6:	60e2                	ld	ra,24(sp)
    80004aa8:	6442                	ld	s0,16(sp)
    80004aaa:	64a2                	ld	s1,8(sp)
    80004aac:	6902                	ld	s2,0(sp)
    80004aae:	6105                	addi	sp,sp,32
    80004ab0:	8082                	ret

0000000080004ab2 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004ab2:	1101                	addi	sp,sp,-32
    80004ab4:	ec06                	sd	ra,24(sp)
    80004ab6:	e822                	sd	s0,16(sp)
    80004ab8:	e426                	sd	s1,8(sp)
    80004aba:	e04a                	sd	s2,0(sp)
    80004abc:	1000                	addi	s0,sp,32
    80004abe:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004ac0:	00850913          	addi	s2,a0,8
    80004ac4:	854a                	mv	a0,s2
    80004ac6:	ffffc097          	auipc	ra,0xffffc
    80004aca:	11e080e7          	jalr	286(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004ace:	409c                	lw	a5,0(s1)
    80004ad0:	cb89                	beqz	a5,80004ae2 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004ad2:	85ca                	mv	a1,s2
    80004ad4:	8526                	mv	a0,s1
    80004ad6:	ffffe097          	auipc	ra,0xffffe
    80004ada:	892080e7          	jalr	-1902(ra) # 80002368 <sleep>
  while (lk->locked) {
    80004ade:	409c                	lw	a5,0(s1)
    80004ae0:	fbed                	bnez	a5,80004ad2 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004ae2:	4785                	li	a5,1
    80004ae4:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004ae6:	ffffd097          	auipc	ra,0xffffd
    80004aea:	20c080e7          	jalr	524(ra) # 80001cf2 <myproc>
    80004aee:	453c                	lw	a5,72(a0)
    80004af0:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004af2:	854a                	mv	a0,s2
    80004af4:	ffffc097          	auipc	ra,0xffffc
    80004af8:	1a4080e7          	jalr	420(ra) # 80000c98 <release>
}
    80004afc:	60e2                	ld	ra,24(sp)
    80004afe:	6442                	ld	s0,16(sp)
    80004b00:	64a2                	ld	s1,8(sp)
    80004b02:	6902                	ld	s2,0(sp)
    80004b04:	6105                	addi	sp,sp,32
    80004b06:	8082                	ret

0000000080004b08 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004b08:	1101                	addi	sp,sp,-32
    80004b0a:	ec06                	sd	ra,24(sp)
    80004b0c:	e822                	sd	s0,16(sp)
    80004b0e:	e426                	sd	s1,8(sp)
    80004b10:	e04a                	sd	s2,0(sp)
    80004b12:	1000                	addi	s0,sp,32
    80004b14:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004b16:	00850913          	addi	s2,a0,8
    80004b1a:	854a                	mv	a0,s2
    80004b1c:	ffffc097          	auipc	ra,0xffffc
    80004b20:	0c8080e7          	jalr	200(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004b24:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004b28:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004b2c:	8526                	mv	a0,s1
    80004b2e:	ffffe097          	auipc	ra,0xffffe
    80004b32:	bf0080e7          	jalr	-1040(ra) # 8000271e <wakeup>
  release(&lk->lk);
    80004b36:	854a                	mv	a0,s2
    80004b38:	ffffc097          	auipc	ra,0xffffc
    80004b3c:	160080e7          	jalr	352(ra) # 80000c98 <release>
}
    80004b40:	60e2                	ld	ra,24(sp)
    80004b42:	6442                	ld	s0,16(sp)
    80004b44:	64a2                	ld	s1,8(sp)
    80004b46:	6902                	ld	s2,0(sp)
    80004b48:	6105                	addi	sp,sp,32
    80004b4a:	8082                	ret

0000000080004b4c <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004b4c:	7179                	addi	sp,sp,-48
    80004b4e:	f406                	sd	ra,40(sp)
    80004b50:	f022                	sd	s0,32(sp)
    80004b52:	ec26                	sd	s1,24(sp)
    80004b54:	e84a                	sd	s2,16(sp)
    80004b56:	e44e                	sd	s3,8(sp)
    80004b58:	1800                	addi	s0,sp,48
    80004b5a:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004b5c:	00850913          	addi	s2,a0,8
    80004b60:	854a                	mv	a0,s2
    80004b62:	ffffc097          	auipc	ra,0xffffc
    80004b66:	082080e7          	jalr	130(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004b6a:	409c                	lw	a5,0(s1)
    80004b6c:	ef99                	bnez	a5,80004b8a <holdingsleep+0x3e>
    80004b6e:	4481                	li	s1,0
  release(&lk->lk);
    80004b70:	854a                	mv	a0,s2
    80004b72:	ffffc097          	auipc	ra,0xffffc
    80004b76:	126080e7          	jalr	294(ra) # 80000c98 <release>
  return r;
}
    80004b7a:	8526                	mv	a0,s1
    80004b7c:	70a2                	ld	ra,40(sp)
    80004b7e:	7402                	ld	s0,32(sp)
    80004b80:	64e2                	ld	s1,24(sp)
    80004b82:	6942                	ld	s2,16(sp)
    80004b84:	69a2                	ld	s3,8(sp)
    80004b86:	6145                	addi	sp,sp,48
    80004b88:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004b8a:	0284a983          	lw	s3,40(s1)
    80004b8e:	ffffd097          	auipc	ra,0xffffd
    80004b92:	164080e7          	jalr	356(ra) # 80001cf2 <myproc>
    80004b96:	4524                	lw	s1,72(a0)
    80004b98:	413484b3          	sub	s1,s1,s3
    80004b9c:	0014b493          	seqz	s1,s1
    80004ba0:	bfc1                	j	80004b70 <holdingsleep+0x24>

0000000080004ba2 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004ba2:	1141                	addi	sp,sp,-16
    80004ba4:	e406                	sd	ra,8(sp)
    80004ba6:	e022                	sd	s0,0(sp)
    80004ba8:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004baa:	00004597          	auipc	a1,0x4
    80004bae:	dfe58593          	addi	a1,a1,-514 # 800089a8 <syscalls+0x248>
    80004bb2:	0001d517          	auipc	a0,0x1d
    80004bb6:	2c650513          	addi	a0,a0,710 # 80021e78 <ftable>
    80004bba:	ffffc097          	auipc	ra,0xffffc
    80004bbe:	f9a080e7          	jalr	-102(ra) # 80000b54 <initlock>
}
    80004bc2:	60a2                	ld	ra,8(sp)
    80004bc4:	6402                	ld	s0,0(sp)
    80004bc6:	0141                	addi	sp,sp,16
    80004bc8:	8082                	ret

0000000080004bca <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004bca:	1101                	addi	sp,sp,-32
    80004bcc:	ec06                	sd	ra,24(sp)
    80004bce:	e822                	sd	s0,16(sp)
    80004bd0:	e426                	sd	s1,8(sp)
    80004bd2:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004bd4:	0001d517          	auipc	a0,0x1d
    80004bd8:	2a450513          	addi	a0,a0,676 # 80021e78 <ftable>
    80004bdc:	ffffc097          	auipc	ra,0xffffc
    80004be0:	008080e7          	jalr	8(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004be4:	0001d497          	auipc	s1,0x1d
    80004be8:	2ac48493          	addi	s1,s1,684 # 80021e90 <ftable+0x18>
    80004bec:	0001e717          	auipc	a4,0x1e
    80004bf0:	24470713          	addi	a4,a4,580 # 80022e30 <ftable+0xfb8>
    if(f->ref == 0){
    80004bf4:	40dc                	lw	a5,4(s1)
    80004bf6:	cf99                	beqz	a5,80004c14 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004bf8:	02848493          	addi	s1,s1,40
    80004bfc:	fee49ce3          	bne	s1,a4,80004bf4 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004c00:	0001d517          	auipc	a0,0x1d
    80004c04:	27850513          	addi	a0,a0,632 # 80021e78 <ftable>
    80004c08:	ffffc097          	auipc	ra,0xffffc
    80004c0c:	090080e7          	jalr	144(ra) # 80000c98 <release>
  return 0;
    80004c10:	4481                	li	s1,0
    80004c12:	a819                	j	80004c28 <filealloc+0x5e>
      f->ref = 1;
    80004c14:	4785                	li	a5,1
    80004c16:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004c18:	0001d517          	auipc	a0,0x1d
    80004c1c:	26050513          	addi	a0,a0,608 # 80021e78 <ftable>
    80004c20:	ffffc097          	auipc	ra,0xffffc
    80004c24:	078080e7          	jalr	120(ra) # 80000c98 <release>
}
    80004c28:	8526                	mv	a0,s1
    80004c2a:	60e2                	ld	ra,24(sp)
    80004c2c:	6442                	ld	s0,16(sp)
    80004c2e:	64a2                	ld	s1,8(sp)
    80004c30:	6105                	addi	sp,sp,32
    80004c32:	8082                	ret

0000000080004c34 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004c34:	1101                	addi	sp,sp,-32
    80004c36:	ec06                	sd	ra,24(sp)
    80004c38:	e822                	sd	s0,16(sp)
    80004c3a:	e426                	sd	s1,8(sp)
    80004c3c:	1000                	addi	s0,sp,32
    80004c3e:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004c40:	0001d517          	auipc	a0,0x1d
    80004c44:	23850513          	addi	a0,a0,568 # 80021e78 <ftable>
    80004c48:	ffffc097          	auipc	ra,0xffffc
    80004c4c:	f9c080e7          	jalr	-100(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004c50:	40dc                	lw	a5,4(s1)
    80004c52:	02f05263          	blez	a5,80004c76 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004c56:	2785                	addiw	a5,a5,1
    80004c58:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004c5a:	0001d517          	auipc	a0,0x1d
    80004c5e:	21e50513          	addi	a0,a0,542 # 80021e78 <ftable>
    80004c62:	ffffc097          	auipc	ra,0xffffc
    80004c66:	036080e7          	jalr	54(ra) # 80000c98 <release>
  return f;
}
    80004c6a:	8526                	mv	a0,s1
    80004c6c:	60e2                	ld	ra,24(sp)
    80004c6e:	6442                	ld	s0,16(sp)
    80004c70:	64a2                	ld	s1,8(sp)
    80004c72:	6105                	addi	sp,sp,32
    80004c74:	8082                	ret
    panic("filedup");
    80004c76:	00004517          	auipc	a0,0x4
    80004c7a:	d3a50513          	addi	a0,a0,-710 # 800089b0 <syscalls+0x250>
    80004c7e:	ffffc097          	auipc	ra,0xffffc
    80004c82:	8c0080e7          	jalr	-1856(ra) # 8000053e <panic>

0000000080004c86 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004c86:	7139                	addi	sp,sp,-64
    80004c88:	fc06                	sd	ra,56(sp)
    80004c8a:	f822                	sd	s0,48(sp)
    80004c8c:	f426                	sd	s1,40(sp)
    80004c8e:	f04a                	sd	s2,32(sp)
    80004c90:	ec4e                	sd	s3,24(sp)
    80004c92:	e852                	sd	s4,16(sp)
    80004c94:	e456                	sd	s5,8(sp)
    80004c96:	0080                	addi	s0,sp,64
    80004c98:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004c9a:	0001d517          	auipc	a0,0x1d
    80004c9e:	1de50513          	addi	a0,a0,478 # 80021e78 <ftable>
    80004ca2:	ffffc097          	auipc	ra,0xffffc
    80004ca6:	f42080e7          	jalr	-190(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004caa:	40dc                	lw	a5,4(s1)
    80004cac:	06f05163          	blez	a5,80004d0e <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004cb0:	37fd                	addiw	a5,a5,-1
    80004cb2:	0007871b          	sext.w	a4,a5
    80004cb6:	c0dc                	sw	a5,4(s1)
    80004cb8:	06e04363          	bgtz	a4,80004d1e <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004cbc:	0004a903          	lw	s2,0(s1)
    80004cc0:	0094ca83          	lbu	s5,9(s1)
    80004cc4:	0104ba03          	ld	s4,16(s1)
    80004cc8:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004ccc:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004cd0:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004cd4:	0001d517          	auipc	a0,0x1d
    80004cd8:	1a450513          	addi	a0,a0,420 # 80021e78 <ftable>
    80004cdc:	ffffc097          	auipc	ra,0xffffc
    80004ce0:	fbc080e7          	jalr	-68(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004ce4:	4785                	li	a5,1
    80004ce6:	04f90d63          	beq	s2,a5,80004d40 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004cea:	3979                	addiw	s2,s2,-2
    80004cec:	4785                	li	a5,1
    80004cee:	0527e063          	bltu	a5,s2,80004d2e <fileclose+0xa8>
    begin_op();
    80004cf2:	00000097          	auipc	ra,0x0
    80004cf6:	ac8080e7          	jalr	-1336(ra) # 800047ba <begin_op>
    iput(ff.ip);
    80004cfa:	854e                	mv	a0,s3
    80004cfc:	fffff097          	auipc	ra,0xfffff
    80004d00:	2a6080e7          	jalr	678(ra) # 80003fa2 <iput>
    end_op();
    80004d04:	00000097          	auipc	ra,0x0
    80004d08:	b36080e7          	jalr	-1226(ra) # 8000483a <end_op>
    80004d0c:	a00d                	j	80004d2e <fileclose+0xa8>
    panic("fileclose");
    80004d0e:	00004517          	auipc	a0,0x4
    80004d12:	caa50513          	addi	a0,a0,-854 # 800089b8 <syscalls+0x258>
    80004d16:	ffffc097          	auipc	ra,0xffffc
    80004d1a:	828080e7          	jalr	-2008(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004d1e:	0001d517          	auipc	a0,0x1d
    80004d22:	15a50513          	addi	a0,a0,346 # 80021e78 <ftable>
    80004d26:	ffffc097          	auipc	ra,0xffffc
    80004d2a:	f72080e7          	jalr	-142(ra) # 80000c98 <release>
  }
}
    80004d2e:	70e2                	ld	ra,56(sp)
    80004d30:	7442                	ld	s0,48(sp)
    80004d32:	74a2                	ld	s1,40(sp)
    80004d34:	7902                	ld	s2,32(sp)
    80004d36:	69e2                	ld	s3,24(sp)
    80004d38:	6a42                	ld	s4,16(sp)
    80004d3a:	6aa2                	ld	s5,8(sp)
    80004d3c:	6121                	addi	sp,sp,64
    80004d3e:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004d40:	85d6                	mv	a1,s5
    80004d42:	8552                	mv	a0,s4
    80004d44:	00000097          	auipc	ra,0x0
    80004d48:	34c080e7          	jalr	844(ra) # 80005090 <pipeclose>
    80004d4c:	b7cd                	j	80004d2e <fileclose+0xa8>

0000000080004d4e <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004d4e:	715d                	addi	sp,sp,-80
    80004d50:	e486                	sd	ra,72(sp)
    80004d52:	e0a2                	sd	s0,64(sp)
    80004d54:	fc26                	sd	s1,56(sp)
    80004d56:	f84a                	sd	s2,48(sp)
    80004d58:	f44e                	sd	s3,40(sp)
    80004d5a:	0880                	addi	s0,sp,80
    80004d5c:	84aa                	mv	s1,a0
    80004d5e:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004d60:	ffffd097          	auipc	ra,0xffffd
    80004d64:	f92080e7          	jalr	-110(ra) # 80001cf2 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004d68:	409c                	lw	a5,0(s1)
    80004d6a:	37f9                	addiw	a5,a5,-2
    80004d6c:	4705                	li	a4,1
    80004d6e:	04f76763          	bltu	a4,a5,80004dbc <filestat+0x6e>
    80004d72:	892a                	mv	s2,a0
    ilock(f->ip);
    80004d74:	6c88                	ld	a0,24(s1)
    80004d76:	fffff097          	auipc	ra,0xfffff
    80004d7a:	072080e7          	jalr	114(ra) # 80003de8 <ilock>
    stati(f->ip, &st);
    80004d7e:	fb840593          	addi	a1,s0,-72
    80004d82:	6c88                	ld	a0,24(s1)
    80004d84:	fffff097          	auipc	ra,0xfffff
    80004d88:	2ee080e7          	jalr	750(ra) # 80004072 <stati>
    iunlock(f->ip);
    80004d8c:	6c88                	ld	a0,24(s1)
    80004d8e:	fffff097          	auipc	ra,0xfffff
    80004d92:	11c080e7          	jalr	284(ra) # 80003eaa <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004d96:	46e1                	li	a3,24
    80004d98:	fb840613          	addi	a2,s0,-72
    80004d9c:	85ce                	mv	a1,s3
    80004d9e:	06893503          	ld	a0,104(s2)
    80004da2:	ffffd097          	auipc	ra,0xffffd
    80004da6:	8d0080e7          	jalr	-1840(ra) # 80001672 <copyout>
    80004daa:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004dae:	60a6                	ld	ra,72(sp)
    80004db0:	6406                	ld	s0,64(sp)
    80004db2:	74e2                	ld	s1,56(sp)
    80004db4:	7942                	ld	s2,48(sp)
    80004db6:	79a2                	ld	s3,40(sp)
    80004db8:	6161                	addi	sp,sp,80
    80004dba:	8082                	ret
  return -1;
    80004dbc:	557d                	li	a0,-1
    80004dbe:	bfc5                	j	80004dae <filestat+0x60>

0000000080004dc0 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004dc0:	7179                	addi	sp,sp,-48
    80004dc2:	f406                	sd	ra,40(sp)
    80004dc4:	f022                	sd	s0,32(sp)
    80004dc6:	ec26                	sd	s1,24(sp)
    80004dc8:	e84a                	sd	s2,16(sp)
    80004dca:	e44e                	sd	s3,8(sp)
    80004dcc:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004dce:	00854783          	lbu	a5,8(a0)
    80004dd2:	c3d5                	beqz	a5,80004e76 <fileread+0xb6>
    80004dd4:	84aa                	mv	s1,a0
    80004dd6:	89ae                	mv	s3,a1
    80004dd8:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004dda:	411c                	lw	a5,0(a0)
    80004ddc:	4705                	li	a4,1
    80004dde:	04e78963          	beq	a5,a4,80004e30 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004de2:	470d                	li	a4,3
    80004de4:	04e78d63          	beq	a5,a4,80004e3e <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004de8:	4709                	li	a4,2
    80004dea:	06e79e63          	bne	a5,a4,80004e66 <fileread+0xa6>
    ilock(f->ip);
    80004dee:	6d08                	ld	a0,24(a0)
    80004df0:	fffff097          	auipc	ra,0xfffff
    80004df4:	ff8080e7          	jalr	-8(ra) # 80003de8 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004df8:	874a                	mv	a4,s2
    80004dfa:	5094                	lw	a3,32(s1)
    80004dfc:	864e                	mv	a2,s3
    80004dfe:	4585                	li	a1,1
    80004e00:	6c88                	ld	a0,24(s1)
    80004e02:	fffff097          	auipc	ra,0xfffff
    80004e06:	29a080e7          	jalr	666(ra) # 8000409c <readi>
    80004e0a:	892a                	mv	s2,a0
    80004e0c:	00a05563          	blez	a0,80004e16 <fileread+0x56>
      f->off += r;
    80004e10:	509c                	lw	a5,32(s1)
    80004e12:	9fa9                	addw	a5,a5,a0
    80004e14:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004e16:	6c88                	ld	a0,24(s1)
    80004e18:	fffff097          	auipc	ra,0xfffff
    80004e1c:	092080e7          	jalr	146(ra) # 80003eaa <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004e20:	854a                	mv	a0,s2
    80004e22:	70a2                	ld	ra,40(sp)
    80004e24:	7402                	ld	s0,32(sp)
    80004e26:	64e2                	ld	s1,24(sp)
    80004e28:	6942                	ld	s2,16(sp)
    80004e2a:	69a2                	ld	s3,8(sp)
    80004e2c:	6145                	addi	sp,sp,48
    80004e2e:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004e30:	6908                	ld	a0,16(a0)
    80004e32:	00000097          	auipc	ra,0x0
    80004e36:	3c8080e7          	jalr	968(ra) # 800051fa <piperead>
    80004e3a:	892a                	mv	s2,a0
    80004e3c:	b7d5                	j	80004e20 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004e3e:	02451783          	lh	a5,36(a0)
    80004e42:	03079693          	slli	a3,a5,0x30
    80004e46:	92c1                	srli	a3,a3,0x30
    80004e48:	4725                	li	a4,9
    80004e4a:	02d76863          	bltu	a4,a3,80004e7a <fileread+0xba>
    80004e4e:	0792                	slli	a5,a5,0x4
    80004e50:	0001d717          	auipc	a4,0x1d
    80004e54:	f8870713          	addi	a4,a4,-120 # 80021dd8 <devsw>
    80004e58:	97ba                	add	a5,a5,a4
    80004e5a:	639c                	ld	a5,0(a5)
    80004e5c:	c38d                	beqz	a5,80004e7e <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004e5e:	4505                	li	a0,1
    80004e60:	9782                	jalr	a5
    80004e62:	892a                	mv	s2,a0
    80004e64:	bf75                	j	80004e20 <fileread+0x60>
    panic("fileread");
    80004e66:	00004517          	auipc	a0,0x4
    80004e6a:	b6250513          	addi	a0,a0,-1182 # 800089c8 <syscalls+0x268>
    80004e6e:	ffffb097          	auipc	ra,0xffffb
    80004e72:	6d0080e7          	jalr	1744(ra) # 8000053e <panic>
    return -1;
    80004e76:	597d                	li	s2,-1
    80004e78:	b765                	j	80004e20 <fileread+0x60>
      return -1;
    80004e7a:	597d                	li	s2,-1
    80004e7c:	b755                	j	80004e20 <fileread+0x60>
    80004e7e:	597d                	li	s2,-1
    80004e80:	b745                	j	80004e20 <fileread+0x60>

0000000080004e82 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004e82:	715d                	addi	sp,sp,-80
    80004e84:	e486                	sd	ra,72(sp)
    80004e86:	e0a2                	sd	s0,64(sp)
    80004e88:	fc26                	sd	s1,56(sp)
    80004e8a:	f84a                	sd	s2,48(sp)
    80004e8c:	f44e                	sd	s3,40(sp)
    80004e8e:	f052                	sd	s4,32(sp)
    80004e90:	ec56                	sd	s5,24(sp)
    80004e92:	e85a                	sd	s6,16(sp)
    80004e94:	e45e                	sd	s7,8(sp)
    80004e96:	e062                	sd	s8,0(sp)
    80004e98:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004e9a:	00954783          	lbu	a5,9(a0)
    80004e9e:	10078663          	beqz	a5,80004faa <filewrite+0x128>
    80004ea2:	892a                	mv	s2,a0
    80004ea4:	8aae                	mv	s5,a1
    80004ea6:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004ea8:	411c                	lw	a5,0(a0)
    80004eaa:	4705                	li	a4,1
    80004eac:	02e78263          	beq	a5,a4,80004ed0 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004eb0:	470d                	li	a4,3
    80004eb2:	02e78663          	beq	a5,a4,80004ede <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004eb6:	4709                	li	a4,2
    80004eb8:	0ee79163          	bne	a5,a4,80004f9a <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004ebc:	0ac05d63          	blez	a2,80004f76 <filewrite+0xf4>
    int i = 0;
    80004ec0:	4981                	li	s3,0
    80004ec2:	6b05                	lui	s6,0x1
    80004ec4:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004ec8:	6b85                	lui	s7,0x1
    80004eca:	c00b8b9b          	addiw	s7,s7,-1024
    80004ece:	a861                	j	80004f66 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004ed0:	6908                	ld	a0,16(a0)
    80004ed2:	00000097          	auipc	ra,0x0
    80004ed6:	22e080e7          	jalr	558(ra) # 80005100 <pipewrite>
    80004eda:	8a2a                	mv	s4,a0
    80004edc:	a045                	j	80004f7c <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004ede:	02451783          	lh	a5,36(a0)
    80004ee2:	03079693          	slli	a3,a5,0x30
    80004ee6:	92c1                	srli	a3,a3,0x30
    80004ee8:	4725                	li	a4,9
    80004eea:	0cd76263          	bltu	a4,a3,80004fae <filewrite+0x12c>
    80004eee:	0792                	slli	a5,a5,0x4
    80004ef0:	0001d717          	auipc	a4,0x1d
    80004ef4:	ee870713          	addi	a4,a4,-280 # 80021dd8 <devsw>
    80004ef8:	97ba                	add	a5,a5,a4
    80004efa:	679c                	ld	a5,8(a5)
    80004efc:	cbdd                	beqz	a5,80004fb2 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004efe:	4505                	li	a0,1
    80004f00:	9782                	jalr	a5
    80004f02:	8a2a                	mv	s4,a0
    80004f04:	a8a5                	j	80004f7c <filewrite+0xfa>
    80004f06:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004f0a:	00000097          	auipc	ra,0x0
    80004f0e:	8b0080e7          	jalr	-1872(ra) # 800047ba <begin_op>
      ilock(f->ip);
    80004f12:	01893503          	ld	a0,24(s2)
    80004f16:	fffff097          	auipc	ra,0xfffff
    80004f1a:	ed2080e7          	jalr	-302(ra) # 80003de8 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004f1e:	8762                	mv	a4,s8
    80004f20:	02092683          	lw	a3,32(s2)
    80004f24:	01598633          	add	a2,s3,s5
    80004f28:	4585                	li	a1,1
    80004f2a:	01893503          	ld	a0,24(s2)
    80004f2e:	fffff097          	auipc	ra,0xfffff
    80004f32:	266080e7          	jalr	614(ra) # 80004194 <writei>
    80004f36:	84aa                	mv	s1,a0
    80004f38:	00a05763          	blez	a0,80004f46 <filewrite+0xc4>
        f->off += r;
    80004f3c:	02092783          	lw	a5,32(s2)
    80004f40:	9fa9                	addw	a5,a5,a0
    80004f42:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004f46:	01893503          	ld	a0,24(s2)
    80004f4a:	fffff097          	auipc	ra,0xfffff
    80004f4e:	f60080e7          	jalr	-160(ra) # 80003eaa <iunlock>
      end_op();
    80004f52:	00000097          	auipc	ra,0x0
    80004f56:	8e8080e7          	jalr	-1816(ra) # 8000483a <end_op>

      if(r != n1){
    80004f5a:	009c1f63          	bne	s8,s1,80004f78 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004f5e:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004f62:	0149db63          	bge	s3,s4,80004f78 <filewrite+0xf6>
      int n1 = n - i;
    80004f66:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004f6a:	84be                	mv	s1,a5
    80004f6c:	2781                	sext.w	a5,a5
    80004f6e:	f8fb5ce3          	bge	s6,a5,80004f06 <filewrite+0x84>
    80004f72:	84de                	mv	s1,s7
    80004f74:	bf49                	j	80004f06 <filewrite+0x84>
    int i = 0;
    80004f76:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004f78:	013a1f63          	bne	s4,s3,80004f96 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004f7c:	8552                	mv	a0,s4
    80004f7e:	60a6                	ld	ra,72(sp)
    80004f80:	6406                	ld	s0,64(sp)
    80004f82:	74e2                	ld	s1,56(sp)
    80004f84:	7942                	ld	s2,48(sp)
    80004f86:	79a2                	ld	s3,40(sp)
    80004f88:	7a02                	ld	s4,32(sp)
    80004f8a:	6ae2                	ld	s5,24(sp)
    80004f8c:	6b42                	ld	s6,16(sp)
    80004f8e:	6ba2                	ld	s7,8(sp)
    80004f90:	6c02                	ld	s8,0(sp)
    80004f92:	6161                	addi	sp,sp,80
    80004f94:	8082                	ret
    ret = (i == n ? n : -1);
    80004f96:	5a7d                	li	s4,-1
    80004f98:	b7d5                	j	80004f7c <filewrite+0xfa>
    panic("filewrite");
    80004f9a:	00004517          	auipc	a0,0x4
    80004f9e:	a3e50513          	addi	a0,a0,-1474 # 800089d8 <syscalls+0x278>
    80004fa2:	ffffb097          	auipc	ra,0xffffb
    80004fa6:	59c080e7          	jalr	1436(ra) # 8000053e <panic>
    return -1;
    80004faa:	5a7d                	li	s4,-1
    80004fac:	bfc1                	j	80004f7c <filewrite+0xfa>
      return -1;
    80004fae:	5a7d                	li	s4,-1
    80004fb0:	b7f1                	j	80004f7c <filewrite+0xfa>
    80004fb2:	5a7d                	li	s4,-1
    80004fb4:	b7e1                	j	80004f7c <filewrite+0xfa>

0000000080004fb6 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004fb6:	7179                	addi	sp,sp,-48
    80004fb8:	f406                	sd	ra,40(sp)
    80004fba:	f022                	sd	s0,32(sp)
    80004fbc:	ec26                	sd	s1,24(sp)
    80004fbe:	e84a                	sd	s2,16(sp)
    80004fc0:	e44e                	sd	s3,8(sp)
    80004fc2:	e052                	sd	s4,0(sp)
    80004fc4:	1800                	addi	s0,sp,48
    80004fc6:	84aa                	mv	s1,a0
    80004fc8:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004fca:	0005b023          	sd	zero,0(a1)
    80004fce:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004fd2:	00000097          	auipc	ra,0x0
    80004fd6:	bf8080e7          	jalr	-1032(ra) # 80004bca <filealloc>
    80004fda:	e088                	sd	a0,0(s1)
    80004fdc:	c551                	beqz	a0,80005068 <pipealloc+0xb2>
    80004fde:	00000097          	auipc	ra,0x0
    80004fe2:	bec080e7          	jalr	-1044(ra) # 80004bca <filealloc>
    80004fe6:	00aa3023          	sd	a0,0(s4)
    80004fea:	c92d                	beqz	a0,8000505c <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004fec:	ffffc097          	auipc	ra,0xffffc
    80004ff0:	b08080e7          	jalr	-1272(ra) # 80000af4 <kalloc>
    80004ff4:	892a                	mv	s2,a0
    80004ff6:	c125                	beqz	a0,80005056 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004ff8:	4985                	li	s3,1
    80004ffa:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004ffe:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80005002:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80005006:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    8000500a:	00004597          	auipc	a1,0x4
    8000500e:	9de58593          	addi	a1,a1,-1570 # 800089e8 <syscalls+0x288>
    80005012:	ffffc097          	auipc	ra,0xffffc
    80005016:	b42080e7          	jalr	-1214(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    8000501a:	609c                	ld	a5,0(s1)
    8000501c:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80005020:	609c                	ld	a5,0(s1)
    80005022:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005026:	609c                	ld	a5,0(s1)
    80005028:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000502c:	609c                	ld	a5,0(s1)
    8000502e:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80005032:	000a3783          	ld	a5,0(s4)
    80005036:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000503a:	000a3783          	ld	a5,0(s4)
    8000503e:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005042:	000a3783          	ld	a5,0(s4)
    80005046:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000504a:	000a3783          	ld	a5,0(s4)
    8000504e:	0127b823          	sd	s2,16(a5)
  return 0;
    80005052:	4501                	li	a0,0
    80005054:	a025                	j	8000507c <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80005056:	6088                	ld	a0,0(s1)
    80005058:	e501                	bnez	a0,80005060 <pipealloc+0xaa>
    8000505a:	a039                	j	80005068 <pipealloc+0xb2>
    8000505c:	6088                	ld	a0,0(s1)
    8000505e:	c51d                	beqz	a0,8000508c <pipealloc+0xd6>
    fileclose(*f0);
    80005060:	00000097          	auipc	ra,0x0
    80005064:	c26080e7          	jalr	-986(ra) # 80004c86 <fileclose>
  if(*f1)
    80005068:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000506c:	557d                	li	a0,-1
  if(*f1)
    8000506e:	c799                	beqz	a5,8000507c <pipealloc+0xc6>
    fileclose(*f1);
    80005070:	853e                	mv	a0,a5
    80005072:	00000097          	auipc	ra,0x0
    80005076:	c14080e7          	jalr	-1004(ra) # 80004c86 <fileclose>
  return -1;
    8000507a:	557d                	li	a0,-1
}
    8000507c:	70a2                	ld	ra,40(sp)
    8000507e:	7402                	ld	s0,32(sp)
    80005080:	64e2                	ld	s1,24(sp)
    80005082:	6942                	ld	s2,16(sp)
    80005084:	69a2                	ld	s3,8(sp)
    80005086:	6a02                	ld	s4,0(sp)
    80005088:	6145                	addi	sp,sp,48
    8000508a:	8082                	ret
  return -1;
    8000508c:	557d                	li	a0,-1
    8000508e:	b7fd                	j	8000507c <pipealloc+0xc6>

0000000080005090 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80005090:	1101                	addi	sp,sp,-32
    80005092:	ec06                	sd	ra,24(sp)
    80005094:	e822                	sd	s0,16(sp)
    80005096:	e426                	sd	s1,8(sp)
    80005098:	e04a                	sd	s2,0(sp)
    8000509a:	1000                	addi	s0,sp,32
    8000509c:	84aa                	mv	s1,a0
    8000509e:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800050a0:	ffffc097          	auipc	ra,0xffffc
    800050a4:	b44080e7          	jalr	-1212(ra) # 80000be4 <acquire>
  if(writable){
    800050a8:	02090d63          	beqz	s2,800050e2 <pipeclose+0x52>
    pi->writeopen = 0;
    800050ac:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800050b0:	21848513          	addi	a0,s1,536
    800050b4:	ffffd097          	auipc	ra,0xffffd
    800050b8:	66a080e7          	jalr	1642(ra) # 8000271e <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800050bc:	2204b783          	ld	a5,544(s1)
    800050c0:	eb95                	bnez	a5,800050f4 <pipeclose+0x64>
    release(&pi->lock);
    800050c2:	8526                	mv	a0,s1
    800050c4:	ffffc097          	auipc	ra,0xffffc
    800050c8:	bd4080e7          	jalr	-1068(ra) # 80000c98 <release>
    kfree((char*)pi);
    800050cc:	8526                	mv	a0,s1
    800050ce:	ffffc097          	auipc	ra,0xffffc
    800050d2:	92a080e7          	jalr	-1750(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    800050d6:	60e2                	ld	ra,24(sp)
    800050d8:	6442                	ld	s0,16(sp)
    800050da:	64a2                	ld	s1,8(sp)
    800050dc:	6902                	ld	s2,0(sp)
    800050de:	6105                	addi	sp,sp,32
    800050e0:	8082                	ret
    pi->readopen = 0;
    800050e2:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800050e6:	21c48513          	addi	a0,s1,540
    800050ea:	ffffd097          	auipc	ra,0xffffd
    800050ee:	634080e7          	jalr	1588(ra) # 8000271e <wakeup>
    800050f2:	b7e9                	j	800050bc <pipeclose+0x2c>
    release(&pi->lock);
    800050f4:	8526                	mv	a0,s1
    800050f6:	ffffc097          	auipc	ra,0xffffc
    800050fa:	ba2080e7          	jalr	-1118(ra) # 80000c98 <release>
}
    800050fe:	bfe1                	j	800050d6 <pipeclose+0x46>

0000000080005100 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005100:	7159                	addi	sp,sp,-112
    80005102:	f486                	sd	ra,104(sp)
    80005104:	f0a2                	sd	s0,96(sp)
    80005106:	eca6                	sd	s1,88(sp)
    80005108:	e8ca                	sd	s2,80(sp)
    8000510a:	e4ce                	sd	s3,72(sp)
    8000510c:	e0d2                	sd	s4,64(sp)
    8000510e:	fc56                	sd	s5,56(sp)
    80005110:	f85a                	sd	s6,48(sp)
    80005112:	f45e                	sd	s7,40(sp)
    80005114:	f062                	sd	s8,32(sp)
    80005116:	ec66                	sd	s9,24(sp)
    80005118:	1880                	addi	s0,sp,112
    8000511a:	84aa                	mv	s1,a0
    8000511c:	8aae                	mv	s5,a1
    8000511e:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005120:	ffffd097          	auipc	ra,0xffffd
    80005124:	bd2080e7          	jalr	-1070(ra) # 80001cf2 <myproc>
    80005128:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    8000512a:	8526                	mv	a0,s1
    8000512c:	ffffc097          	auipc	ra,0xffffc
    80005130:	ab8080e7          	jalr	-1352(ra) # 80000be4 <acquire>
  while(i < n){
    80005134:	0d405163          	blez	s4,800051f6 <pipewrite+0xf6>
    80005138:	8ba6                	mv	s7,s1
  int i = 0;
    8000513a:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000513c:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    8000513e:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005142:	21c48c13          	addi	s8,s1,540
    80005146:	a08d                	j	800051a8 <pipewrite+0xa8>
      release(&pi->lock);
    80005148:	8526                	mv	a0,s1
    8000514a:	ffffc097          	auipc	ra,0xffffc
    8000514e:	b4e080e7          	jalr	-1202(ra) # 80000c98 <release>
      return -1;
    80005152:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005154:	854a                	mv	a0,s2
    80005156:	70a6                	ld	ra,104(sp)
    80005158:	7406                	ld	s0,96(sp)
    8000515a:	64e6                	ld	s1,88(sp)
    8000515c:	6946                	ld	s2,80(sp)
    8000515e:	69a6                	ld	s3,72(sp)
    80005160:	6a06                	ld	s4,64(sp)
    80005162:	7ae2                	ld	s5,56(sp)
    80005164:	7b42                	ld	s6,48(sp)
    80005166:	7ba2                	ld	s7,40(sp)
    80005168:	7c02                	ld	s8,32(sp)
    8000516a:	6ce2                	ld	s9,24(sp)
    8000516c:	6165                	addi	sp,sp,112
    8000516e:	8082                	ret
      wakeup(&pi->nread);
    80005170:	8566                	mv	a0,s9
    80005172:	ffffd097          	auipc	ra,0xffffd
    80005176:	5ac080e7          	jalr	1452(ra) # 8000271e <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    8000517a:	85de                	mv	a1,s7
    8000517c:	8562                	mv	a0,s8
    8000517e:	ffffd097          	auipc	ra,0xffffd
    80005182:	1ea080e7          	jalr	490(ra) # 80002368 <sleep>
    80005186:	a839                	j	800051a4 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005188:	21c4a783          	lw	a5,540(s1)
    8000518c:	0017871b          	addiw	a4,a5,1
    80005190:	20e4ae23          	sw	a4,540(s1)
    80005194:	1ff7f793          	andi	a5,a5,511
    80005198:	97a6                	add	a5,a5,s1
    8000519a:	f9f44703          	lbu	a4,-97(s0)
    8000519e:	00e78c23          	sb	a4,24(a5)
      i++;
    800051a2:	2905                	addiw	s2,s2,1
  while(i < n){
    800051a4:	03495d63          	bge	s2,s4,800051de <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    800051a8:	2204a783          	lw	a5,544(s1)
    800051ac:	dfd1                	beqz	a5,80005148 <pipewrite+0x48>
    800051ae:	0409a783          	lw	a5,64(s3)
    800051b2:	fbd9                	bnez	a5,80005148 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800051b4:	2184a783          	lw	a5,536(s1)
    800051b8:	21c4a703          	lw	a4,540(s1)
    800051bc:	2007879b          	addiw	a5,a5,512
    800051c0:	faf708e3          	beq	a4,a5,80005170 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800051c4:	4685                	li	a3,1
    800051c6:	01590633          	add	a2,s2,s5
    800051ca:	f9f40593          	addi	a1,s0,-97
    800051ce:	0689b503          	ld	a0,104(s3)
    800051d2:	ffffc097          	auipc	ra,0xffffc
    800051d6:	52c080e7          	jalr	1324(ra) # 800016fe <copyin>
    800051da:	fb6517e3          	bne	a0,s6,80005188 <pipewrite+0x88>
  wakeup(&pi->nread);
    800051de:	21848513          	addi	a0,s1,536
    800051e2:	ffffd097          	auipc	ra,0xffffd
    800051e6:	53c080e7          	jalr	1340(ra) # 8000271e <wakeup>
  release(&pi->lock);
    800051ea:	8526                	mv	a0,s1
    800051ec:	ffffc097          	auipc	ra,0xffffc
    800051f0:	aac080e7          	jalr	-1364(ra) # 80000c98 <release>
  return i;
    800051f4:	b785                	j	80005154 <pipewrite+0x54>
  int i = 0;
    800051f6:	4901                	li	s2,0
    800051f8:	b7dd                	j	800051de <pipewrite+0xde>

00000000800051fa <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800051fa:	715d                	addi	sp,sp,-80
    800051fc:	e486                	sd	ra,72(sp)
    800051fe:	e0a2                	sd	s0,64(sp)
    80005200:	fc26                	sd	s1,56(sp)
    80005202:	f84a                	sd	s2,48(sp)
    80005204:	f44e                	sd	s3,40(sp)
    80005206:	f052                	sd	s4,32(sp)
    80005208:	ec56                	sd	s5,24(sp)
    8000520a:	e85a                	sd	s6,16(sp)
    8000520c:	0880                	addi	s0,sp,80
    8000520e:	84aa                	mv	s1,a0
    80005210:	892e                	mv	s2,a1
    80005212:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005214:	ffffd097          	auipc	ra,0xffffd
    80005218:	ade080e7          	jalr	-1314(ra) # 80001cf2 <myproc>
    8000521c:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    8000521e:	8b26                	mv	s6,s1
    80005220:	8526                	mv	a0,s1
    80005222:	ffffc097          	auipc	ra,0xffffc
    80005226:	9c2080e7          	jalr	-1598(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000522a:	2184a703          	lw	a4,536(s1)
    8000522e:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005232:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005236:	02f71463          	bne	a4,a5,8000525e <piperead+0x64>
    8000523a:	2244a783          	lw	a5,548(s1)
    8000523e:	c385                	beqz	a5,8000525e <piperead+0x64>
    if(pr->killed){
    80005240:	040a2783          	lw	a5,64(s4)
    80005244:	ebc1                	bnez	a5,800052d4 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005246:	85da                	mv	a1,s6
    80005248:	854e                	mv	a0,s3
    8000524a:	ffffd097          	auipc	ra,0xffffd
    8000524e:	11e080e7          	jalr	286(ra) # 80002368 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005252:	2184a703          	lw	a4,536(s1)
    80005256:	21c4a783          	lw	a5,540(s1)
    8000525a:	fef700e3          	beq	a4,a5,8000523a <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000525e:	09505263          	blez	s5,800052e2 <piperead+0xe8>
    80005262:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005264:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80005266:	2184a783          	lw	a5,536(s1)
    8000526a:	21c4a703          	lw	a4,540(s1)
    8000526e:	02f70d63          	beq	a4,a5,800052a8 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005272:	0017871b          	addiw	a4,a5,1
    80005276:	20e4ac23          	sw	a4,536(s1)
    8000527a:	1ff7f793          	andi	a5,a5,511
    8000527e:	97a6                	add	a5,a5,s1
    80005280:	0187c783          	lbu	a5,24(a5)
    80005284:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005288:	4685                	li	a3,1
    8000528a:	fbf40613          	addi	a2,s0,-65
    8000528e:	85ca                	mv	a1,s2
    80005290:	068a3503          	ld	a0,104(s4)
    80005294:	ffffc097          	auipc	ra,0xffffc
    80005298:	3de080e7          	jalr	990(ra) # 80001672 <copyout>
    8000529c:	01650663          	beq	a0,s6,800052a8 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800052a0:	2985                	addiw	s3,s3,1
    800052a2:	0905                	addi	s2,s2,1
    800052a4:	fd3a91e3          	bne	s5,s3,80005266 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800052a8:	21c48513          	addi	a0,s1,540
    800052ac:	ffffd097          	auipc	ra,0xffffd
    800052b0:	472080e7          	jalr	1138(ra) # 8000271e <wakeup>
  release(&pi->lock);
    800052b4:	8526                	mv	a0,s1
    800052b6:	ffffc097          	auipc	ra,0xffffc
    800052ba:	9e2080e7          	jalr	-1566(ra) # 80000c98 <release>
  return i;
}
    800052be:	854e                	mv	a0,s3
    800052c0:	60a6                	ld	ra,72(sp)
    800052c2:	6406                	ld	s0,64(sp)
    800052c4:	74e2                	ld	s1,56(sp)
    800052c6:	7942                	ld	s2,48(sp)
    800052c8:	79a2                	ld	s3,40(sp)
    800052ca:	7a02                	ld	s4,32(sp)
    800052cc:	6ae2                	ld	s5,24(sp)
    800052ce:	6b42                	ld	s6,16(sp)
    800052d0:	6161                	addi	sp,sp,80
    800052d2:	8082                	ret
      release(&pi->lock);
    800052d4:	8526                	mv	a0,s1
    800052d6:	ffffc097          	auipc	ra,0xffffc
    800052da:	9c2080e7          	jalr	-1598(ra) # 80000c98 <release>
      return -1;
    800052de:	59fd                	li	s3,-1
    800052e0:	bff9                	j	800052be <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800052e2:	4981                	li	s3,0
    800052e4:	b7d1                	j	800052a8 <piperead+0xae>

00000000800052e6 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    800052e6:	df010113          	addi	sp,sp,-528
    800052ea:	20113423          	sd	ra,520(sp)
    800052ee:	20813023          	sd	s0,512(sp)
    800052f2:	ffa6                	sd	s1,504(sp)
    800052f4:	fbca                	sd	s2,496(sp)
    800052f6:	f7ce                	sd	s3,488(sp)
    800052f8:	f3d2                	sd	s4,480(sp)
    800052fa:	efd6                	sd	s5,472(sp)
    800052fc:	ebda                	sd	s6,464(sp)
    800052fe:	e7de                	sd	s7,456(sp)
    80005300:	e3e2                	sd	s8,448(sp)
    80005302:	ff66                	sd	s9,440(sp)
    80005304:	fb6a                	sd	s10,432(sp)
    80005306:	f76e                	sd	s11,424(sp)
    80005308:	0c00                	addi	s0,sp,528
    8000530a:	84aa                	mv	s1,a0
    8000530c:	dea43c23          	sd	a0,-520(s0)
    80005310:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005314:	ffffd097          	auipc	ra,0xffffd
    80005318:	9de080e7          	jalr	-1570(ra) # 80001cf2 <myproc>
    8000531c:	892a                	mv	s2,a0

  begin_op();
    8000531e:	fffff097          	auipc	ra,0xfffff
    80005322:	49c080e7          	jalr	1180(ra) # 800047ba <begin_op>

  if((ip = namei(path)) == 0){
    80005326:	8526                	mv	a0,s1
    80005328:	fffff097          	auipc	ra,0xfffff
    8000532c:	276080e7          	jalr	630(ra) # 8000459e <namei>
    80005330:	c92d                	beqz	a0,800053a2 <exec+0xbc>
    80005332:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005334:	fffff097          	auipc	ra,0xfffff
    80005338:	ab4080e7          	jalr	-1356(ra) # 80003de8 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000533c:	04000713          	li	a4,64
    80005340:	4681                	li	a3,0
    80005342:	e5040613          	addi	a2,s0,-432
    80005346:	4581                	li	a1,0
    80005348:	8526                	mv	a0,s1
    8000534a:	fffff097          	auipc	ra,0xfffff
    8000534e:	d52080e7          	jalr	-686(ra) # 8000409c <readi>
    80005352:	04000793          	li	a5,64
    80005356:	00f51a63          	bne	a0,a5,8000536a <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    8000535a:	e5042703          	lw	a4,-432(s0)
    8000535e:	464c47b7          	lui	a5,0x464c4
    80005362:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005366:	04f70463          	beq	a4,a5,800053ae <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000536a:	8526                	mv	a0,s1
    8000536c:	fffff097          	auipc	ra,0xfffff
    80005370:	cde080e7          	jalr	-802(ra) # 8000404a <iunlockput>
    end_op();
    80005374:	fffff097          	auipc	ra,0xfffff
    80005378:	4c6080e7          	jalr	1222(ra) # 8000483a <end_op>
  }
  return -1;
    8000537c:	557d                	li	a0,-1
}
    8000537e:	20813083          	ld	ra,520(sp)
    80005382:	20013403          	ld	s0,512(sp)
    80005386:	74fe                	ld	s1,504(sp)
    80005388:	795e                	ld	s2,496(sp)
    8000538a:	79be                	ld	s3,488(sp)
    8000538c:	7a1e                	ld	s4,480(sp)
    8000538e:	6afe                	ld	s5,472(sp)
    80005390:	6b5e                	ld	s6,464(sp)
    80005392:	6bbe                	ld	s7,456(sp)
    80005394:	6c1e                	ld	s8,448(sp)
    80005396:	7cfa                	ld	s9,440(sp)
    80005398:	7d5a                	ld	s10,432(sp)
    8000539a:	7dba                	ld	s11,424(sp)
    8000539c:	21010113          	addi	sp,sp,528
    800053a0:	8082                	ret
    end_op();
    800053a2:	fffff097          	auipc	ra,0xfffff
    800053a6:	498080e7          	jalr	1176(ra) # 8000483a <end_op>
    return -1;
    800053aa:	557d                	li	a0,-1
    800053ac:	bfc9                	j	8000537e <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    800053ae:	854a                	mv	a0,s2
    800053b0:	ffffd097          	auipc	ra,0xffffd
    800053b4:	9f8080e7          	jalr	-1544(ra) # 80001da8 <proc_pagetable>
    800053b8:	8baa                	mv	s7,a0
    800053ba:	d945                	beqz	a0,8000536a <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800053bc:	e7042983          	lw	s3,-400(s0)
    800053c0:	e8845783          	lhu	a5,-376(s0)
    800053c4:	c7ad                	beqz	a5,8000542e <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800053c6:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800053c8:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    800053ca:	6c85                	lui	s9,0x1
    800053cc:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    800053d0:	def43823          	sd	a5,-528(s0)
    800053d4:	a42d                	j	800055fe <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800053d6:	00003517          	auipc	a0,0x3
    800053da:	61a50513          	addi	a0,a0,1562 # 800089f0 <syscalls+0x290>
    800053de:	ffffb097          	auipc	ra,0xffffb
    800053e2:	160080e7          	jalr	352(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800053e6:	8756                	mv	a4,s5
    800053e8:	012d86bb          	addw	a3,s11,s2
    800053ec:	4581                	li	a1,0
    800053ee:	8526                	mv	a0,s1
    800053f0:	fffff097          	auipc	ra,0xfffff
    800053f4:	cac080e7          	jalr	-852(ra) # 8000409c <readi>
    800053f8:	2501                	sext.w	a0,a0
    800053fa:	1aaa9963          	bne	s5,a0,800055ac <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    800053fe:	6785                	lui	a5,0x1
    80005400:	0127893b          	addw	s2,a5,s2
    80005404:	77fd                	lui	a5,0xfffff
    80005406:	01478a3b          	addw	s4,a5,s4
    8000540a:	1f897163          	bgeu	s2,s8,800055ec <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    8000540e:	02091593          	slli	a1,s2,0x20
    80005412:	9181                	srli	a1,a1,0x20
    80005414:	95ea                	add	a1,a1,s10
    80005416:	855e                	mv	a0,s7
    80005418:	ffffc097          	auipc	ra,0xffffc
    8000541c:	c56080e7          	jalr	-938(ra) # 8000106e <walkaddr>
    80005420:	862a                	mv	a2,a0
    if(pa == 0)
    80005422:	d955                	beqz	a0,800053d6 <exec+0xf0>
      n = PGSIZE;
    80005424:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80005426:	fd9a70e3          	bgeu	s4,s9,800053e6 <exec+0x100>
      n = sz - i;
    8000542a:	8ad2                	mv	s5,s4
    8000542c:	bf6d                	j	800053e6 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000542e:	4901                	li	s2,0
  iunlockput(ip);
    80005430:	8526                	mv	a0,s1
    80005432:	fffff097          	auipc	ra,0xfffff
    80005436:	c18080e7          	jalr	-1000(ra) # 8000404a <iunlockput>
  end_op();
    8000543a:	fffff097          	auipc	ra,0xfffff
    8000543e:	400080e7          	jalr	1024(ra) # 8000483a <end_op>
  p = myproc();
    80005442:	ffffd097          	auipc	ra,0xffffd
    80005446:	8b0080e7          	jalr	-1872(ra) # 80001cf2 <myproc>
    8000544a:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    8000544c:	06053d03          	ld	s10,96(a0)
  sz = PGROUNDUP(sz);
    80005450:	6785                	lui	a5,0x1
    80005452:	17fd                	addi	a5,a5,-1
    80005454:	993e                	add	s2,s2,a5
    80005456:	757d                	lui	a0,0xfffff
    80005458:	00a977b3          	and	a5,s2,a0
    8000545c:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005460:	6609                	lui	a2,0x2
    80005462:	963e                	add	a2,a2,a5
    80005464:	85be                	mv	a1,a5
    80005466:	855e                	mv	a0,s7
    80005468:	ffffc097          	auipc	ra,0xffffc
    8000546c:	fba080e7          	jalr	-70(ra) # 80001422 <uvmalloc>
    80005470:	8b2a                	mv	s6,a0
  ip = 0;
    80005472:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005474:	12050c63          	beqz	a0,800055ac <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005478:	75f9                	lui	a1,0xffffe
    8000547a:	95aa                	add	a1,a1,a0
    8000547c:	855e                	mv	a0,s7
    8000547e:	ffffc097          	auipc	ra,0xffffc
    80005482:	1c2080e7          	jalr	450(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    80005486:	7c7d                	lui	s8,0xfffff
    80005488:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    8000548a:	e0043783          	ld	a5,-512(s0)
    8000548e:	6388                	ld	a0,0(a5)
    80005490:	c535                	beqz	a0,800054fc <exec+0x216>
    80005492:	e9040993          	addi	s3,s0,-368
    80005496:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    8000549a:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    8000549c:	ffffc097          	auipc	ra,0xffffc
    800054a0:	9c8080e7          	jalr	-1592(ra) # 80000e64 <strlen>
    800054a4:	2505                	addiw	a0,a0,1
    800054a6:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800054aa:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800054ae:	13896363          	bltu	s2,s8,800055d4 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800054b2:	e0043d83          	ld	s11,-512(s0)
    800054b6:	000dba03          	ld	s4,0(s11)
    800054ba:	8552                	mv	a0,s4
    800054bc:	ffffc097          	auipc	ra,0xffffc
    800054c0:	9a8080e7          	jalr	-1624(ra) # 80000e64 <strlen>
    800054c4:	0015069b          	addiw	a3,a0,1
    800054c8:	8652                	mv	a2,s4
    800054ca:	85ca                	mv	a1,s2
    800054cc:	855e                	mv	a0,s7
    800054ce:	ffffc097          	auipc	ra,0xffffc
    800054d2:	1a4080e7          	jalr	420(ra) # 80001672 <copyout>
    800054d6:	10054363          	bltz	a0,800055dc <exec+0x2f6>
    ustack[argc] = sp;
    800054da:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800054de:	0485                	addi	s1,s1,1
    800054e0:	008d8793          	addi	a5,s11,8
    800054e4:	e0f43023          	sd	a5,-512(s0)
    800054e8:	008db503          	ld	a0,8(s11)
    800054ec:	c911                	beqz	a0,80005500 <exec+0x21a>
    if(argc >= MAXARG)
    800054ee:	09a1                	addi	s3,s3,8
    800054f0:	fb3c96e3          	bne	s9,s3,8000549c <exec+0x1b6>
  sz = sz1;
    800054f4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800054f8:	4481                	li	s1,0
    800054fa:	a84d                	j	800055ac <exec+0x2c6>
  sp = sz;
    800054fc:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    800054fe:	4481                	li	s1,0
  ustack[argc] = 0;
    80005500:	00349793          	slli	a5,s1,0x3
    80005504:	f9040713          	addi	a4,s0,-112
    80005508:	97ba                	add	a5,a5,a4
    8000550a:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    8000550e:	00148693          	addi	a3,s1,1
    80005512:	068e                	slli	a3,a3,0x3
    80005514:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005518:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000551c:	01897663          	bgeu	s2,s8,80005528 <exec+0x242>
  sz = sz1;
    80005520:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005524:	4481                	li	s1,0
    80005526:	a059                	j	800055ac <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005528:	e9040613          	addi	a2,s0,-368
    8000552c:	85ca                	mv	a1,s2
    8000552e:	855e                	mv	a0,s7
    80005530:	ffffc097          	auipc	ra,0xffffc
    80005534:	142080e7          	jalr	322(ra) # 80001672 <copyout>
    80005538:	0a054663          	bltz	a0,800055e4 <exec+0x2fe>
  p->trapframe->a1 = sp;
    8000553c:	070ab783          	ld	a5,112(s5)
    80005540:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005544:	df843783          	ld	a5,-520(s0)
    80005548:	0007c703          	lbu	a4,0(a5)
    8000554c:	cf11                	beqz	a4,80005568 <exec+0x282>
    8000554e:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005550:	02f00693          	li	a3,47
    80005554:	a039                	j	80005562 <exec+0x27c>
      last = s+1;
    80005556:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    8000555a:	0785                	addi	a5,a5,1
    8000555c:	fff7c703          	lbu	a4,-1(a5)
    80005560:	c701                	beqz	a4,80005568 <exec+0x282>
    if(*s == '/')
    80005562:	fed71ce3          	bne	a4,a3,8000555a <exec+0x274>
    80005566:	bfc5                	j	80005556 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005568:	4641                	li	a2,16
    8000556a:	df843583          	ld	a1,-520(s0)
    8000556e:	170a8513          	addi	a0,s5,368
    80005572:	ffffc097          	auipc	ra,0xffffc
    80005576:	8c0080e7          	jalr	-1856(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    8000557a:	068ab503          	ld	a0,104(s5)
  p->pagetable = pagetable;
    8000557e:	077ab423          	sd	s7,104(s5)
  p->sz = sz;
    80005582:	076ab023          	sd	s6,96(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005586:	070ab783          	ld	a5,112(s5)
    8000558a:	e6843703          	ld	a4,-408(s0)
    8000558e:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005590:	070ab783          	ld	a5,112(s5)
    80005594:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005598:	85ea                	mv	a1,s10
    8000559a:	ffffd097          	auipc	ra,0xffffd
    8000559e:	8aa080e7          	jalr	-1878(ra) # 80001e44 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800055a2:	0004851b          	sext.w	a0,s1
    800055a6:	bbe1                	j	8000537e <exec+0x98>
    800055a8:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800055ac:	e0843583          	ld	a1,-504(s0)
    800055b0:	855e                	mv	a0,s7
    800055b2:	ffffd097          	auipc	ra,0xffffd
    800055b6:	892080e7          	jalr	-1902(ra) # 80001e44 <proc_freepagetable>
  if(ip){
    800055ba:	da0498e3          	bnez	s1,8000536a <exec+0x84>
  return -1;
    800055be:	557d                	li	a0,-1
    800055c0:	bb7d                	j	8000537e <exec+0x98>
    800055c2:	e1243423          	sd	s2,-504(s0)
    800055c6:	b7dd                	j	800055ac <exec+0x2c6>
    800055c8:	e1243423          	sd	s2,-504(s0)
    800055cc:	b7c5                	j	800055ac <exec+0x2c6>
    800055ce:	e1243423          	sd	s2,-504(s0)
    800055d2:	bfe9                	j	800055ac <exec+0x2c6>
  sz = sz1;
    800055d4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800055d8:	4481                	li	s1,0
    800055da:	bfc9                	j	800055ac <exec+0x2c6>
  sz = sz1;
    800055dc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800055e0:	4481                	li	s1,0
    800055e2:	b7e9                	j	800055ac <exec+0x2c6>
  sz = sz1;
    800055e4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800055e8:	4481                	li	s1,0
    800055ea:	b7c9                	j	800055ac <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800055ec:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800055f0:	2b05                	addiw	s6,s6,1
    800055f2:	0389899b          	addiw	s3,s3,56
    800055f6:	e8845783          	lhu	a5,-376(s0)
    800055fa:	e2fb5be3          	bge	s6,a5,80005430 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800055fe:	2981                	sext.w	s3,s3
    80005600:	03800713          	li	a4,56
    80005604:	86ce                	mv	a3,s3
    80005606:	e1840613          	addi	a2,s0,-488
    8000560a:	4581                	li	a1,0
    8000560c:	8526                	mv	a0,s1
    8000560e:	fffff097          	auipc	ra,0xfffff
    80005612:	a8e080e7          	jalr	-1394(ra) # 8000409c <readi>
    80005616:	03800793          	li	a5,56
    8000561a:	f8f517e3          	bne	a0,a5,800055a8 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    8000561e:	e1842783          	lw	a5,-488(s0)
    80005622:	4705                	li	a4,1
    80005624:	fce796e3          	bne	a5,a4,800055f0 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005628:	e4043603          	ld	a2,-448(s0)
    8000562c:	e3843783          	ld	a5,-456(s0)
    80005630:	f8f669e3          	bltu	a2,a5,800055c2 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005634:	e2843783          	ld	a5,-472(s0)
    80005638:	963e                	add	a2,a2,a5
    8000563a:	f8f667e3          	bltu	a2,a5,800055c8 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000563e:	85ca                	mv	a1,s2
    80005640:	855e                	mv	a0,s7
    80005642:	ffffc097          	auipc	ra,0xffffc
    80005646:	de0080e7          	jalr	-544(ra) # 80001422 <uvmalloc>
    8000564a:	e0a43423          	sd	a0,-504(s0)
    8000564e:	d141                	beqz	a0,800055ce <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80005650:	e2843d03          	ld	s10,-472(s0)
    80005654:	df043783          	ld	a5,-528(s0)
    80005658:	00fd77b3          	and	a5,s10,a5
    8000565c:	fba1                	bnez	a5,800055ac <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000565e:	e2042d83          	lw	s11,-480(s0)
    80005662:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005666:	f80c03e3          	beqz	s8,800055ec <exec+0x306>
    8000566a:	8a62                	mv	s4,s8
    8000566c:	4901                	li	s2,0
    8000566e:	b345                	j	8000540e <exec+0x128>

0000000080005670 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005670:	7179                	addi	sp,sp,-48
    80005672:	f406                	sd	ra,40(sp)
    80005674:	f022                	sd	s0,32(sp)
    80005676:	ec26                	sd	s1,24(sp)
    80005678:	e84a                	sd	s2,16(sp)
    8000567a:	1800                	addi	s0,sp,48
    8000567c:	892e                	mv	s2,a1
    8000567e:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005680:	fdc40593          	addi	a1,s0,-36
    80005684:	ffffe097          	auipc	ra,0xffffe
    80005688:	ba8080e7          	jalr	-1112(ra) # 8000322c <argint>
    8000568c:	04054063          	bltz	a0,800056cc <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005690:	fdc42703          	lw	a4,-36(s0)
    80005694:	47bd                	li	a5,15
    80005696:	02e7ed63          	bltu	a5,a4,800056d0 <argfd+0x60>
    8000569a:	ffffc097          	auipc	ra,0xffffc
    8000569e:	658080e7          	jalr	1624(ra) # 80001cf2 <myproc>
    800056a2:	fdc42703          	lw	a4,-36(s0)
    800056a6:	01c70793          	addi	a5,a4,28
    800056aa:	078e                	slli	a5,a5,0x3
    800056ac:	953e                	add	a0,a0,a5
    800056ae:	651c                	ld	a5,8(a0)
    800056b0:	c395                	beqz	a5,800056d4 <argfd+0x64>
    return -1;
  if(pfd)
    800056b2:	00090463          	beqz	s2,800056ba <argfd+0x4a>
    *pfd = fd;
    800056b6:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800056ba:	4501                	li	a0,0
  if(pf)
    800056bc:	c091                	beqz	s1,800056c0 <argfd+0x50>
    *pf = f;
    800056be:	e09c                	sd	a5,0(s1)
}
    800056c0:	70a2                	ld	ra,40(sp)
    800056c2:	7402                	ld	s0,32(sp)
    800056c4:	64e2                	ld	s1,24(sp)
    800056c6:	6942                	ld	s2,16(sp)
    800056c8:	6145                	addi	sp,sp,48
    800056ca:	8082                	ret
    return -1;
    800056cc:	557d                	li	a0,-1
    800056ce:	bfcd                	j	800056c0 <argfd+0x50>
    return -1;
    800056d0:	557d                	li	a0,-1
    800056d2:	b7fd                	j	800056c0 <argfd+0x50>
    800056d4:	557d                	li	a0,-1
    800056d6:	b7ed                	j	800056c0 <argfd+0x50>

00000000800056d8 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800056d8:	1101                	addi	sp,sp,-32
    800056da:	ec06                	sd	ra,24(sp)
    800056dc:	e822                	sd	s0,16(sp)
    800056de:	e426                	sd	s1,8(sp)
    800056e0:	1000                	addi	s0,sp,32
    800056e2:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800056e4:	ffffc097          	auipc	ra,0xffffc
    800056e8:	60e080e7          	jalr	1550(ra) # 80001cf2 <myproc>
    800056ec:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800056ee:	0e850793          	addi	a5,a0,232 # fffffffffffff0e8 <end+0xffffffff7ffd90e8>
    800056f2:	4501                	li	a0,0
    800056f4:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800056f6:	6398                	ld	a4,0(a5)
    800056f8:	cb19                	beqz	a4,8000570e <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800056fa:	2505                	addiw	a0,a0,1
    800056fc:	07a1                	addi	a5,a5,8
    800056fe:	fed51ce3          	bne	a0,a3,800056f6 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005702:	557d                	li	a0,-1
}
    80005704:	60e2                	ld	ra,24(sp)
    80005706:	6442                	ld	s0,16(sp)
    80005708:	64a2                	ld	s1,8(sp)
    8000570a:	6105                	addi	sp,sp,32
    8000570c:	8082                	ret
      p->ofile[fd] = f;
    8000570e:	01c50793          	addi	a5,a0,28
    80005712:	078e                	slli	a5,a5,0x3
    80005714:	963e                	add	a2,a2,a5
    80005716:	e604                	sd	s1,8(a2)
      return fd;
    80005718:	b7f5                	j	80005704 <fdalloc+0x2c>

000000008000571a <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000571a:	715d                	addi	sp,sp,-80
    8000571c:	e486                	sd	ra,72(sp)
    8000571e:	e0a2                	sd	s0,64(sp)
    80005720:	fc26                	sd	s1,56(sp)
    80005722:	f84a                	sd	s2,48(sp)
    80005724:	f44e                	sd	s3,40(sp)
    80005726:	f052                	sd	s4,32(sp)
    80005728:	ec56                	sd	s5,24(sp)
    8000572a:	0880                	addi	s0,sp,80
    8000572c:	89ae                	mv	s3,a1
    8000572e:	8ab2                	mv	s5,a2
    80005730:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005732:	fb040593          	addi	a1,s0,-80
    80005736:	fffff097          	auipc	ra,0xfffff
    8000573a:	e86080e7          	jalr	-378(ra) # 800045bc <nameiparent>
    8000573e:	892a                	mv	s2,a0
    80005740:	12050f63          	beqz	a0,8000587e <create+0x164>
    return 0;

  ilock(dp);
    80005744:	ffffe097          	auipc	ra,0xffffe
    80005748:	6a4080e7          	jalr	1700(ra) # 80003de8 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000574c:	4601                	li	a2,0
    8000574e:	fb040593          	addi	a1,s0,-80
    80005752:	854a                	mv	a0,s2
    80005754:	fffff097          	auipc	ra,0xfffff
    80005758:	b78080e7          	jalr	-1160(ra) # 800042cc <dirlookup>
    8000575c:	84aa                	mv	s1,a0
    8000575e:	c921                	beqz	a0,800057ae <create+0x94>
    iunlockput(dp);
    80005760:	854a                	mv	a0,s2
    80005762:	fffff097          	auipc	ra,0xfffff
    80005766:	8e8080e7          	jalr	-1816(ra) # 8000404a <iunlockput>
    ilock(ip);
    8000576a:	8526                	mv	a0,s1
    8000576c:	ffffe097          	auipc	ra,0xffffe
    80005770:	67c080e7          	jalr	1660(ra) # 80003de8 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005774:	2981                	sext.w	s3,s3
    80005776:	4789                	li	a5,2
    80005778:	02f99463          	bne	s3,a5,800057a0 <create+0x86>
    8000577c:	0444d783          	lhu	a5,68(s1)
    80005780:	37f9                	addiw	a5,a5,-2
    80005782:	17c2                	slli	a5,a5,0x30
    80005784:	93c1                	srli	a5,a5,0x30
    80005786:	4705                	li	a4,1
    80005788:	00f76c63          	bltu	a4,a5,800057a0 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000578c:	8526                	mv	a0,s1
    8000578e:	60a6                	ld	ra,72(sp)
    80005790:	6406                	ld	s0,64(sp)
    80005792:	74e2                	ld	s1,56(sp)
    80005794:	7942                	ld	s2,48(sp)
    80005796:	79a2                	ld	s3,40(sp)
    80005798:	7a02                	ld	s4,32(sp)
    8000579a:	6ae2                	ld	s5,24(sp)
    8000579c:	6161                	addi	sp,sp,80
    8000579e:	8082                	ret
    iunlockput(ip);
    800057a0:	8526                	mv	a0,s1
    800057a2:	fffff097          	auipc	ra,0xfffff
    800057a6:	8a8080e7          	jalr	-1880(ra) # 8000404a <iunlockput>
    return 0;
    800057aa:	4481                	li	s1,0
    800057ac:	b7c5                	j	8000578c <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800057ae:	85ce                	mv	a1,s3
    800057b0:	00092503          	lw	a0,0(s2)
    800057b4:	ffffe097          	auipc	ra,0xffffe
    800057b8:	49c080e7          	jalr	1180(ra) # 80003c50 <ialloc>
    800057bc:	84aa                	mv	s1,a0
    800057be:	c529                	beqz	a0,80005808 <create+0xee>
  ilock(ip);
    800057c0:	ffffe097          	auipc	ra,0xffffe
    800057c4:	628080e7          	jalr	1576(ra) # 80003de8 <ilock>
  ip->major = major;
    800057c8:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800057cc:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800057d0:	4785                	li	a5,1
    800057d2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800057d6:	8526                	mv	a0,s1
    800057d8:	ffffe097          	auipc	ra,0xffffe
    800057dc:	546080e7          	jalr	1350(ra) # 80003d1e <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800057e0:	2981                	sext.w	s3,s3
    800057e2:	4785                	li	a5,1
    800057e4:	02f98a63          	beq	s3,a5,80005818 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800057e8:	40d0                	lw	a2,4(s1)
    800057ea:	fb040593          	addi	a1,s0,-80
    800057ee:	854a                	mv	a0,s2
    800057f0:	fffff097          	auipc	ra,0xfffff
    800057f4:	cec080e7          	jalr	-788(ra) # 800044dc <dirlink>
    800057f8:	06054b63          	bltz	a0,8000586e <create+0x154>
  iunlockput(dp);
    800057fc:	854a                	mv	a0,s2
    800057fe:	fffff097          	auipc	ra,0xfffff
    80005802:	84c080e7          	jalr	-1972(ra) # 8000404a <iunlockput>
  return ip;
    80005806:	b759                	j	8000578c <create+0x72>
    panic("create: ialloc");
    80005808:	00003517          	auipc	a0,0x3
    8000580c:	20850513          	addi	a0,a0,520 # 80008a10 <syscalls+0x2b0>
    80005810:	ffffb097          	auipc	ra,0xffffb
    80005814:	d2e080e7          	jalr	-722(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005818:	04a95783          	lhu	a5,74(s2)
    8000581c:	2785                	addiw	a5,a5,1
    8000581e:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005822:	854a                	mv	a0,s2
    80005824:	ffffe097          	auipc	ra,0xffffe
    80005828:	4fa080e7          	jalr	1274(ra) # 80003d1e <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000582c:	40d0                	lw	a2,4(s1)
    8000582e:	00003597          	auipc	a1,0x3
    80005832:	1f258593          	addi	a1,a1,498 # 80008a20 <syscalls+0x2c0>
    80005836:	8526                	mv	a0,s1
    80005838:	fffff097          	auipc	ra,0xfffff
    8000583c:	ca4080e7          	jalr	-860(ra) # 800044dc <dirlink>
    80005840:	00054f63          	bltz	a0,8000585e <create+0x144>
    80005844:	00492603          	lw	a2,4(s2)
    80005848:	00003597          	auipc	a1,0x3
    8000584c:	1e058593          	addi	a1,a1,480 # 80008a28 <syscalls+0x2c8>
    80005850:	8526                	mv	a0,s1
    80005852:	fffff097          	auipc	ra,0xfffff
    80005856:	c8a080e7          	jalr	-886(ra) # 800044dc <dirlink>
    8000585a:	f80557e3          	bgez	a0,800057e8 <create+0xce>
      panic("create dots");
    8000585e:	00003517          	auipc	a0,0x3
    80005862:	1d250513          	addi	a0,a0,466 # 80008a30 <syscalls+0x2d0>
    80005866:	ffffb097          	auipc	ra,0xffffb
    8000586a:	cd8080e7          	jalr	-808(ra) # 8000053e <panic>
    panic("create: dirlink");
    8000586e:	00003517          	auipc	a0,0x3
    80005872:	1d250513          	addi	a0,a0,466 # 80008a40 <syscalls+0x2e0>
    80005876:	ffffb097          	auipc	ra,0xffffb
    8000587a:	cc8080e7          	jalr	-824(ra) # 8000053e <panic>
    return 0;
    8000587e:	84aa                	mv	s1,a0
    80005880:	b731                	j	8000578c <create+0x72>

0000000080005882 <sys_dup>:
{
    80005882:	7179                	addi	sp,sp,-48
    80005884:	f406                	sd	ra,40(sp)
    80005886:	f022                	sd	s0,32(sp)
    80005888:	ec26                	sd	s1,24(sp)
    8000588a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000588c:	fd840613          	addi	a2,s0,-40
    80005890:	4581                	li	a1,0
    80005892:	4501                	li	a0,0
    80005894:	00000097          	auipc	ra,0x0
    80005898:	ddc080e7          	jalr	-548(ra) # 80005670 <argfd>
    return -1;
    8000589c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000589e:	02054363          	bltz	a0,800058c4 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800058a2:	fd843503          	ld	a0,-40(s0)
    800058a6:	00000097          	auipc	ra,0x0
    800058aa:	e32080e7          	jalr	-462(ra) # 800056d8 <fdalloc>
    800058ae:	84aa                	mv	s1,a0
    return -1;
    800058b0:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800058b2:	00054963          	bltz	a0,800058c4 <sys_dup+0x42>
  filedup(f);
    800058b6:	fd843503          	ld	a0,-40(s0)
    800058ba:	fffff097          	auipc	ra,0xfffff
    800058be:	37a080e7          	jalr	890(ra) # 80004c34 <filedup>
  return fd;
    800058c2:	87a6                	mv	a5,s1
}
    800058c4:	853e                	mv	a0,a5
    800058c6:	70a2                	ld	ra,40(sp)
    800058c8:	7402                	ld	s0,32(sp)
    800058ca:	64e2                	ld	s1,24(sp)
    800058cc:	6145                	addi	sp,sp,48
    800058ce:	8082                	ret

00000000800058d0 <sys_read>:
{
    800058d0:	7179                	addi	sp,sp,-48
    800058d2:	f406                	sd	ra,40(sp)
    800058d4:	f022                	sd	s0,32(sp)
    800058d6:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800058d8:	fe840613          	addi	a2,s0,-24
    800058dc:	4581                	li	a1,0
    800058de:	4501                	li	a0,0
    800058e0:	00000097          	auipc	ra,0x0
    800058e4:	d90080e7          	jalr	-624(ra) # 80005670 <argfd>
    return -1;
    800058e8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800058ea:	04054163          	bltz	a0,8000592c <sys_read+0x5c>
    800058ee:	fe440593          	addi	a1,s0,-28
    800058f2:	4509                	li	a0,2
    800058f4:	ffffe097          	auipc	ra,0xffffe
    800058f8:	938080e7          	jalr	-1736(ra) # 8000322c <argint>
    return -1;
    800058fc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800058fe:	02054763          	bltz	a0,8000592c <sys_read+0x5c>
    80005902:	fd840593          	addi	a1,s0,-40
    80005906:	4505                	li	a0,1
    80005908:	ffffe097          	auipc	ra,0xffffe
    8000590c:	946080e7          	jalr	-1722(ra) # 8000324e <argaddr>
    return -1;
    80005910:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005912:	00054d63          	bltz	a0,8000592c <sys_read+0x5c>
  return fileread(f, p, n);
    80005916:	fe442603          	lw	a2,-28(s0)
    8000591a:	fd843583          	ld	a1,-40(s0)
    8000591e:	fe843503          	ld	a0,-24(s0)
    80005922:	fffff097          	auipc	ra,0xfffff
    80005926:	49e080e7          	jalr	1182(ra) # 80004dc0 <fileread>
    8000592a:	87aa                	mv	a5,a0
}
    8000592c:	853e                	mv	a0,a5
    8000592e:	70a2                	ld	ra,40(sp)
    80005930:	7402                	ld	s0,32(sp)
    80005932:	6145                	addi	sp,sp,48
    80005934:	8082                	ret

0000000080005936 <sys_write>:
{
    80005936:	7179                	addi	sp,sp,-48
    80005938:	f406                	sd	ra,40(sp)
    8000593a:	f022                	sd	s0,32(sp)
    8000593c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000593e:	fe840613          	addi	a2,s0,-24
    80005942:	4581                	li	a1,0
    80005944:	4501                	li	a0,0
    80005946:	00000097          	auipc	ra,0x0
    8000594a:	d2a080e7          	jalr	-726(ra) # 80005670 <argfd>
    return -1;
    8000594e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005950:	04054163          	bltz	a0,80005992 <sys_write+0x5c>
    80005954:	fe440593          	addi	a1,s0,-28
    80005958:	4509                	li	a0,2
    8000595a:	ffffe097          	auipc	ra,0xffffe
    8000595e:	8d2080e7          	jalr	-1838(ra) # 8000322c <argint>
    return -1;
    80005962:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005964:	02054763          	bltz	a0,80005992 <sys_write+0x5c>
    80005968:	fd840593          	addi	a1,s0,-40
    8000596c:	4505                	li	a0,1
    8000596e:	ffffe097          	auipc	ra,0xffffe
    80005972:	8e0080e7          	jalr	-1824(ra) # 8000324e <argaddr>
    return -1;
    80005976:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005978:	00054d63          	bltz	a0,80005992 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000597c:	fe442603          	lw	a2,-28(s0)
    80005980:	fd843583          	ld	a1,-40(s0)
    80005984:	fe843503          	ld	a0,-24(s0)
    80005988:	fffff097          	auipc	ra,0xfffff
    8000598c:	4fa080e7          	jalr	1274(ra) # 80004e82 <filewrite>
    80005990:	87aa                	mv	a5,a0
}
    80005992:	853e                	mv	a0,a5
    80005994:	70a2                	ld	ra,40(sp)
    80005996:	7402                	ld	s0,32(sp)
    80005998:	6145                	addi	sp,sp,48
    8000599a:	8082                	ret

000000008000599c <sys_close>:
{
    8000599c:	1101                	addi	sp,sp,-32
    8000599e:	ec06                	sd	ra,24(sp)
    800059a0:	e822                	sd	s0,16(sp)
    800059a2:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800059a4:	fe040613          	addi	a2,s0,-32
    800059a8:	fec40593          	addi	a1,s0,-20
    800059ac:	4501                	li	a0,0
    800059ae:	00000097          	auipc	ra,0x0
    800059b2:	cc2080e7          	jalr	-830(ra) # 80005670 <argfd>
    return -1;
    800059b6:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800059b8:	02054463          	bltz	a0,800059e0 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800059bc:	ffffc097          	auipc	ra,0xffffc
    800059c0:	336080e7          	jalr	822(ra) # 80001cf2 <myproc>
    800059c4:	fec42783          	lw	a5,-20(s0)
    800059c8:	07f1                	addi	a5,a5,28
    800059ca:	078e                	slli	a5,a5,0x3
    800059cc:	97aa                	add	a5,a5,a0
    800059ce:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    800059d2:	fe043503          	ld	a0,-32(s0)
    800059d6:	fffff097          	auipc	ra,0xfffff
    800059da:	2b0080e7          	jalr	688(ra) # 80004c86 <fileclose>
  return 0;
    800059de:	4781                	li	a5,0
}
    800059e0:	853e                	mv	a0,a5
    800059e2:	60e2                	ld	ra,24(sp)
    800059e4:	6442                	ld	s0,16(sp)
    800059e6:	6105                	addi	sp,sp,32
    800059e8:	8082                	ret

00000000800059ea <sys_fstat>:
{
    800059ea:	1101                	addi	sp,sp,-32
    800059ec:	ec06                	sd	ra,24(sp)
    800059ee:	e822                	sd	s0,16(sp)
    800059f0:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800059f2:	fe840613          	addi	a2,s0,-24
    800059f6:	4581                	li	a1,0
    800059f8:	4501                	li	a0,0
    800059fa:	00000097          	auipc	ra,0x0
    800059fe:	c76080e7          	jalr	-906(ra) # 80005670 <argfd>
    return -1;
    80005a02:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005a04:	02054563          	bltz	a0,80005a2e <sys_fstat+0x44>
    80005a08:	fe040593          	addi	a1,s0,-32
    80005a0c:	4505                	li	a0,1
    80005a0e:	ffffe097          	auipc	ra,0xffffe
    80005a12:	840080e7          	jalr	-1984(ra) # 8000324e <argaddr>
    return -1;
    80005a16:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005a18:	00054b63          	bltz	a0,80005a2e <sys_fstat+0x44>
  return filestat(f, st);
    80005a1c:	fe043583          	ld	a1,-32(s0)
    80005a20:	fe843503          	ld	a0,-24(s0)
    80005a24:	fffff097          	auipc	ra,0xfffff
    80005a28:	32a080e7          	jalr	810(ra) # 80004d4e <filestat>
    80005a2c:	87aa                	mv	a5,a0
}
    80005a2e:	853e                	mv	a0,a5
    80005a30:	60e2                	ld	ra,24(sp)
    80005a32:	6442                	ld	s0,16(sp)
    80005a34:	6105                	addi	sp,sp,32
    80005a36:	8082                	ret

0000000080005a38 <sys_link>:
{
    80005a38:	7169                	addi	sp,sp,-304
    80005a3a:	f606                	sd	ra,296(sp)
    80005a3c:	f222                	sd	s0,288(sp)
    80005a3e:	ee26                	sd	s1,280(sp)
    80005a40:	ea4a                	sd	s2,272(sp)
    80005a42:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a44:	08000613          	li	a2,128
    80005a48:	ed040593          	addi	a1,s0,-304
    80005a4c:	4501                	li	a0,0
    80005a4e:	ffffe097          	auipc	ra,0xffffe
    80005a52:	822080e7          	jalr	-2014(ra) # 80003270 <argstr>
    return -1;
    80005a56:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a58:	10054e63          	bltz	a0,80005b74 <sys_link+0x13c>
    80005a5c:	08000613          	li	a2,128
    80005a60:	f5040593          	addi	a1,s0,-176
    80005a64:	4505                	li	a0,1
    80005a66:	ffffe097          	auipc	ra,0xffffe
    80005a6a:	80a080e7          	jalr	-2038(ra) # 80003270 <argstr>
    return -1;
    80005a6e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a70:	10054263          	bltz	a0,80005b74 <sys_link+0x13c>
  begin_op();
    80005a74:	fffff097          	auipc	ra,0xfffff
    80005a78:	d46080e7          	jalr	-698(ra) # 800047ba <begin_op>
  if((ip = namei(old)) == 0){
    80005a7c:	ed040513          	addi	a0,s0,-304
    80005a80:	fffff097          	auipc	ra,0xfffff
    80005a84:	b1e080e7          	jalr	-1250(ra) # 8000459e <namei>
    80005a88:	84aa                	mv	s1,a0
    80005a8a:	c551                	beqz	a0,80005b16 <sys_link+0xde>
  ilock(ip);
    80005a8c:	ffffe097          	auipc	ra,0xffffe
    80005a90:	35c080e7          	jalr	860(ra) # 80003de8 <ilock>
  if(ip->type == T_DIR){
    80005a94:	04449703          	lh	a4,68(s1)
    80005a98:	4785                	li	a5,1
    80005a9a:	08f70463          	beq	a4,a5,80005b22 <sys_link+0xea>
  ip->nlink++;
    80005a9e:	04a4d783          	lhu	a5,74(s1)
    80005aa2:	2785                	addiw	a5,a5,1
    80005aa4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005aa8:	8526                	mv	a0,s1
    80005aaa:	ffffe097          	auipc	ra,0xffffe
    80005aae:	274080e7          	jalr	628(ra) # 80003d1e <iupdate>
  iunlock(ip);
    80005ab2:	8526                	mv	a0,s1
    80005ab4:	ffffe097          	auipc	ra,0xffffe
    80005ab8:	3f6080e7          	jalr	1014(ra) # 80003eaa <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005abc:	fd040593          	addi	a1,s0,-48
    80005ac0:	f5040513          	addi	a0,s0,-176
    80005ac4:	fffff097          	auipc	ra,0xfffff
    80005ac8:	af8080e7          	jalr	-1288(ra) # 800045bc <nameiparent>
    80005acc:	892a                	mv	s2,a0
    80005ace:	c935                	beqz	a0,80005b42 <sys_link+0x10a>
  ilock(dp);
    80005ad0:	ffffe097          	auipc	ra,0xffffe
    80005ad4:	318080e7          	jalr	792(ra) # 80003de8 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005ad8:	00092703          	lw	a4,0(s2)
    80005adc:	409c                	lw	a5,0(s1)
    80005ade:	04f71d63          	bne	a4,a5,80005b38 <sys_link+0x100>
    80005ae2:	40d0                	lw	a2,4(s1)
    80005ae4:	fd040593          	addi	a1,s0,-48
    80005ae8:	854a                	mv	a0,s2
    80005aea:	fffff097          	auipc	ra,0xfffff
    80005aee:	9f2080e7          	jalr	-1550(ra) # 800044dc <dirlink>
    80005af2:	04054363          	bltz	a0,80005b38 <sys_link+0x100>
  iunlockput(dp);
    80005af6:	854a                	mv	a0,s2
    80005af8:	ffffe097          	auipc	ra,0xffffe
    80005afc:	552080e7          	jalr	1362(ra) # 8000404a <iunlockput>
  iput(ip);
    80005b00:	8526                	mv	a0,s1
    80005b02:	ffffe097          	auipc	ra,0xffffe
    80005b06:	4a0080e7          	jalr	1184(ra) # 80003fa2 <iput>
  end_op();
    80005b0a:	fffff097          	auipc	ra,0xfffff
    80005b0e:	d30080e7          	jalr	-720(ra) # 8000483a <end_op>
  return 0;
    80005b12:	4781                	li	a5,0
    80005b14:	a085                	j	80005b74 <sys_link+0x13c>
    end_op();
    80005b16:	fffff097          	auipc	ra,0xfffff
    80005b1a:	d24080e7          	jalr	-732(ra) # 8000483a <end_op>
    return -1;
    80005b1e:	57fd                	li	a5,-1
    80005b20:	a891                	j	80005b74 <sys_link+0x13c>
    iunlockput(ip);
    80005b22:	8526                	mv	a0,s1
    80005b24:	ffffe097          	auipc	ra,0xffffe
    80005b28:	526080e7          	jalr	1318(ra) # 8000404a <iunlockput>
    end_op();
    80005b2c:	fffff097          	auipc	ra,0xfffff
    80005b30:	d0e080e7          	jalr	-754(ra) # 8000483a <end_op>
    return -1;
    80005b34:	57fd                	li	a5,-1
    80005b36:	a83d                	j	80005b74 <sys_link+0x13c>
    iunlockput(dp);
    80005b38:	854a                	mv	a0,s2
    80005b3a:	ffffe097          	auipc	ra,0xffffe
    80005b3e:	510080e7          	jalr	1296(ra) # 8000404a <iunlockput>
  ilock(ip);
    80005b42:	8526                	mv	a0,s1
    80005b44:	ffffe097          	auipc	ra,0xffffe
    80005b48:	2a4080e7          	jalr	676(ra) # 80003de8 <ilock>
  ip->nlink--;
    80005b4c:	04a4d783          	lhu	a5,74(s1)
    80005b50:	37fd                	addiw	a5,a5,-1
    80005b52:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005b56:	8526                	mv	a0,s1
    80005b58:	ffffe097          	auipc	ra,0xffffe
    80005b5c:	1c6080e7          	jalr	454(ra) # 80003d1e <iupdate>
  iunlockput(ip);
    80005b60:	8526                	mv	a0,s1
    80005b62:	ffffe097          	auipc	ra,0xffffe
    80005b66:	4e8080e7          	jalr	1256(ra) # 8000404a <iunlockput>
  end_op();
    80005b6a:	fffff097          	auipc	ra,0xfffff
    80005b6e:	cd0080e7          	jalr	-816(ra) # 8000483a <end_op>
  return -1;
    80005b72:	57fd                	li	a5,-1
}
    80005b74:	853e                	mv	a0,a5
    80005b76:	70b2                	ld	ra,296(sp)
    80005b78:	7412                	ld	s0,288(sp)
    80005b7a:	64f2                	ld	s1,280(sp)
    80005b7c:	6952                	ld	s2,272(sp)
    80005b7e:	6155                	addi	sp,sp,304
    80005b80:	8082                	ret

0000000080005b82 <sys_unlink>:
{
    80005b82:	7151                	addi	sp,sp,-240
    80005b84:	f586                	sd	ra,232(sp)
    80005b86:	f1a2                	sd	s0,224(sp)
    80005b88:	eda6                	sd	s1,216(sp)
    80005b8a:	e9ca                	sd	s2,208(sp)
    80005b8c:	e5ce                	sd	s3,200(sp)
    80005b8e:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005b90:	08000613          	li	a2,128
    80005b94:	f3040593          	addi	a1,s0,-208
    80005b98:	4501                	li	a0,0
    80005b9a:	ffffd097          	auipc	ra,0xffffd
    80005b9e:	6d6080e7          	jalr	1750(ra) # 80003270 <argstr>
    80005ba2:	18054163          	bltz	a0,80005d24 <sys_unlink+0x1a2>
  begin_op();
    80005ba6:	fffff097          	auipc	ra,0xfffff
    80005baa:	c14080e7          	jalr	-1004(ra) # 800047ba <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005bae:	fb040593          	addi	a1,s0,-80
    80005bb2:	f3040513          	addi	a0,s0,-208
    80005bb6:	fffff097          	auipc	ra,0xfffff
    80005bba:	a06080e7          	jalr	-1530(ra) # 800045bc <nameiparent>
    80005bbe:	84aa                	mv	s1,a0
    80005bc0:	c979                	beqz	a0,80005c96 <sys_unlink+0x114>
  ilock(dp);
    80005bc2:	ffffe097          	auipc	ra,0xffffe
    80005bc6:	226080e7          	jalr	550(ra) # 80003de8 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005bca:	00003597          	auipc	a1,0x3
    80005bce:	e5658593          	addi	a1,a1,-426 # 80008a20 <syscalls+0x2c0>
    80005bd2:	fb040513          	addi	a0,s0,-80
    80005bd6:	ffffe097          	auipc	ra,0xffffe
    80005bda:	6dc080e7          	jalr	1756(ra) # 800042b2 <namecmp>
    80005bde:	14050a63          	beqz	a0,80005d32 <sys_unlink+0x1b0>
    80005be2:	00003597          	auipc	a1,0x3
    80005be6:	e4658593          	addi	a1,a1,-442 # 80008a28 <syscalls+0x2c8>
    80005bea:	fb040513          	addi	a0,s0,-80
    80005bee:	ffffe097          	auipc	ra,0xffffe
    80005bf2:	6c4080e7          	jalr	1732(ra) # 800042b2 <namecmp>
    80005bf6:	12050e63          	beqz	a0,80005d32 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005bfa:	f2c40613          	addi	a2,s0,-212
    80005bfe:	fb040593          	addi	a1,s0,-80
    80005c02:	8526                	mv	a0,s1
    80005c04:	ffffe097          	auipc	ra,0xffffe
    80005c08:	6c8080e7          	jalr	1736(ra) # 800042cc <dirlookup>
    80005c0c:	892a                	mv	s2,a0
    80005c0e:	12050263          	beqz	a0,80005d32 <sys_unlink+0x1b0>
  ilock(ip);
    80005c12:	ffffe097          	auipc	ra,0xffffe
    80005c16:	1d6080e7          	jalr	470(ra) # 80003de8 <ilock>
  if(ip->nlink < 1)
    80005c1a:	04a91783          	lh	a5,74(s2)
    80005c1e:	08f05263          	blez	a5,80005ca2 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005c22:	04491703          	lh	a4,68(s2)
    80005c26:	4785                	li	a5,1
    80005c28:	08f70563          	beq	a4,a5,80005cb2 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005c2c:	4641                	li	a2,16
    80005c2e:	4581                	li	a1,0
    80005c30:	fc040513          	addi	a0,s0,-64
    80005c34:	ffffb097          	auipc	ra,0xffffb
    80005c38:	0ac080e7          	jalr	172(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005c3c:	4741                	li	a4,16
    80005c3e:	f2c42683          	lw	a3,-212(s0)
    80005c42:	fc040613          	addi	a2,s0,-64
    80005c46:	4581                	li	a1,0
    80005c48:	8526                	mv	a0,s1
    80005c4a:	ffffe097          	auipc	ra,0xffffe
    80005c4e:	54a080e7          	jalr	1354(ra) # 80004194 <writei>
    80005c52:	47c1                	li	a5,16
    80005c54:	0af51563          	bne	a0,a5,80005cfe <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005c58:	04491703          	lh	a4,68(s2)
    80005c5c:	4785                	li	a5,1
    80005c5e:	0af70863          	beq	a4,a5,80005d0e <sys_unlink+0x18c>
  iunlockput(dp);
    80005c62:	8526                	mv	a0,s1
    80005c64:	ffffe097          	auipc	ra,0xffffe
    80005c68:	3e6080e7          	jalr	998(ra) # 8000404a <iunlockput>
  ip->nlink--;
    80005c6c:	04a95783          	lhu	a5,74(s2)
    80005c70:	37fd                	addiw	a5,a5,-1
    80005c72:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005c76:	854a                	mv	a0,s2
    80005c78:	ffffe097          	auipc	ra,0xffffe
    80005c7c:	0a6080e7          	jalr	166(ra) # 80003d1e <iupdate>
  iunlockput(ip);
    80005c80:	854a                	mv	a0,s2
    80005c82:	ffffe097          	auipc	ra,0xffffe
    80005c86:	3c8080e7          	jalr	968(ra) # 8000404a <iunlockput>
  end_op();
    80005c8a:	fffff097          	auipc	ra,0xfffff
    80005c8e:	bb0080e7          	jalr	-1104(ra) # 8000483a <end_op>
  return 0;
    80005c92:	4501                	li	a0,0
    80005c94:	a84d                	j	80005d46 <sys_unlink+0x1c4>
    end_op();
    80005c96:	fffff097          	auipc	ra,0xfffff
    80005c9a:	ba4080e7          	jalr	-1116(ra) # 8000483a <end_op>
    return -1;
    80005c9e:	557d                	li	a0,-1
    80005ca0:	a05d                	j	80005d46 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005ca2:	00003517          	auipc	a0,0x3
    80005ca6:	dae50513          	addi	a0,a0,-594 # 80008a50 <syscalls+0x2f0>
    80005caa:	ffffb097          	auipc	ra,0xffffb
    80005cae:	894080e7          	jalr	-1900(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005cb2:	04c92703          	lw	a4,76(s2)
    80005cb6:	02000793          	li	a5,32
    80005cba:	f6e7f9e3          	bgeu	a5,a4,80005c2c <sys_unlink+0xaa>
    80005cbe:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005cc2:	4741                	li	a4,16
    80005cc4:	86ce                	mv	a3,s3
    80005cc6:	f1840613          	addi	a2,s0,-232
    80005cca:	4581                	li	a1,0
    80005ccc:	854a                	mv	a0,s2
    80005cce:	ffffe097          	auipc	ra,0xffffe
    80005cd2:	3ce080e7          	jalr	974(ra) # 8000409c <readi>
    80005cd6:	47c1                	li	a5,16
    80005cd8:	00f51b63          	bne	a0,a5,80005cee <sys_unlink+0x16c>
    if(de.inum != 0)
    80005cdc:	f1845783          	lhu	a5,-232(s0)
    80005ce0:	e7a1                	bnez	a5,80005d28 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005ce2:	29c1                	addiw	s3,s3,16
    80005ce4:	04c92783          	lw	a5,76(s2)
    80005ce8:	fcf9ede3          	bltu	s3,a5,80005cc2 <sys_unlink+0x140>
    80005cec:	b781                	j	80005c2c <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005cee:	00003517          	auipc	a0,0x3
    80005cf2:	d7a50513          	addi	a0,a0,-646 # 80008a68 <syscalls+0x308>
    80005cf6:	ffffb097          	auipc	ra,0xffffb
    80005cfa:	848080e7          	jalr	-1976(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005cfe:	00003517          	auipc	a0,0x3
    80005d02:	d8250513          	addi	a0,a0,-638 # 80008a80 <syscalls+0x320>
    80005d06:	ffffb097          	auipc	ra,0xffffb
    80005d0a:	838080e7          	jalr	-1992(ra) # 8000053e <panic>
    dp->nlink--;
    80005d0e:	04a4d783          	lhu	a5,74(s1)
    80005d12:	37fd                	addiw	a5,a5,-1
    80005d14:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005d18:	8526                	mv	a0,s1
    80005d1a:	ffffe097          	auipc	ra,0xffffe
    80005d1e:	004080e7          	jalr	4(ra) # 80003d1e <iupdate>
    80005d22:	b781                	j	80005c62 <sys_unlink+0xe0>
    return -1;
    80005d24:	557d                	li	a0,-1
    80005d26:	a005                	j	80005d46 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005d28:	854a                	mv	a0,s2
    80005d2a:	ffffe097          	auipc	ra,0xffffe
    80005d2e:	320080e7          	jalr	800(ra) # 8000404a <iunlockput>
  iunlockput(dp);
    80005d32:	8526                	mv	a0,s1
    80005d34:	ffffe097          	auipc	ra,0xffffe
    80005d38:	316080e7          	jalr	790(ra) # 8000404a <iunlockput>
  end_op();
    80005d3c:	fffff097          	auipc	ra,0xfffff
    80005d40:	afe080e7          	jalr	-1282(ra) # 8000483a <end_op>
  return -1;
    80005d44:	557d                	li	a0,-1
}
    80005d46:	70ae                	ld	ra,232(sp)
    80005d48:	740e                	ld	s0,224(sp)
    80005d4a:	64ee                	ld	s1,216(sp)
    80005d4c:	694e                	ld	s2,208(sp)
    80005d4e:	69ae                	ld	s3,200(sp)
    80005d50:	616d                	addi	sp,sp,240
    80005d52:	8082                	ret

0000000080005d54 <sys_open>:

uint64
sys_open(void)
{
    80005d54:	7131                	addi	sp,sp,-192
    80005d56:	fd06                	sd	ra,184(sp)
    80005d58:	f922                	sd	s0,176(sp)
    80005d5a:	f526                	sd	s1,168(sp)
    80005d5c:	f14a                	sd	s2,160(sp)
    80005d5e:	ed4e                	sd	s3,152(sp)
    80005d60:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005d62:	08000613          	li	a2,128
    80005d66:	f5040593          	addi	a1,s0,-176
    80005d6a:	4501                	li	a0,0
    80005d6c:	ffffd097          	auipc	ra,0xffffd
    80005d70:	504080e7          	jalr	1284(ra) # 80003270 <argstr>
    return -1;
    80005d74:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005d76:	0c054163          	bltz	a0,80005e38 <sys_open+0xe4>
    80005d7a:	f4c40593          	addi	a1,s0,-180
    80005d7e:	4505                	li	a0,1
    80005d80:	ffffd097          	auipc	ra,0xffffd
    80005d84:	4ac080e7          	jalr	1196(ra) # 8000322c <argint>
    80005d88:	0a054863          	bltz	a0,80005e38 <sys_open+0xe4>

  begin_op();
    80005d8c:	fffff097          	auipc	ra,0xfffff
    80005d90:	a2e080e7          	jalr	-1490(ra) # 800047ba <begin_op>

  if(omode & O_CREATE){
    80005d94:	f4c42783          	lw	a5,-180(s0)
    80005d98:	2007f793          	andi	a5,a5,512
    80005d9c:	cbdd                	beqz	a5,80005e52 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005d9e:	4681                	li	a3,0
    80005da0:	4601                	li	a2,0
    80005da2:	4589                	li	a1,2
    80005da4:	f5040513          	addi	a0,s0,-176
    80005da8:	00000097          	auipc	ra,0x0
    80005dac:	972080e7          	jalr	-1678(ra) # 8000571a <create>
    80005db0:	892a                	mv	s2,a0
    if(ip == 0){
    80005db2:	c959                	beqz	a0,80005e48 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005db4:	04491703          	lh	a4,68(s2)
    80005db8:	478d                	li	a5,3
    80005dba:	00f71763          	bne	a4,a5,80005dc8 <sys_open+0x74>
    80005dbe:	04695703          	lhu	a4,70(s2)
    80005dc2:	47a5                	li	a5,9
    80005dc4:	0ce7ec63          	bltu	a5,a4,80005e9c <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005dc8:	fffff097          	auipc	ra,0xfffff
    80005dcc:	e02080e7          	jalr	-510(ra) # 80004bca <filealloc>
    80005dd0:	89aa                	mv	s3,a0
    80005dd2:	10050263          	beqz	a0,80005ed6 <sys_open+0x182>
    80005dd6:	00000097          	auipc	ra,0x0
    80005dda:	902080e7          	jalr	-1790(ra) # 800056d8 <fdalloc>
    80005dde:	84aa                	mv	s1,a0
    80005de0:	0e054663          	bltz	a0,80005ecc <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005de4:	04491703          	lh	a4,68(s2)
    80005de8:	478d                	li	a5,3
    80005dea:	0cf70463          	beq	a4,a5,80005eb2 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005dee:	4789                	li	a5,2
    80005df0:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005df4:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005df8:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005dfc:	f4c42783          	lw	a5,-180(s0)
    80005e00:	0017c713          	xori	a4,a5,1
    80005e04:	8b05                	andi	a4,a4,1
    80005e06:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005e0a:	0037f713          	andi	a4,a5,3
    80005e0e:	00e03733          	snez	a4,a4
    80005e12:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005e16:	4007f793          	andi	a5,a5,1024
    80005e1a:	c791                	beqz	a5,80005e26 <sys_open+0xd2>
    80005e1c:	04491703          	lh	a4,68(s2)
    80005e20:	4789                	li	a5,2
    80005e22:	08f70f63          	beq	a4,a5,80005ec0 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005e26:	854a                	mv	a0,s2
    80005e28:	ffffe097          	auipc	ra,0xffffe
    80005e2c:	082080e7          	jalr	130(ra) # 80003eaa <iunlock>
  end_op();
    80005e30:	fffff097          	auipc	ra,0xfffff
    80005e34:	a0a080e7          	jalr	-1526(ra) # 8000483a <end_op>

  return fd;
}
    80005e38:	8526                	mv	a0,s1
    80005e3a:	70ea                	ld	ra,184(sp)
    80005e3c:	744a                	ld	s0,176(sp)
    80005e3e:	74aa                	ld	s1,168(sp)
    80005e40:	790a                	ld	s2,160(sp)
    80005e42:	69ea                	ld	s3,152(sp)
    80005e44:	6129                	addi	sp,sp,192
    80005e46:	8082                	ret
      end_op();
    80005e48:	fffff097          	auipc	ra,0xfffff
    80005e4c:	9f2080e7          	jalr	-1550(ra) # 8000483a <end_op>
      return -1;
    80005e50:	b7e5                	j	80005e38 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005e52:	f5040513          	addi	a0,s0,-176
    80005e56:	ffffe097          	auipc	ra,0xffffe
    80005e5a:	748080e7          	jalr	1864(ra) # 8000459e <namei>
    80005e5e:	892a                	mv	s2,a0
    80005e60:	c905                	beqz	a0,80005e90 <sys_open+0x13c>
    ilock(ip);
    80005e62:	ffffe097          	auipc	ra,0xffffe
    80005e66:	f86080e7          	jalr	-122(ra) # 80003de8 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005e6a:	04491703          	lh	a4,68(s2)
    80005e6e:	4785                	li	a5,1
    80005e70:	f4f712e3          	bne	a4,a5,80005db4 <sys_open+0x60>
    80005e74:	f4c42783          	lw	a5,-180(s0)
    80005e78:	dba1                	beqz	a5,80005dc8 <sys_open+0x74>
      iunlockput(ip);
    80005e7a:	854a                	mv	a0,s2
    80005e7c:	ffffe097          	auipc	ra,0xffffe
    80005e80:	1ce080e7          	jalr	462(ra) # 8000404a <iunlockput>
      end_op();
    80005e84:	fffff097          	auipc	ra,0xfffff
    80005e88:	9b6080e7          	jalr	-1610(ra) # 8000483a <end_op>
      return -1;
    80005e8c:	54fd                	li	s1,-1
    80005e8e:	b76d                	j	80005e38 <sys_open+0xe4>
      end_op();
    80005e90:	fffff097          	auipc	ra,0xfffff
    80005e94:	9aa080e7          	jalr	-1622(ra) # 8000483a <end_op>
      return -1;
    80005e98:	54fd                	li	s1,-1
    80005e9a:	bf79                	j	80005e38 <sys_open+0xe4>
    iunlockput(ip);
    80005e9c:	854a                	mv	a0,s2
    80005e9e:	ffffe097          	auipc	ra,0xffffe
    80005ea2:	1ac080e7          	jalr	428(ra) # 8000404a <iunlockput>
    end_op();
    80005ea6:	fffff097          	auipc	ra,0xfffff
    80005eaa:	994080e7          	jalr	-1644(ra) # 8000483a <end_op>
    return -1;
    80005eae:	54fd                	li	s1,-1
    80005eb0:	b761                	j	80005e38 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005eb2:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005eb6:	04691783          	lh	a5,70(s2)
    80005eba:	02f99223          	sh	a5,36(s3)
    80005ebe:	bf2d                	j	80005df8 <sys_open+0xa4>
    itrunc(ip);
    80005ec0:	854a                	mv	a0,s2
    80005ec2:	ffffe097          	auipc	ra,0xffffe
    80005ec6:	034080e7          	jalr	52(ra) # 80003ef6 <itrunc>
    80005eca:	bfb1                	j	80005e26 <sys_open+0xd2>
      fileclose(f);
    80005ecc:	854e                	mv	a0,s3
    80005ece:	fffff097          	auipc	ra,0xfffff
    80005ed2:	db8080e7          	jalr	-584(ra) # 80004c86 <fileclose>
    iunlockput(ip);
    80005ed6:	854a                	mv	a0,s2
    80005ed8:	ffffe097          	auipc	ra,0xffffe
    80005edc:	172080e7          	jalr	370(ra) # 8000404a <iunlockput>
    end_op();
    80005ee0:	fffff097          	auipc	ra,0xfffff
    80005ee4:	95a080e7          	jalr	-1702(ra) # 8000483a <end_op>
    return -1;
    80005ee8:	54fd                	li	s1,-1
    80005eea:	b7b9                	j	80005e38 <sys_open+0xe4>

0000000080005eec <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005eec:	7175                	addi	sp,sp,-144
    80005eee:	e506                	sd	ra,136(sp)
    80005ef0:	e122                	sd	s0,128(sp)
    80005ef2:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005ef4:	fffff097          	auipc	ra,0xfffff
    80005ef8:	8c6080e7          	jalr	-1850(ra) # 800047ba <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005efc:	08000613          	li	a2,128
    80005f00:	f7040593          	addi	a1,s0,-144
    80005f04:	4501                	li	a0,0
    80005f06:	ffffd097          	auipc	ra,0xffffd
    80005f0a:	36a080e7          	jalr	874(ra) # 80003270 <argstr>
    80005f0e:	02054963          	bltz	a0,80005f40 <sys_mkdir+0x54>
    80005f12:	4681                	li	a3,0
    80005f14:	4601                	li	a2,0
    80005f16:	4585                	li	a1,1
    80005f18:	f7040513          	addi	a0,s0,-144
    80005f1c:	fffff097          	auipc	ra,0xfffff
    80005f20:	7fe080e7          	jalr	2046(ra) # 8000571a <create>
    80005f24:	cd11                	beqz	a0,80005f40 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005f26:	ffffe097          	auipc	ra,0xffffe
    80005f2a:	124080e7          	jalr	292(ra) # 8000404a <iunlockput>
  end_op();
    80005f2e:	fffff097          	auipc	ra,0xfffff
    80005f32:	90c080e7          	jalr	-1780(ra) # 8000483a <end_op>
  return 0;
    80005f36:	4501                	li	a0,0
}
    80005f38:	60aa                	ld	ra,136(sp)
    80005f3a:	640a                	ld	s0,128(sp)
    80005f3c:	6149                	addi	sp,sp,144
    80005f3e:	8082                	ret
    end_op();
    80005f40:	fffff097          	auipc	ra,0xfffff
    80005f44:	8fa080e7          	jalr	-1798(ra) # 8000483a <end_op>
    return -1;
    80005f48:	557d                	li	a0,-1
    80005f4a:	b7fd                	j	80005f38 <sys_mkdir+0x4c>

0000000080005f4c <sys_mknod>:

uint64
sys_mknod(void)
{
    80005f4c:	7135                	addi	sp,sp,-160
    80005f4e:	ed06                	sd	ra,152(sp)
    80005f50:	e922                	sd	s0,144(sp)
    80005f52:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005f54:	fffff097          	auipc	ra,0xfffff
    80005f58:	866080e7          	jalr	-1946(ra) # 800047ba <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005f5c:	08000613          	li	a2,128
    80005f60:	f7040593          	addi	a1,s0,-144
    80005f64:	4501                	li	a0,0
    80005f66:	ffffd097          	auipc	ra,0xffffd
    80005f6a:	30a080e7          	jalr	778(ra) # 80003270 <argstr>
    80005f6e:	04054a63          	bltz	a0,80005fc2 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005f72:	f6c40593          	addi	a1,s0,-148
    80005f76:	4505                	li	a0,1
    80005f78:	ffffd097          	auipc	ra,0xffffd
    80005f7c:	2b4080e7          	jalr	692(ra) # 8000322c <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005f80:	04054163          	bltz	a0,80005fc2 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005f84:	f6840593          	addi	a1,s0,-152
    80005f88:	4509                	li	a0,2
    80005f8a:	ffffd097          	auipc	ra,0xffffd
    80005f8e:	2a2080e7          	jalr	674(ra) # 8000322c <argint>
     argint(1, &major) < 0 ||
    80005f92:	02054863          	bltz	a0,80005fc2 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005f96:	f6841683          	lh	a3,-152(s0)
    80005f9a:	f6c41603          	lh	a2,-148(s0)
    80005f9e:	458d                	li	a1,3
    80005fa0:	f7040513          	addi	a0,s0,-144
    80005fa4:	fffff097          	auipc	ra,0xfffff
    80005fa8:	776080e7          	jalr	1910(ra) # 8000571a <create>
     argint(2, &minor) < 0 ||
    80005fac:	c919                	beqz	a0,80005fc2 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005fae:	ffffe097          	auipc	ra,0xffffe
    80005fb2:	09c080e7          	jalr	156(ra) # 8000404a <iunlockput>
  end_op();
    80005fb6:	fffff097          	auipc	ra,0xfffff
    80005fba:	884080e7          	jalr	-1916(ra) # 8000483a <end_op>
  return 0;
    80005fbe:	4501                	li	a0,0
    80005fc0:	a031                	j	80005fcc <sys_mknod+0x80>
    end_op();
    80005fc2:	fffff097          	auipc	ra,0xfffff
    80005fc6:	878080e7          	jalr	-1928(ra) # 8000483a <end_op>
    return -1;
    80005fca:	557d                	li	a0,-1
}
    80005fcc:	60ea                	ld	ra,152(sp)
    80005fce:	644a                	ld	s0,144(sp)
    80005fd0:	610d                	addi	sp,sp,160
    80005fd2:	8082                	ret

0000000080005fd4 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005fd4:	7135                	addi	sp,sp,-160
    80005fd6:	ed06                	sd	ra,152(sp)
    80005fd8:	e922                	sd	s0,144(sp)
    80005fda:	e526                	sd	s1,136(sp)
    80005fdc:	e14a                	sd	s2,128(sp)
    80005fde:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005fe0:	ffffc097          	auipc	ra,0xffffc
    80005fe4:	d12080e7          	jalr	-750(ra) # 80001cf2 <myproc>
    80005fe8:	892a                	mv	s2,a0
  
  begin_op();
    80005fea:	ffffe097          	auipc	ra,0xffffe
    80005fee:	7d0080e7          	jalr	2000(ra) # 800047ba <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005ff2:	08000613          	li	a2,128
    80005ff6:	f6040593          	addi	a1,s0,-160
    80005ffa:	4501                	li	a0,0
    80005ffc:	ffffd097          	auipc	ra,0xffffd
    80006000:	274080e7          	jalr	628(ra) # 80003270 <argstr>
    80006004:	04054b63          	bltz	a0,8000605a <sys_chdir+0x86>
    80006008:	f6040513          	addi	a0,s0,-160
    8000600c:	ffffe097          	auipc	ra,0xffffe
    80006010:	592080e7          	jalr	1426(ra) # 8000459e <namei>
    80006014:	84aa                	mv	s1,a0
    80006016:	c131                	beqz	a0,8000605a <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006018:	ffffe097          	auipc	ra,0xffffe
    8000601c:	dd0080e7          	jalr	-560(ra) # 80003de8 <ilock>
  if(ip->type != T_DIR){
    80006020:	04449703          	lh	a4,68(s1)
    80006024:	4785                	li	a5,1
    80006026:	04f71063          	bne	a4,a5,80006066 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    8000602a:	8526                	mv	a0,s1
    8000602c:	ffffe097          	auipc	ra,0xffffe
    80006030:	e7e080e7          	jalr	-386(ra) # 80003eaa <iunlock>
  iput(p->cwd);
    80006034:	16893503          	ld	a0,360(s2)
    80006038:	ffffe097          	auipc	ra,0xffffe
    8000603c:	f6a080e7          	jalr	-150(ra) # 80003fa2 <iput>
  end_op();
    80006040:	ffffe097          	auipc	ra,0xffffe
    80006044:	7fa080e7          	jalr	2042(ra) # 8000483a <end_op>
  p->cwd = ip;
    80006048:	16993423          	sd	s1,360(s2)
  return 0;
    8000604c:	4501                	li	a0,0
}
    8000604e:	60ea                	ld	ra,152(sp)
    80006050:	644a                	ld	s0,144(sp)
    80006052:	64aa                	ld	s1,136(sp)
    80006054:	690a                	ld	s2,128(sp)
    80006056:	610d                	addi	sp,sp,160
    80006058:	8082                	ret
    end_op();
    8000605a:	ffffe097          	auipc	ra,0xffffe
    8000605e:	7e0080e7          	jalr	2016(ra) # 8000483a <end_op>
    return -1;
    80006062:	557d                	li	a0,-1
    80006064:	b7ed                	j	8000604e <sys_chdir+0x7a>
    iunlockput(ip);
    80006066:	8526                	mv	a0,s1
    80006068:	ffffe097          	auipc	ra,0xffffe
    8000606c:	fe2080e7          	jalr	-30(ra) # 8000404a <iunlockput>
    end_op();
    80006070:	ffffe097          	auipc	ra,0xffffe
    80006074:	7ca080e7          	jalr	1994(ra) # 8000483a <end_op>
    return -1;
    80006078:	557d                	li	a0,-1
    8000607a:	bfd1                	j	8000604e <sys_chdir+0x7a>

000000008000607c <sys_exec>:

uint64
sys_exec(void)
{
    8000607c:	7145                	addi	sp,sp,-464
    8000607e:	e786                	sd	ra,456(sp)
    80006080:	e3a2                	sd	s0,448(sp)
    80006082:	ff26                	sd	s1,440(sp)
    80006084:	fb4a                	sd	s2,432(sp)
    80006086:	f74e                	sd	s3,424(sp)
    80006088:	f352                	sd	s4,416(sp)
    8000608a:	ef56                	sd	s5,408(sp)
    8000608c:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    8000608e:	08000613          	li	a2,128
    80006092:	f4040593          	addi	a1,s0,-192
    80006096:	4501                	li	a0,0
    80006098:	ffffd097          	auipc	ra,0xffffd
    8000609c:	1d8080e7          	jalr	472(ra) # 80003270 <argstr>
    return -1;
    800060a0:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800060a2:	0c054a63          	bltz	a0,80006176 <sys_exec+0xfa>
    800060a6:	e3840593          	addi	a1,s0,-456
    800060aa:	4505                	li	a0,1
    800060ac:	ffffd097          	auipc	ra,0xffffd
    800060b0:	1a2080e7          	jalr	418(ra) # 8000324e <argaddr>
    800060b4:	0c054163          	bltz	a0,80006176 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    800060b8:	10000613          	li	a2,256
    800060bc:	4581                	li	a1,0
    800060be:	e4040513          	addi	a0,s0,-448
    800060c2:	ffffb097          	auipc	ra,0xffffb
    800060c6:	c1e080e7          	jalr	-994(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800060ca:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800060ce:	89a6                	mv	s3,s1
    800060d0:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800060d2:	02000a13          	li	s4,32
    800060d6:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800060da:	00391513          	slli	a0,s2,0x3
    800060de:	e3040593          	addi	a1,s0,-464
    800060e2:	e3843783          	ld	a5,-456(s0)
    800060e6:	953e                	add	a0,a0,a5
    800060e8:	ffffd097          	auipc	ra,0xffffd
    800060ec:	0aa080e7          	jalr	170(ra) # 80003192 <fetchaddr>
    800060f0:	02054a63          	bltz	a0,80006124 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    800060f4:	e3043783          	ld	a5,-464(s0)
    800060f8:	c3b9                	beqz	a5,8000613e <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800060fa:	ffffb097          	auipc	ra,0xffffb
    800060fe:	9fa080e7          	jalr	-1542(ra) # 80000af4 <kalloc>
    80006102:	85aa                	mv	a1,a0
    80006104:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006108:	cd11                	beqz	a0,80006124 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    8000610a:	6605                	lui	a2,0x1
    8000610c:	e3043503          	ld	a0,-464(s0)
    80006110:	ffffd097          	auipc	ra,0xffffd
    80006114:	0d4080e7          	jalr	212(ra) # 800031e4 <fetchstr>
    80006118:	00054663          	bltz	a0,80006124 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    8000611c:	0905                	addi	s2,s2,1
    8000611e:	09a1                	addi	s3,s3,8
    80006120:	fb491be3          	bne	s2,s4,800060d6 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006124:	10048913          	addi	s2,s1,256
    80006128:	6088                	ld	a0,0(s1)
    8000612a:	c529                	beqz	a0,80006174 <sys_exec+0xf8>
    kfree(argv[i]);
    8000612c:	ffffb097          	auipc	ra,0xffffb
    80006130:	8cc080e7          	jalr	-1844(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006134:	04a1                	addi	s1,s1,8
    80006136:	ff2499e3          	bne	s1,s2,80006128 <sys_exec+0xac>
  return -1;
    8000613a:	597d                	li	s2,-1
    8000613c:	a82d                	j	80006176 <sys_exec+0xfa>
      argv[i] = 0;
    8000613e:	0a8e                	slli	s5,s5,0x3
    80006140:	fc040793          	addi	a5,s0,-64
    80006144:	9abe                	add	s5,s5,a5
    80006146:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    8000614a:	e4040593          	addi	a1,s0,-448
    8000614e:	f4040513          	addi	a0,s0,-192
    80006152:	fffff097          	auipc	ra,0xfffff
    80006156:	194080e7          	jalr	404(ra) # 800052e6 <exec>
    8000615a:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000615c:	10048993          	addi	s3,s1,256
    80006160:	6088                	ld	a0,0(s1)
    80006162:	c911                	beqz	a0,80006176 <sys_exec+0xfa>
    kfree(argv[i]);
    80006164:	ffffb097          	auipc	ra,0xffffb
    80006168:	894080e7          	jalr	-1900(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000616c:	04a1                	addi	s1,s1,8
    8000616e:	ff3499e3          	bne	s1,s3,80006160 <sys_exec+0xe4>
    80006172:	a011                	j	80006176 <sys_exec+0xfa>
  return -1;
    80006174:	597d                	li	s2,-1
}
    80006176:	854a                	mv	a0,s2
    80006178:	60be                	ld	ra,456(sp)
    8000617a:	641e                	ld	s0,448(sp)
    8000617c:	74fa                	ld	s1,440(sp)
    8000617e:	795a                	ld	s2,432(sp)
    80006180:	79ba                	ld	s3,424(sp)
    80006182:	7a1a                	ld	s4,416(sp)
    80006184:	6afa                	ld	s5,408(sp)
    80006186:	6179                	addi	sp,sp,464
    80006188:	8082                	ret

000000008000618a <sys_pipe>:

uint64
sys_pipe(void)
{
    8000618a:	7139                	addi	sp,sp,-64
    8000618c:	fc06                	sd	ra,56(sp)
    8000618e:	f822                	sd	s0,48(sp)
    80006190:	f426                	sd	s1,40(sp)
    80006192:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006194:	ffffc097          	auipc	ra,0xffffc
    80006198:	b5e080e7          	jalr	-1186(ra) # 80001cf2 <myproc>
    8000619c:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    8000619e:	fd840593          	addi	a1,s0,-40
    800061a2:	4501                	li	a0,0
    800061a4:	ffffd097          	auipc	ra,0xffffd
    800061a8:	0aa080e7          	jalr	170(ra) # 8000324e <argaddr>
    return -1;
    800061ac:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    800061ae:	0e054063          	bltz	a0,8000628e <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    800061b2:	fc840593          	addi	a1,s0,-56
    800061b6:	fd040513          	addi	a0,s0,-48
    800061ba:	fffff097          	auipc	ra,0xfffff
    800061be:	dfc080e7          	jalr	-516(ra) # 80004fb6 <pipealloc>
    return -1;
    800061c2:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800061c4:	0c054563          	bltz	a0,8000628e <sys_pipe+0x104>
  fd0 = -1;
    800061c8:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800061cc:	fd043503          	ld	a0,-48(s0)
    800061d0:	fffff097          	auipc	ra,0xfffff
    800061d4:	508080e7          	jalr	1288(ra) # 800056d8 <fdalloc>
    800061d8:	fca42223          	sw	a0,-60(s0)
    800061dc:	08054c63          	bltz	a0,80006274 <sys_pipe+0xea>
    800061e0:	fc843503          	ld	a0,-56(s0)
    800061e4:	fffff097          	auipc	ra,0xfffff
    800061e8:	4f4080e7          	jalr	1268(ra) # 800056d8 <fdalloc>
    800061ec:	fca42023          	sw	a0,-64(s0)
    800061f0:	06054863          	bltz	a0,80006260 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800061f4:	4691                	li	a3,4
    800061f6:	fc440613          	addi	a2,s0,-60
    800061fa:	fd843583          	ld	a1,-40(s0)
    800061fe:	74a8                	ld	a0,104(s1)
    80006200:	ffffb097          	auipc	ra,0xffffb
    80006204:	472080e7          	jalr	1138(ra) # 80001672 <copyout>
    80006208:	02054063          	bltz	a0,80006228 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    8000620c:	4691                	li	a3,4
    8000620e:	fc040613          	addi	a2,s0,-64
    80006212:	fd843583          	ld	a1,-40(s0)
    80006216:	0591                	addi	a1,a1,4
    80006218:	74a8                	ld	a0,104(s1)
    8000621a:	ffffb097          	auipc	ra,0xffffb
    8000621e:	458080e7          	jalr	1112(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006222:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006224:	06055563          	bgez	a0,8000628e <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80006228:	fc442783          	lw	a5,-60(s0)
    8000622c:	07f1                	addi	a5,a5,28
    8000622e:	078e                	slli	a5,a5,0x3
    80006230:	97a6                	add	a5,a5,s1
    80006232:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80006236:	fc042503          	lw	a0,-64(s0)
    8000623a:	0571                	addi	a0,a0,28
    8000623c:	050e                	slli	a0,a0,0x3
    8000623e:	9526                	add	a0,a0,s1
    80006240:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80006244:	fd043503          	ld	a0,-48(s0)
    80006248:	fffff097          	auipc	ra,0xfffff
    8000624c:	a3e080e7          	jalr	-1474(ra) # 80004c86 <fileclose>
    fileclose(wf);
    80006250:	fc843503          	ld	a0,-56(s0)
    80006254:	fffff097          	auipc	ra,0xfffff
    80006258:	a32080e7          	jalr	-1486(ra) # 80004c86 <fileclose>
    return -1;
    8000625c:	57fd                	li	a5,-1
    8000625e:	a805                	j	8000628e <sys_pipe+0x104>
    if(fd0 >= 0)
    80006260:	fc442783          	lw	a5,-60(s0)
    80006264:	0007c863          	bltz	a5,80006274 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80006268:	01c78513          	addi	a0,a5,28
    8000626c:	050e                	slli	a0,a0,0x3
    8000626e:	9526                	add	a0,a0,s1
    80006270:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80006274:	fd043503          	ld	a0,-48(s0)
    80006278:	fffff097          	auipc	ra,0xfffff
    8000627c:	a0e080e7          	jalr	-1522(ra) # 80004c86 <fileclose>
    fileclose(wf);
    80006280:	fc843503          	ld	a0,-56(s0)
    80006284:	fffff097          	auipc	ra,0xfffff
    80006288:	a02080e7          	jalr	-1534(ra) # 80004c86 <fileclose>
    return -1;
    8000628c:	57fd                	li	a5,-1
}
    8000628e:	853e                	mv	a0,a5
    80006290:	70e2                	ld	ra,56(sp)
    80006292:	7442                	ld	s0,48(sp)
    80006294:	74a2                	ld	s1,40(sp)
    80006296:	6121                	addi	sp,sp,64
    80006298:	8082                	ret
    8000629a:	0000                	unimp
    8000629c:	0000                	unimp
	...

00000000800062a0 <kernelvec>:
    800062a0:	7111                	addi	sp,sp,-256
    800062a2:	e006                	sd	ra,0(sp)
    800062a4:	e40a                	sd	sp,8(sp)
    800062a6:	e80e                	sd	gp,16(sp)
    800062a8:	ec12                	sd	tp,24(sp)
    800062aa:	f016                	sd	t0,32(sp)
    800062ac:	f41a                	sd	t1,40(sp)
    800062ae:	f81e                	sd	t2,48(sp)
    800062b0:	fc22                	sd	s0,56(sp)
    800062b2:	e0a6                	sd	s1,64(sp)
    800062b4:	e4aa                	sd	a0,72(sp)
    800062b6:	e8ae                	sd	a1,80(sp)
    800062b8:	ecb2                	sd	a2,88(sp)
    800062ba:	f0b6                	sd	a3,96(sp)
    800062bc:	f4ba                	sd	a4,104(sp)
    800062be:	f8be                	sd	a5,112(sp)
    800062c0:	fcc2                	sd	a6,120(sp)
    800062c2:	e146                	sd	a7,128(sp)
    800062c4:	e54a                	sd	s2,136(sp)
    800062c6:	e94e                	sd	s3,144(sp)
    800062c8:	ed52                	sd	s4,152(sp)
    800062ca:	f156                	sd	s5,160(sp)
    800062cc:	f55a                	sd	s6,168(sp)
    800062ce:	f95e                	sd	s7,176(sp)
    800062d0:	fd62                	sd	s8,184(sp)
    800062d2:	e1e6                	sd	s9,192(sp)
    800062d4:	e5ea                	sd	s10,200(sp)
    800062d6:	e9ee                	sd	s11,208(sp)
    800062d8:	edf2                	sd	t3,216(sp)
    800062da:	f1f6                	sd	t4,224(sp)
    800062dc:	f5fa                	sd	t5,232(sp)
    800062de:	f9fe                	sd	t6,240(sp)
    800062e0:	d7ffc0ef          	jal	ra,8000305e <kerneltrap>
    800062e4:	6082                	ld	ra,0(sp)
    800062e6:	6122                	ld	sp,8(sp)
    800062e8:	61c2                	ld	gp,16(sp)
    800062ea:	7282                	ld	t0,32(sp)
    800062ec:	7322                	ld	t1,40(sp)
    800062ee:	73c2                	ld	t2,48(sp)
    800062f0:	7462                	ld	s0,56(sp)
    800062f2:	6486                	ld	s1,64(sp)
    800062f4:	6526                	ld	a0,72(sp)
    800062f6:	65c6                	ld	a1,80(sp)
    800062f8:	6666                	ld	a2,88(sp)
    800062fa:	7686                	ld	a3,96(sp)
    800062fc:	7726                	ld	a4,104(sp)
    800062fe:	77c6                	ld	a5,112(sp)
    80006300:	7866                	ld	a6,120(sp)
    80006302:	688a                	ld	a7,128(sp)
    80006304:	692a                	ld	s2,136(sp)
    80006306:	69ca                	ld	s3,144(sp)
    80006308:	6a6a                	ld	s4,152(sp)
    8000630a:	7a8a                	ld	s5,160(sp)
    8000630c:	7b2a                	ld	s6,168(sp)
    8000630e:	7bca                	ld	s7,176(sp)
    80006310:	7c6a                	ld	s8,184(sp)
    80006312:	6c8e                	ld	s9,192(sp)
    80006314:	6d2e                	ld	s10,200(sp)
    80006316:	6dce                	ld	s11,208(sp)
    80006318:	6e6e                	ld	t3,216(sp)
    8000631a:	7e8e                	ld	t4,224(sp)
    8000631c:	7f2e                	ld	t5,232(sp)
    8000631e:	7fce                	ld	t6,240(sp)
    80006320:	6111                	addi	sp,sp,256
    80006322:	10200073          	sret
    80006326:	00000013          	nop
    8000632a:	00000013          	nop
    8000632e:	0001                	nop

0000000080006330 <timervec>:
    80006330:	34051573          	csrrw	a0,mscratch,a0
    80006334:	e10c                	sd	a1,0(a0)
    80006336:	e510                	sd	a2,8(a0)
    80006338:	e914                	sd	a3,16(a0)
    8000633a:	6d0c                	ld	a1,24(a0)
    8000633c:	7110                	ld	a2,32(a0)
    8000633e:	6194                	ld	a3,0(a1)
    80006340:	96b2                	add	a3,a3,a2
    80006342:	e194                	sd	a3,0(a1)
    80006344:	4589                	li	a1,2
    80006346:	14459073          	csrw	sip,a1
    8000634a:	6914                	ld	a3,16(a0)
    8000634c:	6510                	ld	a2,8(a0)
    8000634e:	610c                	ld	a1,0(a0)
    80006350:	34051573          	csrrw	a0,mscratch,a0
    80006354:	30200073          	mret
	...

000000008000635a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000635a:	1141                	addi	sp,sp,-16
    8000635c:	e422                	sd	s0,8(sp)
    8000635e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006360:	0c0007b7          	lui	a5,0xc000
    80006364:	4705                	li	a4,1
    80006366:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006368:	c3d8                	sw	a4,4(a5)
}
    8000636a:	6422                	ld	s0,8(sp)
    8000636c:	0141                	addi	sp,sp,16
    8000636e:	8082                	ret

0000000080006370 <plicinithart>:

void
plicinithart(void)
{
    80006370:	1141                	addi	sp,sp,-16
    80006372:	e406                	sd	ra,8(sp)
    80006374:	e022                	sd	s0,0(sp)
    80006376:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006378:	ffffc097          	auipc	ra,0xffffc
    8000637c:	94e080e7          	jalr	-1714(ra) # 80001cc6 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006380:	0085171b          	slliw	a4,a0,0x8
    80006384:	0c0027b7          	lui	a5,0xc002
    80006388:	97ba                	add	a5,a5,a4
    8000638a:	40200713          	li	a4,1026
    8000638e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006392:	00d5151b          	slliw	a0,a0,0xd
    80006396:	0c2017b7          	lui	a5,0xc201
    8000639a:	953e                	add	a0,a0,a5
    8000639c:	00052023          	sw	zero,0(a0)
}
    800063a0:	60a2                	ld	ra,8(sp)
    800063a2:	6402                	ld	s0,0(sp)
    800063a4:	0141                	addi	sp,sp,16
    800063a6:	8082                	ret

00000000800063a8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800063a8:	1141                	addi	sp,sp,-16
    800063aa:	e406                	sd	ra,8(sp)
    800063ac:	e022                	sd	s0,0(sp)
    800063ae:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800063b0:	ffffc097          	auipc	ra,0xffffc
    800063b4:	916080e7          	jalr	-1770(ra) # 80001cc6 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800063b8:	00d5179b          	slliw	a5,a0,0xd
    800063bc:	0c201537          	lui	a0,0xc201
    800063c0:	953e                	add	a0,a0,a5
  return irq;
}
    800063c2:	4148                	lw	a0,4(a0)
    800063c4:	60a2                	ld	ra,8(sp)
    800063c6:	6402                	ld	s0,0(sp)
    800063c8:	0141                	addi	sp,sp,16
    800063ca:	8082                	ret

00000000800063cc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800063cc:	1101                	addi	sp,sp,-32
    800063ce:	ec06                	sd	ra,24(sp)
    800063d0:	e822                	sd	s0,16(sp)
    800063d2:	e426                	sd	s1,8(sp)
    800063d4:	1000                	addi	s0,sp,32
    800063d6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800063d8:	ffffc097          	auipc	ra,0xffffc
    800063dc:	8ee080e7          	jalr	-1810(ra) # 80001cc6 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800063e0:	00d5151b          	slliw	a0,a0,0xd
    800063e4:	0c2017b7          	lui	a5,0xc201
    800063e8:	97aa                	add	a5,a5,a0
    800063ea:	c3c4                	sw	s1,4(a5)
}
    800063ec:	60e2                	ld	ra,24(sp)
    800063ee:	6442                	ld	s0,16(sp)
    800063f0:	64a2                	ld	s1,8(sp)
    800063f2:	6105                	addi	sp,sp,32
    800063f4:	8082                	ret

00000000800063f6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800063f6:	1141                	addi	sp,sp,-16
    800063f8:	e406                	sd	ra,8(sp)
    800063fa:	e022                	sd	s0,0(sp)
    800063fc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800063fe:	479d                	li	a5,7
    80006400:	06a7c963          	blt	a5,a0,80006472 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006404:	0001d797          	auipc	a5,0x1d
    80006408:	bfc78793          	addi	a5,a5,-1028 # 80023000 <disk>
    8000640c:	00a78733          	add	a4,a5,a0
    80006410:	6789                	lui	a5,0x2
    80006412:	97ba                	add	a5,a5,a4
    80006414:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006418:	e7ad                	bnez	a5,80006482 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000641a:	00451793          	slli	a5,a0,0x4
    8000641e:	0001f717          	auipc	a4,0x1f
    80006422:	be270713          	addi	a4,a4,-1054 # 80025000 <disk+0x2000>
    80006426:	6314                	ld	a3,0(a4)
    80006428:	96be                	add	a3,a3,a5
    8000642a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000642e:	6314                	ld	a3,0(a4)
    80006430:	96be                	add	a3,a3,a5
    80006432:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006436:	6314                	ld	a3,0(a4)
    80006438:	96be                	add	a3,a3,a5
    8000643a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000643e:	6318                	ld	a4,0(a4)
    80006440:	97ba                	add	a5,a5,a4
    80006442:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006446:	0001d797          	auipc	a5,0x1d
    8000644a:	bba78793          	addi	a5,a5,-1094 # 80023000 <disk>
    8000644e:	97aa                	add	a5,a5,a0
    80006450:	6509                	lui	a0,0x2
    80006452:	953e                	add	a0,a0,a5
    80006454:	4785                	li	a5,1
    80006456:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000645a:	0001f517          	auipc	a0,0x1f
    8000645e:	bbe50513          	addi	a0,a0,-1090 # 80025018 <disk+0x2018>
    80006462:	ffffc097          	auipc	ra,0xffffc
    80006466:	2bc080e7          	jalr	700(ra) # 8000271e <wakeup>
}
    8000646a:	60a2                	ld	ra,8(sp)
    8000646c:	6402                	ld	s0,0(sp)
    8000646e:	0141                	addi	sp,sp,16
    80006470:	8082                	ret
    panic("free_desc 1");
    80006472:	00002517          	auipc	a0,0x2
    80006476:	61e50513          	addi	a0,a0,1566 # 80008a90 <syscalls+0x330>
    8000647a:	ffffa097          	auipc	ra,0xffffa
    8000647e:	0c4080e7          	jalr	196(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006482:	00002517          	auipc	a0,0x2
    80006486:	61e50513          	addi	a0,a0,1566 # 80008aa0 <syscalls+0x340>
    8000648a:	ffffa097          	auipc	ra,0xffffa
    8000648e:	0b4080e7          	jalr	180(ra) # 8000053e <panic>

0000000080006492 <virtio_disk_init>:
{
    80006492:	1101                	addi	sp,sp,-32
    80006494:	ec06                	sd	ra,24(sp)
    80006496:	e822                	sd	s0,16(sp)
    80006498:	e426                	sd	s1,8(sp)
    8000649a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000649c:	00002597          	auipc	a1,0x2
    800064a0:	61458593          	addi	a1,a1,1556 # 80008ab0 <syscalls+0x350>
    800064a4:	0001f517          	auipc	a0,0x1f
    800064a8:	c8450513          	addi	a0,a0,-892 # 80025128 <disk+0x2128>
    800064ac:	ffffa097          	auipc	ra,0xffffa
    800064b0:	6a8080e7          	jalr	1704(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800064b4:	100017b7          	lui	a5,0x10001
    800064b8:	4398                	lw	a4,0(a5)
    800064ba:	2701                	sext.w	a4,a4
    800064bc:	747277b7          	lui	a5,0x74727
    800064c0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800064c4:	0ef71163          	bne	a4,a5,800065a6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800064c8:	100017b7          	lui	a5,0x10001
    800064cc:	43dc                	lw	a5,4(a5)
    800064ce:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800064d0:	4705                	li	a4,1
    800064d2:	0ce79a63          	bne	a5,a4,800065a6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800064d6:	100017b7          	lui	a5,0x10001
    800064da:	479c                	lw	a5,8(a5)
    800064dc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800064de:	4709                	li	a4,2
    800064e0:	0ce79363          	bne	a5,a4,800065a6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800064e4:	100017b7          	lui	a5,0x10001
    800064e8:	47d8                	lw	a4,12(a5)
    800064ea:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800064ec:	554d47b7          	lui	a5,0x554d4
    800064f0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800064f4:	0af71963          	bne	a4,a5,800065a6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800064f8:	100017b7          	lui	a5,0x10001
    800064fc:	4705                	li	a4,1
    800064fe:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006500:	470d                	li	a4,3
    80006502:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006504:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006506:	c7ffe737          	lui	a4,0xc7ffe
    8000650a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000650e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006510:	2701                	sext.w	a4,a4
    80006512:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006514:	472d                	li	a4,11
    80006516:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006518:	473d                	li	a4,15
    8000651a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000651c:	6705                	lui	a4,0x1
    8000651e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006520:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006524:	5bdc                	lw	a5,52(a5)
    80006526:	2781                	sext.w	a5,a5
  if(max == 0)
    80006528:	c7d9                	beqz	a5,800065b6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000652a:	471d                	li	a4,7
    8000652c:	08f77d63          	bgeu	a4,a5,800065c6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006530:	100014b7          	lui	s1,0x10001
    80006534:	47a1                	li	a5,8
    80006536:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006538:	6609                	lui	a2,0x2
    8000653a:	4581                	li	a1,0
    8000653c:	0001d517          	auipc	a0,0x1d
    80006540:	ac450513          	addi	a0,a0,-1340 # 80023000 <disk>
    80006544:	ffffa097          	auipc	ra,0xffffa
    80006548:	79c080e7          	jalr	1948(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000654c:	0001d717          	auipc	a4,0x1d
    80006550:	ab470713          	addi	a4,a4,-1356 # 80023000 <disk>
    80006554:	00c75793          	srli	a5,a4,0xc
    80006558:	2781                	sext.w	a5,a5
    8000655a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000655c:	0001f797          	auipc	a5,0x1f
    80006560:	aa478793          	addi	a5,a5,-1372 # 80025000 <disk+0x2000>
    80006564:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006566:	0001d717          	auipc	a4,0x1d
    8000656a:	b1a70713          	addi	a4,a4,-1254 # 80023080 <disk+0x80>
    8000656e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006570:	0001e717          	auipc	a4,0x1e
    80006574:	a9070713          	addi	a4,a4,-1392 # 80024000 <disk+0x1000>
    80006578:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000657a:	4705                	li	a4,1
    8000657c:	00e78c23          	sb	a4,24(a5)
    80006580:	00e78ca3          	sb	a4,25(a5)
    80006584:	00e78d23          	sb	a4,26(a5)
    80006588:	00e78da3          	sb	a4,27(a5)
    8000658c:	00e78e23          	sb	a4,28(a5)
    80006590:	00e78ea3          	sb	a4,29(a5)
    80006594:	00e78f23          	sb	a4,30(a5)
    80006598:	00e78fa3          	sb	a4,31(a5)
}
    8000659c:	60e2                	ld	ra,24(sp)
    8000659e:	6442                	ld	s0,16(sp)
    800065a0:	64a2                	ld	s1,8(sp)
    800065a2:	6105                	addi	sp,sp,32
    800065a4:	8082                	ret
    panic("could not find virtio disk");
    800065a6:	00002517          	auipc	a0,0x2
    800065aa:	51a50513          	addi	a0,a0,1306 # 80008ac0 <syscalls+0x360>
    800065ae:	ffffa097          	auipc	ra,0xffffa
    800065b2:	f90080e7          	jalr	-112(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    800065b6:	00002517          	auipc	a0,0x2
    800065ba:	52a50513          	addi	a0,a0,1322 # 80008ae0 <syscalls+0x380>
    800065be:	ffffa097          	auipc	ra,0xffffa
    800065c2:	f80080e7          	jalr	-128(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    800065c6:	00002517          	auipc	a0,0x2
    800065ca:	53a50513          	addi	a0,a0,1338 # 80008b00 <syscalls+0x3a0>
    800065ce:	ffffa097          	auipc	ra,0xffffa
    800065d2:	f70080e7          	jalr	-144(ra) # 8000053e <panic>

00000000800065d6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800065d6:	7159                	addi	sp,sp,-112
    800065d8:	f486                	sd	ra,104(sp)
    800065da:	f0a2                	sd	s0,96(sp)
    800065dc:	eca6                	sd	s1,88(sp)
    800065de:	e8ca                	sd	s2,80(sp)
    800065e0:	e4ce                	sd	s3,72(sp)
    800065e2:	e0d2                	sd	s4,64(sp)
    800065e4:	fc56                	sd	s5,56(sp)
    800065e6:	f85a                	sd	s6,48(sp)
    800065e8:	f45e                	sd	s7,40(sp)
    800065ea:	f062                	sd	s8,32(sp)
    800065ec:	ec66                	sd	s9,24(sp)
    800065ee:	e86a                	sd	s10,16(sp)
    800065f0:	1880                	addi	s0,sp,112
    800065f2:	892a                	mv	s2,a0
    800065f4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800065f6:	00c52c83          	lw	s9,12(a0)
    800065fa:	001c9c9b          	slliw	s9,s9,0x1
    800065fe:	1c82                	slli	s9,s9,0x20
    80006600:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006604:	0001f517          	auipc	a0,0x1f
    80006608:	b2450513          	addi	a0,a0,-1244 # 80025128 <disk+0x2128>
    8000660c:	ffffa097          	auipc	ra,0xffffa
    80006610:	5d8080e7          	jalr	1496(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006614:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006616:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006618:	0001db97          	auipc	s7,0x1d
    8000661c:	9e8b8b93          	addi	s7,s7,-1560 # 80023000 <disk>
    80006620:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006622:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006624:	8a4e                	mv	s4,s3
    80006626:	a051                	j	800066aa <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006628:	00fb86b3          	add	a3,s7,a5
    8000662c:	96da                	add	a3,a3,s6
    8000662e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006632:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006634:	0207c563          	bltz	a5,8000665e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006638:	2485                	addiw	s1,s1,1
    8000663a:	0711                	addi	a4,a4,4
    8000663c:	25548063          	beq	s1,s5,8000687c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006640:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006642:	0001f697          	auipc	a3,0x1f
    80006646:	9d668693          	addi	a3,a3,-1578 # 80025018 <disk+0x2018>
    8000664a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000664c:	0006c583          	lbu	a1,0(a3)
    80006650:	fde1                	bnez	a1,80006628 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006652:	2785                	addiw	a5,a5,1
    80006654:	0685                	addi	a3,a3,1
    80006656:	ff879be3          	bne	a5,s8,8000664c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000665a:	57fd                	li	a5,-1
    8000665c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000665e:	02905a63          	blez	s1,80006692 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006662:	f9042503          	lw	a0,-112(s0)
    80006666:	00000097          	auipc	ra,0x0
    8000666a:	d90080e7          	jalr	-624(ra) # 800063f6 <free_desc>
      for(int j = 0; j < i; j++)
    8000666e:	4785                	li	a5,1
    80006670:	0297d163          	bge	a5,s1,80006692 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006674:	f9442503          	lw	a0,-108(s0)
    80006678:	00000097          	auipc	ra,0x0
    8000667c:	d7e080e7          	jalr	-642(ra) # 800063f6 <free_desc>
      for(int j = 0; j < i; j++)
    80006680:	4789                	li	a5,2
    80006682:	0097d863          	bge	a5,s1,80006692 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006686:	f9842503          	lw	a0,-104(s0)
    8000668a:	00000097          	auipc	ra,0x0
    8000668e:	d6c080e7          	jalr	-660(ra) # 800063f6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006692:	0001f597          	auipc	a1,0x1f
    80006696:	a9658593          	addi	a1,a1,-1386 # 80025128 <disk+0x2128>
    8000669a:	0001f517          	auipc	a0,0x1f
    8000669e:	97e50513          	addi	a0,a0,-1666 # 80025018 <disk+0x2018>
    800066a2:	ffffc097          	auipc	ra,0xffffc
    800066a6:	cc6080e7          	jalr	-826(ra) # 80002368 <sleep>
  for(int i = 0; i < 3; i++){
    800066aa:	f9040713          	addi	a4,s0,-112
    800066ae:	84ce                	mv	s1,s3
    800066b0:	bf41                	j	80006640 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800066b2:	20058713          	addi	a4,a1,512
    800066b6:	00471693          	slli	a3,a4,0x4
    800066ba:	0001d717          	auipc	a4,0x1d
    800066be:	94670713          	addi	a4,a4,-1722 # 80023000 <disk>
    800066c2:	9736                	add	a4,a4,a3
    800066c4:	4685                	li	a3,1
    800066c6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800066ca:	20058713          	addi	a4,a1,512
    800066ce:	00471693          	slli	a3,a4,0x4
    800066d2:	0001d717          	auipc	a4,0x1d
    800066d6:	92e70713          	addi	a4,a4,-1746 # 80023000 <disk>
    800066da:	9736                	add	a4,a4,a3
    800066dc:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800066e0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800066e4:	7679                	lui	a2,0xffffe
    800066e6:	963e                	add	a2,a2,a5
    800066e8:	0001f697          	auipc	a3,0x1f
    800066ec:	91868693          	addi	a3,a3,-1768 # 80025000 <disk+0x2000>
    800066f0:	6298                	ld	a4,0(a3)
    800066f2:	9732                	add	a4,a4,a2
    800066f4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800066f6:	6298                	ld	a4,0(a3)
    800066f8:	9732                	add	a4,a4,a2
    800066fa:	4541                	li	a0,16
    800066fc:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800066fe:	6298                	ld	a4,0(a3)
    80006700:	9732                	add	a4,a4,a2
    80006702:	4505                	li	a0,1
    80006704:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006708:	f9442703          	lw	a4,-108(s0)
    8000670c:	6288                	ld	a0,0(a3)
    8000670e:	962a                	add	a2,a2,a0
    80006710:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006714:	0712                	slli	a4,a4,0x4
    80006716:	6290                	ld	a2,0(a3)
    80006718:	963a                	add	a2,a2,a4
    8000671a:	05890513          	addi	a0,s2,88
    8000671e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006720:	6294                	ld	a3,0(a3)
    80006722:	96ba                	add	a3,a3,a4
    80006724:	40000613          	li	a2,1024
    80006728:	c690                	sw	a2,8(a3)
  if(write)
    8000672a:	140d0063          	beqz	s10,8000686a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000672e:	0001f697          	auipc	a3,0x1f
    80006732:	8d26b683          	ld	a3,-1838(a3) # 80025000 <disk+0x2000>
    80006736:	96ba                	add	a3,a3,a4
    80006738:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000673c:	0001d817          	auipc	a6,0x1d
    80006740:	8c480813          	addi	a6,a6,-1852 # 80023000 <disk>
    80006744:	0001f517          	auipc	a0,0x1f
    80006748:	8bc50513          	addi	a0,a0,-1860 # 80025000 <disk+0x2000>
    8000674c:	6114                	ld	a3,0(a0)
    8000674e:	96ba                	add	a3,a3,a4
    80006750:	00c6d603          	lhu	a2,12(a3)
    80006754:	00166613          	ori	a2,a2,1
    80006758:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000675c:	f9842683          	lw	a3,-104(s0)
    80006760:	6110                	ld	a2,0(a0)
    80006762:	9732                	add	a4,a4,a2
    80006764:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006768:	20058613          	addi	a2,a1,512
    8000676c:	0612                	slli	a2,a2,0x4
    8000676e:	9642                	add	a2,a2,a6
    80006770:	577d                	li	a4,-1
    80006772:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006776:	00469713          	slli	a4,a3,0x4
    8000677a:	6114                	ld	a3,0(a0)
    8000677c:	96ba                	add	a3,a3,a4
    8000677e:	03078793          	addi	a5,a5,48
    80006782:	97c2                	add	a5,a5,a6
    80006784:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006786:	611c                	ld	a5,0(a0)
    80006788:	97ba                	add	a5,a5,a4
    8000678a:	4685                	li	a3,1
    8000678c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000678e:	611c                	ld	a5,0(a0)
    80006790:	97ba                	add	a5,a5,a4
    80006792:	4809                	li	a6,2
    80006794:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006798:	611c                	ld	a5,0(a0)
    8000679a:	973e                	add	a4,a4,a5
    8000679c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800067a0:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    800067a4:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800067a8:	6518                	ld	a4,8(a0)
    800067aa:	00275783          	lhu	a5,2(a4)
    800067ae:	8b9d                	andi	a5,a5,7
    800067b0:	0786                	slli	a5,a5,0x1
    800067b2:	97ba                	add	a5,a5,a4
    800067b4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800067b8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800067bc:	6518                	ld	a4,8(a0)
    800067be:	00275783          	lhu	a5,2(a4)
    800067c2:	2785                	addiw	a5,a5,1
    800067c4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800067c8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800067cc:	100017b7          	lui	a5,0x10001
    800067d0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800067d4:	00492703          	lw	a4,4(s2)
    800067d8:	4785                	li	a5,1
    800067da:	02f71163          	bne	a4,a5,800067fc <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800067de:	0001f997          	auipc	s3,0x1f
    800067e2:	94a98993          	addi	s3,s3,-1718 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    800067e6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800067e8:	85ce                	mv	a1,s3
    800067ea:	854a                	mv	a0,s2
    800067ec:	ffffc097          	auipc	ra,0xffffc
    800067f0:	b7c080e7          	jalr	-1156(ra) # 80002368 <sleep>
  while(b->disk == 1) {
    800067f4:	00492783          	lw	a5,4(s2)
    800067f8:	fe9788e3          	beq	a5,s1,800067e8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800067fc:	f9042903          	lw	s2,-112(s0)
    80006800:	20090793          	addi	a5,s2,512
    80006804:	00479713          	slli	a4,a5,0x4
    80006808:	0001c797          	auipc	a5,0x1c
    8000680c:	7f878793          	addi	a5,a5,2040 # 80023000 <disk>
    80006810:	97ba                	add	a5,a5,a4
    80006812:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006816:	0001e997          	auipc	s3,0x1e
    8000681a:	7ea98993          	addi	s3,s3,2026 # 80025000 <disk+0x2000>
    8000681e:	00491713          	slli	a4,s2,0x4
    80006822:	0009b783          	ld	a5,0(s3)
    80006826:	97ba                	add	a5,a5,a4
    80006828:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000682c:	854a                	mv	a0,s2
    8000682e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006832:	00000097          	auipc	ra,0x0
    80006836:	bc4080e7          	jalr	-1084(ra) # 800063f6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000683a:	8885                	andi	s1,s1,1
    8000683c:	f0ed                	bnez	s1,8000681e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000683e:	0001f517          	auipc	a0,0x1f
    80006842:	8ea50513          	addi	a0,a0,-1814 # 80025128 <disk+0x2128>
    80006846:	ffffa097          	auipc	ra,0xffffa
    8000684a:	452080e7          	jalr	1106(ra) # 80000c98 <release>
}
    8000684e:	70a6                	ld	ra,104(sp)
    80006850:	7406                	ld	s0,96(sp)
    80006852:	64e6                	ld	s1,88(sp)
    80006854:	6946                	ld	s2,80(sp)
    80006856:	69a6                	ld	s3,72(sp)
    80006858:	6a06                	ld	s4,64(sp)
    8000685a:	7ae2                	ld	s5,56(sp)
    8000685c:	7b42                	ld	s6,48(sp)
    8000685e:	7ba2                	ld	s7,40(sp)
    80006860:	7c02                	ld	s8,32(sp)
    80006862:	6ce2                	ld	s9,24(sp)
    80006864:	6d42                	ld	s10,16(sp)
    80006866:	6165                	addi	sp,sp,112
    80006868:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000686a:	0001e697          	auipc	a3,0x1e
    8000686e:	7966b683          	ld	a3,1942(a3) # 80025000 <disk+0x2000>
    80006872:	96ba                	add	a3,a3,a4
    80006874:	4609                	li	a2,2
    80006876:	00c69623          	sh	a2,12(a3)
    8000687a:	b5c9                	j	8000673c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000687c:	f9042583          	lw	a1,-112(s0)
    80006880:	20058793          	addi	a5,a1,512
    80006884:	0792                	slli	a5,a5,0x4
    80006886:	0001d517          	auipc	a0,0x1d
    8000688a:	82250513          	addi	a0,a0,-2014 # 800230a8 <disk+0xa8>
    8000688e:	953e                	add	a0,a0,a5
  if(write)
    80006890:	e20d11e3          	bnez	s10,800066b2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006894:	20058713          	addi	a4,a1,512
    80006898:	00471693          	slli	a3,a4,0x4
    8000689c:	0001c717          	auipc	a4,0x1c
    800068a0:	76470713          	addi	a4,a4,1892 # 80023000 <disk>
    800068a4:	9736                	add	a4,a4,a3
    800068a6:	0a072423          	sw	zero,168(a4)
    800068aa:	b505                	j	800066ca <virtio_disk_rw+0xf4>

00000000800068ac <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800068ac:	1101                	addi	sp,sp,-32
    800068ae:	ec06                	sd	ra,24(sp)
    800068b0:	e822                	sd	s0,16(sp)
    800068b2:	e426                	sd	s1,8(sp)
    800068b4:	e04a                	sd	s2,0(sp)
    800068b6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800068b8:	0001f517          	auipc	a0,0x1f
    800068bc:	87050513          	addi	a0,a0,-1936 # 80025128 <disk+0x2128>
    800068c0:	ffffa097          	auipc	ra,0xffffa
    800068c4:	324080e7          	jalr	804(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800068c8:	10001737          	lui	a4,0x10001
    800068cc:	533c                	lw	a5,96(a4)
    800068ce:	8b8d                	andi	a5,a5,3
    800068d0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800068d2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800068d6:	0001e797          	auipc	a5,0x1e
    800068da:	72a78793          	addi	a5,a5,1834 # 80025000 <disk+0x2000>
    800068de:	6b94                	ld	a3,16(a5)
    800068e0:	0207d703          	lhu	a4,32(a5)
    800068e4:	0026d783          	lhu	a5,2(a3)
    800068e8:	06f70163          	beq	a4,a5,8000694a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800068ec:	0001c917          	auipc	s2,0x1c
    800068f0:	71490913          	addi	s2,s2,1812 # 80023000 <disk>
    800068f4:	0001e497          	auipc	s1,0x1e
    800068f8:	70c48493          	addi	s1,s1,1804 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800068fc:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006900:	6898                	ld	a4,16(s1)
    80006902:	0204d783          	lhu	a5,32(s1)
    80006906:	8b9d                	andi	a5,a5,7
    80006908:	078e                	slli	a5,a5,0x3
    8000690a:	97ba                	add	a5,a5,a4
    8000690c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000690e:	20078713          	addi	a4,a5,512
    80006912:	0712                	slli	a4,a4,0x4
    80006914:	974a                	add	a4,a4,s2
    80006916:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000691a:	e731                	bnez	a4,80006966 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000691c:	20078793          	addi	a5,a5,512
    80006920:	0792                	slli	a5,a5,0x4
    80006922:	97ca                	add	a5,a5,s2
    80006924:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006926:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000692a:	ffffc097          	auipc	ra,0xffffc
    8000692e:	df4080e7          	jalr	-524(ra) # 8000271e <wakeup>

    disk.used_idx += 1;
    80006932:	0204d783          	lhu	a5,32(s1)
    80006936:	2785                	addiw	a5,a5,1
    80006938:	17c2                	slli	a5,a5,0x30
    8000693a:	93c1                	srli	a5,a5,0x30
    8000693c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006940:	6898                	ld	a4,16(s1)
    80006942:	00275703          	lhu	a4,2(a4)
    80006946:	faf71be3          	bne	a4,a5,800068fc <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000694a:	0001e517          	auipc	a0,0x1e
    8000694e:	7de50513          	addi	a0,a0,2014 # 80025128 <disk+0x2128>
    80006952:	ffffa097          	auipc	ra,0xffffa
    80006956:	346080e7          	jalr	838(ra) # 80000c98 <release>
}
    8000695a:	60e2                	ld	ra,24(sp)
    8000695c:	6442                	ld	s0,16(sp)
    8000695e:	64a2                	ld	s1,8(sp)
    80006960:	6902                	ld	s2,0(sp)
    80006962:	6105                	addi	sp,sp,32
    80006964:	8082                	ret
      panic("virtio_disk_intr status");
    80006966:	00002517          	auipc	a0,0x2
    8000696a:	1ba50513          	addi	a0,a0,442 # 80008b20 <syscalls+0x3c0>
    8000696e:	ffffa097          	auipc	ra,0xffffa
    80006972:	bd0080e7          	jalr	-1072(ra) # 8000053e <panic>

0000000080006976 <cas>:
    80006976:	100522af          	lr.w	t0,(a0)
    8000697a:	00b29563          	bne	t0,a1,80006984 <fail>
    8000697e:	18c5252f          	sc.w	a0,a2,(a0)
    80006982:	8082                	ret

0000000080006984 <fail>:
    80006984:	4505                	li	a0,1
    80006986:	8082                	ret
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
