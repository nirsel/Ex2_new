
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	93013103          	ld	sp,-1744(sp) # 80008930 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000068:	43c78793          	addi	a5,a5,1084 # 800064a0 <timervec>
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
    80000130:	9b2080e7          	jalr	-1614(ra) # 80002ade <either_copyin>
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
    800001c8:	b98080e7          	jalr	-1128(ra) # 80001d5c <myproc>
    800001cc:	413c                	lw	a5,64(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	380080e7          	jalr	896(ra) # 80002554 <sleep>
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
    80000214:	878080e7          	jalr	-1928(ra) # 80002a88 <either_copyout>
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
    800002f6:	842080e7          	jalr	-1982(ra) # 80002b34 <procdump>
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
    8000044a:	2ae080e7          	jalr	686(ra) # 800026f4 <wakeup>
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
    80000570:	dc450513          	addi	a0,a0,-572 # 80008330 <digits+0x2f0>
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
    800008a4:	e54080e7          	jalr	-428(ra) # 800026f4 <wakeup>
    
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
    80000930:	c28080e7          	jalr	-984(ra) # 80002554 <sleep>
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
    80000b82:	1c2080e7          	jalr	450(ra) # 80001d40 <mycpu>
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
    80000bb4:	190080e7          	jalr	400(ra) # 80001d40 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	184080e7          	jalr	388(ra) # 80001d40 <mycpu>
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
    80000bd8:	16c080e7          	jalr	364(ra) # 80001d40 <mycpu>
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
    80000c18:	12c080e7          	jalr	300(ra) # 80001d40 <mycpu>
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
    80000c44:	100080e7          	jalr	256(ra) # 80001d40 <mycpu>
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
    80000e9a:	e9a080e7          	jalr	-358(ra) # 80001d30 <cpuid>
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
    80000eb6:	e7e080e7          	jalr	-386(ra) # 80001d30 <cpuid>
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
    80000ed8:	06e080e7          	jalr	110(ra) # 80002f42 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	604080e7          	jalr	1540(ra) # 800064e0 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	43e080e7          	jalr	1086(ra) # 80002322 <scheduler>
    consoleinit();
    80000eec:	fffff097          	auipc	ra,0xfffff
    80000ef0:	564080e7          	jalr	1380(ra) # 80000450 <consoleinit>
    printfinit();
    80000ef4:	00000097          	auipc	ra,0x0
    80000ef8:	87a080e7          	jalr	-1926(ra) # 8000076e <printfinit>
    printf("\n");
    80000efc:	00007517          	auipc	a0,0x7
    80000f00:	43450513          	addi	a0,a0,1076 # 80008330 <digits+0x2f0>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	684080e7          	jalr	1668(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	19450513          	addi	a0,a0,404 # 800080a0 <digits+0x60>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	41450513          	addi	a0,a0,1044 # 80008330 <digits+0x2f0>
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
    80000f48:	d10080e7          	jalr	-752(ra) # 80001c54 <procinit>
    trapinit();      // trap vectors
    80000f4c:	00002097          	auipc	ra,0x2
    80000f50:	fce080e7          	jalr	-50(ra) # 80002f1a <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	fee080e7          	jalr	-18(ra) # 80002f42 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	56e080e7          	jalr	1390(ra) # 800064ca <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	57c080e7          	jalr	1404(ra) # 800064e0 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	762080e7          	jalr	1890(ra) # 800036ce <binit>
    iinit();         // inode table
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	df2080e7          	jalr	-526(ra) # 80003d66 <iinit>
    fileinit();      // file table
    80000f7c:	00004097          	auipc	ra,0x4
    80000f80:	d9c080e7          	jalr	-612(ra) # 80004d18 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	67e080e7          	jalr	1662(ra) # 80006602 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	130080e7          	jalr	304(ra) # 800020bc <userinit>
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
    80001244:	97e080e7          	jalr	-1666(ra) # 80001bbe <proc_mapstacks>
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
    80001840:	e406                	sd	ra,8(sp)
    80001842:	e022                	sd	s0,0(sp)
    80001844:	0800                	addi	s0,sp,16

  printf("start lists init\n");
    80001846:	00007517          	auipc	a0,0x7
    8000184a:	99250513          	addi	a0,a0,-1646 # 800081d8 <digits+0x198>
    8000184e:	fffff097          	auipc	ra,0xfffff
    80001852:	d3a080e7          	jalr	-710(ra) # 80000588 <printf>
  
  unused_list.head = -1;
    80001856:	00010797          	auipc	a5,0x10
    8000185a:	a4a78793          	addi	a5,a5,-1462 # 800112a0 <unused_list>
    8000185e:	577d                	li	a4,-1
    80001860:	c398                	sw	a4,0(a5)
  
  unused_list.last = -1;
    80001862:	c3d8                	sw	a4,4(a5)
  
  sleeping_list.head = -1;
    80001864:	d398                	sw	a4,32(a5)
  sleeping_list.last = -1;
    80001866:	d3d8                	sw	a4,36(a5)
  zombie_list.head = -1;
    80001868:	c3b8                	sw	a4,64(a5)
  zombie_list.last = -1;
    8000186a:	c3f8                	sw	a4,68(a5)
  struct processList* p;
  for (p = runnable_cpu_lists; p<&runnable_cpu_lists[3]; p++){
      
      p->head = -1;
    8000186c:	d3b8                	sw	a4,96(a5)
      p->last = -1;
    8000186e:	d3f8                	sw	a4,100(a5)
      p->head = -1;
    80001870:	08e7a023          	sw	a4,128(a5)
      p->last = -1;
    80001874:	08e7a223          	sw	a4,132(a5)
      p->head = -1;
    80001878:	0ae7a023          	sw	a4,160(a5)
      p->last = -1;
    8000187c:	0ae7a223          	sw	a4,164(a5)
  }
  printf("finished lists init\n");
    80001880:	00007517          	auipc	a0,0x7
    80001884:	97050513          	addi	a0,a0,-1680 # 800081f0 <digits+0x1b0>
    80001888:	fffff097          	auipc	ra,0xfffff
    8000188c:	d00080e7          	jalr	-768(ra) # 80000588 <printf>
}
    80001890:	60a2                	ld	ra,8(sp)
    80001892:	6402                	ld	s0,0(sp)
    80001894:	0141                	addi	sp,sp,16
    80001896:	8082                	ret

0000000080001898 <remove_link>:

void remove_link(struct processList* list, int index){  // index = the process index in proc
    80001898:	715d                	addi	sp,sp,-80
    8000189a:	e486                	sd	ra,72(sp)
    8000189c:	e0a2                	sd	s0,64(sp)
    8000189e:	fc26                	sd	s1,56(sp)
    800018a0:	f84a                	sd	s2,48(sp)
    800018a2:	f44e                	sd	s3,40(sp)
    800018a4:	f052                	sd	s4,32(sp)
    800018a6:	ec56                	sd	s5,24(sp)
    800018a8:	e85a                	sd	s6,16(sp)
    800018aa:	e45e                	sd	s7,8(sp)
    800018ac:	0880                	addi	s0,sp,80
    800018ae:	8aaa                	mv	s5,a0
    800018b0:	892e                	mv	s2,a1
  //printf("start remove proc with index %d\n", index);
  acquire(&list->head_lock);
    800018b2:	00850993          	addi	s3,a0,8
    800018b6:	854e                	mv	a0,s3
    800018b8:	fffff097          	auipc	ra,0xfffff
    800018bc:	32c080e7          	jalr	812(ra) # 80000be4 <acquire>
  if (list->head == -1){  //empty list
    800018c0:	000aa503          	lw	a0,0(s5) # fffffffffffff000 <end+0xffffffff7ffd9000>
    800018c4:	57fd                	li	a5,-1
    800018c6:	1af50363          	beq	a0,a5,80001a6c <remove_link+0x1d4>
    return;
  }
  acquire(&proc[list->head].list_lock);
    800018ca:	19000793          	li	a5,400
    800018ce:	02f50533          	mul	a0,a0,a5
    800018d2:	00010797          	auipc	a5,0x10
    800018d6:	ed678793          	addi	a5,a5,-298 # 800117a8 <proc+0x18>
    800018da:	953e                	add	a0,a0,a5
    800018dc:	fffff097          	auipc	ra,0xfffff
    800018e0:	308080e7          	jalr	776(ra) # 80000be4 <acquire>
  struct proc* head = &proc[list->head];
    800018e4:	000aab83          	lw	s7,0(s5)
  if (list->head == list->last){  //list of size 1
    800018e8:	004aa783          	lw	a5,4(s5)
    800018ec:	0b778763          	beq	a5,s7,8000199a <remove_link+0x102>
      release(&head->list_lock);
      release(&list->head_lock);
      return;
  }
  else{  //list of size > 1 and removing the head
    if (head->proc_index == index){
    800018f0:	19000793          	li	a5,400
    800018f4:	02fb8733          	mul	a4,s7,a5
    800018f8:	00010797          	auipc	a5,0x10
    800018fc:	e9878793          	addi	a5,a5,-360 # 80011790 <proc>
    80001900:	97ba                	add	a5,a5,a4
    80001902:	1847a783          	lw	a5,388(a5)
    80001906:	0f278b63          	beq	a5,s2,800019fc <remove_link+0x164>
  struct proc* head = &proc[list->head];
    8000190a:	19000493          	li	s1,400
    8000190e:	029b8bb3          	mul	s7,s7,s1
    80001912:	00010a17          	auipc	s4,0x10
    80001916:	e7ea0a13          	addi	s4,s4,-386 # 80011790 <proc>
    8000191a:	9bd2                	add	s7,s7,s4
      release(&list->head_lock);
      return;
    }
  }
  
  acquire(&proc[head->next_proc_index].list_lock);
    8000191c:	180ba503          	lw	a0,384(s7) # fffffffffffff180 <end+0xffffffff7ffd9180>
    80001920:	02950533          	mul	a0,a0,s1
    80001924:	0561                	addi	a0,a0,24
    80001926:	9552                	add	a0,a0,s4
    80001928:	fffff097          	auipc	ra,0xfffff
    8000192c:	2bc080e7          	jalr	700(ra) # 80000be4 <acquire>
  struct proc* next = &proc[head->next_proc_index];
    80001930:	180ba783          	lw	a5,384(s7)
    80001934:	029784b3          	mul	s1,a5,s1
    80001938:	94d2                	add	s1,s1,s4
  release(&list->head_lock);
    8000193a:	854e                	mv	a0,s3
    8000193c:	fffff097          	auipc	ra,0xfffff
    80001940:	35c080e7          	jalr	860(ra) # 80000c98 <release>
  while(next->proc_index != index && next->next_proc_index != -1){
    80001944:	1844a703          	lw	a4,388(s1)
    80001948:	5b7d                	li	s6,-1
      release(&head->list_lock);
      head = next;
      acquire(&proc[head->next_proc_index].list_lock);
    8000194a:	19000a13          	li	s4,400
    8000194e:	00010997          	auipc	s3,0x10
    80001952:	e4298993          	addi	s3,s3,-446 # 80011790 <proc>
  while(next->proc_index != index && next->next_proc_index != -1){
    80001956:	0ce90d63          	beq	s2,a4,80001a30 <remove_link+0x198>
    8000195a:	1804a783          	lw	a5,384(s1)
    8000195e:	0f678963          	beq	a5,s6,80001a50 <remove_link+0x1b8>
      release(&head->list_lock);
    80001962:	018b8513          	addi	a0,s7,24
    80001966:	fffff097          	auipc	ra,0xfffff
    8000196a:	332080e7          	jalr	818(ra) # 80000c98 <release>
      acquire(&proc[head->next_proc_index].list_lock);
    8000196e:	1804a503          	lw	a0,384(s1)
    80001972:	03450533          	mul	a0,a0,s4
    80001976:	0561                	addi	a0,a0,24
    80001978:	954e                	add	a0,a0,s3
    8000197a:	fffff097          	auipc	ra,0xfffff
    8000197e:	26a080e7          	jalr	618(ra) # 80000be4 <acquire>
      next = &proc[next->next_proc_index];
    80001982:	1804a783          	lw	a5,384(s1)
    80001986:	034787b3          	mul	a5,a5,s4
    8000198a:	97ce                	add	a5,a5,s3
  while(next->proc_index != index && next->next_proc_index != -1){
    8000198c:	1847a703          	lw	a4,388(a5)
    80001990:	8ba6                	mv	s7,s1
    80001992:	0b270163          	beq	a4,s2,80001a34 <remove_link+0x19c>
      next = &proc[next->next_proc_index];
    80001996:	84be                	mv	s1,a5
    80001998:	b7c9                	j	8000195a <remove_link+0xc2>
    if (head->proc_index == index){
    8000199a:	19000793          	li	a5,400
    8000199e:	02fb8733          	mul	a4,s7,a5
    800019a2:	00010797          	auipc	a5,0x10
    800019a6:	dee78793          	addi	a5,a5,-530 # 80011790 <proc>
    800019aa:	97ba                	add	a5,a5,a4
    800019ac:	1847a783          	lw	a5,388(a5)
    800019b0:	03278563          	beq	a5,s2,800019da <remove_link+0x142>
      release(&head->list_lock);
    800019b4:	19000513          	li	a0,400
    800019b8:	02ab8bb3          	mul	s7,s7,a0
    800019bc:	00010517          	auipc	a0,0x10
    800019c0:	dec50513          	addi	a0,a0,-532 # 800117a8 <proc+0x18>
    800019c4:	955e                	add	a0,a0,s7
    800019c6:	fffff097          	auipc	ra,0xfffff
    800019ca:	2d2080e7          	jalr	722(ra) # 80000c98 <release>
      release(&list->head_lock);
    800019ce:	854e                	mv	a0,s3
    800019d0:	fffff097          	auipc	ra,0xfffff
    800019d4:	2c8080e7          	jalr	712(ra) # 80000c98 <release>
      return;
    800019d8:	a851                	j	80001a6c <remove_link+0x1d4>
      list->head = -1;
    800019da:	577d                	li	a4,-1
    800019dc:	00eaa023          	sw	a4,0(s5)
      list->last = -1;
    800019e0:	00eaa223          	sw	a4,4(s5)
      head->next_proc_index = -1;
    800019e4:	19000793          	li	a5,400
    800019e8:	02fb86b3          	mul	a3,s7,a5
    800019ec:	00010797          	auipc	a5,0x10
    800019f0:	da478793          	addi	a5,a5,-604 # 80011790 <proc>
    800019f4:	97b6                	add	a5,a5,a3
    800019f6:	18e7a023          	sw	a4,384(a5)
    800019fa:	bf6d                	j	800019b4 <remove_link+0x11c>
      list->head = head->next_proc_index;
    800019fc:	00010517          	auipc	a0,0x10
    80001a00:	d9450513          	addi	a0,a0,-620 # 80011790 <proc>
    80001a04:	8bba                	mv	s7,a4
    80001a06:	00e507b3          	add	a5,a0,a4
    80001a0a:	1807a703          	lw	a4,384(a5)
    80001a0e:	00eaa023          	sw	a4,0(s5)
      head->next_proc_index = -1;
    80001a12:	577d                	li	a4,-1
    80001a14:	18e7a023          	sw	a4,384(a5)
      release(&head->list_lock);
    80001a18:	0be1                	addi	s7,s7,24
    80001a1a:	955e                	add	a0,a0,s7
    80001a1c:	fffff097          	auipc	ra,0xfffff
    80001a20:	27c080e7          	jalr	636(ra) # 80000c98 <release>
      release(&list->head_lock);
    80001a24:	854e                	mv	a0,s3
    80001a26:	fffff097          	auipc	ra,0xfffff
    80001a2a:	272080e7          	jalr	626(ra) # 80000c98 <release>
      return;
    80001a2e:	a83d                	j	80001a6c <remove_link+0x1d4>
  struct proc* next = &proc[head->next_proc_index];
    80001a30:	87a6                	mv	a5,s1
  struct proc* head = &proc[list->head];
    80001a32:	84de                	mv	s1,s7
  }
  if (next->proc_index == index){
      head->next_proc_index = next->next_proc_index;
    80001a34:	1807a703          	lw	a4,384(a5)
    80001a38:	18e4a023          	sw	a4,384(s1)
      next->next_proc_index = -1;
    80001a3c:	577d                	li	a4,-1
    80001a3e:	18e7a023          	sw	a4,384(a5)
      if (next->next_proc_index == -1){
          list->last = head->proc_index;
    80001a42:	1844a703          	lw	a4,388(s1)
    80001a46:	00eaa223          	sw	a4,4(s5)
    80001a4a:	8ba6                	mv	s7,s1
    80001a4c:	84be                	mv	s1,a5
    80001a4e:	a019                	j	80001a54 <remove_link+0x1bc>
  if (next->proc_index == index){
    80001a50:	02e90963          	beq	s2,a4,80001a82 <remove_link+0x1ea>
      }
    }
  release(&head->list_lock);
    80001a54:	018b8513          	addi	a0,s7,24
    80001a58:	fffff097          	auipc	ra,0xfffff
    80001a5c:	240080e7          	jalr	576(ra) # 80000c98 <release>
  release(&next->list_lock);
    80001a60:	01848513          	addi	a0,s1,24
    80001a64:	fffff097          	auipc	ra,0xfffff
    80001a68:	234080e7          	jalr	564(ra) # 80000c98 <release>


}
    80001a6c:	60a6                	ld	ra,72(sp)
    80001a6e:	6406                	ld	s0,64(sp)
    80001a70:	74e2                	ld	s1,56(sp)
    80001a72:	7942                	ld	s2,48(sp)
    80001a74:	79a2                	ld	s3,40(sp)
    80001a76:	7a02                	ld	s4,32(sp)
    80001a78:	6ae2                	ld	s5,24(sp)
    80001a7a:	6b42                	ld	s6,16(sp)
    80001a7c:	6ba2                	ld	s7,8(sp)
    80001a7e:	6161                	addi	sp,sp,80
    80001a80:	8082                	ret
    80001a82:	87a6                	mv	a5,s1
    80001a84:	84de                	mv	s1,s7
    80001a86:	b77d                	j	80001a34 <remove_link+0x19c>

0000000080001a88 <add_link>:

void add_link(struct processList* list, int index){ // index = the process index in proc
    80001a88:	7139                	addi	sp,sp,-64
    80001a8a:	fc06                	sd	ra,56(sp)
    80001a8c:	f822                	sd	s0,48(sp)
    80001a8e:	f426                	sd	s1,40(sp)
    80001a90:	f04a                	sd	s2,32(sp)
    80001a92:	ec4e                	sd	s3,24(sp)
    80001a94:	e852                	sd	s4,16(sp)
    80001a96:	e456                	sd	s5,8(sp)
    80001a98:	e05a                	sd	s6,0(sp)
    80001a9a:	0080                	addi	s0,sp,64
    80001a9c:	84aa                	mv	s1,a0
    80001a9e:	8a2e                	mv	s4,a1
 
  acquire(&list->head_lock);
    80001aa0:	00850b13          	addi	s6,a0,8
    80001aa4:	855a                	mv	a0,s6
    80001aa6:	fffff097          	auipc	ra,0xfffff
    80001aaa:	13e080e7          	jalr	318(ra) # 80000be4 <acquire>

  acquire(&proc[index].list_lock);
    80001aae:	19000913          	li	s2,400
    80001ab2:	032a0933          	mul	s2,s4,s2
    80001ab6:	00010797          	auipc	a5,0x10
    80001aba:	cf278793          	addi	a5,a5,-782 # 800117a8 <proc+0x18>
    80001abe:	993e                	add	s2,s2,a5
    80001ac0:	854a                	mv	a0,s2
    80001ac2:	fffff097          	auipc	ra,0xfffff
    80001ac6:	122080e7          	jalr	290(ra) # 80000be4 <acquire>
  //printf("index to insert is %d\n",index);
  //printf("list head is %d\n", list->head);
  //printf("list last is %d\n", list->last);
  //procdump();
  if (list->head == -1){  //empty list
    80001aca:	0004aa83          	lw	s5,0(s1)
    80001ace:	57fd                	li	a5,-1
    80001ad0:	08fa8b63          	beq	s5,a5,80001b66 <add_link+0xde>
    release(&proc[index].list_lock);
    //printf("finished add_link\n");
    return;
  }
  struct proc* head = &proc[list->head];
  acquire(&head->list_lock);
    80001ad4:	19000993          	li	s3,400
    80001ad8:	033a89b3          	mul	s3,s5,s3
    80001adc:	00010797          	auipc	a5,0x10
    80001ae0:	ccc78793          	addi	a5,a5,-820 # 800117a8 <proc+0x18>
    80001ae4:	99be                	add	s3,s3,a5
    80001ae6:	854e                	mv	a0,s3
    80001ae8:	fffff097          	auipc	ra,0xfffff
    80001aec:	0fc080e7          	jalr	252(ra) # 80000be4 <acquire>
  if (list->head == list->last){  //list of size 1
    80001af0:	4098                	lw	a4,0(s1)
    80001af2:	40dc                	lw	a5,4(s1)
    80001af4:	08f70863          	beq	a4,a5,80001b84 <add_link+0xfc>
      release(&head->list_lock);
      release(&list->head_lock);
      release(&proc[index].list_lock);
      return;
  }
  release(&list->head_lock);
    80001af8:	855a                	mv	a0,s6
    80001afa:	fffff097          	auipc	ra,0xfffff
    80001afe:	19e080e7          	jalr	414(ra) # 80000c98 <release>
  release(&head->list_lock);
    80001b02:	854e                	mv	a0,s3
    80001b04:	fffff097          	auipc	ra,0xfffff
    80001b08:	194080e7          	jalr	404(ra) # 80000c98 <release>
  acquire(&proc[list->last].list_lock);
    80001b0c:	40c8                	lw	a0,4(s1)
    80001b0e:	19000a93          	li	s5,400
    80001b12:	03550533          	mul	a0,a0,s5
    80001b16:	0561                	addi	a0,a0,24
    80001b18:	00010997          	auipc	s3,0x10
    80001b1c:	c7898993          	addi	s3,s3,-904 # 80011790 <proc>
    80001b20:	954e                	add	a0,a0,s3
    80001b22:	fffff097          	auipc	ra,0xfffff
    80001b26:	0c2080e7          	jalr	194(ra) # 80000be4 <acquire>
  struct proc* last = &proc[list->last];
    80001b2a:	40c8                	lw	a0,4(s1)
  last->next_proc_index = index;
    80001b2c:	03550533          	mul	a0,a0,s5
    80001b30:	00a987b3          	add	a5,s3,a0
    80001b34:	1947a023          	sw	s4,384(a5)
  list->last = index;
    80001b38:	0144a223          	sw	s4,4(s1)
  release(&last->list_lock);
    80001b3c:	0561                	addi	a0,a0,24
    80001b3e:	954e                	add	a0,a0,s3
    80001b40:	fffff097          	auipc	ra,0xfffff
    80001b44:	158080e7          	jalr	344(ra) # 80000c98 <release>
  release(&proc[index].list_lock);
    80001b48:	854a                	mv	a0,s2
    80001b4a:	fffff097          	auipc	ra,0xfffff
    80001b4e:	14e080e7          	jalr	334(ra) # 80000c98 <release>
  
  return;


}
    80001b52:	70e2                	ld	ra,56(sp)
    80001b54:	7442                	ld	s0,48(sp)
    80001b56:	74a2                	ld	s1,40(sp)
    80001b58:	7902                	ld	s2,32(sp)
    80001b5a:	69e2                	ld	s3,24(sp)
    80001b5c:	6a42                	ld	s4,16(sp)
    80001b5e:	6aa2                	ld	s5,8(sp)
    80001b60:	6b02                	ld	s6,0(sp)
    80001b62:	6121                	addi	sp,sp,64
    80001b64:	8082                	ret
    list->head = index;
    80001b66:	0144a023          	sw	s4,0(s1)
    list->last = index;
    80001b6a:	0144a223          	sw	s4,4(s1)
    release(&list->head_lock);
    80001b6e:	855a                	mv	a0,s6
    80001b70:	fffff097          	auipc	ra,0xfffff
    80001b74:	128080e7          	jalr	296(ra) # 80000c98 <release>
    release(&proc[index].list_lock);
    80001b78:	854a                	mv	a0,s2
    80001b7a:	fffff097          	auipc	ra,0xfffff
    80001b7e:	11e080e7          	jalr	286(ra) # 80000c98 <release>
    return;
    80001b82:	bfc1                	j	80001b52 <add_link+0xca>
      head->next_proc_index = index;
    80001b84:	19000793          	li	a5,400
    80001b88:	02fa87b3          	mul	a5,s5,a5
    80001b8c:	00010717          	auipc	a4,0x10
    80001b90:	c0470713          	addi	a4,a4,-1020 # 80011790 <proc>
    80001b94:	97ba                	add	a5,a5,a4
    80001b96:	1947a023          	sw	s4,384(a5)
      list->last = index;
    80001b9a:	0144a223          	sw	s4,4(s1)
      release(&head->list_lock);
    80001b9e:	854e                	mv	a0,s3
    80001ba0:	fffff097          	auipc	ra,0xfffff
    80001ba4:	0f8080e7          	jalr	248(ra) # 80000c98 <release>
      release(&list->head_lock);
    80001ba8:	855a                	mv	a0,s6
    80001baa:	fffff097          	auipc	ra,0xfffff
    80001bae:	0ee080e7          	jalr	238(ra) # 80000c98 <release>
      release(&proc[index].list_lock);
    80001bb2:	854a                	mv	a0,s2
    80001bb4:	fffff097          	auipc	ra,0xfffff
    80001bb8:	0e4080e7          	jalr	228(ra) # 80000c98 <release>
      return;
    80001bbc:	bf59                	j	80001b52 <add_link+0xca>

0000000080001bbe <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001bbe:	7139                	addi	sp,sp,-64
    80001bc0:	fc06                	sd	ra,56(sp)
    80001bc2:	f822                	sd	s0,48(sp)
    80001bc4:	f426                	sd	s1,40(sp)
    80001bc6:	f04a                	sd	s2,32(sp)
    80001bc8:	ec4e                	sd	s3,24(sp)
    80001bca:	e852                	sd	s4,16(sp)
    80001bcc:	e456                	sd	s5,8(sp)
    80001bce:	e05a                	sd	s6,0(sp)
    80001bd0:	0080                	addi	s0,sp,64
    80001bd2:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bd4:	00010497          	auipc	s1,0x10
    80001bd8:	bbc48493          	addi	s1,s1,-1092 # 80011790 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001bdc:	8b26                	mv	s6,s1
    80001bde:	00006a97          	auipc	s5,0x6
    80001be2:	422a8a93          	addi	s5,s5,1058 # 80008000 <etext>
    80001be6:	04000937          	lui	s2,0x4000
    80001bea:	197d                	addi	s2,s2,-1
    80001bec:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bee:	00016a17          	auipc	s4,0x16
    80001bf2:	fa2a0a13          	addi	s4,s4,-94 # 80017b90 <tickslock>
    char *pa = kalloc();
    80001bf6:	fffff097          	auipc	ra,0xfffff
    80001bfa:	efe080e7          	jalr	-258(ra) # 80000af4 <kalloc>
    80001bfe:	862a                	mv	a2,a0
    if(pa == 0)
    80001c00:	c131                	beqz	a0,80001c44 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001c02:	416485b3          	sub	a1,s1,s6
    80001c06:	8591                	srai	a1,a1,0x4
    80001c08:	000ab783          	ld	a5,0(s5)
    80001c0c:	02f585b3          	mul	a1,a1,a5
    80001c10:	2585                	addiw	a1,a1,1
    80001c12:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001c16:	4719                	li	a4,6
    80001c18:	6685                	lui	a3,0x1
    80001c1a:	40b905b3          	sub	a1,s2,a1
    80001c1e:	854e                	mv	a0,s3
    80001c20:	fffff097          	auipc	ra,0xfffff
    80001c24:	530080e7          	jalr	1328(ra) # 80001150 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c28:	19048493          	addi	s1,s1,400
    80001c2c:	fd4495e3          	bne	s1,s4,80001bf6 <proc_mapstacks+0x38>
  }
}
    80001c30:	70e2                	ld	ra,56(sp)
    80001c32:	7442                	ld	s0,48(sp)
    80001c34:	74a2                	ld	s1,40(sp)
    80001c36:	7902                	ld	s2,32(sp)
    80001c38:	69e2                	ld	s3,24(sp)
    80001c3a:	6a42                	ld	s4,16(sp)
    80001c3c:	6aa2                	ld	s5,8(sp)
    80001c3e:	6b02                	ld	s6,0(sp)
    80001c40:	6121                	addi	sp,sp,64
    80001c42:	8082                	ret
      panic("kalloc");
    80001c44:	00006517          	auipc	a0,0x6
    80001c48:	5c450513          	addi	a0,a0,1476 # 80008208 <digits+0x1c8>
    80001c4c:	fffff097          	auipc	ra,0xfffff
    80001c50:	8f2080e7          	jalr	-1806(ra) # 8000053e <panic>

0000000080001c54 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    80001c54:	715d                	addi	sp,sp,-80
    80001c56:	e486                	sd	ra,72(sp)
    80001c58:	e0a2                	sd	s0,64(sp)
    80001c5a:	fc26                	sd	s1,56(sp)
    80001c5c:	f84a                	sd	s2,48(sp)
    80001c5e:	f44e                	sd	s3,40(sp)
    80001c60:	f052                	sd	s4,32(sp)
    80001c62:	ec56                	sd	s5,24(sp)
    80001c64:	e85a                	sd	s6,16(sp)
    80001c66:	e45e                	sd	s7,8(sp)
    80001c68:	e062                	sd	s8,0(sp)
    80001c6a:	0880                	addi	s0,sp,80
  lists_init();
    80001c6c:	00000097          	auipc	ra,0x0
    80001c70:	bd2080e7          	jalr	-1070(ra) # 8000183e <lists_init>
  struct proc *p;
  int index = 0;
  initlock(&pid_lock, "nextpid");
    80001c74:	00006597          	auipc	a1,0x6
    80001c78:	59c58593          	addi	a1,a1,1436 # 80008210 <digits+0x1d0>
    80001c7c:	0000f517          	auipc	a0,0xf
    80001c80:	6e450513          	addi	a0,a0,1764 # 80011360 <pid_lock>
    80001c84:	fffff097          	auipc	ra,0xfffff
    80001c88:	ed0080e7          	jalr	-304(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001c8c:	00006597          	auipc	a1,0x6
    80001c90:	58c58593          	addi	a1,a1,1420 # 80008218 <digits+0x1d8>
    80001c94:	0000f517          	auipc	a0,0xf
    80001c98:	6e450513          	addi	a0,a0,1764 # 80011378 <wait_lock>
    80001c9c:	fffff097          	auipc	ra,0xfffff
    80001ca0:	eb8080e7          	jalr	-328(ra) # 80000b54 <initlock>
  int index = 0;
    80001ca4:	4901                	li	s2,0
  //printf("start procinit\n");
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ca6:	00010497          	auipc	s1,0x10
    80001caa:	aea48493          	addi	s1,s1,-1302 # 80011790 <proc>
      initlock(&p->lock, "proc");
    80001cae:	00006c17          	auipc	s8,0x6
    80001cb2:	57ac0c13          	addi	s8,s8,1402 # 80008228 <digits+0x1e8>
      p->kstack = KSTACK((int) (p - proc));
    80001cb6:	8ba6                	mv	s7,s1
    80001cb8:	00006b17          	auipc	s6,0x6
    80001cbc:	348b0b13          	addi	s6,s6,840 # 80008000 <etext>
    80001cc0:	040009b7          	lui	s3,0x4000
    80001cc4:	19fd                	addi	s3,s3,-1
    80001cc6:	09b2                	slli	s3,s3,0xc
      p->proc_index=index;
      //printf("proc is %d\n", index);
      add_link(&unused_list, index);
    80001cc8:	0000fa97          	auipc	s5,0xf
    80001ccc:	5d8a8a93          	addi	s5,s5,1496 # 800112a0 <unused_list>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cd0:	00016a17          	auipc	s4,0x16
    80001cd4:	ec0a0a13          	addi	s4,s4,-320 # 80017b90 <tickslock>
      initlock(&p->lock, "proc");
    80001cd8:	85e2                	mv	a1,s8
    80001cda:	8526                	mv	a0,s1
    80001cdc:	fffff097          	auipc	ra,0xfffff
    80001ce0:	e78080e7          	jalr	-392(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001ce4:	417487b3          	sub	a5,s1,s7
    80001ce8:	8791                	srai	a5,a5,0x4
    80001cea:	000b3703          	ld	a4,0(s6)
    80001cee:	02e787b3          	mul	a5,a5,a4
    80001cf2:	2785                	addiw	a5,a5,1
    80001cf4:	00d7979b          	slliw	a5,a5,0xd
    80001cf8:	40f987b3          	sub	a5,s3,a5
    80001cfc:	ecbc                	sd	a5,88(s1)
      p->proc_index=index;
    80001cfe:	1924a223          	sw	s2,388(s1)
      add_link(&unused_list, index);
    80001d02:	85ca                	mv	a1,s2
    80001d04:	8556                	mv	a0,s5
    80001d06:	00000097          	auipc	ra,0x0
    80001d0a:	d82080e7          	jalr	-638(ra) # 80001a88 <add_link>
      index++;
    80001d0e:	2905                	addiw	s2,s2,1
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d10:	19048493          	addi	s1,s1,400
    80001d14:	fd4492e3          	bne	s1,s4,80001cd8 <procinit+0x84>
  }
}
    80001d18:	60a6                	ld	ra,72(sp)
    80001d1a:	6406                	ld	s0,64(sp)
    80001d1c:	74e2                	ld	s1,56(sp)
    80001d1e:	7942                	ld	s2,48(sp)
    80001d20:	79a2                	ld	s3,40(sp)
    80001d22:	7a02                	ld	s4,32(sp)
    80001d24:	6ae2                	ld	s5,24(sp)
    80001d26:	6b42                	ld	s6,16(sp)
    80001d28:	6ba2                	ld	s7,8(sp)
    80001d2a:	6c02                	ld	s8,0(sp)
    80001d2c:	6161                	addi	sp,sp,80
    80001d2e:	8082                	ret

0000000080001d30 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001d30:	1141                	addi	sp,sp,-16
    80001d32:	e422                	sd	s0,8(sp)
    80001d34:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001d36:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001d38:	2501                	sext.w	a0,a0
    80001d3a:	6422                	ld	s0,8(sp)
    80001d3c:	0141                	addi	sp,sp,16
    80001d3e:	8082                	ret

0000000080001d40 <mycpu>:


// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001d40:	1141                	addi	sp,sp,-16
    80001d42:	e422                	sd	s0,8(sp)
    80001d44:	0800                	addi	s0,sp,16
    80001d46:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001d48:	2781                	sext.w	a5,a5
    80001d4a:	079e                	slli	a5,a5,0x7
  return c;
}
    80001d4c:	0000f517          	auipc	a0,0xf
    80001d50:	64450513          	addi	a0,a0,1604 # 80011390 <cpus>
    80001d54:	953e                	add	a0,a0,a5
    80001d56:	6422                	ld	s0,8(sp)
    80001d58:	0141                	addi	sp,sp,16
    80001d5a:	8082                	ret

0000000080001d5c <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001d5c:	1101                	addi	sp,sp,-32
    80001d5e:	ec06                	sd	ra,24(sp)
    80001d60:	e822                	sd	s0,16(sp)
    80001d62:	e426                	sd	s1,8(sp)
    80001d64:	1000                	addi	s0,sp,32
  push_off();
    80001d66:	fffff097          	auipc	ra,0xfffff
    80001d6a:	e32080e7          	jalr	-462(ra) # 80000b98 <push_off>
    80001d6e:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001d70:	2781                	sext.w	a5,a5
    80001d72:	079e                	slli	a5,a5,0x7
    80001d74:	0000f717          	auipc	a4,0xf
    80001d78:	52c70713          	addi	a4,a4,1324 # 800112a0 <unused_list>
    80001d7c:	97ba                	add	a5,a5,a4
    80001d7e:	7be4                	ld	s1,240(a5)
  pop_off();
    80001d80:	fffff097          	auipc	ra,0xfffff
    80001d84:	eb8080e7          	jalr	-328(ra) # 80000c38 <pop_off>
  return p;
}
    80001d88:	8526                	mv	a0,s1
    80001d8a:	60e2                	ld	ra,24(sp)
    80001d8c:	6442                	ld	s0,16(sp)
    80001d8e:	64a2                	ld	s1,8(sp)
    80001d90:	6105                	addi	sp,sp,32
    80001d92:	8082                	ret

0000000080001d94 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001d94:	1141                	addi	sp,sp,-16
    80001d96:	e406                	sd	ra,8(sp)
    80001d98:	e022                	sd	s0,0(sp)
    80001d9a:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001d9c:	00000097          	auipc	ra,0x0
    80001da0:	fc0080e7          	jalr	-64(ra) # 80001d5c <myproc>
    80001da4:	fffff097          	auipc	ra,0xfffff
    80001da8:	ef4080e7          	jalr	-268(ra) # 80000c98 <release>

  if (first) {
    80001dac:	00007797          	auipc	a5,0x7
    80001db0:	b347a783          	lw	a5,-1228(a5) # 800088e0 <first.1717>
    80001db4:	eb89                	bnez	a5,80001dc6 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001db6:	00001097          	auipc	ra,0x1
    80001dba:	1a4080e7          	jalr	420(ra) # 80002f5a <usertrapret>
}
    80001dbe:	60a2                	ld	ra,8(sp)
    80001dc0:	6402                	ld	s0,0(sp)
    80001dc2:	0141                	addi	sp,sp,16
    80001dc4:	8082                	ret
    first = 0;
    80001dc6:	00007797          	auipc	a5,0x7
    80001dca:	b007ad23          	sw	zero,-1254(a5) # 800088e0 <first.1717>
    fsinit(ROOTDEV);
    80001dce:	4505                	li	a0,1
    80001dd0:	00002097          	auipc	ra,0x2
    80001dd4:	f16080e7          	jalr	-234(ra) # 80003ce6 <fsinit>
    80001dd8:	bff9                	j	80001db6 <forkret+0x22>

0000000080001dda <allocpid>:
allocpid() {
    80001dda:	1101                	addi	sp,sp,-32
    80001ddc:	ec06                	sd	ra,24(sp)
    80001dde:	e822                	sd	s0,16(sp)
    80001de0:	e426                	sd	s1,8(sp)
    80001de2:	e04a                	sd	s2,0(sp)
    80001de4:	1000                	addi	s0,sp,32
    pid = nextpid;
    80001de6:	00007917          	auipc	s2,0x7
    80001dea:	afe90913          	addi	s2,s2,-1282 # 800088e4 <nextpid>
    80001dee:	00092483          	lw	s1,0(s2)
  } while (cas(&nextpid, pid, pid+1));
    80001df2:	0014861b          	addiw	a2,s1,1
    80001df6:	85a6                	mv	a1,s1
    80001df8:	854a                	mv	a0,s2
    80001dfa:	00005097          	auipc	ra,0x5
    80001dfe:	cec080e7          	jalr	-788(ra) # 80006ae6 <cas>
    80001e02:	f575                	bnez	a0,80001dee <allocpid+0x14>
}
    80001e04:	8526                	mv	a0,s1
    80001e06:	60e2                	ld	ra,24(sp)
    80001e08:	6442                	ld	s0,16(sp)
    80001e0a:	64a2                	ld	s1,8(sp)
    80001e0c:	6902                	ld	s2,0(sp)
    80001e0e:	6105                	addi	sp,sp,32
    80001e10:	8082                	ret

0000000080001e12 <proc_pagetable>:
{
    80001e12:	1101                	addi	sp,sp,-32
    80001e14:	ec06                	sd	ra,24(sp)
    80001e16:	e822                	sd	s0,16(sp)
    80001e18:	e426                	sd	s1,8(sp)
    80001e1a:	e04a                	sd	s2,0(sp)
    80001e1c:	1000                	addi	s0,sp,32
    80001e1e:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001e20:	fffff097          	auipc	ra,0xfffff
    80001e24:	51a080e7          	jalr	1306(ra) # 8000133a <uvmcreate>
    80001e28:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001e2a:	c121                	beqz	a0,80001e6a <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001e2c:	4729                	li	a4,10
    80001e2e:	00005697          	auipc	a3,0x5
    80001e32:	1d268693          	addi	a3,a3,466 # 80007000 <_trampoline>
    80001e36:	6605                	lui	a2,0x1
    80001e38:	040005b7          	lui	a1,0x4000
    80001e3c:	15fd                	addi	a1,a1,-1
    80001e3e:	05b2                	slli	a1,a1,0xc
    80001e40:	fffff097          	auipc	ra,0xfffff
    80001e44:	270080e7          	jalr	624(ra) # 800010b0 <mappages>
    80001e48:	02054863          	bltz	a0,80001e78 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001e4c:	4719                	li	a4,6
    80001e4e:	07093683          	ld	a3,112(s2)
    80001e52:	6605                	lui	a2,0x1
    80001e54:	020005b7          	lui	a1,0x2000
    80001e58:	15fd                	addi	a1,a1,-1
    80001e5a:	05b6                	slli	a1,a1,0xd
    80001e5c:	8526                	mv	a0,s1
    80001e5e:	fffff097          	auipc	ra,0xfffff
    80001e62:	252080e7          	jalr	594(ra) # 800010b0 <mappages>
    80001e66:	02054163          	bltz	a0,80001e88 <proc_pagetable+0x76>
}
    80001e6a:	8526                	mv	a0,s1
    80001e6c:	60e2                	ld	ra,24(sp)
    80001e6e:	6442                	ld	s0,16(sp)
    80001e70:	64a2                	ld	s1,8(sp)
    80001e72:	6902                	ld	s2,0(sp)
    80001e74:	6105                	addi	sp,sp,32
    80001e76:	8082                	ret
    uvmfree(pagetable, 0);
    80001e78:	4581                	li	a1,0
    80001e7a:	8526                	mv	a0,s1
    80001e7c:	fffff097          	auipc	ra,0xfffff
    80001e80:	6ba080e7          	jalr	1722(ra) # 80001536 <uvmfree>
    return 0;
    80001e84:	4481                	li	s1,0
    80001e86:	b7d5                	j	80001e6a <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001e88:	4681                	li	a3,0
    80001e8a:	4605                	li	a2,1
    80001e8c:	040005b7          	lui	a1,0x4000
    80001e90:	15fd                	addi	a1,a1,-1
    80001e92:	05b2                	slli	a1,a1,0xc
    80001e94:	8526                	mv	a0,s1
    80001e96:	fffff097          	auipc	ra,0xfffff
    80001e9a:	3e0080e7          	jalr	992(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80001e9e:	4581                	li	a1,0
    80001ea0:	8526                	mv	a0,s1
    80001ea2:	fffff097          	auipc	ra,0xfffff
    80001ea6:	694080e7          	jalr	1684(ra) # 80001536 <uvmfree>
    return 0;
    80001eaa:	4481                	li	s1,0
    80001eac:	bf7d                	j	80001e6a <proc_pagetable+0x58>

0000000080001eae <proc_freepagetable>:
{
    80001eae:	1101                	addi	sp,sp,-32
    80001eb0:	ec06                	sd	ra,24(sp)
    80001eb2:	e822                	sd	s0,16(sp)
    80001eb4:	e426                	sd	s1,8(sp)
    80001eb6:	e04a                	sd	s2,0(sp)
    80001eb8:	1000                	addi	s0,sp,32
    80001eba:	84aa                	mv	s1,a0
    80001ebc:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ebe:	4681                	li	a3,0
    80001ec0:	4605                	li	a2,1
    80001ec2:	040005b7          	lui	a1,0x4000
    80001ec6:	15fd                	addi	a1,a1,-1
    80001ec8:	05b2                	slli	a1,a1,0xc
    80001eca:	fffff097          	auipc	ra,0xfffff
    80001ece:	3ac080e7          	jalr	940(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001ed2:	4681                	li	a3,0
    80001ed4:	4605                	li	a2,1
    80001ed6:	020005b7          	lui	a1,0x2000
    80001eda:	15fd                	addi	a1,a1,-1
    80001edc:	05b6                	slli	a1,a1,0xd
    80001ede:	8526                	mv	a0,s1
    80001ee0:	fffff097          	auipc	ra,0xfffff
    80001ee4:	396080e7          	jalr	918(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80001ee8:	85ca                	mv	a1,s2
    80001eea:	8526                	mv	a0,s1
    80001eec:	fffff097          	auipc	ra,0xfffff
    80001ef0:	64a080e7          	jalr	1610(ra) # 80001536 <uvmfree>
}
    80001ef4:	60e2                	ld	ra,24(sp)
    80001ef6:	6442                	ld	s0,16(sp)
    80001ef8:	64a2                	ld	s1,8(sp)
    80001efa:	6902                	ld	s2,0(sp)
    80001efc:	6105                	addi	sp,sp,32
    80001efe:	8082                	ret

0000000080001f00 <freeproc>:
{
    80001f00:	1101                	addi	sp,sp,-32
    80001f02:	ec06                	sd	ra,24(sp)
    80001f04:	e822                	sd	s0,16(sp)
    80001f06:	e426                	sd	s1,8(sp)
    80001f08:	1000                	addi	s0,sp,32
    80001f0a:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001f0c:	7928                	ld	a0,112(a0)
    80001f0e:	c509                	beqz	a0,80001f18 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001f10:	fffff097          	auipc	ra,0xfffff
    80001f14:	ae8080e7          	jalr	-1304(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001f18:	0604b823          	sd	zero,112(s1)
  if(p->pagetable)
    80001f1c:	74a8                	ld	a0,104(s1)
    80001f1e:	c511                	beqz	a0,80001f2a <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001f20:	70ac                	ld	a1,96(s1)
    80001f22:	00000097          	auipc	ra,0x0
    80001f26:	f8c080e7          	jalr	-116(ra) # 80001eae <proc_freepagetable>
  remove_link(&zombie_list, p->proc_index);
    80001f2a:	1844a583          	lw	a1,388(s1)
    80001f2e:	0000f517          	auipc	a0,0xf
    80001f32:	3b250513          	addi	a0,a0,946 # 800112e0 <zombie_list>
    80001f36:	00000097          	auipc	ra,0x0
    80001f3a:	962080e7          	jalr	-1694(ra) # 80001898 <remove_link>
  add_link(&unused_list, p->proc_index);
    80001f3e:	1844a583          	lw	a1,388(s1)
    80001f42:	0000f517          	auipc	a0,0xf
    80001f46:	35e50513          	addi	a0,a0,862 # 800112a0 <unused_list>
    80001f4a:	00000097          	auipc	ra,0x0
    80001f4e:	b3e080e7          	jalr	-1218(ra) # 80001a88 <add_link>
  p->pagetable = 0;
    80001f52:	0604b423          	sd	zero,104(s1)
  p->sz = 0;
    80001f56:	0604b023          	sd	zero,96(s1)
  p->pid = 0;
    80001f5a:	0404a423          	sw	zero,72(s1)
  p->parent = 0;
    80001f5e:	0404b823          	sd	zero,80(s1)
  p->name[0] = 0;
    80001f62:	16048823          	sb	zero,368(s1)
  p->chan = 0;
    80001f66:	0204bc23          	sd	zero,56(s1)
  p->killed = 0;
    80001f6a:	0404a023          	sw	zero,64(s1)
  p->xstate = 0;
    80001f6e:	0404a223          	sw	zero,68(s1)
  p->state = UNUSED;
    80001f72:	0204a823          	sw	zero,48(s1)
}
    80001f76:	60e2                	ld	ra,24(sp)
    80001f78:	6442                	ld	s0,16(sp)
    80001f7a:	64a2                	ld	s1,8(sp)
    80001f7c:	6105                	addi	sp,sp,32
    80001f7e:	8082                	ret

0000000080001f80 <allocproc>:
{
    80001f80:	7139                	addi	sp,sp,-64
    80001f82:	fc06                	sd	ra,56(sp)
    80001f84:	f822                	sd	s0,48(sp)
    80001f86:	f426                	sd	s1,40(sp)
    80001f88:	f04a                	sd	s2,32(sp)
    80001f8a:	ec4e                	sd	s3,24(sp)
    80001f8c:	e852                	sd	s4,16(sp)
    80001f8e:	e456                	sd	s5,8(sp)
    80001f90:	0080                	addi	s0,sp,64
  if (unused_list.head == -1){
    80001f92:	0000f497          	auipc	s1,0xf
    80001f96:	30e4a483          	lw	s1,782(s1) # 800112a0 <unused_list>
    80001f9a:	57fd                	li	a5,-1
    80001f9c:	0cf48363          	beq	s1,a5,80002062 <allocproc+0xe2>
  struct proc *p = &proc[unused_list.head];
    80001fa0:	19000793          	li	a5,400
    80001fa4:	02f484b3          	mul	s1,s1,a5
    80001fa8:	0000f797          	auipc	a5,0xf
    80001fac:	7e878793          	addi	a5,a5,2024 # 80011790 <proc>
    80001fb0:	94be                	add	s1,s1,a5
  acquire(&p->lock);
    80001fb2:	8526                	mv	a0,s1
    80001fb4:	fffff097          	auipc	ra,0xfffff
    80001fb8:	c30080e7          	jalr	-976(ra) # 80000be4 <acquire>
  while(p->state != UNUSED){
    80001fbc:	589c                	lw	a5,48(s1)
    80001fbe:	cf9d                	beqz	a5,80001ffc <allocproc+0x7c>
    if (unused_list.head == -1)
    80001fc0:	0000f997          	auipc	s3,0xf
    80001fc4:	2e098993          	addi	s3,s3,736 # 800112a0 <unused_list>
    80001fc8:	597d                	li	s2,-1
    p = &proc[unused_list.head];
    80001fca:	19000a93          	li	s5,400
    80001fce:	0000fa17          	auipc	s4,0xf
    80001fd2:	7c2a0a13          	addi	s4,s4,1986 # 80011790 <proc>
    release(&p->lock);
    80001fd6:	8526                	mv	a0,s1
    80001fd8:	fffff097          	auipc	ra,0xfffff
    80001fdc:	cc0080e7          	jalr	-832(ra) # 80000c98 <release>
    if (unused_list.head == -1)
    80001fe0:	0009a483          	lw	s1,0(s3)
    80001fe4:	0d248163          	beq	s1,s2,800020a6 <allocproc+0x126>
    p = &proc[unused_list.head];
    80001fe8:	035484b3          	mul	s1,s1,s5
    80001fec:	94d2                	add	s1,s1,s4
    acquire(&p->lock);
    80001fee:	8526                	mv	a0,s1
    80001ff0:	fffff097          	auipc	ra,0xfffff
    80001ff4:	bf4080e7          	jalr	-1036(ra) # 80000be4 <acquire>
  while(p->state != UNUSED){
    80001ff8:	589c                	lw	a5,48(s1)
    80001ffa:	fff1                	bnez	a5,80001fd6 <allocproc+0x56>
  remove_link(&unused_list, p->proc_index);
    80001ffc:	1844a583          	lw	a1,388(s1)
    80002000:	0000f517          	auipc	a0,0xf
    80002004:	2a050513          	addi	a0,a0,672 # 800112a0 <unused_list>
    80002008:	00000097          	auipc	ra,0x0
    8000200c:	890080e7          	jalr	-1904(ra) # 80001898 <remove_link>
  p->pid = allocpid();
    80002010:	00000097          	auipc	ra,0x0
    80002014:	dca080e7          	jalr	-566(ra) # 80001dda <allocpid>
    80002018:	c4a8                	sw	a0,72(s1)
  p->state = USED;
    8000201a:	4785                	li	a5,1
    8000201c:	d89c                	sw	a5,48(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    8000201e:	fffff097          	auipc	ra,0xfffff
    80002022:	ad6080e7          	jalr	-1322(ra) # 80000af4 <kalloc>
    80002026:	892a                	mv	s2,a0
    80002028:	f8a8                	sd	a0,112(s1)
    8000202a:	c531                	beqz	a0,80002076 <allocproc+0xf6>
  p->pagetable = proc_pagetable(p);
    8000202c:	8526                	mv	a0,s1
    8000202e:	00000097          	auipc	ra,0x0
    80002032:	de4080e7          	jalr	-540(ra) # 80001e12 <proc_pagetable>
    80002036:	892a                	mv	s2,a0
    80002038:	f4a8                	sd	a0,104(s1)
  if(p->pagetable == 0){
    8000203a:	c931                	beqz	a0,8000208e <allocproc+0x10e>
  memset(&p->context, 0, sizeof(p->context));
    8000203c:	07000613          	li	a2,112
    80002040:	4581                	li	a1,0
    80002042:	07848513          	addi	a0,s1,120
    80002046:	fffff097          	auipc	ra,0xfffff
    8000204a:	c9a080e7          	jalr	-870(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    8000204e:	00000797          	auipc	a5,0x0
    80002052:	d4678793          	addi	a5,a5,-698 # 80001d94 <forkret>
    80002056:	fcbc                	sd	a5,120(s1)
  p->context.sp = p->kstack + PGSIZE;
    80002058:	6cbc                	ld	a5,88(s1)
    8000205a:	6705                	lui	a4,0x1
    8000205c:	97ba                	add	a5,a5,a4
    8000205e:	e0dc                	sd	a5,128(s1)
  return p;
    80002060:	a0a1                	j	800020a8 <allocproc+0x128>
    printf("unused list is empty in allocproc\n");
    80002062:	00006517          	auipc	a0,0x6
    80002066:	1ce50513          	addi	a0,a0,462 # 80008230 <digits+0x1f0>
    8000206a:	ffffe097          	auipc	ra,0xffffe
    8000206e:	51e080e7          	jalr	1310(ra) # 80000588 <printf>
    return 0;
    80002072:	4481                	li	s1,0
    80002074:	a815                	j	800020a8 <allocproc+0x128>
    freeproc(p);
    80002076:	8526                	mv	a0,s1
    80002078:	00000097          	auipc	ra,0x0
    8000207c:	e88080e7          	jalr	-376(ra) # 80001f00 <freeproc>
    release(&p->lock);
    80002080:	8526                	mv	a0,s1
    80002082:	fffff097          	auipc	ra,0xfffff
    80002086:	c16080e7          	jalr	-1002(ra) # 80000c98 <release>
    return 0;
    8000208a:	84ca                	mv	s1,s2
    8000208c:	a831                	j	800020a8 <allocproc+0x128>
    freeproc(p);
    8000208e:	8526                	mv	a0,s1
    80002090:	00000097          	auipc	ra,0x0
    80002094:	e70080e7          	jalr	-400(ra) # 80001f00 <freeproc>
    release(&p->lock);
    80002098:	8526                	mv	a0,s1
    8000209a:	fffff097          	auipc	ra,0xfffff
    8000209e:	bfe080e7          	jalr	-1026(ra) # 80000c98 <release>
    return 0;
    800020a2:	84ca                	mv	s1,s2
    800020a4:	a011                	j	800020a8 <allocproc+0x128>
      return 0;
    800020a6:	4481                	li	s1,0
}
    800020a8:	8526                	mv	a0,s1
    800020aa:	70e2                	ld	ra,56(sp)
    800020ac:	7442                	ld	s0,48(sp)
    800020ae:	74a2                	ld	s1,40(sp)
    800020b0:	7902                	ld	s2,32(sp)
    800020b2:	69e2                	ld	s3,24(sp)
    800020b4:	6a42                	ld	s4,16(sp)
    800020b6:	6aa2                	ld	s5,8(sp)
    800020b8:	6121                	addi	sp,sp,64
    800020ba:	8082                	ret

00000000800020bc <userinit>:
{
    800020bc:	1101                	addi	sp,sp,-32
    800020be:	ec06                	sd	ra,24(sp)
    800020c0:	e822                	sd	s0,16(sp)
    800020c2:	e426                	sd	s1,8(sp)
    800020c4:	1000                	addi	s0,sp,32
  p = allocproc();
    800020c6:	00000097          	auipc	ra,0x0
    800020ca:	eba080e7          	jalr	-326(ra) # 80001f80 <allocproc>
    800020ce:	84aa                	mv	s1,a0
  initproc = p;
    800020d0:	00007797          	auipc	a5,0x7
    800020d4:	f4a7bc23          	sd	a0,-168(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    800020d8:	03400613          	li	a2,52
    800020dc:	00007597          	auipc	a1,0x7
    800020e0:	81458593          	addi	a1,a1,-2028 # 800088f0 <initcode>
    800020e4:	7528                	ld	a0,104(a0)
    800020e6:	fffff097          	auipc	ra,0xfffff
    800020ea:	282080e7          	jalr	642(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    800020ee:	6785                	lui	a5,0x1
    800020f0:	f0bc                	sd	a5,96(s1)
  p->trapframe->epc = 0;      // user program counter
    800020f2:	78b8                	ld	a4,112(s1)
    800020f4:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    800020f8:	78b8                	ld	a4,112(s1)
    800020fa:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    800020fc:	4641                	li	a2,16
    800020fe:	00006597          	auipc	a1,0x6
    80002102:	15a58593          	addi	a1,a1,346 # 80008258 <digits+0x218>
    80002106:	17048513          	addi	a0,s1,368
    8000210a:	fffff097          	auipc	ra,0xfffff
    8000210e:	d28080e7          	jalr	-728(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80002112:	00006517          	auipc	a0,0x6
    80002116:	15650513          	addi	a0,a0,342 # 80008268 <digits+0x228>
    8000211a:	00002097          	auipc	ra,0x2
    8000211e:	5fa080e7          	jalr	1530(ra) # 80004714 <namei>
    80002122:	16a4b423          	sd	a0,360(s1)
  p->state = RUNNABLE;
    80002126:	478d                	li	a5,3
    80002128:	d89c                	sw	a5,48(s1)
  add_link(&runnable_cpu_lists[0], p->proc_index); // init_proc index is 0
    8000212a:	1844a583          	lw	a1,388(s1)
    8000212e:	0000f517          	auipc	a0,0xf
    80002132:	1d250513          	addi	a0,a0,466 # 80011300 <runnable_cpu_lists>
    80002136:	00000097          	auipc	ra,0x0
    8000213a:	952080e7          	jalr	-1710(ra) # 80001a88 <add_link>
  release(&p->lock);
    8000213e:	8526                	mv	a0,s1
    80002140:	fffff097          	auipc	ra,0xfffff
    80002144:	b58080e7          	jalr	-1192(ra) # 80000c98 <release>
}
    80002148:	60e2                	ld	ra,24(sp)
    8000214a:	6442                	ld	s0,16(sp)
    8000214c:	64a2                	ld	s1,8(sp)
    8000214e:	6105                	addi	sp,sp,32
    80002150:	8082                	ret

0000000080002152 <growproc>:
{
    80002152:	1101                	addi	sp,sp,-32
    80002154:	ec06                	sd	ra,24(sp)
    80002156:	e822                	sd	s0,16(sp)
    80002158:	e426                	sd	s1,8(sp)
    8000215a:	e04a                	sd	s2,0(sp)
    8000215c:	1000                	addi	s0,sp,32
    8000215e:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002160:	00000097          	auipc	ra,0x0
    80002164:	bfc080e7          	jalr	-1028(ra) # 80001d5c <myproc>
    80002168:	892a                	mv	s2,a0
  sz = p->sz;
    8000216a:	712c                	ld	a1,96(a0)
    8000216c:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80002170:	00904f63          	bgtz	s1,8000218e <growproc+0x3c>
  } else if(n < 0){
    80002174:	0204cc63          	bltz	s1,800021ac <growproc+0x5a>
  p->sz = sz;
    80002178:	1602                	slli	a2,a2,0x20
    8000217a:	9201                	srli	a2,a2,0x20
    8000217c:	06c93023          	sd	a2,96(s2)
  return 0;
    80002180:	4501                	li	a0,0
}
    80002182:	60e2                	ld	ra,24(sp)
    80002184:	6442                	ld	s0,16(sp)
    80002186:	64a2                	ld	s1,8(sp)
    80002188:	6902                	ld	s2,0(sp)
    8000218a:	6105                	addi	sp,sp,32
    8000218c:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    8000218e:	9e25                	addw	a2,a2,s1
    80002190:	1602                	slli	a2,a2,0x20
    80002192:	9201                	srli	a2,a2,0x20
    80002194:	1582                	slli	a1,a1,0x20
    80002196:	9181                	srli	a1,a1,0x20
    80002198:	7528                	ld	a0,104(a0)
    8000219a:	fffff097          	auipc	ra,0xfffff
    8000219e:	288080e7          	jalr	648(ra) # 80001422 <uvmalloc>
    800021a2:	0005061b          	sext.w	a2,a0
    800021a6:	fa69                	bnez	a2,80002178 <growproc+0x26>
      return -1;
    800021a8:	557d                	li	a0,-1
    800021aa:	bfe1                	j	80002182 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    800021ac:	9e25                	addw	a2,a2,s1
    800021ae:	1602                	slli	a2,a2,0x20
    800021b0:	9201                	srli	a2,a2,0x20
    800021b2:	1582                	slli	a1,a1,0x20
    800021b4:	9181                	srli	a1,a1,0x20
    800021b6:	7528                	ld	a0,104(a0)
    800021b8:	fffff097          	auipc	ra,0xfffff
    800021bc:	222080e7          	jalr	546(ra) # 800013da <uvmdealloc>
    800021c0:	0005061b          	sext.w	a2,a0
    800021c4:	bf55                	j	80002178 <growproc+0x26>

00000000800021c6 <fork>:
{
    800021c6:	7179                	addi	sp,sp,-48
    800021c8:	f406                	sd	ra,40(sp)
    800021ca:	f022                	sd	s0,32(sp)
    800021cc:	ec26                	sd	s1,24(sp)
    800021ce:	e84a                	sd	s2,16(sp)
    800021d0:	e44e                	sd	s3,8(sp)
    800021d2:	e052                	sd	s4,0(sp)
    800021d4:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800021d6:	00000097          	auipc	ra,0x0
    800021da:	b86080e7          	jalr	-1146(ra) # 80001d5c <myproc>
    800021de:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    800021e0:	00000097          	auipc	ra,0x0
    800021e4:	da0080e7          	jalr	-608(ra) # 80001f80 <allocproc>
    800021e8:	12050b63          	beqz	a0,8000231e <fork+0x158>
    800021ec:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    800021ee:	06093603          	ld	a2,96(s2)
    800021f2:	752c                	ld	a1,104(a0)
    800021f4:	06893503          	ld	a0,104(s2)
    800021f8:	fffff097          	auipc	ra,0xfffff
    800021fc:	376080e7          	jalr	886(ra) # 8000156e <uvmcopy>
    80002200:	04054663          	bltz	a0,8000224c <fork+0x86>
  np->sz = p->sz;
    80002204:	06093783          	ld	a5,96(s2)
    80002208:	06f9b023          	sd	a5,96(s3)
  *(np->trapframe) = *(p->trapframe);
    8000220c:	07093683          	ld	a3,112(s2)
    80002210:	87b6                	mv	a5,a3
    80002212:	0709b703          	ld	a4,112(s3)
    80002216:	12068693          	addi	a3,a3,288
    8000221a:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    8000221e:	6788                	ld	a0,8(a5)
    80002220:	6b8c                	ld	a1,16(a5)
    80002222:	6f90                	ld	a2,24(a5)
    80002224:	01073023          	sd	a6,0(a4)
    80002228:	e708                	sd	a0,8(a4)
    8000222a:	eb0c                	sd	a1,16(a4)
    8000222c:	ef10                	sd	a2,24(a4)
    8000222e:	02078793          	addi	a5,a5,32
    80002232:	02070713          	addi	a4,a4,32
    80002236:	fed792e3          	bne	a5,a3,8000221a <fork+0x54>
  np->trapframe->a0 = 0;
    8000223a:	0709b783          	ld	a5,112(s3)
    8000223e:	0607b823          	sd	zero,112(a5)
    80002242:	0e800493          	li	s1,232
  for(i = 0; i < NOFILE; i++)
    80002246:	16800a13          	li	s4,360
    8000224a:	a03d                	j	80002278 <fork+0xb2>
    freeproc(np);
    8000224c:	854e                	mv	a0,s3
    8000224e:	00000097          	auipc	ra,0x0
    80002252:	cb2080e7          	jalr	-846(ra) # 80001f00 <freeproc>
    release(&np->lock);
    80002256:	854e                	mv	a0,s3
    80002258:	fffff097          	auipc	ra,0xfffff
    8000225c:	a40080e7          	jalr	-1472(ra) # 80000c98 <release>
    return -1;
    80002260:	5a7d                	li	s4,-1
    80002262:	a06d                	j	8000230c <fork+0x146>
      np->ofile[i] = filedup(p->ofile[i]);
    80002264:	00003097          	auipc	ra,0x3
    80002268:	b46080e7          	jalr	-1210(ra) # 80004daa <filedup>
    8000226c:	009987b3          	add	a5,s3,s1
    80002270:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80002272:	04a1                	addi	s1,s1,8
    80002274:	01448763          	beq	s1,s4,80002282 <fork+0xbc>
    if(p->ofile[i])
    80002278:	009907b3          	add	a5,s2,s1
    8000227c:	6388                	ld	a0,0(a5)
    8000227e:	f17d                	bnez	a0,80002264 <fork+0x9e>
    80002280:	bfcd                	j	80002272 <fork+0xac>
  np->cwd = idup(p->cwd);
    80002282:	16893503          	ld	a0,360(s2)
    80002286:	00002097          	auipc	ra,0x2
    8000228a:	c9a080e7          	jalr	-870(ra) # 80003f20 <idup>
    8000228e:	16a9b423          	sd	a0,360(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002292:	4641                	li	a2,16
    80002294:	17090593          	addi	a1,s2,368
    80002298:	17098513          	addi	a0,s3,368
    8000229c:	fffff097          	auipc	ra,0xfffff
    800022a0:	b96080e7          	jalr	-1130(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    800022a4:	0489aa03          	lw	s4,72(s3)
  release(&np->lock);
    800022a8:	854e                	mv	a0,s3
    800022aa:	fffff097          	auipc	ra,0xfffff
    800022ae:	9ee080e7          	jalr	-1554(ra) # 80000c98 <release>
  acquire(&wait_lock);
    800022b2:	0000f497          	auipc	s1,0xf
    800022b6:	0c648493          	addi	s1,s1,198 # 80011378 <wait_lock>
    800022ba:	8526                	mv	a0,s1
    800022bc:	fffff097          	auipc	ra,0xfffff
    800022c0:	928080e7          	jalr	-1752(ra) # 80000be4 <acquire>
  np->parent = p;
    800022c4:	0529b823          	sd	s2,80(s3)
  release(&wait_lock);
    800022c8:	8526                	mv	a0,s1
    800022ca:	fffff097          	auipc	ra,0xfffff
    800022ce:	9ce080e7          	jalr	-1586(ra) # 80000c98 <release>
  acquire(&np->lock);
    800022d2:	854e                	mv	a0,s3
    800022d4:	fffff097          	auipc	ra,0xfffff
    800022d8:	910080e7          	jalr	-1776(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    800022dc:	478d                	li	a5,3
    800022de:	02f9a823          	sw	a5,48(s3)
  np-> affiliated_cpu = p-> affiliated_cpu;
    800022e2:	18892503          	lw	a0,392(s2)
    800022e6:	18a9a423          	sw	a0,392(s3)
  add_link(&runnable_cpu_lists[np->affiliated_cpu], np->proc_index);
    800022ea:	0516                	slli	a0,a0,0x5
    800022ec:	1849a583          	lw	a1,388(s3)
    800022f0:	0000f797          	auipc	a5,0xf
    800022f4:	01078793          	addi	a5,a5,16 # 80011300 <runnable_cpu_lists>
    800022f8:	953e                	add	a0,a0,a5
    800022fa:	fffff097          	auipc	ra,0xfffff
    800022fe:	78e080e7          	jalr	1934(ra) # 80001a88 <add_link>
  release(&np->lock);
    80002302:	854e                	mv	a0,s3
    80002304:	fffff097          	auipc	ra,0xfffff
    80002308:	994080e7          	jalr	-1644(ra) # 80000c98 <release>
}
    8000230c:	8552                	mv	a0,s4
    8000230e:	70a2                	ld	ra,40(sp)
    80002310:	7402                	ld	s0,32(sp)
    80002312:	64e2                	ld	s1,24(sp)
    80002314:	6942                	ld	s2,16(sp)
    80002316:	69a2                	ld	s3,8(sp)
    80002318:	6a02                	ld	s4,0(sp)
    8000231a:	6145                	addi	sp,sp,48
    8000231c:	8082                	ret
    return -1;
    8000231e:	5a7d                	li	s4,-1
    80002320:	b7f5                	j	8000230c <fork+0x146>

0000000080002322 <scheduler>:
{
    80002322:	7119                	addi	sp,sp,-128
    80002324:	fc86                	sd	ra,120(sp)
    80002326:	f8a2                	sd	s0,112(sp)
    80002328:	f4a6                	sd	s1,104(sp)
    8000232a:	f0ca                	sd	s2,96(sp)
    8000232c:	ecce                	sd	s3,88(sp)
    8000232e:	e8d2                	sd	s4,80(sp)
    80002330:	e4d6                	sd	s5,72(sp)
    80002332:	e0da                	sd	s6,64(sp)
    80002334:	fc5e                	sd	s7,56(sp)
    80002336:	f862                	sd	s8,48(sp)
    80002338:	f466                	sd	s9,40(sp)
    8000233a:	f06a                	sd	s10,32(sp)
    8000233c:	ec6e                	sd	s11,24(sp)
    8000233e:	0100                	addi	s0,sp,128
    80002340:	8792                	mv	a5,tp
  int id = r_tp();
    80002342:	2781                	sext.w	a5,a5
    80002344:	8712                	mv	a4,tp
    80002346:	2701                	sext.w	a4,a4
  struct processList* ready_list = &runnable_cpu_lists[cpu_id];
    80002348:	00571693          	slli	a3,a4,0x5
    8000234c:	0000f917          	auipc	s2,0xf
    80002350:	fb490913          	addi	s2,s2,-76 # 80011300 <runnable_cpu_lists>
    80002354:	00d90d33          	add	s10,s2,a3
  c->proc = 0;
    80002358:	00779593          	slli	a1,a5,0x7
    8000235c:	0000f617          	auipc	a2,0xf
    80002360:	f4460613          	addi	a2,a2,-188 # 800112a0 <unused_list>
    80002364:	962e                	add	a2,a2,a1
    80002366:	0e063823          	sd	zero,240(a2)
    acquire(&ready_list->head_lock);
    8000236a:	06a1                	addi	a3,a3,8
    8000236c:	9936                	add	s2,s2,a3
        swtch(&c->context, &p->context);
    8000236e:	0000f697          	auipc	a3,0xf
    80002372:	02a68693          	addi	a3,a3,42 # 80011398 <cpus+0x8>
    80002376:	96ae                	add	a3,a3,a1
    80002378:	f8d43423          	sd	a3,-120(s0)
    if (ready_list->head == -1){
    8000237c:	0000fd97          	auipc	s11,0xf
    80002380:	f24d8d93          	addi	s11,s11,-220 # 800112a0 <unused_list>
    80002384:	0716                	slli	a4,a4,0x5
    80002386:	00ed89b3          	add	s3,s11,a4
    8000238a:	5b7d                	li	s6,-1
    8000238c:	19000c13          	li	s8,400
    p = &proc[ready_list->head];
    80002390:	0000fb97          	auipc	s7,0xf
    80002394:	400b8b93          	addi	s7,s7,1024 # 80011790 <proc>
    if(p->state == RUNNABLE) {
    80002398:	4c8d                	li	s9,3
        c->proc = p;
    8000239a:	8db2                	mv	s11,a2
    8000239c:	a081                	j	800023dc <scheduler+0xba>
    release(&ready_list->head_lock);
    8000239e:	854a                	mv	a0,s2
    800023a0:	fffff097          	auipc	ra,0xfffff
    800023a4:	8f8080e7          	jalr	-1800(ra) # 80000c98 <release>
    p = &proc[ready_list->head];
    800023a8:	0609aa03          	lw	s4,96(s3)
    800023ac:	038a0ab3          	mul	s5,s4,s8
    800023b0:	017a84b3          	add	s1,s5,s7
    remove_link(ready_list, p->proc_index);
    800023b4:	1844a583          	lw	a1,388(s1)
    800023b8:	856a                	mv	a0,s10
    800023ba:	fffff097          	auipc	ra,0xfffff
    800023be:	4de080e7          	jalr	1246(ra) # 80001898 <remove_link>
    acquire(&p->lock);
    800023c2:	8526                	mv	a0,s1
    800023c4:	fffff097          	auipc	ra,0xfffff
    800023c8:	820080e7          	jalr	-2016(ra) # 80000be4 <acquire>
    if(p->state == RUNNABLE) {
    800023cc:	589c                	lw	a5,48(s1)
    800023ce:	03978c63          	beq	a5,s9,80002406 <scheduler+0xe4>
    release(&p->lock);
    800023d2:	8526                	mv	a0,s1
    800023d4:	fffff097          	auipc	ra,0xfffff
    800023d8:	8c4080e7          	jalr	-1852(ra) # 80000c98 <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800023dc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800023e0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800023e4:	10079073          	csrw	sstatus,a5
    acquire(&ready_list->head_lock);
    800023e8:	854a                	mv	a0,s2
    800023ea:	ffffe097          	auipc	ra,0xffffe
    800023ee:	7fa080e7          	jalr	2042(ra) # 80000be4 <acquire>
    if (ready_list->head == -1){
    800023f2:	0609a783          	lw	a5,96(s3)
    800023f6:	fb6794e3          	bne	a5,s6,8000239e <scheduler+0x7c>
        release(&ready_list->head_lock);
    800023fa:	854a                	mv	a0,s2
    800023fc:	fffff097          	auipc	ra,0xfffff
    80002400:	89c080e7          	jalr	-1892(ra) # 80000c98 <release>
        continue; // TODO: CHECK IT OUT
    80002404:	bfe1                	j	800023dc <scheduler+0xba>
        p->state = RUNNING;
    80002406:	4791                	li	a5,4
    80002408:	d89c                	sw	a5,48(s1)
        c->proc = p;
    8000240a:	0e9db823          	sd	s1,240(s11)
        swtch(&c->context, &p->context);
    8000240e:	078a8593          	addi	a1,s5,120
    80002412:	95de                	add	a1,a1,s7
    80002414:	f8843503          	ld	a0,-120(s0)
    80002418:	00001097          	auipc	ra,0x1
    8000241c:	a98080e7          	jalr	-1384(ra) # 80002eb0 <swtch>
        c->proc = 0;
    80002420:	0e0db823          	sd	zero,240(s11)
    80002424:	b77d                	j	800023d2 <scheduler+0xb0>

0000000080002426 <sched>:
{
    80002426:	7179                	addi	sp,sp,-48
    80002428:	f406                	sd	ra,40(sp)
    8000242a:	f022                	sd	s0,32(sp)
    8000242c:	ec26                	sd	s1,24(sp)
    8000242e:	e84a                	sd	s2,16(sp)
    80002430:	e44e                	sd	s3,8(sp)
    80002432:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002434:	00000097          	auipc	ra,0x0
    80002438:	928080e7          	jalr	-1752(ra) # 80001d5c <myproc>
    8000243c:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000243e:	ffffe097          	auipc	ra,0xffffe
    80002442:	72c080e7          	jalr	1836(ra) # 80000b6a <holding>
    80002446:	c93d                	beqz	a0,800024bc <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002448:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    8000244a:	2781                	sext.w	a5,a5
    8000244c:	079e                	slli	a5,a5,0x7
    8000244e:	0000f717          	auipc	a4,0xf
    80002452:	e5270713          	addi	a4,a4,-430 # 800112a0 <unused_list>
    80002456:	97ba                	add	a5,a5,a4
    80002458:	1687a703          	lw	a4,360(a5)
    8000245c:	4785                	li	a5,1
    8000245e:	06f71763          	bne	a4,a5,800024cc <sched+0xa6>
  if(p->state == RUNNING)
    80002462:	5898                	lw	a4,48(s1)
    80002464:	4791                	li	a5,4
    80002466:	06f70b63          	beq	a4,a5,800024dc <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000246a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000246e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002470:	efb5                	bnez	a5,800024ec <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002472:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002474:	0000f917          	auipc	s2,0xf
    80002478:	e2c90913          	addi	s2,s2,-468 # 800112a0 <unused_list>
    8000247c:	2781                	sext.w	a5,a5
    8000247e:	079e                	slli	a5,a5,0x7
    80002480:	97ca                	add	a5,a5,s2
    80002482:	16c7a983          	lw	s3,364(a5)
    80002486:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002488:	2781                	sext.w	a5,a5
    8000248a:	079e                	slli	a5,a5,0x7
    8000248c:	0000f597          	auipc	a1,0xf
    80002490:	f0c58593          	addi	a1,a1,-244 # 80011398 <cpus+0x8>
    80002494:	95be                	add	a1,a1,a5
    80002496:	07848513          	addi	a0,s1,120
    8000249a:	00001097          	auipc	ra,0x1
    8000249e:	a16080e7          	jalr	-1514(ra) # 80002eb0 <swtch>
    800024a2:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800024a4:	2781                	sext.w	a5,a5
    800024a6:	079e                	slli	a5,a5,0x7
    800024a8:	97ca                	add	a5,a5,s2
    800024aa:	1737a623          	sw	s3,364(a5)
}
    800024ae:	70a2                	ld	ra,40(sp)
    800024b0:	7402                	ld	s0,32(sp)
    800024b2:	64e2                	ld	s1,24(sp)
    800024b4:	6942                	ld	s2,16(sp)
    800024b6:	69a2                	ld	s3,8(sp)
    800024b8:	6145                	addi	sp,sp,48
    800024ba:	8082                	ret
    panic("sched p->lock");
    800024bc:	00006517          	auipc	a0,0x6
    800024c0:	db450513          	addi	a0,a0,-588 # 80008270 <digits+0x230>
    800024c4:	ffffe097          	auipc	ra,0xffffe
    800024c8:	07a080e7          	jalr	122(ra) # 8000053e <panic>
    panic("sched locks");
    800024cc:	00006517          	auipc	a0,0x6
    800024d0:	db450513          	addi	a0,a0,-588 # 80008280 <digits+0x240>
    800024d4:	ffffe097          	auipc	ra,0xffffe
    800024d8:	06a080e7          	jalr	106(ra) # 8000053e <panic>
    panic("sched running");
    800024dc:	00006517          	auipc	a0,0x6
    800024e0:	db450513          	addi	a0,a0,-588 # 80008290 <digits+0x250>
    800024e4:	ffffe097          	auipc	ra,0xffffe
    800024e8:	05a080e7          	jalr	90(ra) # 8000053e <panic>
    panic("sched interruptible");
    800024ec:	00006517          	auipc	a0,0x6
    800024f0:	db450513          	addi	a0,a0,-588 # 800082a0 <digits+0x260>
    800024f4:	ffffe097          	auipc	ra,0xffffe
    800024f8:	04a080e7          	jalr	74(ra) # 8000053e <panic>

00000000800024fc <yield>:
{
    800024fc:	1101                	addi	sp,sp,-32
    800024fe:	ec06                	sd	ra,24(sp)
    80002500:	e822                	sd	s0,16(sp)
    80002502:	e426                	sd	s1,8(sp)
    80002504:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002506:	00000097          	auipc	ra,0x0
    8000250a:	856080e7          	jalr	-1962(ra) # 80001d5c <myproc>
    8000250e:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002510:	ffffe097          	auipc	ra,0xffffe
    80002514:	6d4080e7          	jalr	1748(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    80002518:	478d                	li	a5,3
    8000251a:	d89c                	sw	a5,48(s1)
  add_link(&runnable_cpu_lists[p->affiliated_cpu], p->proc_index);
    8000251c:	1884a783          	lw	a5,392(s1)
    80002520:	0796                	slli	a5,a5,0x5
    80002522:	1844a583          	lw	a1,388(s1)
    80002526:	0000f517          	auipc	a0,0xf
    8000252a:	dda50513          	addi	a0,a0,-550 # 80011300 <runnable_cpu_lists>
    8000252e:	953e                	add	a0,a0,a5
    80002530:	fffff097          	auipc	ra,0xfffff
    80002534:	558080e7          	jalr	1368(ra) # 80001a88 <add_link>
  sched();
    80002538:	00000097          	auipc	ra,0x0
    8000253c:	eee080e7          	jalr	-274(ra) # 80002426 <sched>
  release(&p->lock);
    80002540:	8526                	mv	a0,s1
    80002542:	ffffe097          	auipc	ra,0xffffe
    80002546:	756080e7          	jalr	1878(ra) # 80000c98 <release>
}
    8000254a:	60e2                	ld	ra,24(sp)
    8000254c:	6442                	ld	s0,16(sp)
    8000254e:	64a2                	ld	s1,8(sp)
    80002550:	6105                	addi	sp,sp,32
    80002552:	8082                	ret

0000000080002554 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002554:	7179                	addi	sp,sp,-48
    80002556:	f406                	sd	ra,40(sp)
    80002558:	f022                	sd	s0,32(sp)
    8000255a:	ec26                	sd	s1,24(sp)
    8000255c:	e84a                	sd	s2,16(sp)
    8000255e:	e44e                	sd	s3,8(sp)
    80002560:	1800                	addi	s0,sp,48
    80002562:	89aa                	mv	s3,a0
    80002564:	892e                	mv	s2,a1

  
  struct proc *p = myproc();
    80002566:	fffff097          	auipc	ra,0xfffff
    8000256a:	7f6080e7          	jalr	2038(ra) # 80001d5c <myproc>
    8000256e:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002570:	ffffe097          	auipc	ra,0xffffe
    80002574:	674080e7          	jalr	1652(ra) # 80000be4 <acquire>
  //printf("start sleep for proc index %d\n", p->proc_index);
  release(lk);
    80002578:	854a                	mv	a0,s2
    8000257a:	ffffe097          	auipc	ra,0xffffe
    8000257e:	71e080e7          	jalr	1822(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    80002582:	0334bc23          	sd	s3,56(s1)
  p->state = SLEEPING;
    80002586:	4789                	li	a5,2
    80002588:	d89c                	sw	a5,48(s1)
  
  add_link(&sleeping_list, p->proc_index);
    8000258a:	1844a583          	lw	a1,388(s1)
    8000258e:	0000f517          	auipc	a0,0xf
    80002592:	d3250513          	addi	a0,a0,-718 # 800112c0 <sleeping_list>
    80002596:	fffff097          	auipc	ra,0xfffff
    8000259a:	4f2080e7          	jalr	1266(ra) # 80001a88 <add_link>
  //printf("after adding link to sleeping list\n");
  sched();
    8000259e:	00000097          	auipc	ra,0x0
    800025a2:	e88080e7          	jalr	-376(ra) # 80002426 <sched>

  // Tidy up.
  p->chan = 0;
    800025a6:	0204bc23          	sd	zero,56(s1)

  // Reacquire original lock.
  release(&p->lock);
    800025aa:	8526                	mv	a0,s1
    800025ac:	ffffe097          	auipc	ra,0xffffe
    800025b0:	6ec080e7          	jalr	1772(ra) # 80000c98 <release>
  
  acquire(lk);
    800025b4:	854a                	mv	a0,s2
    800025b6:	ffffe097          	auipc	ra,0xffffe
    800025ba:	62e080e7          	jalr	1582(ra) # 80000be4 <acquire>
  //printf("finish sleep procedure\n");
}
    800025be:	70a2                	ld	ra,40(sp)
    800025c0:	7402                	ld	s0,32(sp)
    800025c2:	64e2                	ld	s1,24(sp)
    800025c4:	6942                	ld	s2,16(sp)
    800025c6:	69a2                	ld	s3,8(sp)
    800025c8:	6145                	addi	sp,sp,48
    800025ca:	8082                	ret

00000000800025cc <wait>:
{
    800025cc:	715d                	addi	sp,sp,-80
    800025ce:	e486                	sd	ra,72(sp)
    800025d0:	e0a2                	sd	s0,64(sp)
    800025d2:	fc26                	sd	s1,56(sp)
    800025d4:	f84a                	sd	s2,48(sp)
    800025d6:	f44e                	sd	s3,40(sp)
    800025d8:	f052                	sd	s4,32(sp)
    800025da:	ec56                	sd	s5,24(sp)
    800025dc:	e85a                	sd	s6,16(sp)
    800025de:	e45e                	sd	s7,8(sp)
    800025e0:	e062                	sd	s8,0(sp)
    800025e2:	0880                	addi	s0,sp,80
    800025e4:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800025e6:	fffff097          	auipc	ra,0xfffff
    800025ea:	776080e7          	jalr	1910(ra) # 80001d5c <myproc>
    800025ee:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800025f0:	0000f517          	auipc	a0,0xf
    800025f4:	d8850513          	addi	a0,a0,-632 # 80011378 <wait_lock>
    800025f8:	ffffe097          	auipc	ra,0xffffe
    800025fc:	5ec080e7          	jalr	1516(ra) # 80000be4 <acquire>
    havekids = 0;
    80002600:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002602:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    80002604:	00015997          	auipc	s3,0x15
    80002608:	58c98993          	addi	s3,s3,1420 # 80017b90 <tickslock>
        havekids = 1;
    8000260c:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000260e:	0000fc17          	auipc	s8,0xf
    80002612:	d6ac0c13          	addi	s8,s8,-662 # 80011378 <wait_lock>
    havekids = 0;
    80002616:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002618:	0000f497          	auipc	s1,0xf
    8000261c:	17848493          	addi	s1,s1,376 # 80011790 <proc>
    80002620:	a0bd                	j	8000268e <wait+0xc2>
          pid = np->pid;
    80002622:	0484a983          	lw	s3,72(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002626:	000b0e63          	beqz	s6,80002642 <wait+0x76>
    8000262a:	4691                	li	a3,4
    8000262c:	04448613          	addi	a2,s1,68
    80002630:	85da                	mv	a1,s6
    80002632:	06893503          	ld	a0,104(s2)
    80002636:	fffff097          	auipc	ra,0xfffff
    8000263a:	03c080e7          	jalr	60(ra) # 80001672 <copyout>
    8000263e:	02054563          	bltz	a0,80002668 <wait+0x9c>
          freeproc(np);
    80002642:	8526                	mv	a0,s1
    80002644:	00000097          	auipc	ra,0x0
    80002648:	8bc080e7          	jalr	-1860(ra) # 80001f00 <freeproc>
          release(&np->lock);
    8000264c:	8526                	mv	a0,s1
    8000264e:	ffffe097          	auipc	ra,0xffffe
    80002652:	64a080e7          	jalr	1610(ra) # 80000c98 <release>
          release(&wait_lock);
    80002656:	0000f517          	auipc	a0,0xf
    8000265a:	d2250513          	addi	a0,a0,-734 # 80011378 <wait_lock>
    8000265e:	ffffe097          	auipc	ra,0xffffe
    80002662:	63a080e7          	jalr	1594(ra) # 80000c98 <release>
          return pid;
    80002666:	a09d                	j	800026cc <wait+0x100>
            release(&np->lock);
    80002668:	8526                	mv	a0,s1
    8000266a:	ffffe097          	auipc	ra,0xffffe
    8000266e:	62e080e7          	jalr	1582(ra) # 80000c98 <release>
            release(&wait_lock);
    80002672:	0000f517          	auipc	a0,0xf
    80002676:	d0650513          	addi	a0,a0,-762 # 80011378 <wait_lock>
    8000267a:	ffffe097          	auipc	ra,0xffffe
    8000267e:	61e080e7          	jalr	1566(ra) # 80000c98 <release>
            return -1;
    80002682:	59fd                	li	s3,-1
    80002684:	a0a1                	j	800026cc <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002686:	19048493          	addi	s1,s1,400
    8000268a:	03348463          	beq	s1,s3,800026b2 <wait+0xe6>
      if(np->parent == p){
    8000268e:	68bc                	ld	a5,80(s1)
    80002690:	ff279be3          	bne	a5,s2,80002686 <wait+0xba>
        acquire(&np->lock);
    80002694:	8526                	mv	a0,s1
    80002696:	ffffe097          	auipc	ra,0xffffe
    8000269a:	54e080e7          	jalr	1358(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    8000269e:	589c                	lw	a5,48(s1)
    800026a0:	f94781e3          	beq	a5,s4,80002622 <wait+0x56>
        release(&np->lock);
    800026a4:	8526                	mv	a0,s1
    800026a6:	ffffe097          	auipc	ra,0xffffe
    800026aa:	5f2080e7          	jalr	1522(ra) # 80000c98 <release>
        havekids = 1;
    800026ae:	8756                	mv	a4,s5
    800026b0:	bfd9                	j	80002686 <wait+0xba>
    if(!havekids || p->killed){
    800026b2:	c701                	beqz	a4,800026ba <wait+0xee>
    800026b4:	04092783          	lw	a5,64(s2)
    800026b8:	c79d                	beqz	a5,800026e6 <wait+0x11a>
      release(&wait_lock);
    800026ba:	0000f517          	auipc	a0,0xf
    800026be:	cbe50513          	addi	a0,a0,-834 # 80011378 <wait_lock>
    800026c2:	ffffe097          	auipc	ra,0xffffe
    800026c6:	5d6080e7          	jalr	1494(ra) # 80000c98 <release>
      return -1;
    800026ca:	59fd                	li	s3,-1
}
    800026cc:	854e                	mv	a0,s3
    800026ce:	60a6                	ld	ra,72(sp)
    800026d0:	6406                	ld	s0,64(sp)
    800026d2:	74e2                	ld	s1,56(sp)
    800026d4:	7942                	ld	s2,48(sp)
    800026d6:	79a2                	ld	s3,40(sp)
    800026d8:	7a02                	ld	s4,32(sp)
    800026da:	6ae2                	ld	s5,24(sp)
    800026dc:	6b42                	ld	s6,16(sp)
    800026de:	6ba2                	ld	s7,8(sp)
    800026e0:	6c02                	ld	s8,0(sp)
    800026e2:	6161                	addi	sp,sp,80
    800026e4:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800026e6:	85e2                	mv	a1,s8
    800026e8:	854a                	mv	a0,s2
    800026ea:	00000097          	auipc	ra,0x0
    800026ee:	e6a080e7          	jalr	-406(ra) # 80002554 <sleep>
    havekids = 0;
    800026f2:	b715                	j	80002616 <wait+0x4a>

00000000800026f4 <wakeup>:

}

void
wakeup(void *chan)
{
    800026f4:	711d                	addi	sp,sp,-96
    800026f6:	ec86                	sd	ra,88(sp)
    800026f8:	e8a2                	sd	s0,80(sp)
    800026fa:	e4a6                	sd	s1,72(sp)
    800026fc:	e0ca                	sd	s2,64(sp)
    800026fe:	fc4e                	sd	s3,56(sp)
    80002700:	f852                	sd	s4,48(sp)
    80002702:	f456                	sd	s5,40(sp)
    80002704:	f05a                	sd	s6,32(sp)
    80002706:	ec5e                	sd	s7,24(sp)
    80002708:	e862                	sd	s8,16(sp)
    8000270a:	e466                	sd	s9,8(sp)
    8000270c:	e06a                	sd	s10,0(sp)
    8000270e:	1080                	addi	s0,sp,96
    80002710:	8baa                	mv	s7,a0
  
  while(1) // Keep looping until no process is waken up
  {
    
    //Loop until finds process that needs to be waken up
    acquire(&sleeping_list.head_lock);
    80002712:	0000fd17          	auipc	s10,0xf
    80002716:	b8ed0d13          	addi	s10,s10,-1138 # 800112a0 <unused_list>
    8000271a:	0000fc97          	auipc	s9,0xf
    8000271e:	baec8c93          	addi	s9,s9,-1106 # 800112c8 <sleeping_list+0x8>
    if (sleeping_list.head == -1) //empty list
    80002722:	5c7d                	li	s8,-1
    80002724:	19000a93          	li	s5,400
      
      release(&sleeping_list.head_lock);
      return;
    }
    //non-empty:
    curr = &proc[sleeping_list.head];
    80002728:	0000fa17          	auipc	s4,0xf
    8000272c:	068a0a13          	addi	s4,s4,104 # 80011790 <proc>
    acquire(&sleeping_list.head_lock);
    80002730:	8566                	mv	a0,s9
    80002732:	ffffe097          	auipc	ra,0xffffe
    80002736:	4b2080e7          	jalr	1202(ra) # 80000be4 <acquire>
    if (sleeping_list.head == -1) //empty list
    8000273a:	020d2483          	lw	s1,32(s10)
    8000273e:	0d848463          	beq	s1,s8,80002806 <wakeup+0x112>
    curr = &proc[sleeping_list.head];
    80002742:	03548533          	mul	a0,s1,s5
    80002746:	014509b3          	add	s3,a0,s4
    {
      release(&sleeping_list.head_lock); 
      return;
    }

    acquire(&curr->list_lock);
    8000274a:	0561                	addi	a0,a0,24
    8000274c:	01450933          	add	s2,a0,s4
    80002750:	854a                	mv	a0,s2
    80002752:	ffffe097          	auipc	ra,0xffffe
    80002756:	492080e7          	jalr	1170(ra) # 80000be4 <acquire>
    release(&sleeping_list.head_lock);
    8000275a:	8566                	mv	a0,s9
    8000275c:	ffffe097          	auipc	ra,0xffffe
    80002760:	53c080e7          	jalr	1340(ra) # 80000c98 <release>
    acquire(&curr->lock);
    80002764:	854e                	mv	a0,s3
    80002766:	ffffe097          	auipc	ra,0xffffe
    8000276a:	47e080e7          	jalr	1150(ra) # 80000be4 <acquire>
    
    if(curr->chan == chan) //needs to wake up
    8000276e:	0389b783          	ld	a5,56(s3)
    80002772:	0b778363          	beq	a5,s7,80002818 <wakeup+0x124>
      remove_link(&sleeping_list, curr->proc_index);
      add_link(cpuList, curr->proc_index);
      release(&curr->lock);
      continue; //another iteration on list
    }
    release(&curr->lock);
    80002776:	854e                	mv	a0,s3
    80002778:	ffffe097          	auipc	ra,0xffffe
    8000277c:	520080e7          	jalr	1312(ra) # 80000c98 <release>
    int finished = 1;
    while(curr->next_proc_index!= -1) //loop to find process that needs to be waken up
    80002780:	035484b3          	mul	s1,s1,s5
    80002784:	94d2                	add	s1,s1,s4
    80002786:	1804a483          	lw	s1,384(s1)
    8000278a:	05848a63          	beq	s1,s8,800027de <wakeup+0xea>
    {
      next = &proc[curr->next_proc_index];
    8000278e:	035487b3          	mul	a5,s1,s5
    80002792:	8b4e                	mv	s6,s3
    80002794:	014789b3          	add	s3,a5,s4
      acquire(&next->list_lock);
    80002798:	07e1                	addi	a5,a5,24
    8000279a:	01478933          	add	s2,a5,s4
    8000279e:	854a                	mv	a0,s2
    800027a0:	ffffe097          	auipc	ra,0xffffe
    800027a4:	444080e7          	jalr	1092(ra) # 80000be4 <acquire>
      release(&curr->list_lock);
    800027a8:	018b0513          	addi	a0,s6,24
    800027ac:	ffffe097          	auipc	ra,0xffffe
    800027b0:	4ec080e7          	jalr	1260(ra) # 80000c98 <release>
      curr = next;

      acquire(&curr->lock);
    800027b4:	854e                	mv	a0,s3
    800027b6:	ffffe097          	auipc	ra,0xffffe
    800027ba:	42e080e7          	jalr	1070(ra) # 80000be4 <acquire>
      if(curr->chan == chan) //needs to wake up
    800027be:	0389b783          	ld	a5,56(s3)
    800027c2:	0b778363          	beq	a5,s7,80002868 <wakeup+0x174>
        add_link(cpuList, curr->proc_index);
        release(&curr->lock);
        finished = 0;
        break; //another iteration on list
      }
      release(&curr->lock);
    800027c6:	854e                	mv	a0,s3
    800027c8:	ffffe097          	auipc	ra,0xffffe
    800027cc:	4d0080e7          	jalr	1232(ra) # 80000c98 <release>
    while(curr->next_proc_index!= -1) //loop to find process that needs to be waken up
    800027d0:	035484b3          	mul	s1,s1,s5
    800027d4:	94d2                	add	s1,s1,s4
    800027d6:	1804a483          	lw	s1,384(s1)
    800027da:	fb849ae3          	bne	s1,s8,8000278e <wakeup+0x9a>
    }
    if(finished == 1) //full iteration with no wakeup
    {
      //printf("exiting wakeup\n");
      release(&curr->list_lock);
    800027de:	01898513          	addi	a0,s3,24
    800027e2:	ffffe097          	auipc	ra,0xffffe
    800027e6:	4b6080e7          	jalr	1206(ra) # 80000c98 <release>
      return;
    }
  }
}
    800027ea:	60e6                	ld	ra,88(sp)
    800027ec:	6446                	ld	s0,80(sp)
    800027ee:	64a6                	ld	s1,72(sp)
    800027f0:	6906                	ld	s2,64(sp)
    800027f2:	79e2                	ld	s3,56(sp)
    800027f4:	7a42                	ld	s4,48(sp)
    800027f6:	7aa2                	ld	s5,40(sp)
    800027f8:	7b02                	ld	s6,32(sp)
    800027fa:	6be2                	ld	s7,24(sp)
    800027fc:	6c42                	ld	s8,16(sp)
    800027fe:	6ca2                	ld	s9,8(sp)
    80002800:	6d02                	ld	s10,0(sp)
    80002802:	6125                	addi	sp,sp,96
    80002804:	8082                	ret
      release(&sleeping_list.head_lock);
    80002806:	0000f517          	auipc	a0,0xf
    8000280a:	ac250513          	addi	a0,a0,-1342 # 800112c8 <sleeping_list+0x8>
    8000280e:	ffffe097          	auipc	ra,0xffffe
    80002812:	48a080e7          	jalr	1162(ra) # 80000c98 <release>
      return;
    80002816:	bfd1                	j	800027ea <wakeup+0xf6>
      curr->state = RUNNABLE;
    80002818:	478d                	li	a5,3
    8000281a:	02f9a823          	sw	a5,48(s3)
      struct processList* cpuList = &runnable_cpu_lists[curr->affiliated_cpu];
    8000281e:	1889ab03          	lw	s6,392(s3)
    80002822:	005b1793          	slli	a5,s6,0x5
    80002826:	0000fb17          	auipc	s6,0xf
    8000282a:	adab0b13          	addi	s6,s6,-1318 # 80011300 <runnable_cpu_lists>
    8000282e:	9b3e                	add	s6,s6,a5
      release(&curr->list_lock);
    80002830:	854a                	mv	a0,s2
    80002832:	ffffe097          	auipc	ra,0xffffe
    80002836:	466080e7          	jalr	1126(ra) # 80000c98 <release>
      remove_link(&sleeping_list, curr->proc_index);
    8000283a:	1849a583          	lw	a1,388(s3)
    8000283e:	0000f517          	auipc	a0,0xf
    80002842:	a8250513          	addi	a0,a0,-1406 # 800112c0 <sleeping_list>
    80002846:	fffff097          	auipc	ra,0xfffff
    8000284a:	052080e7          	jalr	82(ra) # 80001898 <remove_link>
      add_link(cpuList, curr->proc_index);
    8000284e:	1849a583          	lw	a1,388(s3)
    80002852:	855a                	mv	a0,s6
    80002854:	fffff097          	auipc	ra,0xfffff
    80002858:	234080e7          	jalr	564(ra) # 80001a88 <add_link>
      release(&curr->lock);
    8000285c:	854e                	mv	a0,s3
    8000285e:	ffffe097          	auipc	ra,0xffffe
    80002862:	43a080e7          	jalr	1082(ra) # 80000c98 <release>
      continue; //another iteration on list
    80002866:	b5e9                	j	80002730 <wakeup+0x3c>
        curr->state = RUNNABLE;
    80002868:	478d                	li	a5,3
    8000286a:	02f9a823          	sw	a5,48(s3)
        struct processList* cpuList = &runnable_cpu_lists[curr->affiliated_cpu];
    8000286e:	1889ab03          	lw	s6,392(s3)
    80002872:	005b1793          	slli	a5,s6,0x5
    80002876:	0000fb17          	auipc	s6,0xf
    8000287a:	a8ab0b13          	addi	s6,s6,-1398 # 80011300 <runnable_cpu_lists>
    8000287e:	9b3e                	add	s6,s6,a5
        release(&curr->list_lock);
    80002880:	854a                	mv	a0,s2
    80002882:	ffffe097          	auipc	ra,0xffffe
    80002886:	416080e7          	jalr	1046(ra) # 80000c98 <release>
        remove_link(&sleeping_list, curr->proc_index);
    8000288a:	1849a583          	lw	a1,388(s3)
    8000288e:	0000f517          	auipc	a0,0xf
    80002892:	a3250513          	addi	a0,a0,-1486 # 800112c0 <sleeping_list>
    80002896:	fffff097          	auipc	ra,0xfffff
    8000289a:	002080e7          	jalr	2(ra) # 80001898 <remove_link>
        add_link(cpuList, curr->proc_index);
    8000289e:	1849a583          	lw	a1,388(s3)
    800028a2:	855a                	mv	a0,s6
    800028a4:	fffff097          	auipc	ra,0xfffff
    800028a8:	1e4080e7          	jalr	484(ra) # 80001a88 <add_link>
        release(&curr->lock);
    800028ac:	854e                	mv	a0,s3
    800028ae:	ffffe097          	auipc	ra,0xffffe
    800028b2:	3ea080e7          	jalr	1002(ra) # 80000c98 <release>
    if(finished == 1) //full iteration with no wakeup
    800028b6:	bdad                	j	80002730 <wakeup+0x3c>

00000000800028b8 <reparent>:
{
    800028b8:	7139                	addi	sp,sp,-64
    800028ba:	fc06                	sd	ra,56(sp)
    800028bc:	f822                	sd	s0,48(sp)
    800028be:	f426                	sd	s1,40(sp)
    800028c0:	f04a                	sd	s2,32(sp)
    800028c2:	ec4e                	sd	s3,24(sp)
    800028c4:	e852                	sd	s4,16(sp)
    800028c6:	e456                	sd	s5,8(sp)
    800028c8:	0080                	addi	s0,sp,64
    800028ca:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800028cc:	0000f497          	auipc	s1,0xf
    800028d0:	ec448493          	addi	s1,s1,-316 # 80011790 <proc>
      pp->parent = initproc;
    800028d4:	00006a17          	auipc	s4,0x6
    800028d8:	754a0a13          	addi	s4,s4,1876 # 80009028 <initproc>
      printf("reparent\n");
    800028dc:	00006a97          	auipc	s5,0x6
    800028e0:	9dca8a93          	addi	s5,s5,-1572 # 800082b8 <digits+0x278>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800028e4:	00015997          	auipc	s3,0x15
    800028e8:	2ac98993          	addi	s3,s3,684 # 80017b90 <tickslock>
    800028ec:	a029                	j	800028f6 <reparent+0x3e>
    800028ee:	19048493          	addi	s1,s1,400
    800028f2:	03348463          	beq	s1,s3,8000291a <reparent+0x62>
    if(pp->parent == p){
    800028f6:	68bc                	ld	a5,80(s1)
    800028f8:	ff279be3          	bne	a5,s2,800028ee <reparent+0x36>
      pp->parent = initproc;
    800028fc:	000a3783          	ld	a5,0(s4)
    80002900:	e8bc                	sd	a5,80(s1)
      printf("reparent\n");
    80002902:	8556                	mv	a0,s5
    80002904:	ffffe097          	auipc	ra,0xffffe
    80002908:	c84080e7          	jalr	-892(ra) # 80000588 <printf>
      wakeup(initproc);
    8000290c:	000a3503          	ld	a0,0(s4)
    80002910:	00000097          	auipc	ra,0x0
    80002914:	de4080e7          	jalr	-540(ra) # 800026f4 <wakeup>
    80002918:	bfd9                	j	800028ee <reparent+0x36>
}
    8000291a:	70e2                	ld	ra,56(sp)
    8000291c:	7442                	ld	s0,48(sp)
    8000291e:	74a2                	ld	s1,40(sp)
    80002920:	7902                	ld	s2,32(sp)
    80002922:	69e2                	ld	s3,24(sp)
    80002924:	6a42                	ld	s4,16(sp)
    80002926:	6aa2                	ld	s5,8(sp)
    80002928:	6121                	addi	sp,sp,64
    8000292a:	8082                	ret

000000008000292c <exit>:
{
    8000292c:	7179                	addi	sp,sp,-48
    8000292e:	f406                	sd	ra,40(sp)
    80002930:	f022                	sd	s0,32(sp)
    80002932:	ec26                	sd	s1,24(sp)
    80002934:	e84a                	sd	s2,16(sp)
    80002936:	e44e                	sd	s3,8(sp)
    80002938:	e052                	sd	s4,0(sp)
    8000293a:	1800                	addi	s0,sp,48
    8000293c:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000293e:	fffff097          	auipc	ra,0xfffff
    80002942:	41e080e7          	jalr	1054(ra) # 80001d5c <myproc>
    80002946:	89aa                	mv	s3,a0
  if(p == initproc)
    80002948:	00006797          	auipc	a5,0x6
    8000294c:	6e07b783          	ld	a5,1760(a5) # 80009028 <initproc>
    80002950:	0e850493          	addi	s1,a0,232
    80002954:	16850913          	addi	s2,a0,360
    80002958:	02a79363          	bne	a5,a0,8000297e <exit+0x52>
    panic("init exiting");
    8000295c:	00006517          	auipc	a0,0x6
    80002960:	96c50513          	addi	a0,a0,-1684 # 800082c8 <digits+0x288>
    80002964:	ffffe097          	auipc	ra,0xffffe
    80002968:	bda080e7          	jalr	-1062(ra) # 8000053e <panic>
      fileclose(f);
    8000296c:	00002097          	auipc	ra,0x2
    80002970:	490080e7          	jalr	1168(ra) # 80004dfc <fileclose>
      p->ofile[fd] = 0;
    80002974:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002978:	04a1                	addi	s1,s1,8
    8000297a:	01248563          	beq	s1,s2,80002984 <exit+0x58>
    if(p->ofile[fd]){
    8000297e:	6088                	ld	a0,0(s1)
    80002980:	f575                	bnez	a0,8000296c <exit+0x40>
    80002982:	bfdd                	j	80002978 <exit+0x4c>
  begin_op();
    80002984:	00002097          	auipc	ra,0x2
    80002988:	fac080e7          	jalr	-84(ra) # 80004930 <begin_op>
  iput(p->cwd);
    8000298c:	1689b503          	ld	a0,360(s3)
    80002990:	00001097          	auipc	ra,0x1
    80002994:	788080e7          	jalr	1928(ra) # 80004118 <iput>
  end_op();
    80002998:	00002097          	auipc	ra,0x2
    8000299c:	018080e7          	jalr	24(ra) # 800049b0 <end_op>
  p->cwd = 0;
    800029a0:	1609b423          	sd	zero,360(s3)
  acquire(&wait_lock);
    800029a4:	0000f497          	auipc	s1,0xf
    800029a8:	9d448493          	addi	s1,s1,-1580 # 80011378 <wait_lock>
    800029ac:	8526                	mv	a0,s1
    800029ae:	ffffe097          	auipc	ra,0xffffe
    800029b2:	236080e7          	jalr	566(ra) # 80000be4 <acquire>
  reparent(p);
    800029b6:	854e                	mv	a0,s3
    800029b8:	00000097          	auipc	ra,0x0
    800029bc:	f00080e7          	jalr	-256(ra) # 800028b8 <reparent>
  wakeup(p->parent);
    800029c0:	0509b503          	ld	a0,80(s3)
    800029c4:	00000097          	auipc	ra,0x0
    800029c8:	d30080e7          	jalr	-720(ra) # 800026f4 <wakeup>
  acquire(&p->lock);
    800029cc:	854e                	mv	a0,s3
    800029ce:	ffffe097          	auipc	ra,0xffffe
    800029d2:	216080e7          	jalr	534(ra) # 80000be4 <acquire>
  p->xstate = status;
    800029d6:	0549a223          	sw	s4,68(s3)
  p->state = ZOMBIE;
    800029da:	4795                	li	a5,5
    800029dc:	02f9a823          	sw	a5,48(s3)
  add_link(&zombie_list, p->proc_index);
    800029e0:	1849a583          	lw	a1,388(s3)
    800029e4:	0000f517          	auipc	a0,0xf
    800029e8:	8fc50513          	addi	a0,a0,-1796 # 800112e0 <zombie_list>
    800029ec:	fffff097          	auipc	ra,0xfffff
    800029f0:	09c080e7          	jalr	156(ra) # 80001a88 <add_link>
  release(&wait_lock);
    800029f4:	8526                	mv	a0,s1
    800029f6:	ffffe097          	auipc	ra,0xffffe
    800029fa:	2a2080e7          	jalr	674(ra) # 80000c98 <release>
  sched();
    800029fe:	00000097          	auipc	ra,0x0
    80002a02:	a28080e7          	jalr	-1496(ra) # 80002426 <sched>
  panic("zombie exit");
    80002a06:	00006517          	auipc	a0,0x6
    80002a0a:	8d250513          	addi	a0,a0,-1838 # 800082d8 <digits+0x298>
    80002a0e:	ffffe097          	auipc	ra,0xffffe
    80002a12:	b30080e7          	jalr	-1232(ra) # 8000053e <panic>

0000000080002a16 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002a16:	7179                	addi	sp,sp,-48
    80002a18:	f406                	sd	ra,40(sp)
    80002a1a:	f022                	sd	s0,32(sp)
    80002a1c:	ec26                	sd	s1,24(sp)
    80002a1e:	e84a                	sd	s2,16(sp)
    80002a20:	e44e                	sd	s3,8(sp)
    80002a22:	1800                	addi	s0,sp,48
    80002a24:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002a26:	0000f497          	auipc	s1,0xf
    80002a2a:	d6a48493          	addi	s1,s1,-662 # 80011790 <proc>
    80002a2e:	00015997          	auipc	s3,0x15
    80002a32:	16298993          	addi	s3,s3,354 # 80017b90 <tickslock>
    acquire(&p->lock);
    80002a36:	8526                	mv	a0,s1
    80002a38:	ffffe097          	auipc	ra,0xffffe
    80002a3c:	1ac080e7          	jalr	428(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    80002a40:	44bc                	lw	a5,72(s1)
    80002a42:	01278d63          	beq	a5,s2,80002a5c <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002a46:	8526                	mv	a0,s1
    80002a48:	ffffe097          	auipc	ra,0xffffe
    80002a4c:	250080e7          	jalr	592(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002a50:	19048493          	addi	s1,s1,400
    80002a54:	ff3491e3          	bne	s1,s3,80002a36 <kill+0x20>
  }
  return -1;
    80002a58:	557d                	li	a0,-1
    80002a5a:	a829                	j	80002a74 <kill+0x5e>
      p->killed = 1;
    80002a5c:	4785                	li	a5,1
    80002a5e:	c0bc                	sw	a5,64(s1)
      if(p->state == SLEEPING){
    80002a60:	5898                	lw	a4,48(s1)
    80002a62:	4789                	li	a5,2
    80002a64:	00f70f63          	beq	a4,a5,80002a82 <kill+0x6c>
      release(&p->lock);
    80002a68:	8526                	mv	a0,s1
    80002a6a:	ffffe097          	auipc	ra,0xffffe
    80002a6e:	22e080e7          	jalr	558(ra) # 80000c98 <release>
      return 0;
    80002a72:	4501                	li	a0,0
}
    80002a74:	70a2                	ld	ra,40(sp)
    80002a76:	7402                	ld	s0,32(sp)
    80002a78:	64e2                	ld	s1,24(sp)
    80002a7a:	6942                	ld	s2,16(sp)
    80002a7c:	69a2                	ld	s3,8(sp)
    80002a7e:	6145                	addi	sp,sp,48
    80002a80:	8082                	ret
        p->state = RUNNABLE;
    80002a82:	478d                	li	a5,3
    80002a84:	d89c                	sw	a5,48(s1)
    80002a86:	b7cd                	j	80002a68 <kill+0x52>

0000000080002a88 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002a88:	7179                	addi	sp,sp,-48
    80002a8a:	f406                	sd	ra,40(sp)
    80002a8c:	f022                	sd	s0,32(sp)
    80002a8e:	ec26                	sd	s1,24(sp)
    80002a90:	e84a                	sd	s2,16(sp)
    80002a92:	e44e                	sd	s3,8(sp)
    80002a94:	e052                	sd	s4,0(sp)
    80002a96:	1800                	addi	s0,sp,48
    80002a98:	84aa                	mv	s1,a0
    80002a9a:	892e                	mv	s2,a1
    80002a9c:	89b2                	mv	s3,a2
    80002a9e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002aa0:	fffff097          	auipc	ra,0xfffff
    80002aa4:	2bc080e7          	jalr	700(ra) # 80001d5c <myproc>
  if(user_dst){
    80002aa8:	c08d                	beqz	s1,80002aca <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002aaa:	86d2                	mv	a3,s4
    80002aac:	864e                	mv	a2,s3
    80002aae:	85ca                	mv	a1,s2
    80002ab0:	7528                	ld	a0,104(a0)
    80002ab2:	fffff097          	auipc	ra,0xfffff
    80002ab6:	bc0080e7          	jalr	-1088(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002aba:	70a2                	ld	ra,40(sp)
    80002abc:	7402                	ld	s0,32(sp)
    80002abe:	64e2                	ld	s1,24(sp)
    80002ac0:	6942                	ld	s2,16(sp)
    80002ac2:	69a2                	ld	s3,8(sp)
    80002ac4:	6a02                	ld	s4,0(sp)
    80002ac6:	6145                	addi	sp,sp,48
    80002ac8:	8082                	ret
    memmove((char *)dst, src, len);
    80002aca:	000a061b          	sext.w	a2,s4
    80002ace:	85ce                	mv	a1,s3
    80002ad0:	854a                	mv	a0,s2
    80002ad2:	ffffe097          	auipc	ra,0xffffe
    80002ad6:	26e080e7          	jalr	622(ra) # 80000d40 <memmove>
    return 0;
    80002ada:	8526                	mv	a0,s1
    80002adc:	bff9                	j	80002aba <either_copyout+0x32>

0000000080002ade <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002ade:	7179                	addi	sp,sp,-48
    80002ae0:	f406                	sd	ra,40(sp)
    80002ae2:	f022                	sd	s0,32(sp)
    80002ae4:	ec26                	sd	s1,24(sp)
    80002ae6:	e84a                	sd	s2,16(sp)
    80002ae8:	e44e                	sd	s3,8(sp)
    80002aea:	e052                	sd	s4,0(sp)
    80002aec:	1800                	addi	s0,sp,48
    80002aee:	892a                	mv	s2,a0
    80002af0:	84ae                	mv	s1,a1
    80002af2:	89b2                	mv	s3,a2
    80002af4:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002af6:	fffff097          	auipc	ra,0xfffff
    80002afa:	266080e7          	jalr	614(ra) # 80001d5c <myproc>
  if(user_src){
    80002afe:	c08d                	beqz	s1,80002b20 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002b00:	86d2                	mv	a3,s4
    80002b02:	864e                	mv	a2,s3
    80002b04:	85ca                	mv	a1,s2
    80002b06:	7528                	ld	a0,104(a0)
    80002b08:	fffff097          	auipc	ra,0xfffff
    80002b0c:	bf6080e7          	jalr	-1034(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002b10:	70a2                	ld	ra,40(sp)
    80002b12:	7402                	ld	s0,32(sp)
    80002b14:	64e2                	ld	s1,24(sp)
    80002b16:	6942                	ld	s2,16(sp)
    80002b18:	69a2                	ld	s3,8(sp)
    80002b1a:	6a02                	ld	s4,0(sp)
    80002b1c:	6145                	addi	sp,sp,48
    80002b1e:	8082                	ret
    memmove(dst, (char*)src, len);
    80002b20:	000a061b          	sext.w	a2,s4
    80002b24:	85ce                	mv	a1,s3
    80002b26:	854a                	mv	a0,s2
    80002b28:	ffffe097          	auipc	ra,0xffffe
    80002b2c:	218080e7          	jalr	536(ra) # 80000d40 <memmove>
    return 0;
    80002b30:	8526                	mv	a0,s1
    80002b32:	bff9                	j	80002b10 <either_copyin+0x32>

0000000080002b34 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002b34:	715d                	addi	sp,sp,-80
    80002b36:	e486                	sd	ra,72(sp)
    80002b38:	e0a2                	sd	s0,64(sp)
    80002b3a:	fc26                	sd	s1,56(sp)
    80002b3c:	f84a                	sd	s2,48(sp)
    80002b3e:	f44e                	sd	s3,40(sp)
    80002b40:	f052                	sd	s4,32(sp)
    80002b42:	ec56                	sd	s5,24(sp)
    80002b44:	e85a                	sd	s6,16(sp)
    80002b46:	e45e                	sd	s7,8(sp)
    80002b48:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002b4a:	00005517          	auipc	a0,0x5
    80002b4e:	7e650513          	addi	a0,a0,2022 # 80008330 <digits+0x2f0>
    80002b52:	ffffe097          	auipc	ra,0xffffe
    80002b56:	a36080e7          	jalr	-1482(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002b5a:	0000f497          	auipc	s1,0xf
    80002b5e:	da648493          	addi	s1,s1,-602 # 80011900 <proc+0x170>
    80002b62:	00015917          	auipc	s2,0x15
    80002b66:	19e90913          	addi	s2,s2,414 # 80017d00 <bcache+0x158>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002b6a:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002b6c:	00005997          	auipc	s3,0x5
    80002b70:	77c98993          	addi	s3,s3,1916 # 800082e8 <digits+0x2a8>
    printf("%d %s %s", p->pid, state, p->name);
    80002b74:	00005a97          	auipc	s5,0x5
    80002b78:	77ca8a93          	addi	s5,s5,1916 # 800082f0 <digits+0x2b0>
    printf("\n");
    80002b7c:	00005a17          	auipc	s4,0x5
    80002b80:	7b4a0a13          	addi	s4,s4,1972 # 80008330 <digits+0x2f0>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002b84:	00005b97          	auipc	s7,0x5
    80002b88:	7fcb8b93          	addi	s7,s7,2044 # 80008380 <states.1768>
    80002b8c:	a00d                	j	80002bae <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002b8e:	ed86a583          	lw	a1,-296(a3)
    80002b92:	8556                	mv	a0,s5
    80002b94:	ffffe097          	auipc	ra,0xffffe
    80002b98:	9f4080e7          	jalr	-1548(ra) # 80000588 <printf>
    printf("\n");
    80002b9c:	8552                	mv	a0,s4
    80002b9e:	ffffe097          	auipc	ra,0xffffe
    80002ba2:	9ea080e7          	jalr	-1558(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002ba6:	19048493          	addi	s1,s1,400
    80002baa:	03248163          	beq	s1,s2,80002bcc <procdump+0x98>
    if(p->state == UNUSED)
    80002bae:	86a6                	mv	a3,s1
    80002bb0:	ec04a783          	lw	a5,-320(s1)
    80002bb4:	dbed                	beqz	a5,80002ba6 <procdump+0x72>
      state = "???";
    80002bb6:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002bb8:	fcfb6be3          	bltu	s6,a5,80002b8e <procdump+0x5a>
    80002bbc:	1782                	slli	a5,a5,0x20
    80002bbe:	9381                	srli	a5,a5,0x20
    80002bc0:	078e                	slli	a5,a5,0x3
    80002bc2:	97de                	add	a5,a5,s7
    80002bc4:	6390                	ld	a2,0(a5)
    80002bc6:	f661                	bnez	a2,80002b8e <procdump+0x5a>
      state = "???";
    80002bc8:	864e                	mv	a2,s3
    80002bca:	b7d1                	j	80002b8e <procdump+0x5a>
  }
}
    80002bcc:	60a6                	ld	ra,72(sp)
    80002bce:	6406                	ld	s0,64(sp)
    80002bd0:	74e2                	ld	s1,56(sp)
    80002bd2:	7942                	ld	s2,48(sp)
    80002bd4:	79a2                	ld	s3,40(sp)
    80002bd6:	7a02                	ld	s4,32(sp)
    80002bd8:	6ae2                	ld	s5,24(sp)
    80002bda:	6b42                	ld	s6,16(sp)
    80002bdc:	6ba2                	ld	s7,8(sp)
    80002bde:	6161                	addi	sp,sp,80
    80002be0:	8082                	ret

0000000080002be2 <wakeup2>:
{
    80002be2:	7159                	addi	sp,sp,-112
    80002be4:	f486                	sd	ra,104(sp)
    80002be6:	f0a2                	sd	s0,96(sp)
    80002be8:	eca6                	sd	s1,88(sp)
    80002bea:	e8ca                	sd	s2,80(sp)
    80002bec:	e4ce                	sd	s3,72(sp)
    80002bee:	e0d2                	sd	s4,64(sp)
    80002bf0:	fc56                	sd	s5,56(sp)
    80002bf2:	f85a                	sd	s6,48(sp)
    80002bf4:	f45e                	sd	s7,40(sp)
    80002bf6:	f062                	sd	s8,32(sp)
    80002bf8:	ec66                	sd	s9,24(sp)
    80002bfa:	e86a                	sd	s10,16(sp)
    80002bfc:	e46e                	sd	s11,8(sp)
    80002bfe:	1880                	addi	s0,sp,112
    80002c00:	8b2a                	mv	s6,a0
  acquire(&sleeping_list.head_lock);
    80002c02:	0000e517          	auipc	a0,0xe
    80002c06:	6c650513          	addi	a0,a0,1734 # 800112c8 <sleeping_list+0x8>
    80002c0a:	ffffe097          	auipc	ra,0xffffe
    80002c0e:	fda080e7          	jalr	-38(ra) # 80000be4 <acquire>
  if (sleeping_list.head == -1){
    80002c12:	0000e797          	auipc	a5,0xe
    80002c16:	6ae7a783          	lw	a5,1710(a5) # 800112c0 <sleeping_list>
    80002c1a:	577d                	li	a4,-1
    80002c1c:	0ae78c63          	beq	a5,a4,80002cd4 <wakeup2+0xf2>
  acquire(&proc[sleeping_list.head].list_lock);
    80002c20:	19000913          	li	s2,400
    80002c24:	032787b3          	mul	a5,a5,s2
    80002c28:	01878513          	addi	a0,a5,24
    80002c2c:	0000f997          	auipc	s3,0xf
    80002c30:	b6498993          	addi	s3,s3,-1180 # 80011790 <proc>
    80002c34:	954e                	add	a0,a0,s3
    80002c36:	ffffe097          	auipc	ra,0xffffe
    80002c3a:	fae080e7          	jalr	-82(ra) # 80000be4 <acquire>
  p = &proc[sleeping_list.head];
    80002c3e:	0000e497          	auipc	s1,0xe
    80002c42:	6824a483          	lw	s1,1666(s1) # 800112c0 <sleeping_list>
    80002c46:	03248933          	mul	s2,s1,s2
    80002c4a:	994e                	add	s2,s2,s3
  acquire(&p->lock);
    80002c4c:	854a                	mv	a0,s2
    80002c4e:	ffffe097          	auipc	ra,0xffffe
    80002c52:	f96080e7          	jalr	-106(ra) # 80000be4 <acquire>
  if(p!=myproc()&&p->chan == chan) {
    80002c56:	fffff097          	auipc	ra,0xfffff
    80002c5a:	106080e7          	jalr	262(ra) # 80001d5c <myproc>
    80002c5e:	00a90663          	beq	s2,a0,80002c6a <wakeup2+0x88>
    80002c62:	03893783          	ld	a5,56(s2)
    80002c66:	09678c63          	beq	a5,s6,80002cfe <wakeup2+0x11c>
        release(&sleeping_list.head_lock);
    80002c6a:	0000e517          	auipc	a0,0xe
    80002c6e:	65e50513          	addi	a0,a0,1630 # 800112c8 <sleeping_list+0x8>
    80002c72:	ffffe097          	auipc	ra,0xffffe
    80002c76:	026080e7          	jalr	38(ra) # 80000c98 <release>
        release(&proc[sleeping_list.head].list_lock);
    80002c7a:	0000e797          	auipc	a5,0xe
    80002c7e:	6467a783          	lw	a5,1606(a5) # 800112c0 <sleeping_list>
    80002c82:	19000513          	li	a0,400
    80002c86:	02a787b3          	mul	a5,a5,a0
    80002c8a:	0000f517          	auipc	a0,0xf
    80002c8e:	b1e50513          	addi	a0,a0,-1250 # 800117a8 <proc+0x18>
    80002c92:	953e                	add	a0,a0,a5
    80002c94:	ffffe097          	auipc	ra,0xffffe
    80002c98:	004080e7          	jalr	4(ra) # 80000c98 <release>
  release(&p->lock);
    80002c9c:	854a                	mv	a0,s2
    80002c9e:	ffffe097          	auipc	ra,0xffffe
    80002ca2:	ffa080e7          	jalr	-6(ra) # 80000c98 <release>
  printf("exiting wakeup\n");
    80002ca6:	00005517          	auipc	a0,0x5
    80002caa:	69250513          	addi	a0,a0,1682 # 80008338 <digits+0x2f8>
    80002cae:	ffffe097          	auipc	ra,0xffffe
    80002cb2:	8da080e7          	jalr	-1830(ra) # 80000588 <printf>
}
    80002cb6:	70a6                	ld	ra,104(sp)
    80002cb8:	7406                	ld	s0,96(sp)
    80002cba:	64e6                	ld	s1,88(sp)
    80002cbc:	6946                	ld	s2,80(sp)
    80002cbe:	69a6                	ld	s3,72(sp)
    80002cc0:	6a06                	ld	s4,64(sp)
    80002cc2:	7ae2                	ld	s5,56(sp)
    80002cc4:	7b42                	ld	s6,48(sp)
    80002cc6:	7ba2                	ld	s7,40(sp)
    80002cc8:	7c02                	ld	s8,32(sp)
    80002cca:	6ce2                	ld	s9,24(sp)
    80002ccc:	6d42                	ld	s10,16(sp)
    80002cce:	6da2                	ld	s11,8(sp)
    80002cd0:	6165                	addi	sp,sp,112
    80002cd2:	8082                	ret
    printf("sleeping list is empty\n");
    80002cd4:	00005517          	auipc	a0,0x5
    80002cd8:	62c50513          	addi	a0,a0,1580 # 80008300 <digits+0x2c0>
    80002cdc:	ffffe097          	auipc	ra,0xffffe
    80002ce0:	8ac080e7          	jalr	-1876(ra) # 80000588 <printf>
    release(&sleeping_list.head_lock);
    80002ce4:	0000e517          	auipc	a0,0xe
    80002ce8:	5e450513          	addi	a0,a0,1508 # 800112c8 <sleeping_list+0x8>
    80002cec:	ffffe097          	auipc	ra,0xffffe
    80002cf0:	fac080e7          	jalr	-84(ra) # 80000c98 <release>
    procdump();
    80002cf4:	00000097          	auipc	ra,0x0
    80002cf8:	e40080e7          	jalr	-448(ra) # 80002b34 <procdump>
    return;
    80002cfc:	bf6d                	j	80002cb6 <wakeup2+0xd4>
        printf("waking up proc number %d\n", p->pid);
    80002cfe:	8a4e                	mv	s4,s3
    80002d00:	19000a93          	li	s5,400
    80002d04:	04892583          	lw	a1,72(s2)
    80002d08:	00005517          	auipc	a0,0x5
    80002d0c:	61050513          	addi	a0,a0,1552 # 80008318 <digits+0x2d8>
    80002d10:	ffffe097          	auipc	ra,0xffffe
    80002d14:	878080e7          	jalr	-1928(ra) # 80000588 <printf>
        p->state = RUNNABLE;
    80002d18:	478d                	li	a5,3
    80002d1a:	02f92823          	sw	a5,48(s2)
        next_link_index = p->next_proc_index;
    80002d1e:	18092983          	lw	s3,384(s2)
        release(&sleeping_list.head_lock);
    80002d22:	0000e517          	auipc	a0,0xe
    80002d26:	5a650513          	addi	a0,a0,1446 # 800112c8 <sleeping_list+0x8>
    80002d2a:	ffffe097          	auipc	ra,0xffffe
    80002d2e:	f6e080e7          	jalr	-146(ra) # 80000c98 <release>
        release(&proc[sleeping_list.head].list_lock);
    80002d32:	0000e517          	auipc	a0,0xe
    80002d36:	58e52503          	lw	a0,1422(a0) # 800112c0 <sleeping_list>
    80002d3a:	03550533          	mul	a0,a0,s5
    80002d3e:	0561                	addi	a0,a0,24
    80002d40:	9552                	add	a0,a0,s4
    80002d42:	ffffe097          	auipc	ra,0xffffe
    80002d46:	f56080e7          	jalr	-170(ra) # 80000c98 <release>
        remove_link(&sleeping_list, p->proc_index);
    80002d4a:	18492583          	lw	a1,388(s2)
    80002d4e:	0000e517          	auipc	a0,0xe
    80002d52:	57250513          	addi	a0,a0,1394 # 800112c0 <sleeping_list>
    80002d56:	fffff097          	auipc	ra,0xfffff
    80002d5a:	b42080e7          	jalr	-1214(ra) # 80001898 <remove_link>
        add_link(&runnable_cpu_lists[p->affiliated_cpu], p->proc_index);
    80002d5e:	18892783          	lw	a5,392(s2)
    80002d62:	0796                	slli	a5,a5,0x5
    80002d64:	18492583          	lw	a1,388(s2)
    80002d68:	0000e517          	auipc	a0,0xe
    80002d6c:	59850513          	addi	a0,a0,1432 # 80011300 <runnable_cpu_lists>
    80002d70:	953e                	add	a0,a0,a5
    80002d72:	fffff097          	auipc	ra,0xfffff
    80002d76:	d16080e7          	jalr	-746(ra) # 80001a88 <add_link>
  release(&p->lock);
    80002d7a:	854a                	mv	a0,s2
    80002d7c:	ffffe097          	auipc	ra,0xffffe
    80002d80:	f1c080e7          	jalr	-228(ra) # 80000c98 <release>
  while(next_link_index != -1){   // TODO: NOT SAFE!!
    80002d84:	57fd                	li	a5,-1
    80002d86:	f2f980e3          	beq	s3,a5,80002ca6 <wakeup2+0xc4>
        p->state = RUNNABLE;
    80002d8a:	4d0d                	li	s10,3
        remove_link(&sleeping_list, p->proc_index);
    80002d8c:	0000ec97          	auipc	s9,0xe
    80002d90:	534c8c93          	addi	s9,s9,1332 # 800112c0 <sleeping_list>
        add_link(&runnable_cpu_lists[p->affiliated_cpu], p->proc_index);
    80002d94:	0000ec17          	auipc	s8,0xe
    80002d98:	56cc0c13          	addi	s8,s8,1388 # 80011300 <runnable_cpu_lists>
  while(next_link_index != -1){   // TODO: NOT SAFE!!
    80002d9c:	5bfd                	li	s7,-1
    80002d9e:	a829                	j	80002db8 <wakeup2+0x1d6>
        release(&proc[next_link_index].list_lock);
    80002da0:	854a                	mv	a0,s2
    80002da2:	ffffe097          	auipc	ra,0xffffe
    80002da6:	ef6080e7          	jalr	-266(ra) # 80000c98 <release>
    release(&p->lock);
    80002daa:	8526                	mv	a0,s1
    80002dac:	ffffe097          	auipc	ra,0xffffe
    80002db0:	eec080e7          	jalr	-276(ra) # 80000c98 <release>
  while(next_link_index != -1){   // TODO: NOT SAFE!!
    80002db4:	ef7989e3          	beq	s3,s7,80002ca6 <wakeup2+0xc4>
    acquire(&proc[next_link_index].list_lock);
    80002db8:	035984b3          	mul	s1,s3,s5
    80002dbc:	01848913          	addi	s2,s1,24
    80002dc0:	9952                	add	s2,s2,s4
    80002dc2:	854a                	mv	a0,s2
    80002dc4:	ffffe097          	auipc	ra,0xffffe
    80002dc8:	e20080e7          	jalr	-480(ra) # 80000be4 <acquire>
    p = &proc[next_link_index];
    80002dcc:	94d2                	add	s1,s1,s4
    acquire(&p->lock);
    80002dce:	8526                	mv	a0,s1
    80002dd0:	ffffe097          	auipc	ra,0xffffe
    80002dd4:	e14080e7          	jalr	-492(ra) # 80000be4 <acquire>
      if(p!=myproc()&&p->chan == chan) {
    80002dd8:	fffff097          	auipc	ra,0xfffff
    80002ddc:	f84080e7          	jalr	-124(ra) # 80001d5c <myproc>
    80002de0:	fca480e3          	beq	s1,a0,80002da0 <wakeup2+0x1be>
    80002de4:	7c9c                	ld	a5,56(s1)
    80002de6:	fb679de3          	bne	a5,s6,80002da0 <wakeup2+0x1be>
        p->state = RUNNABLE;
    80002dea:	03a4a823          	sw	s10,48(s1)
        release(&proc[next_link_index].list_lock);
    80002dee:	854a                	mv	a0,s2
    80002df0:	ffffe097          	auipc	ra,0xffffe
    80002df4:	ea8080e7          	jalr	-344(ra) # 80000c98 <release>
        next_link_index = p->next_proc_index;
    80002df8:	1804a983          	lw	s3,384(s1)
        remove_link(&sleeping_list, p->proc_index);
    80002dfc:	1844a583          	lw	a1,388(s1)
    80002e00:	8566                	mv	a0,s9
    80002e02:	fffff097          	auipc	ra,0xfffff
    80002e06:	a96080e7          	jalr	-1386(ra) # 80001898 <remove_link>
        add_link(&runnable_cpu_lists[p->affiliated_cpu], p->proc_index);
    80002e0a:	1884a503          	lw	a0,392(s1)
    80002e0e:	0516                	slli	a0,a0,0x5
    80002e10:	1844a583          	lw	a1,388(s1)
    80002e14:	9562                	add	a0,a0,s8
    80002e16:	fffff097          	auipc	ra,0xfffff
    80002e1a:	c72080e7          	jalr	-910(ra) # 80001a88 <add_link>
    80002e1e:	b771                	j	80002daa <wakeup2+0x1c8>

0000000080002e20 <set_cpu>:

int set_cpu(int cpu_num){
  if (cpu_num >= NCPU)
    80002e20:	479d                	li	a5,7
    80002e22:	04a7c463          	blt	a5,a0,80002e6a <set_cpu+0x4a>
int set_cpu(int cpu_num){
    80002e26:	1101                	addi	sp,sp,-32
    80002e28:	ec06                	sd	ra,24(sp)
    80002e2a:	e822                	sd	s0,16(sp)
    80002e2c:	e426                	sd	s1,8(sp)
    80002e2e:	e04a                	sd	s2,0(sp)
    80002e30:	1000                	addi	s0,sp,32
    80002e32:	84aa                	mv	s1,a0
    return -1;
  
  struct proc* my_proc = myproc();
    80002e34:	fffff097          	auipc	ra,0xfffff
    80002e38:	f28080e7          	jalr	-216(ra) # 80001d5c <myproc>
    80002e3c:	892a                	mv	s2,a0
  acquire(&my_proc->lock);
    80002e3e:	ffffe097          	auipc	ra,0xffffe
    80002e42:	da6080e7          	jalr	-602(ra) # 80000be4 <acquire>
  my_proc -> affiliated_cpu = cpu_num; 
    80002e46:	18992423          	sw	s1,392(s2)
  release(&my_proc->lock);
    80002e4a:	854a                	mv	a0,s2
    80002e4c:	ffffe097          	auipc	ra,0xffffe
    80002e50:	e4c080e7          	jalr	-436(ra) # 80000c98 <release>
  yield();
    80002e54:	fffff097          	auipc	ra,0xfffff
    80002e58:	6a8080e7          	jalr	1704(ra) # 800024fc <yield>

  return cpu_num;
    80002e5c:	8526                	mv	a0,s1

}
    80002e5e:	60e2                	ld	ra,24(sp)
    80002e60:	6442                	ld	s0,16(sp)
    80002e62:	64a2                	ld	s1,8(sp)
    80002e64:	6902                	ld	s2,0(sp)
    80002e66:	6105                	addi	sp,sp,32
    80002e68:	8082                	ret
    return -1;
    80002e6a:	557d                	li	a0,-1
}
    80002e6c:	8082                	ret

0000000080002e6e <get_cpu>:

int get_cpu(void){
    80002e6e:	1101                	addi	sp,sp,-32
    80002e70:	ec06                	sd	ra,24(sp)
    80002e72:	e822                	sd	s0,16(sp)
    80002e74:	e426                	sd	s1,8(sp)
    80002e76:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e78:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002e7c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e7e:	10079073          	csrw	sstatus,a5
  asm volatile("mv %0, tp" : "=r" (x) );
    80002e82:	8492                	mv	s1,tp
  int id = r_tp();
    80002e84:	2481                	sext.w	s1,s1
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e86:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002e8a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e8e:	10079073          	csrw	sstatus,a5
  */
  
  intr_off();
  int res = cpuid();
  intr_on();
  printf("cpuid is %d\n", res);
    80002e92:	85a6                	mv	a1,s1
    80002e94:	00005517          	auipc	a0,0x5
    80002e98:	4b450513          	addi	a0,a0,1204 # 80008348 <digits+0x308>
    80002e9c:	ffffd097          	auipc	ra,0xffffd
    80002ea0:	6ec080e7          	jalr	1772(ra) # 80000588 <printf>
  return res;
}
    80002ea4:	8526                	mv	a0,s1
    80002ea6:	60e2                	ld	ra,24(sp)
    80002ea8:	6442                	ld	s0,16(sp)
    80002eaa:	64a2                	ld	s1,8(sp)
    80002eac:	6105                	addi	sp,sp,32
    80002eae:	8082                	ret

0000000080002eb0 <swtch>:
    80002eb0:	00153023          	sd	ra,0(a0)
    80002eb4:	00253423          	sd	sp,8(a0)
    80002eb8:	e900                	sd	s0,16(a0)
    80002eba:	ed04                	sd	s1,24(a0)
    80002ebc:	03253023          	sd	s2,32(a0)
    80002ec0:	03353423          	sd	s3,40(a0)
    80002ec4:	03453823          	sd	s4,48(a0)
    80002ec8:	03553c23          	sd	s5,56(a0)
    80002ecc:	05653023          	sd	s6,64(a0)
    80002ed0:	05753423          	sd	s7,72(a0)
    80002ed4:	05853823          	sd	s8,80(a0)
    80002ed8:	05953c23          	sd	s9,88(a0)
    80002edc:	07a53023          	sd	s10,96(a0)
    80002ee0:	07b53423          	sd	s11,104(a0)
    80002ee4:	0005b083          	ld	ra,0(a1)
    80002ee8:	0085b103          	ld	sp,8(a1)
    80002eec:	6980                	ld	s0,16(a1)
    80002eee:	6d84                	ld	s1,24(a1)
    80002ef0:	0205b903          	ld	s2,32(a1)
    80002ef4:	0285b983          	ld	s3,40(a1)
    80002ef8:	0305ba03          	ld	s4,48(a1)
    80002efc:	0385ba83          	ld	s5,56(a1)
    80002f00:	0405bb03          	ld	s6,64(a1)
    80002f04:	0485bb83          	ld	s7,72(a1)
    80002f08:	0505bc03          	ld	s8,80(a1)
    80002f0c:	0585bc83          	ld	s9,88(a1)
    80002f10:	0605bd03          	ld	s10,96(a1)
    80002f14:	0685bd83          	ld	s11,104(a1)
    80002f18:	8082                	ret

0000000080002f1a <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002f1a:	1141                	addi	sp,sp,-16
    80002f1c:	e406                	sd	ra,8(sp)
    80002f1e:	e022                	sd	s0,0(sp)
    80002f20:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002f22:	00005597          	auipc	a1,0x5
    80002f26:	48e58593          	addi	a1,a1,1166 # 800083b0 <states.1768+0x30>
    80002f2a:	00015517          	auipc	a0,0x15
    80002f2e:	c6650513          	addi	a0,a0,-922 # 80017b90 <tickslock>
    80002f32:	ffffe097          	auipc	ra,0xffffe
    80002f36:	c22080e7          	jalr	-990(ra) # 80000b54 <initlock>
}
    80002f3a:	60a2                	ld	ra,8(sp)
    80002f3c:	6402                	ld	s0,0(sp)
    80002f3e:	0141                	addi	sp,sp,16
    80002f40:	8082                	ret

0000000080002f42 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002f42:	1141                	addi	sp,sp,-16
    80002f44:	e422                	sd	s0,8(sp)
    80002f46:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002f48:	00003797          	auipc	a5,0x3
    80002f4c:	4c878793          	addi	a5,a5,1224 # 80006410 <kernelvec>
    80002f50:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002f54:	6422                	ld	s0,8(sp)
    80002f56:	0141                	addi	sp,sp,16
    80002f58:	8082                	ret

0000000080002f5a <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002f5a:	1141                	addi	sp,sp,-16
    80002f5c:	e406                	sd	ra,8(sp)
    80002f5e:	e022                	sd	s0,0(sp)
    80002f60:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002f62:	fffff097          	auipc	ra,0xfffff
    80002f66:	dfa080e7          	jalr	-518(ra) # 80001d5c <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f6a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002f6e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002f70:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002f74:	00004617          	auipc	a2,0x4
    80002f78:	08c60613          	addi	a2,a2,140 # 80007000 <_trampoline>
    80002f7c:	00004697          	auipc	a3,0x4
    80002f80:	08468693          	addi	a3,a3,132 # 80007000 <_trampoline>
    80002f84:	8e91                	sub	a3,a3,a2
    80002f86:	040007b7          	lui	a5,0x4000
    80002f8a:	17fd                	addi	a5,a5,-1
    80002f8c:	07b2                	slli	a5,a5,0xc
    80002f8e:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002f90:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002f94:	7938                	ld	a4,112(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002f96:	180026f3          	csrr	a3,satp
    80002f9a:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002f9c:	7938                	ld	a4,112(a0)
    80002f9e:	6d34                	ld	a3,88(a0)
    80002fa0:	6585                	lui	a1,0x1
    80002fa2:	96ae                	add	a3,a3,a1
    80002fa4:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002fa6:	7938                	ld	a4,112(a0)
    80002fa8:	00000697          	auipc	a3,0x0
    80002fac:	13868693          	addi	a3,a3,312 # 800030e0 <usertrap>
    80002fb0:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002fb2:	7938                	ld	a4,112(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002fb4:	8692                	mv	a3,tp
    80002fb6:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fb8:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002fbc:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002fc0:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002fc4:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002fc8:	7938                	ld	a4,112(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002fca:	6f18                	ld	a4,24(a4)
    80002fcc:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002fd0:	752c                	ld	a1,104(a0)
    80002fd2:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002fd4:	00004717          	auipc	a4,0x4
    80002fd8:	0bc70713          	addi	a4,a4,188 # 80007090 <userret>
    80002fdc:	8f11                	sub	a4,a4,a2
    80002fde:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002fe0:	577d                	li	a4,-1
    80002fe2:	177e                	slli	a4,a4,0x3f
    80002fe4:	8dd9                	or	a1,a1,a4
    80002fe6:	02000537          	lui	a0,0x2000
    80002fea:	157d                	addi	a0,a0,-1
    80002fec:	0536                	slli	a0,a0,0xd
    80002fee:	9782                	jalr	a5
}
    80002ff0:	60a2                	ld	ra,8(sp)
    80002ff2:	6402                	ld	s0,0(sp)
    80002ff4:	0141                	addi	sp,sp,16
    80002ff6:	8082                	ret

0000000080002ff8 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002ff8:	1101                	addi	sp,sp,-32
    80002ffa:	ec06                	sd	ra,24(sp)
    80002ffc:	e822                	sd	s0,16(sp)
    80002ffe:	e426                	sd	s1,8(sp)
    80003000:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80003002:	00015497          	auipc	s1,0x15
    80003006:	b8e48493          	addi	s1,s1,-1138 # 80017b90 <tickslock>
    8000300a:	8526                	mv	a0,s1
    8000300c:	ffffe097          	auipc	ra,0xffffe
    80003010:	bd8080e7          	jalr	-1064(ra) # 80000be4 <acquire>
  ticks++;
    80003014:	00006517          	auipc	a0,0x6
    80003018:	01c50513          	addi	a0,a0,28 # 80009030 <ticks>
    8000301c:	411c                	lw	a5,0(a0)
    8000301e:	2785                	addiw	a5,a5,1
    80003020:	c11c                	sw	a5,0(a0)
  //printf("clockintr\n");
  wakeup(&ticks);
    80003022:	fffff097          	auipc	ra,0xfffff
    80003026:	6d2080e7          	jalr	1746(ra) # 800026f4 <wakeup>
  release(&tickslock);
    8000302a:	8526                	mv	a0,s1
    8000302c:	ffffe097          	auipc	ra,0xffffe
    80003030:	c6c080e7          	jalr	-916(ra) # 80000c98 <release>
}
    80003034:	60e2                	ld	ra,24(sp)
    80003036:	6442                	ld	s0,16(sp)
    80003038:	64a2                	ld	s1,8(sp)
    8000303a:	6105                	addi	sp,sp,32
    8000303c:	8082                	ret

000000008000303e <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000303e:	1101                	addi	sp,sp,-32
    80003040:	ec06                	sd	ra,24(sp)
    80003042:	e822                	sd	s0,16(sp)
    80003044:	e426                	sd	s1,8(sp)
    80003046:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003048:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000304c:	00074d63          	bltz	a4,80003066 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80003050:	57fd                	li	a5,-1
    80003052:	17fe                	slli	a5,a5,0x3f
    80003054:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80003056:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80003058:	06f70363          	beq	a4,a5,800030be <devintr+0x80>
  }
}
    8000305c:	60e2                	ld	ra,24(sp)
    8000305e:	6442                	ld	s0,16(sp)
    80003060:	64a2                	ld	s1,8(sp)
    80003062:	6105                	addi	sp,sp,32
    80003064:	8082                	ret
     (scause & 0xff) == 9){
    80003066:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    8000306a:	46a5                	li	a3,9
    8000306c:	fed792e3          	bne	a5,a3,80003050 <devintr+0x12>
    int irq = plic_claim();
    80003070:	00003097          	auipc	ra,0x3
    80003074:	4a8080e7          	jalr	1192(ra) # 80006518 <plic_claim>
    80003078:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000307a:	47a9                	li	a5,10
    8000307c:	02f50763          	beq	a0,a5,800030aa <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80003080:	4785                	li	a5,1
    80003082:	02f50963          	beq	a0,a5,800030b4 <devintr+0x76>
    return 1;
    80003086:	4505                	li	a0,1
    } else if(irq){
    80003088:	d8f1                	beqz	s1,8000305c <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000308a:	85a6                	mv	a1,s1
    8000308c:	00005517          	auipc	a0,0x5
    80003090:	32c50513          	addi	a0,a0,812 # 800083b8 <states.1768+0x38>
    80003094:	ffffd097          	auipc	ra,0xffffd
    80003098:	4f4080e7          	jalr	1268(ra) # 80000588 <printf>
      plic_complete(irq);
    8000309c:	8526                	mv	a0,s1
    8000309e:	00003097          	auipc	ra,0x3
    800030a2:	49e080e7          	jalr	1182(ra) # 8000653c <plic_complete>
    return 1;
    800030a6:	4505                	li	a0,1
    800030a8:	bf55                	j	8000305c <devintr+0x1e>
      uartintr();
    800030aa:	ffffe097          	auipc	ra,0xffffe
    800030ae:	8fe080e7          	jalr	-1794(ra) # 800009a8 <uartintr>
    800030b2:	b7ed                	j	8000309c <devintr+0x5e>
      virtio_disk_intr();
    800030b4:	00004097          	auipc	ra,0x4
    800030b8:	968080e7          	jalr	-1688(ra) # 80006a1c <virtio_disk_intr>
    800030bc:	b7c5                	j	8000309c <devintr+0x5e>
    if(cpuid() == 0){
    800030be:	fffff097          	auipc	ra,0xfffff
    800030c2:	c72080e7          	jalr	-910(ra) # 80001d30 <cpuid>
    800030c6:	c901                	beqz	a0,800030d6 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800030c8:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800030cc:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800030ce:	14479073          	csrw	sip,a5
    return 2;
    800030d2:	4509                	li	a0,2
    800030d4:	b761                	j	8000305c <devintr+0x1e>
      clockintr();
    800030d6:	00000097          	auipc	ra,0x0
    800030da:	f22080e7          	jalr	-222(ra) # 80002ff8 <clockintr>
    800030de:	b7ed                	j	800030c8 <devintr+0x8a>

00000000800030e0 <usertrap>:
{
    800030e0:	1101                	addi	sp,sp,-32
    800030e2:	ec06                	sd	ra,24(sp)
    800030e4:	e822                	sd	s0,16(sp)
    800030e6:	e426                	sd	s1,8(sp)
    800030e8:	e04a                	sd	s2,0(sp)
    800030ea:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800030ec:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800030f0:	1007f793          	andi	a5,a5,256
    800030f4:	e3ad                	bnez	a5,80003156 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800030f6:	00003797          	auipc	a5,0x3
    800030fa:	31a78793          	addi	a5,a5,794 # 80006410 <kernelvec>
    800030fe:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80003102:	fffff097          	auipc	ra,0xfffff
    80003106:	c5a080e7          	jalr	-934(ra) # 80001d5c <myproc>
    8000310a:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    8000310c:	793c                	ld	a5,112(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000310e:	14102773          	csrr	a4,sepc
    80003112:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003114:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80003118:	47a1                	li	a5,8
    8000311a:	04f71c63          	bne	a4,a5,80003172 <usertrap+0x92>
    if(p->killed)
    8000311e:	413c                	lw	a5,64(a0)
    80003120:	e3b9                	bnez	a5,80003166 <usertrap+0x86>
    p->trapframe->epc += 4;
    80003122:	78b8                	ld	a4,112(s1)
    80003124:	6f1c                	ld	a5,24(a4)
    80003126:	0791                	addi	a5,a5,4
    80003128:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000312a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000312e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003132:	10079073          	csrw	sstatus,a5
    syscall();
    80003136:	00000097          	auipc	ra,0x0
    8000313a:	2e0080e7          	jalr	736(ra) # 80003416 <syscall>
  if(p->killed)
    8000313e:	40bc                	lw	a5,64(s1)
    80003140:	ebc1                	bnez	a5,800031d0 <usertrap+0xf0>
  usertrapret();
    80003142:	00000097          	auipc	ra,0x0
    80003146:	e18080e7          	jalr	-488(ra) # 80002f5a <usertrapret>
}
    8000314a:	60e2                	ld	ra,24(sp)
    8000314c:	6442                	ld	s0,16(sp)
    8000314e:	64a2                	ld	s1,8(sp)
    80003150:	6902                	ld	s2,0(sp)
    80003152:	6105                	addi	sp,sp,32
    80003154:	8082                	ret
    panic("usertrap: not from user mode");
    80003156:	00005517          	auipc	a0,0x5
    8000315a:	28250513          	addi	a0,a0,642 # 800083d8 <states.1768+0x58>
    8000315e:	ffffd097          	auipc	ra,0xffffd
    80003162:	3e0080e7          	jalr	992(ra) # 8000053e <panic>
      exit(-1);
    80003166:	557d                	li	a0,-1
    80003168:	fffff097          	auipc	ra,0xfffff
    8000316c:	7c4080e7          	jalr	1988(ra) # 8000292c <exit>
    80003170:	bf4d                	j	80003122 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80003172:	00000097          	auipc	ra,0x0
    80003176:	ecc080e7          	jalr	-308(ra) # 8000303e <devintr>
    8000317a:	892a                	mv	s2,a0
    8000317c:	c501                	beqz	a0,80003184 <usertrap+0xa4>
  if(p->killed)
    8000317e:	40bc                	lw	a5,64(s1)
    80003180:	c3a1                	beqz	a5,800031c0 <usertrap+0xe0>
    80003182:	a815                	j	800031b6 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003184:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80003188:	44b0                	lw	a2,72(s1)
    8000318a:	00005517          	auipc	a0,0x5
    8000318e:	26e50513          	addi	a0,a0,622 # 800083f8 <states.1768+0x78>
    80003192:	ffffd097          	auipc	ra,0xffffd
    80003196:	3f6080e7          	jalr	1014(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000319a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000319e:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800031a2:	00005517          	auipc	a0,0x5
    800031a6:	28650513          	addi	a0,a0,646 # 80008428 <states.1768+0xa8>
    800031aa:	ffffd097          	auipc	ra,0xffffd
    800031ae:	3de080e7          	jalr	990(ra) # 80000588 <printf>
    p->killed = 1;
    800031b2:	4785                	li	a5,1
    800031b4:	c0bc                	sw	a5,64(s1)
    exit(-1);
    800031b6:	557d                	li	a0,-1
    800031b8:	fffff097          	auipc	ra,0xfffff
    800031bc:	774080e7          	jalr	1908(ra) # 8000292c <exit>
  if(which_dev == 2)
    800031c0:	4789                	li	a5,2
    800031c2:	f8f910e3          	bne	s2,a5,80003142 <usertrap+0x62>
    yield();
    800031c6:	fffff097          	auipc	ra,0xfffff
    800031ca:	336080e7          	jalr	822(ra) # 800024fc <yield>
    800031ce:	bf95                	j	80003142 <usertrap+0x62>
  int which_dev = 0;
    800031d0:	4901                	li	s2,0
    800031d2:	b7d5                	j	800031b6 <usertrap+0xd6>

00000000800031d4 <kerneltrap>:
{
    800031d4:	7179                	addi	sp,sp,-48
    800031d6:	f406                	sd	ra,40(sp)
    800031d8:	f022                	sd	s0,32(sp)
    800031da:	ec26                	sd	s1,24(sp)
    800031dc:	e84a                	sd	s2,16(sp)
    800031de:	e44e                	sd	s3,8(sp)
    800031e0:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800031e2:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800031e6:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800031ea:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800031ee:	1004f793          	andi	a5,s1,256
    800031f2:	cb85                	beqz	a5,80003222 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800031f4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800031f8:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800031fa:	ef85                	bnez	a5,80003232 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800031fc:	00000097          	auipc	ra,0x0
    80003200:	e42080e7          	jalr	-446(ra) # 8000303e <devintr>
    80003204:	cd1d                	beqz	a0,80003242 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003206:	4789                	li	a5,2
    80003208:	06f50a63          	beq	a0,a5,8000327c <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000320c:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003210:	10049073          	csrw	sstatus,s1
}
    80003214:	70a2                	ld	ra,40(sp)
    80003216:	7402                	ld	s0,32(sp)
    80003218:	64e2                	ld	s1,24(sp)
    8000321a:	6942                	ld	s2,16(sp)
    8000321c:	69a2                	ld	s3,8(sp)
    8000321e:	6145                	addi	sp,sp,48
    80003220:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80003222:	00005517          	auipc	a0,0x5
    80003226:	22650513          	addi	a0,a0,550 # 80008448 <states.1768+0xc8>
    8000322a:	ffffd097          	auipc	ra,0xffffd
    8000322e:	314080e7          	jalr	788(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80003232:	00005517          	auipc	a0,0x5
    80003236:	23e50513          	addi	a0,a0,574 # 80008470 <states.1768+0xf0>
    8000323a:	ffffd097          	auipc	ra,0xffffd
    8000323e:	304080e7          	jalr	772(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80003242:	85ce                	mv	a1,s3
    80003244:	00005517          	auipc	a0,0x5
    80003248:	24c50513          	addi	a0,a0,588 # 80008490 <states.1768+0x110>
    8000324c:	ffffd097          	auipc	ra,0xffffd
    80003250:	33c080e7          	jalr	828(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003254:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003258:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000325c:	00005517          	auipc	a0,0x5
    80003260:	24450513          	addi	a0,a0,580 # 800084a0 <states.1768+0x120>
    80003264:	ffffd097          	auipc	ra,0xffffd
    80003268:	324080e7          	jalr	804(ra) # 80000588 <printf>
    panic("kerneltrap");
    8000326c:	00005517          	auipc	a0,0x5
    80003270:	24c50513          	addi	a0,a0,588 # 800084b8 <states.1768+0x138>
    80003274:	ffffd097          	auipc	ra,0xffffd
    80003278:	2ca080e7          	jalr	714(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000327c:	fffff097          	auipc	ra,0xfffff
    80003280:	ae0080e7          	jalr	-1312(ra) # 80001d5c <myproc>
    80003284:	d541                	beqz	a0,8000320c <kerneltrap+0x38>
    80003286:	fffff097          	auipc	ra,0xfffff
    8000328a:	ad6080e7          	jalr	-1322(ra) # 80001d5c <myproc>
    8000328e:	5918                	lw	a4,48(a0)
    80003290:	4791                	li	a5,4
    80003292:	f6f71de3          	bne	a4,a5,8000320c <kerneltrap+0x38>
    yield();
    80003296:	fffff097          	auipc	ra,0xfffff
    8000329a:	266080e7          	jalr	614(ra) # 800024fc <yield>
    8000329e:	b7bd                	j	8000320c <kerneltrap+0x38>

00000000800032a0 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800032a0:	1101                	addi	sp,sp,-32
    800032a2:	ec06                	sd	ra,24(sp)
    800032a4:	e822                	sd	s0,16(sp)
    800032a6:	e426                	sd	s1,8(sp)
    800032a8:	1000                	addi	s0,sp,32
    800032aa:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800032ac:	fffff097          	auipc	ra,0xfffff
    800032b0:	ab0080e7          	jalr	-1360(ra) # 80001d5c <myproc>
  switch (n) {
    800032b4:	4795                	li	a5,5
    800032b6:	0497e163          	bltu	a5,s1,800032f8 <argraw+0x58>
    800032ba:	048a                	slli	s1,s1,0x2
    800032bc:	00005717          	auipc	a4,0x5
    800032c0:	23470713          	addi	a4,a4,564 # 800084f0 <states.1768+0x170>
    800032c4:	94ba                	add	s1,s1,a4
    800032c6:	409c                	lw	a5,0(s1)
    800032c8:	97ba                	add	a5,a5,a4
    800032ca:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800032cc:	793c                	ld	a5,112(a0)
    800032ce:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800032d0:	60e2                	ld	ra,24(sp)
    800032d2:	6442                	ld	s0,16(sp)
    800032d4:	64a2                	ld	s1,8(sp)
    800032d6:	6105                	addi	sp,sp,32
    800032d8:	8082                	ret
    return p->trapframe->a1;
    800032da:	793c                	ld	a5,112(a0)
    800032dc:	7fa8                	ld	a0,120(a5)
    800032de:	bfcd                	j	800032d0 <argraw+0x30>
    return p->trapframe->a2;
    800032e0:	793c                	ld	a5,112(a0)
    800032e2:	63c8                	ld	a0,128(a5)
    800032e4:	b7f5                	j	800032d0 <argraw+0x30>
    return p->trapframe->a3;
    800032e6:	793c                	ld	a5,112(a0)
    800032e8:	67c8                	ld	a0,136(a5)
    800032ea:	b7dd                	j	800032d0 <argraw+0x30>
    return p->trapframe->a4;
    800032ec:	793c                	ld	a5,112(a0)
    800032ee:	6bc8                	ld	a0,144(a5)
    800032f0:	b7c5                	j	800032d0 <argraw+0x30>
    return p->trapframe->a5;
    800032f2:	793c                	ld	a5,112(a0)
    800032f4:	6fc8                	ld	a0,152(a5)
    800032f6:	bfe9                	j	800032d0 <argraw+0x30>
  panic("argraw");
    800032f8:	00005517          	auipc	a0,0x5
    800032fc:	1d050513          	addi	a0,a0,464 # 800084c8 <states.1768+0x148>
    80003300:	ffffd097          	auipc	ra,0xffffd
    80003304:	23e080e7          	jalr	574(ra) # 8000053e <panic>

0000000080003308 <fetchaddr>:
{
    80003308:	1101                	addi	sp,sp,-32
    8000330a:	ec06                	sd	ra,24(sp)
    8000330c:	e822                	sd	s0,16(sp)
    8000330e:	e426                	sd	s1,8(sp)
    80003310:	e04a                	sd	s2,0(sp)
    80003312:	1000                	addi	s0,sp,32
    80003314:	84aa                	mv	s1,a0
    80003316:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80003318:	fffff097          	auipc	ra,0xfffff
    8000331c:	a44080e7          	jalr	-1468(ra) # 80001d5c <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80003320:	713c                	ld	a5,96(a0)
    80003322:	02f4f863          	bgeu	s1,a5,80003352 <fetchaddr+0x4a>
    80003326:	00848713          	addi	a4,s1,8
    8000332a:	02e7e663          	bltu	a5,a4,80003356 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    8000332e:	46a1                	li	a3,8
    80003330:	8626                	mv	a2,s1
    80003332:	85ca                	mv	a1,s2
    80003334:	7528                	ld	a0,104(a0)
    80003336:	ffffe097          	auipc	ra,0xffffe
    8000333a:	3c8080e7          	jalr	968(ra) # 800016fe <copyin>
    8000333e:	00a03533          	snez	a0,a0
    80003342:	40a00533          	neg	a0,a0
}
    80003346:	60e2                	ld	ra,24(sp)
    80003348:	6442                	ld	s0,16(sp)
    8000334a:	64a2                	ld	s1,8(sp)
    8000334c:	6902                	ld	s2,0(sp)
    8000334e:	6105                	addi	sp,sp,32
    80003350:	8082                	ret
    return -1;
    80003352:	557d                	li	a0,-1
    80003354:	bfcd                	j	80003346 <fetchaddr+0x3e>
    80003356:	557d                	li	a0,-1
    80003358:	b7fd                	j	80003346 <fetchaddr+0x3e>

000000008000335a <fetchstr>:
{
    8000335a:	7179                	addi	sp,sp,-48
    8000335c:	f406                	sd	ra,40(sp)
    8000335e:	f022                	sd	s0,32(sp)
    80003360:	ec26                	sd	s1,24(sp)
    80003362:	e84a                	sd	s2,16(sp)
    80003364:	e44e                	sd	s3,8(sp)
    80003366:	1800                	addi	s0,sp,48
    80003368:	892a                	mv	s2,a0
    8000336a:	84ae                	mv	s1,a1
    8000336c:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    8000336e:	fffff097          	auipc	ra,0xfffff
    80003372:	9ee080e7          	jalr	-1554(ra) # 80001d5c <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80003376:	86ce                	mv	a3,s3
    80003378:	864a                	mv	a2,s2
    8000337a:	85a6                	mv	a1,s1
    8000337c:	7528                	ld	a0,104(a0)
    8000337e:	ffffe097          	auipc	ra,0xffffe
    80003382:	40c080e7          	jalr	1036(ra) # 8000178a <copyinstr>
  if(err < 0)
    80003386:	00054763          	bltz	a0,80003394 <fetchstr+0x3a>
  return strlen(buf);
    8000338a:	8526                	mv	a0,s1
    8000338c:	ffffe097          	auipc	ra,0xffffe
    80003390:	ad8080e7          	jalr	-1320(ra) # 80000e64 <strlen>
}
    80003394:	70a2                	ld	ra,40(sp)
    80003396:	7402                	ld	s0,32(sp)
    80003398:	64e2                	ld	s1,24(sp)
    8000339a:	6942                	ld	s2,16(sp)
    8000339c:	69a2                	ld	s3,8(sp)
    8000339e:	6145                	addi	sp,sp,48
    800033a0:	8082                	ret

00000000800033a2 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    800033a2:	1101                	addi	sp,sp,-32
    800033a4:	ec06                	sd	ra,24(sp)
    800033a6:	e822                	sd	s0,16(sp)
    800033a8:	e426                	sd	s1,8(sp)
    800033aa:	1000                	addi	s0,sp,32
    800033ac:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800033ae:	00000097          	auipc	ra,0x0
    800033b2:	ef2080e7          	jalr	-270(ra) # 800032a0 <argraw>
    800033b6:	c088                	sw	a0,0(s1)
  return 0;
}
    800033b8:	4501                	li	a0,0
    800033ba:	60e2                	ld	ra,24(sp)
    800033bc:	6442                	ld	s0,16(sp)
    800033be:	64a2                	ld	s1,8(sp)
    800033c0:	6105                	addi	sp,sp,32
    800033c2:	8082                	ret

00000000800033c4 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    800033c4:	1101                	addi	sp,sp,-32
    800033c6:	ec06                	sd	ra,24(sp)
    800033c8:	e822                	sd	s0,16(sp)
    800033ca:	e426                	sd	s1,8(sp)
    800033cc:	1000                	addi	s0,sp,32
    800033ce:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800033d0:	00000097          	auipc	ra,0x0
    800033d4:	ed0080e7          	jalr	-304(ra) # 800032a0 <argraw>
    800033d8:	e088                	sd	a0,0(s1)
  return 0;
}
    800033da:	4501                	li	a0,0
    800033dc:	60e2                	ld	ra,24(sp)
    800033de:	6442                	ld	s0,16(sp)
    800033e0:	64a2                	ld	s1,8(sp)
    800033e2:	6105                	addi	sp,sp,32
    800033e4:	8082                	ret

00000000800033e6 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800033e6:	1101                	addi	sp,sp,-32
    800033e8:	ec06                	sd	ra,24(sp)
    800033ea:	e822                	sd	s0,16(sp)
    800033ec:	e426                	sd	s1,8(sp)
    800033ee:	e04a                	sd	s2,0(sp)
    800033f0:	1000                	addi	s0,sp,32
    800033f2:	84ae                	mv	s1,a1
    800033f4:	8932                	mv	s2,a2
  *ip = argraw(n);
    800033f6:	00000097          	auipc	ra,0x0
    800033fa:	eaa080e7          	jalr	-342(ra) # 800032a0 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    800033fe:	864a                	mv	a2,s2
    80003400:	85a6                	mv	a1,s1
    80003402:	00000097          	auipc	ra,0x0
    80003406:	f58080e7          	jalr	-168(ra) # 8000335a <fetchstr>
}
    8000340a:	60e2                	ld	ra,24(sp)
    8000340c:	6442                	ld	s0,16(sp)
    8000340e:	64a2                	ld	s1,8(sp)
    80003410:	6902                	ld	s2,0(sp)
    80003412:	6105                	addi	sp,sp,32
    80003414:	8082                	ret

0000000080003416 <syscall>:
[SYS_getcpu] sys_getcpu,
};

void
syscall(void)
{
    80003416:	1101                	addi	sp,sp,-32
    80003418:	ec06                	sd	ra,24(sp)
    8000341a:	e822                	sd	s0,16(sp)
    8000341c:	e426                	sd	s1,8(sp)
    8000341e:	e04a                	sd	s2,0(sp)
    80003420:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80003422:	fffff097          	auipc	ra,0xfffff
    80003426:	93a080e7          	jalr	-1734(ra) # 80001d5c <myproc>
    8000342a:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    8000342c:	07053903          	ld	s2,112(a0)
    80003430:	0a893783          	ld	a5,168(s2)
    80003434:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003438:	37fd                	addiw	a5,a5,-1
    8000343a:	4759                	li	a4,22
    8000343c:	00f76f63          	bltu	a4,a5,8000345a <syscall+0x44>
    80003440:	00369713          	slli	a4,a3,0x3
    80003444:	00005797          	auipc	a5,0x5
    80003448:	0c478793          	addi	a5,a5,196 # 80008508 <syscalls>
    8000344c:	97ba                	add	a5,a5,a4
    8000344e:	639c                	ld	a5,0(a5)
    80003450:	c789                	beqz	a5,8000345a <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80003452:	9782                	jalr	a5
    80003454:	06a93823          	sd	a0,112(s2)
    80003458:	a839                	j	80003476 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    8000345a:	17048613          	addi	a2,s1,368
    8000345e:	44ac                	lw	a1,72(s1)
    80003460:	00005517          	auipc	a0,0x5
    80003464:	07050513          	addi	a0,a0,112 # 800084d0 <states.1768+0x150>
    80003468:	ffffd097          	auipc	ra,0xffffd
    8000346c:	120080e7          	jalr	288(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003470:	78bc                	ld	a5,112(s1)
    80003472:	577d                	li	a4,-1
    80003474:	fbb8                	sd	a4,112(a5)
  }
}
    80003476:	60e2                	ld	ra,24(sp)
    80003478:	6442                	ld	s0,16(sp)
    8000347a:	64a2                	ld	s1,8(sp)
    8000347c:	6902                	ld	s2,0(sp)
    8000347e:	6105                	addi	sp,sp,32
    80003480:	8082                	ret

0000000080003482 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003482:	1101                	addi	sp,sp,-32
    80003484:	ec06                	sd	ra,24(sp)
    80003486:	e822                	sd	s0,16(sp)
    80003488:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    8000348a:	fec40593          	addi	a1,s0,-20
    8000348e:	4501                	li	a0,0
    80003490:	00000097          	auipc	ra,0x0
    80003494:	f12080e7          	jalr	-238(ra) # 800033a2 <argint>
    return -1;
    80003498:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    8000349a:	00054963          	bltz	a0,800034ac <sys_exit+0x2a>
  exit(n);
    8000349e:	fec42503          	lw	a0,-20(s0)
    800034a2:	fffff097          	auipc	ra,0xfffff
    800034a6:	48a080e7          	jalr	1162(ra) # 8000292c <exit>
  return 0;  // not reached
    800034aa:	4781                	li	a5,0
}
    800034ac:	853e                	mv	a0,a5
    800034ae:	60e2                	ld	ra,24(sp)
    800034b0:	6442                	ld	s0,16(sp)
    800034b2:	6105                	addi	sp,sp,32
    800034b4:	8082                	ret

00000000800034b6 <sys_getpid>:

uint64
sys_getpid(void)
{
    800034b6:	1141                	addi	sp,sp,-16
    800034b8:	e406                	sd	ra,8(sp)
    800034ba:	e022                	sd	s0,0(sp)
    800034bc:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800034be:	fffff097          	auipc	ra,0xfffff
    800034c2:	89e080e7          	jalr	-1890(ra) # 80001d5c <myproc>
}
    800034c6:	4528                	lw	a0,72(a0)
    800034c8:	60a2                	ld	ra,8(sp)
    800034ca:	6402                	ld	s0,0(sp)
    800034cc:	0141                	addi	sp,sp,16
    800034ce:	8082                	ret

00000000800034d0 <sys_fork>:

uint64
sys_fork(void)
{
    800034d0:	1141                	addi	sp,sp,-16
    800034d2:	e406                	sd	ra,8(sp)
    800034d4:	e022                	sd	s0,0(sp)
    800034d6:	0800                	addi	s0,sp,16
  return fork();
    800034d8:	fffff097          	auipc	ra,0xfffff
    800034dc:	cee080e7          	jalr	-786(ra) # 800021c6 <fork>
}
    800034e0:	60a2                	ld	ra,8(sp)
    800034e2:	6402                	ld	s0,0(sp)
    800034e4:	0141                	addi	sp,sp,16
    800034e6:	8082                	ret

00000000800034e8 <sys_wait>:

uint64
sys_wait(void)
{
    800034e8:	1101                	addi	sp,sp,-32
    800034ea:	ec06                	sd	ra,24(sp)
    800034ec:	e822                	sd	s0,16(sp)
    800034ee:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    800034f0:	fe840593          	addi	a1,s0,-24
    800034f4:	4501                	li	a0,0
    800034f6:	00000097          	auipc	ra,0x0
    800034fa:	ece080e7          	jalr	-306(ra) # 800033c4 <argaddr>
    800034fe:	87aa                	mv	a5,a0
    return -1;
    80003500:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80003502:	0007c863          	bltz	a5,80003512 <sys_wait+0x2a>
  return wait(p);
    80003506:	fe843503          	ld	a0,-24(s0)
    8000350a:	fffff097          	auipc	ra,0xfffff
    8000350e:	0c2080e7          	jalr	194(ra) # 800025cc <wait>
}
    80003512:	60e2                	ld	ra,24(sp)
    80003514:	6442                	ld	s0,16(sp)
    80003516:	6105                	addi	sp,sp,32
    80003518:	8082                	ret

000000008000351a <sys_sbrk>:

uint64
sys_sbrk(void)
{
    8000351a:	7179                	addi	sp,sp,-48
    8000351c:	f406                	sd	ra,40(sp)
    8000351e:	f022                	sd	s0,32(sp)
    80003520:	ec26                	sd	s1,24(sp)
    80003522:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80003524:	fdc40593          	addi	a1,s0,-36
    80003528:	4501                	li	a0,0
    8000352a:	00000097          	auipc	ra,0x0
    8000352e:	e78080e7          	jalr	-392(ra) # 800033a2 <argint>
    80003532:	87aa                	mv	a5,a0
    return -1;
    80003534:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80003536:	0207c063          	bltz	a5,80003556 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    8000353a:	fffff097          	auipc	ra,0xfffff
    8000353e:	822080e7          	jalr	-2014(ra) # 80001d5c <myproc>
    80003542:	5124                	lw	s1,96(a0)
  if(growproc(n) < 0)
    80003544:	fdc42503          	lw	a0,-36(s0)
    80003548:	fffff097          	auipc	ra,0xfffff
    8000354c:	c0a080e7          	jalr	-1014(ra) # 80002152 <growproc>
    80003550:	00054863          	bltz	a0,80003560 <sys_sbrk+0x46>
    return -1;
  return addr;
    80003554:	8526                	mv	a0,s1
}
    80003556:	70a2                	ld	ra,40(sp)
    80003558:	7402                	ld	s0,32(sp)
    8000355a:	64e2                	ld	s1,24(sp)
    8000355c:	6145                	addi	sp,sp,48
    8000355e:	8082                	ret
    return -1;
    80003560:	557d                	li	a0,-1
    80003562:	bfd5                	j	80003556 <sys_sbrk+0x3c>

0000000080003564 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003564:	7139                	addi	sp,sp,-64
    80003566:	fc06                	sd	ra,56(sp)
    80003568:	f822                	sd	s0,48(sp)
    8000356a:	f426                	sd	s1,40(sp)
    8000356c:	f04a                	sd	s2,32(sp)
    8000356e:	ec4e                	sd	s3,24(sp)
    80003570:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003572:	fcc40593          	addi	a1,s0,-52
    80003576:	4501                	li	a0,0
    80003578:	00000097          	auipc	ra,0x0
    8000357c:	e2a080e7          	jalr	-470(ra) # 800033a2 <argint>
    return -1;
    80003580:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003582:	06054563          	bltz	a0,800035ec <sys_sleep+0x88>
  acquire(&tickslock);
    80003586:	00014517          	auipc	a0,0x14
    8000358a:	60a50513          	addi	a0,a0,1546 # 80017b90 <tickslock>
    8000358e:	ffffd097          	auipc	ra,0xffffd
    80003592:	656080e7          	jalr	1622(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80003596:	00006917          	auipc	s2,0x6
    8000359a:	a9a92903          	lw	s2,-1382(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    8000359e:	fcc42783          	lw	a5,-52(s0)
    800035a2:	cf85                	beqz	a5,800035da <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800035a4:	00014997          	auipc	s3,0x14
    800035a8:	5ec98993          	addi	s3,s3,1516 # 80017b90 <tickslock>
    800035ac:	00006497          	auipc	s1,0x6
    800035b0:	a8448493          	addi	s1,s1,-1404 # 80009030 <ticks>
    if(myproc()->killed){
    800035b4:	ffffe097          	auipc	ra,0xffffe
    800035b8:	7a8080e7          	jalr	1960(ra) # 80001d5c <myproc>
    800035bc:	413c                	lw	a5,64(a0)
    800035be:	ef9d                	bnez	a5,800035fc <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    800035c0:	85ce                	mv	a1,s3
    800035c2:	8526                	mv	a0,s1
    800035c4:	fffff097          	auipc	ra,0xfffff
    800035c8:	f90080e7          	jalr	-112(ra) # 80002554 <sleep>
  while(ticks - ticks0 < n){
    800035cc:	409c                	lw	a5,0(s1)
    800035ce:	412787bb          	subw	a5,a5,s2
    800035d2:	fcc42703          	lw	a4,-52(s0)
    800035d6:	fce7efe3          	bltu	a5,a4,800035b4 <sys_sleep+0x50>
  }
  release(&tickslock);
    800035da:	00014517          	auipc	a0,0x14
    800035de:	5b650513          	addi	a0,a0,1462 # 80017b90 <tickslock>
    800035e2:	ffffd097          	auipc	ra,0xffffd
    800035e6:	6b6080e7          	jalr	1718(ra) # 80000c98 <release>
  return 0;
    800035ea:	4781                	li	a5,0
}
    800035ec:	853e                	mv	a0,a5
    800035ee:	70e2                	ld	ra,56(sp)
    800035f0:	7442                	ld	s0,48(sp)
    800035f2:	74a2                	ld	s1,40(sp)
    800035f4:	7902                	ld	s2,32(sp)
    800035f6:	69e2                	ld	s3,24(sp)
    800035f8:	6121                	addi	sp,sp,64
    800035fa:	8082                	ret
      release(&tickslock);
    800035fc:	00014517          	auipc	a0,0x14
    80003600:	59450513          	addi	a0,a0,1428 # 80017b90 <tickslock>
    80003604:	ffffd097          	auipc	ra,0xffffd
    80003608:	694080e7          	jalr	1684(ra) # 80000c98 <release>
      return -1;
    8000360c:	57fd                	li	a5,-1
    8000360e:	bff9                	j	800035ec <sys_sleep+0x88>

0000000080003610 <sys_kill>:

uint64
sys_kill(void)
{
    80003610:	1101                	addi	sp,sp,-32
    80003612:	ec06                	sd	ra,24(sp)
    80003614:	e822                	sd	s0,16(sp)
    80003616:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003618:	fec40593          	addi	a1,s0,-20
    8000361c:	4501                	li	a0,0
    8000361e:	00000097          	auipc	ra,0x0
    80003622:	d84080e7          	jalr	-636(ra) # 800033a2 <argint>
    80003626:	87aa                	mv	a5,a0
    return -1;
    80003628:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    8000362a:	0007c863          	bltz	a5,8000363a <sys_kill+0x2a>
  return kill(pid);
    8000362e:	fec42503          	lw	a0,-20(s0)
    80003632:	fffff097          	auipc	ra,0xfffff
    80003636:	3e4080e7          	jalr	996(ra) # 80002a16 <kill>
}
    8000363a:	60e2                	ld	ra,24(sp)
    8000363c:	6442                	ld	s0,16(sp)
    8000363e:	6105                	addi	sp,sp,32
    80003640:	8082                	ret

0000000080003642 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003642:	1101                	addi	sp,sp,-32
    80003644:	ec06                	sd	ra,24(sp)
    80003646:	e822                	sd	s0,16(sp)
    80003648:	e426                	sd	s1,8(sp)
    8000364a:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000364c:	00014517          	auipc	a0,0x14
    80003650:	54450513          	addi	a0,a0,1348 # 80017b90 <tickslock>
    80003654:	ffffd097          	auipc	ra,0xffffd
    80003658:	590080e7          	jalr	1424(ra) # 80000be4 <acquire>
  xticks = ticks;
    8000365c:	00006497          	auipc	s1,0x6
    80003660:	9d44a483          	lw	s1,-1580(s1) # 80009030 <ticks>
  release(&tickslock);
    80003664:	00014517          	auipc	a0,0x14
    80003668:	52c50513          	addi	a0,a0,1324 # 80017b90 <tickslock>
    8000366c:	ffffd097          	auipc	ra,0xffffd
    80003670:	62c080e7          	jalr	1580(ra) # 80000c98 <release>
  return xticks;
}
    80003674:	02049513          	slli	a0,s1,0x20
    80003678:	9101                	srli	a0,a0,0x20
    8000367a:	60e2                	ld	ra,24(sp)
    8000367c:	6442                	ld	s0,16(sp)
    8000367e:	64a2                	ld	s1,8(sp)
    80003680:	6105                	addi	sp,sp,32
    80003682:	8082                	ret

0000000080003684 <sys_setcpu>:

uint64
sys_setcpu(void){
    80003684:	1101                	addi	sp,sp,-32
    80003686:	ec06                	sd	ra,24(sp)
    80003688:	e822                	sd	s0,16(sp)
    8000368a:	1000                	addi	s0,sp,32
  int cpid;
  if(argint(0, &cpid) < 0)
    8000368c:	fec40593          	addi	a1,s0,-20
    80003690:	4501                	li	a0,0
    80003692:	00000097          	auipc	ra,0x0
    80003696:	d10080e7          	jalr	-752(ra) # 800033a2 <argint>
    8000369a:	87aa                	mv	a5,a0
    return -1;
    8000369c:	557d                	li	a0,-1
  if(argint(0, &cpid) < 0)
    8000369e:	0007c863          	bltz	a5,800036ae <sys_setcpu+0x2a>

  return set_cpu(cpid);
    800036a2:	fec42503          	lw	a0,-20(s0)
    800036a6:	fffff097          	auipc	ra,0xfffff
    800036aa:	77a080e7          	jalr	1914(ra) # 80002e20 <set_cpu>

}
    800036ae:	60e2                	ld	ra,24(sp)
    800036b0:	6442                	ld	s0,16(sp)
    800036b2:	6105                	addi	sp,sp,32
    800036b4:	8082                	ret

00000000800036b6 <sys_getcpu>:

uint64
sys_getcpu(void){
    800036b6:	1141                	addi	sp,sp,-16
    800036b8:	e406                	sd	ra,8(sp)
    800036ba:	e022                	sd	s0,0(sp)
    800036bc:	0800                	addi	s0,sp,16
  return get_cpu();
    800036be:	fffff097          	auipc	ra,0xfffff
    800036c2:	7b0080e7          	jalr	1968(ra) # 80002e6e <get_cpu>
}
    800036c6:	60a2                	ld	ra,8(sp)
    800036c8:	6402                	ld	s0,0(sp)
    800036ca:	0141                	addi	sp,sp,16
    800036cc:	8082                	ret

00000000800036ce <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800036ce:	7179                	addi	sp,sp,-48
    800036d0:	f406                	sd	ra,40(sp)
    800036d2:	f022                	sd	s0,32(sp)
    800036d4:	ec26                	sd	s1,24(sp)
    800036d6:	e84a                	sd	s2,16(sp)
    800036d8:	e44e                	sd	s3,8(sp)
    800036da:	e052                	sd	s4,0(sp)
    800036dc:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800036de:	00005597          	auipc	a1,0x5
    800036e2:	eea58593          	addi	a1,a1,-278 # 800085c8 <syscalls+0xc0>
    800036e6:	00014517          	auipc	a0,0x14
    800036ea:	4c250513          	addi	a0,a0,1218 # 80017ba8 <bcache>
    800036ee:	ffffd097          	auipc	ra,0xffffd
    800036f2:	466080e7          	jalr	1126(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800036f6:	0001c797          	auipc	a5,0x1c
    800036fa:	4b278793          	addi	a5,a5,1202 # 8001fba8 <bcache+0x8000>
    800036fe:	0001c717          	auipc	a4,0x1c
    80003702:	71270713          	addi	a4,a4,1810 # 8001fe10 <bcache+0x8268>
    80003706:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000370a:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000370e:	00014497          	auipc	s1,0x14
    80003712:	4b248493          	addi	s1,s1,1202 # 80017bc0 <bcache+0x18>
    b->next = bcache.head.next;
    80003716:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003718:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000371a:	00005a17          	auipc	s4,0x5
    8000371e:	eb6a0a13          	addi	s4,s4,-330 # 800085d0 <syscalls+0xc8>
    b->next = bcache.head.next;
    80003722:	2b893783          	ld	a5,696(s2)
    80003726:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003728:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000372c:	85d2                	mv	a1,s4
    8000372e:	01048513          	addi	a0,s1,16
    80003732:	00001097          	auipc	ra,0x1
    80003736:	4bc080e7          	jalr	1212(ra) # 80004bee <initsleeplock>
    bcache.head.next->prev = b;
    8000373a:	2b893783          	ld	a5,696(s2)
    8000373e:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003740:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003744:	45848493          	addi	s1,s1,1112
    80003748:	fd349de3          	bne	s1,s3,80003722 <binit+0x54>
  }
}
    8000374c:	70a2                	ld	ra,40(sp)
    8000374e:	7402                	ld	s0,32(sp)
    80003750:	64e2                	ld	s1,24(sp)
    80003752:	6942                	ld	s2,16(sp)
    80003754:	69a2                	ld	s3,8(sp)
    80003756:	6a02                	ld	s4,0(sp)
    80003758:	6145                	addi	sp,sp,48
    8000375a:	8082                	ret

000000008000375c <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000375c:	7179                	addi	sp,sp,-48
    8000375e:	f406                	sd	ra,40(sp)
    80003760:	f022                	sd	s0,32(sp)
    80003762:	ec26                	sd	s1,24(sp)
    80003764:	e84a                	sd	s2,16(sp)
    80003766:	e44e                	sd	s3,8(sp)
    80003768:	1800                	addi	s0,sp,48
    8000376a:	89aa                	mv	s3,a0
    8000376c:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    8000376e:	00014517          	auipc	a0,0x14
    80003772:	43a50513          	addi	a0,a0,1082 # 80017ba8 <bcache>
    80003776:	ffffd097          	auipc	ra,0xffffd
    8000377a:	46e080e7          	jalr	1134(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000377e:	0001c497          	auipc	s1,0x1c
    80003782:	6e24b483          	ld	s1,1762(s1) # 8001fe60 <bcache+0x82b8>
    80003786:	0001c797          	auipc	a5,0x1c
    8000378a:	68a78793          	addi	a5,a5,1674 # 8001fe10 <bcache+0x8268>
    8000378e:	02f48f63          	beq	s1,a5,800037cc <bread+0x70>
    80003792:	873e                	mv	a4,a5
    80003794:	a021                	j	8000379c <bread+0x40>
    80003796:	68a4                	ld	s1,80(s1)
    80003798:	02e48a63          	beq	s1,a4,800037cc <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000379c:	449c                	lw	a5,8(s1)
    8000379e:	ff379ce3          	bne	a5,s3,80003796 <bread+0x3a>
    800037a2:	44dc                	lw	a5,12(s1)
    800037a4:	ff2799e3          	bne	a5,s2,80003796 <bread+0x3a>
      b->refcnt++;
    800037a8:	40bc                	lw	a5,64(s1)
    800037aa:	2785                	addiw	a5,a5,1
    800037ac:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800037ae:	00014517          	auipc	a0,0x14
    800037b2:	3fa50513          	addi	a0,a0,1018 # 80017ba8 <bcache>
    800037b6:	ffffd097          	auipc	ra,0xffffd
    800037ba:	4e2080e7          	jalr	1250(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800037be:	01048513          	addi	a0,s1,16
    800037c2:	00001097          	auipc	ra,0x1
    800037c6:	466080e7          	jalr	1126(ra) # 80004c28 <acquiresleep>
      return b;
    800037ca:	a8b9                	j	80003828 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800037cc:	0001c497          	auipc	s1,0x1c
    800037d0:	68c4b483          	ld	s1,1676(s1) # 8001fe58 <bcache+0x82b0>
    800037d4:	0001c797          	auipc	a5,0x1c
    800037d8:	63c78793          	addi	a5,a5,1596 # 8001fe10 <bcache+0x8268>
    800037dc:	00f48863          	beq	s1,a5,800037ec <bread+0x90>
    800037e0:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800037e2:	40bc                	lw	a5,64(s1)
    800037e4:	cf81                	beqz	a5,800037fc <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800037e6:	64a4                	ld	s1,72(s1)
    800037e8:	fee49de3          	bne	s1,a4,800037e2 <bread+0x86>
  panic("bget: no buffers");
    800037ec:	00005517          	auipc	a0,0x5
    800037f0:	dec50513          	addi	a0,a0,-532 # 800085d8 <syscalls+0xd0>
    800037f4:	ffffd097          	auipc	ra,0xffffd
    800037f8:	d4a080e7          	jalr	-694(ra) # 8000053e <panic>
      b->dev = dev;
    800037fc:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003800:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003804:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003808:	4785                	li	a5,1
    8000380a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000380c:	00014517          	auipc	a0,0x14
    80003810:	39c50513          	addi	a0,a0,924 # 80017ba8 <bcache>
    80003814:	ffffd097          	auipc	ra,0xffffd
    80003818:	484080e7          	jalr	1156(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    8000381c:	01048513          	addi	a0,s1,16
    80003820:	00001097          	auipc	ra,0x1
    80003824:	408080e7          	jalr	1032(ra) # 80004c28 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003828:	409c                	lw	a5,0(s1)
    8000382a:	cb89                	beqz	a5,8000383c <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000382c:	8526                	mv	a0,s1
    8000382e:	70a2                	ld	ra,40(sp)
    80003830:	7402                	ld	s0,32(sp)
    80003832:	64e2                	ld	s1,24(sp)
    80003834:	6942                	ld	s2,16(sp)
    80003836:	69a2                	ld	s3,8(sp)
    80003838:	6145                	addi	sp,sp,48
    8000383a:	8082                	ret
    virtio_disk_rw(b, 0);
    8000383c:	4581                	li	a1,0
    8000383e:	8526                	mv	a0,s1
    80003840:	00003097          	auipc	ra,0x3
    80003844:	f06080e7          	jalr	-250(ra) # 80006746 <virtio_disk_rw>
    b->valid = 1;
    80003848:	4785                	li	a5,1
    8000384a:	c09c                	sw	a5,0(s1)
  return b;
    8000384c:	b7c5                	j	8000382c <bread+0xd0>

000000008000384e <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000384e:	1101                	addi	sp,sp,-32
    80003850:	ec06                	sd	ra,24(sp)
    80003852:	e822                	sd	s0,16(sp)
    80003854:	e426                	sd	s1,8(sp)
    80003856:	1000                	addi	s0,sp,32
    80003858:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000385a:	0541                	addi	a0,a0,16
    8000385c:	00001097          	auipc	ra,0x1
    80003860:	466080e7          	jalr	1126(ra) # 80004cc2 <holdingsleep>
    80003864:	cd01                	beqz	a0,8000387c <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003866:	4585                	li	a1,1
    80003868:	8526                	mv	a0,s1
    8000386a:	00003097          	auipc	ra,0x3
    8000386e:	edc080e7          	jalr	-292(ra) # 80006746 <virtio_disk_rw>
}
    80003872:	60e2                	ld	ra,24(sp)
    80003874:	6442                	ld	s0,16(sp)
    80003876:	64a2                	ld	s1,8(sp)
    80003878:	6105                	addi	sp,sp,32
    8000387a:	8082                	ret
    panic("bwrite");
    8000387c:	00005517          	auipc	a0,0x5
    80003880:	d7450513          	addi	a0,a0,-652 # 800085f0 <syscalls+0xe8>
    80003884:	ffffd097          	auipc	ra,0xffffd
    80003888:	cba080e7          	jalr	-838(ra) # 8000053e <panic>

000000008000388c <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000388c:	1101                	addi	sp,sp,-32
    8000388e:	ec06                	sd	ra,24(sp)
    80003890:	e822                	sd	s0,16(sp)
    80003892:	e426                	sd	s1,8(sp)
    80003894:	e04a                	sd	s2,0(sp)
    80003896:	1000                	addi	s0,sp,32
    80003898:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000389a:	01050913          	addi	s2,a0,16
    8000389e:	854a                	mv	a0,s2
    800038a0:	00001097          	auipc	ra,0x1
    800038a4:	422080e7          	jalr	1058(ra) # 80004cc2 <holdingsleep>
    800038a8:	c92d                	beqz	a0,8000391a <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800038aa:	854a                	mv	a0,s2
    800038ac:	00001097          	auipc	ra,0x1
    800038b0:	3d2080e7          	jalr	978(ra) # 80004c7e <releasesleep>

  acquire(&bcache.lock);
    800038b4:	00014517          	auipc	a0,0x14
    800038b8:	2f450513          	addi	a0,a0,756 # 80017ba8 <bcache>
    800038bc:	ffffd097          	auipc	ra,0xffffd
    800038c0:	328080e7          	jalr	808(ra) # 80000be4 <acquire>
  b->refcnt--;
    800038c4:	40bc                	lw	a5,64(s1)
    800038c6:	37fd                	addiw	a5,a5,-1
    800038c8:	0007871b          	sext.w	a4,a5
    800038cc:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800038ce:	eb05                	bnez	a4,800038fe <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800038d0:	68bc                	ld	a5,80(s1)
    800038d2:	64b8                	ld	a4,72(s1)
    800038d4:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800038d6:	64bc                	ld	a5,72(s1)
    800038d8:	68b8                	ld	a4,80(s1)
    800038da:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800038dc:	0001c797          	auipc	a5,0x1c
    800038e0:	2cc78793          	addi	a5,a5,716 # 8001fba8 <bcache+0x8000>
    800038e4:	2b87b703          	ld	a4,696(a5)
    800038e8:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800038ea:	0001c717          	auipc	a4,0x1c
    800038ee:	52670713          	addi	a4,a4,1318 # 8001fe10 <bcache+0x8268>
    800038f2:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800038f4:	2b87b703          	ld	a4,696(a5)
    800038f8:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800038fa:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800038fe:	00014517          	auipc	a0,0x14
    80003902:	2aa50513          	addi	a0,a0,682 # 80017ba8 <bcache>
    80003906:	ffffd097          	auipc	ra,0xffffd
    8000390a:	392080e7          	jalr	914(ra) # 80000c98 <release>
}
    8000390e:	60e2                	ld	ra,24(sp)
    80003910:	6442                	ld	s0,16(sp)
    80003912:	64a2                	ld	s1,8(sp)
    80003914:	6902                	ld	s2,0(sp)
    80003916:	6105                	addi	sp,sp,32
    80003918:	8082                	ret
    panic("brelse");
    8000391a:	00005517          	auipc	a0,0x5
    8000391e:	cde50513          	addi	a0,a0,-802 # 800085f8 <syscalls+0xf0>
    80003922:	ffffd097          	auipc	ra,0xffffd
    80003926:	c1c080e7          	jalr	-996(ra) # 8000053e <panic>

000000008000392a <bpin>:

void
bpin(struct buf *b) {
    8000392a:	1101                	addi	sp,sp,-32
    8000392c:	ec06                	sd	ra,24(sp)
    8000392e:	e822                	sd	s0,16(sp)
    80003930:	e426                	sd	s1,8(sp)
    80003932:	1000                	addi	s0,sp,32
    80003934:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003936:	00014517          	auipc	a0,0x14
    8000393a:	27250513          	addi	a0,a0,626 # 80017ba8 <bcache>
    8000393e:	ffffd097          	auipc	ra,0xffffd
    80003942:	2a6080e7          	jalr	678(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003946:	40bc                	lw	a5,64(s1)
    80003948:	2785                	addiw	a5,a5,1
    8000394a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000394c:	00014517          	auipc	a0,0x14
    80003950:	25c50513          	addi	a0,a0,604 # 80017ba8 <bcache>
    80003954:	ffffd097          	auipc	ra,0xffffd
    80003958:	344080e7          	jalr	836(ra) # 80000c98 <release>
}
    8000395c:	60e2                	ld	ra,24(sp)
    8000395e:	6442                	ld	s0,16(sp)
    80003960:	64a2                	ld	s1,8(sp)
    80003962:	6105                	addi	sp,sp,32
    80003964:	8082                	ret

0000000080003966 <bunpin>:

void
bunpin(struct buf *b) {
    80003966:	1101                	addi	sp,sp,-32
    80003968:	ec06                	sd	ra,24(sp)
    8000396a:	e822                	sd	s0,16(sp)
    8000396c:	e426                	sd	s1,8(sp)
    8000396e:	1000                	addi	s0,sp,32
    80003970:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003972:	00014517          	auipc	a0,0x14
    80003976:	23650513          	addi	a0,a0,566 # 80017ba8 <bcache>
    8000397a:	ffffd097          	auipc	ra,0xffffd
    8000397e:	26a080e7          	jalr	618(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003982:	40bc                	lw	a5,64(s1)
    80003984:	37fd                	addiw	a5,a5,-1
    80003986:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003988:	00014517          	auipc	a0,0x14
    8000398c:	22050513          	addi	a0,a0,544 # 80017ba8 <bcache>
    80003990:	ffffd097          	auipc	ra,0xffffd
    80003994:	308080e7          	jalr	776(ra) # 80000c98 <release>
}
    80003998:	60e2                	ld	ra,24(sp)
    8000399a:	6442                	ld	s0,16(sp)
    8000399c:	64a2                	ld	s1,8(sp)
    8000399e:	6105                	addi	sp,sp,32
    800039a0:	8082                	ret

00000000800039a2 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800039a2:	1101                	addi	sp,sp,-32
    800039a4:	ec06                	sd	ra,24(sp)
    800039a6:	e822                	sd	s0,16(sp)
    800039a8:	e426                	sd	s1,8(sp)
    800039aa:	e04a                	sd	s2,0(sp)
    800039ac:	1000                	addi	s0,sp,32
    800039ae:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800039b0:	00d5d59b          	srliw	a1,a1,0xd
    800039b4:	0001d797          	auipc	a5,0x1d
    800039b8:	8d07a783          	lw	a5,-1840(a5) # 80020284 <sb+0x1c>
    800039bc:	9dbd                	addw	a1,a1,a5
    800039be:	00000097          	auipc	ra,0x0
    800039c2:	d9e080e7          	jalr	-610(ra) # 8000375c <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800039c6:	0074f713          	andi	a4,s1,7
    800039ca:	4785                	li	a5,1
    800039cc:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800039d0:	14ce                	slli	s1,s1,0x33
    800039d2:	90d9                	srli	s1,s1,0x36
    800039d4:	00950733          	add	a4,a0,s1
    800039d8:	05874703          	lbu	a4,88(a4)
    800039dc:	00e7f6b3          	and	a3,a5,a4
    800039e0:	c69d                	beqz	a3,80003a0e <bfree+0x6c>
    800039e2:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800039e4:	94aa                	add	s1,s1,a0
    800039e6:	fff7c793          	not	a5,a5
    800039ea:	8ff9                	and	a5,a5,a4
    800039ec:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800039f0:	00001097          	auipc	ra,0x1
    800039f4:	118080e7          	jalr	280(ra) # 80004b08 <log_write>
  brelse(bp);
    800039f8:	854a                	mv	a0,s2
    800039fa:	00000097          	auipc	ra,0x0
    800039fe:	e92080e7          	jalr	-366(ra) # 8000388c <brelse>
}
    80003a02:	60e2                	ld	ra,24(sp)
    80003a04:	6442                	ld	s0,16(sp)
    80003a06:	64a2                	ld	s1,8(sp)
    80003a08:	6902                	ld	s2,0(sp)
    80003a0a:	6105                	addi	sp,sp,32
    80003a0c:	8082                	ret
    panic("freeing free block");
    80003a0e:	00005517          	auipc	a0,0x5
    80003a12:	bf250513          	addi	a0,a0,-1038 # 80008600 <syscalls+0xf8>
    80003a16:	ffffd097          	auipc	ra,0xffffd
    80003a1a:	b28080e7          	jalr	-1240(ra) # 8000053e <panic>

0000000080003a1e <balloc>:
{
    80003a1e:	711d                	addi	sp,sp,-96
    80003a20:	ec86                	sd	ra,88(sp)
    80003a22:	e8a2                	sd	s0,80(sp)
    80003a24:	e4a6                	sd	s1,72(sp)
    80003a26:	e0ca                	sd	s2,64(sp)
    80003a28:	fc4e                	sd	s3,56(sp)
    80003a2a:	f852                	sd	s4,48(sp)
    80003a2c:	f456                	sd	s5,40(sp)
    80003a2e:	f05a                	sd	s6,32(sp)
    80003a30:	ec5e                	sd	s7,24(sp)
    80003a32:	e862                	sd	s8,16(sp)
    80003a34:	e466                	sd	s9,8(sp)
    80003a36:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003a38:	0001d797          	auipc	a5,0x1d
    80003a3c:	8347a783          	lw	a5,-1996(a5) # 8002026c <sb+0x4>
    80003a40:	cbd1                	beqz	a5,80003ad4 <balloc+0xb6>
    80003a42:	8baa                	mv	s7,a0
    80003a44:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003a46:	0001db17          	auipc	s6,0x1d
    80003a4a:	822b0b13          	addi	s6,s6,-2014 # 80020268 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003a4e:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003a50:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003a52:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003a54:	6c89                	lui	s9,0x2
    80003a56:	a831                	j	80003a72 <balloc+0x54>
    brelse(bp);
    80003a58:	854a                	mv	a0,s2
    80003a5a:	00000097          	auipc	ra,0x0
    80003a5e:	e32080e7          	jalr	-462(ra) # 8000388c <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003a62:	015c87bb          	addw	a5,s9,s5
    80003a66:	00078a9b          	sext.w	s5,a5
    80003a6a:	004b2703          	lw	a4,4(s6)
    80003a6e:	06eaf363          	bgeu	s5,a4,80003ad4 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003a72:	41fad79b          	sraiw	a5,s5,0x1f
    80003a76:	0137d79b          	srliw	a5,a5,0x13
    80003a7a:	015787bb          	addw	a5,a5,s5
    80003a7e:	40d7d79b          	sraiw	a5,a5,0xd
    80003a82:	01cb2583          	lw	a1,28(s6)
    80003a86:	9dbd                	addw	a1,a1,a5
    80003a88:	855e                	mv	a0,s7
    80003a8a:	00000097          	auipc	ra,0x0
    80003a8e:	cd2080e7          	jalr	-814(ra) # 8000375c <bread>
    80003a92:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003a94:	004b2503          	lw	a0,4(s6)
    80003a98:	000a849b          	sext.w	s1,s5
    80003a9c:	8662                	mv	a2,s8
    80003a9e:	faa4fde3          	bgeu	s1,a0,80003a58 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003aa2:	41f6579b          	sraiw	a5,a2,0x1f
    80003aa6:	01d7d69b          	srliw	a3,a5,0x1d
    80003aaa:	00c6873b          	addw	a4,a3,a2
    80003aae:	00777793          	andi	a5,a4,7
    80003ab2:	9f95                	subw	a5,a5,a3
    80003ab4:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003ab8:	4037571b          	sraiw	a4,a4,0x3
    80003abc:	00e906b3          	add	a3,s2,a4
    80003ac0:	0586c683          	lbu	a3,88(a3)
    80003ac4:	00d7f5b3          	and	a1,a5,a3
    80003ac8:	cd91                	beqz	a1,80003ae4 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003aca:	2605                	addiw	a2,a2,1
    80003acc:	2485                	addiw	s1,s1,1
    80003ace:	fd4618e3          	bne	a2,s4,80003a9e <balloc+0x80>
    80003ad2:	b759                	j	80003a58 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003ad4:	00005517          	auipc	a0,0x5
    80003ad8:	b4450513          	addi	a0,a0,-1212 # 80008618 <syscalls+0x110>
    80003adc:	ffffd097          	auipc	ra,0xffffd
    80003ae0:	a62080e7          	jalr	-1438(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003ae4:	974a                	add	a4,a4,s2
    80003ae6:	8fd5                	or	a5,a5,a3
    80003ae8:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003aec:	854a                	mv	a0,s2
    80003aee:	00001097          	auipc	ra,0x1
    80003af2:	01a080e7          	jalr	26(ra) # 80004b08 <log_write>
        brelse(bp);
    80003af6:	854a                	mv	a0,s2
    80003af8:	00000097          	auipc	ra,0x0
    80003afc:	d94080e7          	jalr	-620(ra) # 8000388c <brelse>
  bp = bread(dev, bno);
    80003b00:	85a6                	mv	a1,s1
    80003b02:	855e                	mv	a0,s7
    80003b04:	00000097          	auipc	ra,0x0
    80003b08:	c58080e7          	jalr	-936(ra) # 8000375c <bread>
    80003b0c:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003b0e:	40000613          	li	a2,1024
    80003b12:	4581                	li	a1,0
    80003b14:	05850513          	addi	a0,a0,88
    80003b18:	ffffd097          	auipc	ra,0xffffd
    80003b1c:	1c8080e7          	jalr	456(ra) # 80000ce0 <memset>
  log_write(bp);
    80003b20:	854a                	mv	a0,s2
    80003b22:	00001097          	auipc	ra,0x1
    80003b26:	fe6080e7          	jalr	-26(ra) # 80004b08 <log_write>
  brelse(bp);
    80003b2a:	854a                	mv	a0,s2
    80003b2c:	00000097          	auipc	ra,0x0
    80003b30:	d60080e7          	jalr	-672(ra) # 8000388c <brelse>
}
    80003b34:	8526                	mv	a0,s1
    80003b36:	60e6                	ld	ra,88(sp)
    80003b38:	6446                	ld	s0,80(sp)
    80003b3a:	64a6                	ld	s1,72(sp)
    80003b3c:	6906                	ld	s2,64(sp)
    80003b3e:	79e2                	ld	s3,56(sp)
    80003b40:	7a42                	ld	s4,48(sp)
    80003b42:	7aa2                	ld	s5,40(sp)
    80003b44:	7b02                	ld	s6,32(sp)
    80003b46:	6be2                	ld	s7,24(sp)
    80003b48:	6c42                	ld	s8,16(sp)
    80003b4a:	6ca2                	ld	s9,8(sp)
    80003b4c:	6125                	addi	sp,sp,96
    80003b4e:	8082                	ret

0000000080003b50 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003b50:	7179                	addi	sp,sp,-48
    80003b52:	f406                	sd	ra,40(sp)
    80003b54:	f022                	sd	s0,32(sp)
    80003b56:	ec26                	sd	s1,24(sp)
    80003b58:	e84a                	sd	s2,16(sp)
    80003b5a:	e44e                	sd	s3,8(sp)
    80003b5c:	e052                	sd	s4,0(sp)
    80003b5e:	1800                	addi	s0,sp,48
    80003b60:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003b62:	47ad                	li	a5,11
    80003b64:	04b7fe63          	bgeu	a5,a1,80003bc0 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003b68:	ff45849b          	addiw	s1,a1,-12
    80003b6c:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003b70:	0ff00793          	li	a5,255
    80003b74:	0ae7e363          	bltu	a5,a4,80003c1a <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003b78:	08052583          	lw	a1,128(a0)
    80003b7c:	c5ad                	beqz	a1,80003be6 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003b7e:	00092503          	lw	a0,0(s2)
    80003b82:	00000097          	auipc	ra,0x0
    80003b86:	bda080e7          	jalr	-1062(ra) # 8000375c <bread>
    80003b8a:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003b8c:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003b90:	02049593          	slli	a1,s1,0x20
    80003b94:	9181                	srli	a1,a1,0x20
    80003b96:	058a                	slli	a1,a1,0x2
    80003b98:	00b784b3          	add	s1,a5,a1
    80003b9c:	0004a983          	lw	s3,0(s1)
    80003ba0:	04098d63          	beqz	s3,80003bfa <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003ba4:	8552                	mv	a0,s4
    80003ba6:	00000097          	auipc	ra,0x0
    80003baa:	ce6080e7          	jalr	-794(ra) # 8000388c <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003bae:	854e                	mv	a0,s3
    80003bb0:	70a2                	ld	ra,40(sp)
    80003bb2:	7402                	ld	s0,32(sp)
    80003bb4:	64e2                	ld	s1,24(sp)
    80003bb6:	6942                	ld	s2,16(sp)
    80003bb8:	69a2                	ld	s3,8(sp)
    80003bba:	6a02                	ld	s4,0(sp)
    80003bbc:	6145                	addi	sp,sp,48
    80003bbe:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003bc0:	02059493          	slli	s1,a1,0x20
    80003bc4:	9081                	srli	s1,s1,0x20
    80003bc6:	048a                	slli	s1,s1,0x2
    80003bc8:	94aa                	add	s1,s1,a0
    80003bca:	0504a983          	lw	s3,80(s1)
    80003bce:	fe0990e3          	bnez	s3,80003bae <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003bd2:	4108                	lw	a0,0(a0)
    80003bd4:	00000097          	auipc	ra,0x0
    80003bd8:	e4a080e7          	jalr	-438(ra) # 80003a1e <balloc>
    80003bdc:	0005099b          	sext.w	s3,a0
    80003be0:	0534a823          	sw	s3,80(s1)
    80003be4:	b7e9                	j	80003bae <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003be6:	4108                	lw	a0,0(a0)
    80003be8:	00000097          	auipc	ra,0x0
    80003bec:	e36080e7          	jalr	-458(ra) # 80003a1e <balloc>
    80003bf0:	0005059b          	sext.w	a1,a0
    80003bf4:	08b92023          	sw	a1,128(s2)
    80003bf8:	b759                	j	80003b7e <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003bfa:	00092503          	lw	a0,0(s2)
    80003bfe:	00000097          	auipc	ra,0x0
    80003c02:	e20080e7          	jalr	-480(ra) # 80003a1e <balloc>
    80003c06:	0005099b          	sext.w	s3,a0
    80003c0a:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003c0e:	8552                	mv	a0,s4
    80003c10:	00001097          	auipc	ra,0x1
    80003c14:	ef8080e7          	jalr	-264(ra) # 80004b08 <log_write>
    80003c18:	b771                	j	80003ba4 <bmap+0x54>
  panic("bmap: out of range");
    80003c1a:	00005517          	auipc	a0,0x5
    80003c1e:	a1650513          	addi	a0,a0,-1514 # 80008630 <syscalls+0x128>
    80003c22:	ffffd097          	auipc	ra,0xffffd
    80003c26:	91c080e7          	jalr	-1764(ra) # 8000053e <panic>

0000000080003c2a <iget>:
{
    80003c2a:	7179                	addi	sp,sp,-48
    80003c2c:	f406                	sd	ra,40(sp)
    80003c2e:	f022                	sd	s0,32(sp)
    80003c30:	ec26                	sd	s1,24(sp)
    80003c32:	e84a                	sd	s2,16(sp)
    80003c34:	e44e                	sd	s3,8(sp)
    80003c36:	e052                	sd	s4,0(sp)
    80003c38:	1800                	addi	s0,sp,48
    80003c3a:	89aa                	mv	s3,a0
    80003c3c:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003c3e:	0001c517          	auipc	a0,0x1c
    80003c42:	64a50513          	addi	a0,a0,1610 # 80020288 <itable>
    80003c46:	ffffd097          	auipc	ra,0xffffd
    80003c4a:	f9e080e7          	jalr	-98(ra) # 80000be4 <acquire>
  empty = 0;
    80003c4e:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003c50:	0001c497          	auipc	s1,0x1c
    80003c54:	65048493          	addi	s1,s1,1616 # 800202a0 <itable+0x18>
    80003c58:	0001e697          	auipc	a3,0x1e
    80003c5c:	0d868693          	addi	a3,a3,216 # 80021d30 <log>
    80003c60:	a039                	j	80003c6e <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003c62:	02090b63          	beqz	s2,80003c98 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003c66:	08848493          	addi	s1,s1,136
    80003c6a:	02d48a63          	beq	s1,a3,80003c9e <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003c6e:	449c                	lw	a5,8(s1)
    80003c70:	fef059e3          	blez	a5,80003c62 <iget+0x38>
    80003c74:	4098                	lw	a4,0(s1)
    80003c76:	ff3716e3          	bne	a4,s3,80003c62 <iget+0x38>
    80003c7a:	40d8                	lw	a4,4(s1)
    80003c7c:	ff4713e3          	bne	a4,s4,80003c62 <iget+0x38>
      ip->ref++;
    80003c80:	2785                	addiw	a5,a5,1
    80003c82:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003c84:	0001c517          	auipc	a0,0x1c
    80003c88:	60450513          	addi	a0,a0,1540 # 80020288 <itable>
    80003c8c:	ffffd097          	auipc	ra,0xffffd
    80003c90:	00c080e7          	jalr	12(ra) # 80000c98 <release>
      return ip;
    80003c94:	8926                	mv	s2,s1
    80003c96:	a03d                	j	80003cc4 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003c98:	f7f9                	bnez	a5,80003c66 <iget+0x3c>
    80003c9a:	8926                	mv	s2,s1
    80003c9c:	b7e9                	j	80003c66 <iget+0x3c>
  if(empty == 0)
    80003c9e:	02090c63          	beqz	s2,80003cd6 <iget+0xac>
  ip->dev = dev;
    80003ca2:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003ca6:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003caa:	4785                	li	a5,1
    80003cac:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003cb0:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003cb4:	0001c517          	auipc	a0,0x1c
    80003cb8:	5d450513          	addi	a0,a0,1492 # 80020288 <itable>
    80003cbc:	ffffd097          	auipc	ra,0xffffd
    80003cc0:	fdc080e7          	jalr	-36(ra) # 80000c98 <release>
}
    80003cc4:	854a                	mv	a0,s2
    80003cc6:	70a2                	ld	ra,40(sp)
    80003cc8:	7402                	ld	s0,32(sp)
    80003cca:	64e2                	ld	s1,24(sp)
    80003ccc:	6942                	ld	s2,16(sp)
    80003cce:	69a2                	ld	s3,8(sp)
    80003cd0:	6a02                	ld	s4,0(sp)
    80003cd2:	6145                	addi	sp,sp,48
    80003cd4:	8082                	ret
    panic("iget: no inodes");
    80003cd6:	00005517          	auipc	a0,0x5
    80003cda:	97250513          	addi	a0,a0,-1678 # 80008648 <syscalls+0x140>
    80003cde:	ffffd097          	auipc	ra,0xffffd
    80003ce2:	860080e7          	jalr	-1952(ra) # 8000053e <panic>

0000000080003ce6 <fsinit>:
fsinit(int dev) {
    80003ce6:	7179                	addi	sp,sp,-48
    80003ce8:	f406                	sd	ra,40(sp)
    80003cea:	f022                	sd	s0,32(sp)
    80003cec:	ec26                	sd	s1,24(sp)
    80003cee:	e84a                	sd	s2,16(sp)
    80003cf0:	e44e                	sd	s3,8(sp)
    80003cf2:	1800                	addi	s0,sp,48
    80003cf4:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003cf6:	4585                	li	a1,1
    80003cf8:	00000097          	auipc	ra,0x0
    80003cfc:	a64080e7          	jalr	-1436(ra) # 8000375c <bread>
    80003d00:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003d02:	0001c997          	auipc	s3,0x1c
    80003d06:	56698993          	addi	s3,s3,1382 # 80020268 <sb>
    80003d0a:	02000613          	li	a2,32
    80003d0e:	05850593          	addi	a1,a0,88
    80003d12:	854e                	mv	a0,s3
    80003d14:	ffffd097          	auipc	ra,0xffffd
    80003d18:	02c080e7          	jalr	44(ra) # 80000d40 <memmove>
  brelse(bp);
    80003d1c:	8526                	mv	a0,s1
    80003d1e:	00000097          	auipc	ra,0x0
    80003d22:	b6e080e7          	jalr	-1170(ra) # 8000388c <brelse>
  if(sb.magic != FSMAGIC)
    80003d26:	0009a703          	lw	a4,0(s3)
    80003d2a:	102037b7          	lui	a5,0x10203
    80003d2e:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003d32:	02f71263          	bne	a4,a5,80003d56 <fsinit+0x70>
  initlog(dev, &sb);
    80003d36:	0001c597          	auipc	a1,0x1c
    80003d3a:	53258593          	addi	a1,a1,1330 # 80020268 <sb>
    80003d3e:	854a                	mv	a0,s2
    80003d40:	00001097          	auipc	ra,0x1
    80003d44:	b4c080e7          	jalr	-1204(ra) # 8000488c <initlog>
}
    80003d48:	70a2                	ld	ra,40(sp)
    80003d4a:	7402                	ld	s0,32(sp)
    80003d4c:	64e2                	ld	s1,24(sp)
    80003d4e:	6942                	ld	s2,16(sp)
    80003d50:	69a2                	ld	s3,8(sp)
    80003d52:	6145                	addi	sp,sp,48
    80003d54:	8082                	ret
    panic("invalid file system");
    80003d56:	00005517          	auipc	a0,0x5
    80003d5a:	90250513          	addi	a0,a0,-1790 # 80008658 <syscalls+0x150>
    80003d5e:	ffffc097          	auipc	ra,0xffffc
    80003d62:	7e0080e7          	jalr	2016(ra) # 8000053e <panic>

0000000080003d66 <iinit>:
{
    80003d66:	7179                	addi	sp,sp,-48
    80003d68:	f406                	sd	ra,40(sp)
    80003d6a:	f022                	sd	s0,32(sp)
    80003d6c:	ec26                	sd	s1,24(sp)
    80003d6e:	e84a                	sd	s2,16(sp)
    80003d70:	e44e                	sd	s3,8(sp)
    80003d72:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003d74:	00005597          	auipc	a1,0x5
    80003d78:	8fc58593          	addi	a1,a1,-1796 # 80008670 <syscalls+0x168>
    80003d7c:	0001c517          	auipc	a0,0x1c
    80003d80:	50c50513          	addi	a0,a0,1292 # 80020288 <itable>
    80003d84:	ffffd097          	auipc	ra,0xffffd
    80003d88:	dd0080e7          	jalr	-560(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003d8c:	0001c497          	auipc	s1,0x1c
    80003d90:	52448493          	addi	s1,s1,1316 # 800202b0 <itable+0x28>
    80003d94:	0001e997          	auipc	s3,0x1e
    80003d98:	fac98993          	addi	s3,s3,-84 # 80021d40 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003d9c:	00005917          	auipc	s2,0x5
    80003da0:	8dc90913          	addi	s2,s2,-1828 # 80008678 <syscalls+0x170>
    80003da4:	85ca                	mv	a1,s2
    80003da6:	8526                	mv	a0,s1
    80003da8:	00001097          	auipc	ra,0x1
    80003dac:	e46080e7          	jalr	-442(ra) # 80004bee <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003db0:	08848493          	addi	s1,s1,136
    80003db4:	ff3498e3          	bne	s1,s3,80003da4 <iinit+0x3e>
}
    80003db8:	70a2                	ld	ra,40(sp)
    80003dba:	7402                	ld	s0,32(sp)
    80003dbc:	64e2                	ld	s1,24(sp)
    80003dbe:	6942                	ld	s2,16(sp)
    80003dc0:	69a2                	ld	s3,8(sp)
    80003dc2:	6145                	addi	sp,sp,48
    80003dc4:	8082                	ret

0000000080003dc6 <ialloc>:
{
    80003dc6:	715d                	addi	sp,sp,-80
    80003dc8:	e486                	sd	ra,72(sp)
    80003dca:	e0a2                	sd	s0,64(sp)
    80003dcc:	fc26                	sd	s1,56(sp)
    80003dce:	f84a                	sd	s2,48(sp)
    80003dd0:	f44e                	sd	s3,40(sp)
    80003dd2:	f052                	sd	s4,32(sp)
    80003dd4:	ec56                	sd	s5,24(sp)
    80003dd6:	e85a                	sd	s6,16(sp)
    80003dd8:	e45e                	sd	s7,8(sp)
    80003dda:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003ddc:	0001c717          	auipc	a4,0x1c
    80003de0:	49872703          	lw	a4,1176(a4) # 80020274 <sb+0xc>
    80003de4:	4785                	li	a5,1
    80003de6:	04e7fa63          	bgeu	a5,a4,80003e3a <ialloc+0x74>
    80003dea:	8aaa                	mv	s5,a0
    80003dec:	8bae                	mv	s7,a1
    80003dee:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003df0:	0001ca17          	auipc	s4,0x1c
    80003df4:	478a0a13          	addi	s4,s4,1144 # 80020268 <sb>
    80003df8:	00048b1b          	sext.w	s6,s1
    80003dfc:	0044d593          	srli	a1,s1,0x4
    80003e00:	018a2783          	lw	a5,24(s4)
    80003e04:	9dbd                	addw	a1,a1,a5
    80003e06:	8556                	mv	a0,s5
    80003e08:	00000097          	auipc	ra,0x0
    80003e0c:	954080e7          	jalr	-1708(ra) # 8000375c <bread>
    80003e10:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003e12:	05850993          	addi	s3,a0,88
    80003e16:	00f4f793          	andi	a5,s1,15
    80003e1a:	079a                	slli	a5,a5,0x6
    80003e1c:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003e1e:	00099783          	lh	a5,0(s3)
    80003e22:	c785                	beqz	a5,80003e4a <ialloc+0x84>
    brelse(bp);
    80003e24:	00000097          	auipc	ra,0x0
    80003e28:	a68080e7          	jalr	-1432(ra) # 8000388c <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003e2c:	0485                	addi	s1,s1,1
    80003e2e:	00ca2703          	lw	a4,12(s4)
    80003e32:	0004879b          	sext.w	a5,s1
    80003e36:	fce7e1e3          	bltu	a5,a4,80003df8 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003e3a:	00005517          	auipc	a0,0x5
    80003e3e:	84650513          	addi	a0,a0,-1978 # 80008680 <syscalls+0x178>
    80003e42:	ffffc097          	auipc	ra,0xffffc
    80003e46:	6fc080e7          	jalr	1788(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003e4a:	04000613          	li	a2,64
    80003e4e:	4581                	li	a1,0
    80003e50:	854e                	mv	a0,s3
    80003e52:	ffffd097          	auipc	ra,0xffffd
    80003e56:	e8e080e7          	jalr	-370(ra) # 80000ce0 <memset>
      dip->type = type;
    80003e5a:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003e5e:	854a                	mv	a0,s2
    80003e60:	00001097          	auipc	ra,0x1
    80003e64:	ca8080e7          	jalr	-856(ra) # 80004b08 <log_write>
      brelse(bp);
    80003e68:	854a                	mv	a0,s2
    80003e6a:	00000097          	auipc	ra,0x0
    80003e6e:	a22080e7          	jalr	-1502(ra) # 8000388c <brelse>
      return iget(dev, inum);
    80003e72:	85da                	mv	a1,s6
    80003e74:	8556                	mv	a0,s5
    80003e76:	00000097          	auipc	ra,0x0
    80003e7a:	db4080e7          	jalr	-588(ra) # 80003c2a <iget>
}
    80003e7e:	60a6                	ld	ra,72(sp)
    80003e80:	6406                	ld	s0,64(sp)
    80003e82:	74e2                	ld	s1,56(sp)
    80003e84:	7942                	ld	s2,48(sp)
    80003e86:	79a2                	ld	s3,40(sp)
    80003e88:	7a02                	ld	s4,32(sp)
    80003e8a:	6ae2                	ld	s5,24(sp)
    80003e8c:	6b42                	ld	s6,16(sp)
    80003e8e:	6ba2                	ld	s7,8(sp)
    80003e90:	6161                	addi	sp,sp,80
    80003e92:	8082                	ret

0000000080003e94 <iupdate>:
{
    80003e94:	1101                	addi	sp,sp,-32
    80003e96:	ec06                	sd	ra,24(sp)
    80003e98:	e822                	sd	s0,16(sp)
    80003e9a:	e426                	sd	s1,8(sp)
    80003e9c:	e04a                	sd	s2,0(sp)
    80003e9e:	1000                	addi	s0,sp,32
    80003ea0:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003ea2:	415c                	lw	a5,4(a0)
    80003ea4:	0047d79b          	srliw	a5,a5,0x4
    80003ea8:	0001c597          	auipc	a1,0x1c
    80003eac:	3d85a583          	lw	a1,984(a1) # 80020280 <sb+0x18>
    80003eb0:	9dbd                	addw	a1,a1,a5
    80003eb2:	4108                	lw	a0,0(a0)
    80003eb4:	00000097          	auipc	ra,0x0
    80003eb8:	8a8080e7          	jalr	-1880(ra) # 8000375c <bread>
    80003ebc:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003ebe:	05850793          	addi	a5,a0,88
    80003ec2:	40c8                	lw	a0,4(s1)
    80003ec4:	893d                	andi	a0,a0,15
    80003ec6:	051a                	slli	a0,a0,0x6
    80003ec8:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003eca:	04449703          	lh	a4,68(s1)
    80003ece:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003ed2:	04649703          	lh	a4,70(s1)
    80003ed6:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003eda:	04849703          	lh	a4,72(s1)
    80003ede:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003ee2:	04a49703          	lh	a4,74(s1)
    80003ee6:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003eea:	44f8                	lw	a4,76(s1)
    80003eec:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003eee:	03400613          	li	a2,52
    80003ef2:	05048593          	addi	a1,s1,80
    80003ef6:	0531                	addi	a0,a0,12
    80003ef8:	ffffd097          	auipc	ra,0xffffd
    80003efc:	e48080e7          	jalr	-440(ra) # 80000d40 <memmove>
  log_write(bp);
    80003f00:	854a                	mv	a0,s2
    80003f02:	00001097          	auipc	ra,0x1
    80003f06:	c06080e7          	jalr	-1018(ra) # 80004b08 <log_write>
  brelse(bp);
    80003f0a:	854a                	mv	a0,s2
    80003f0c:	00000097          	auipc	ra,0x0
    80003f10:	980080e7          	jalr	-1664(ra) # 8000388c <brelse>
}
    80003f14:	60e2                	ld	ra,24(sp)
    80003f16:	6442                	ld	s0,16(sp)
    80003f18:	64a2                	ld	s1,8(sp)
    80003f1a:	6902                	ld	s2,0(sp)
    80003f1c:	6105                	addi	sp,sp,32
    80003f1e:	8082                	ret

0000000080003f20 <idup>:
{
    80003f20:	1101                	addi	sp,sp,-32
    80003f22:	ec06                	sd	ra,24(sp)
    80003f24:	e822                	sd	s0,16(sp)
    80003f26:	e426                	sd	s1,8(sp)
    80003f28:	1000                	addi	s0,sp,32
    80003f2a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003f2c:	0001c517          	auipc	a0,0x1c
    80003f30:	35c50513          	addi	a0,a0,860 # 80020288 <itable>
    80003f34:	ffffd097          	auipc	ra,0xffffd
    80003f38:	cb0080e7          	jalr	-848(ra) # 80000be4 <acquire>
  ip->ref++;
    80003f3c:	449c                	lw	a5,8(s1)
    80003f3e:	2785                	addiw	a5,a5,1
    80003f40:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003f42:	0001c517          	auipc	a0,0x1c
    80003f46:	34650513          	addi	a0,a0,838 # 80020288 <itable>
    80003f4a:	ffffd097          	auipc	ra,0xffffd
    80003f4e:	d4e080e7          	jalr	-690(ra) # 80000c98 <release>
}
    80003f52:	8526                	mv	a0,s1
    80003f54:	60e2                	ld	ra,24(sp)
    80003f56:	6442                	ld	s0,16(sp)
    80003f58:	64a2                	ld	s1,8(sp)
    80003f5a:	6105                	addi	sp,sp,32
    80003f5c:	8082                	ret

0000000080003f5e <ilock>:
{
    80003f5e:	1101                	addi	sp,sp,-32
    80003f60:	ec06                	sd	ra,24(sp)
    80003f62:	e822                	sd	s0,16(sp)
    80003f64:	e426                	sd	s1,8(sp)
    80003f66:	e04a                	sd	s2,0(sp)
    80003f68:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003f6a:	c115                	beqz	a0,80003f8e <ilock+0x30>
    80003f6c:	84aa                	mv	s1,a0
    80003f6e:	451c                	lw	a5,8(a0)
    80003f70:	00f05f63          	blez	a5,80003f8e <ilock+0x30>
  acquiresleep(&ip->lock);
    80003f74:	0541                	addi	a0,a0,16
    80003f76:	00001097          	auipc	ra,0x1
    80003f7a:	cb2080e7          	jalr	-846(ra) # 80004c28 <acquiresleep>
  if(ip->valid == 0){
    80003f7e:	40bc                	lw	a5,64(s1)
    80003f80:	cf99                	beqz	a5,80003f9e <ilock+0x40>
}
    80003f82:	60e2                	ld	ra,24(sp)
    80003f84:	6442                	ld	s0,16(sp)
    80003f86:	64a2                	ld	s1,8(sp)
    80003f88:	6902                	ld	s2,0(sp)
    80003f8a:	6105                	addi	sp,sp,32
    80003f8c:	8082                	ret
    panic("ilock");
    80003f8e:	00004517          	auipc	a0,0x4
    80003f92:	70a50513          	addi	a0,a0,1802 # 80008698 <syscalls+0x190>
    80003f96:	ffffc097          	auipc	ra,0xffffc
    80003f9a:	5a8080e7          	jalr	1448(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003f9e:	40dc                	lw	a5,4(s1)
    80003fa0:	0047d79b          	srliw	a5,a5,0x4
    80003fa4:	0001c597          	auipc	a1,0x1c
    80003fa8:	2dc5a583          	lw	a1,732(a1) # 80020280 <sb+0x18>
    80003fac:	9dbd                	addw	a1,a1,a5
    80003fae:	4088                	lw	a0,0(s1)
    80003fb0:	fffff097          	auipc	ra,0xfffff
    80003fb4:	7ac080e7          	jalr	1964(ra) # 8000375c <bread>
    80003fb8:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003fba:	05850593          	addi	a1,a0,88
    80003fbe:	40dc                	lw	a5,4(s1)
    80003fc0:	8bbd                	andi	a5,a5,15
    80003fc2:	079a                	slli	a5,a5,0x6
    80003fc4:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003fc6:	00059783          	lh	a5,0(a1)
    80003fca:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003fce:	00259783          	lh	a5,2(a1)
    80003fd2:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003fd6:	00459783          	lh	a5,4(a1)
    80003fda:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003fde:	00659783          	lh	a5,6(a1)
    80003fe2:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003fe6:	459c                	lw	a5,8(a1)
    80003fe8:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003fea:	03400613          	li	a2,52
    80003fee:	05b1                	addi	a1,a1,12
    80003ff0:	05048513          	addi	a0,s1,80
    80003ff4:	ffffd097          	auipc	ra,0xffffd
    80003ff8:	d4c080e7          	jalr	-692(ra) # 80000d40 <memmove>
    brelse(bp);
    80003ffc:	854a                	mv	a0,s2
    80003ffe:	00000097          	auipc	ra,0x0
    80004002:	88e080e7          	jalr	-1906(ra) # 8000388c <brelse>
    ip->valid = 1;
    80004006:	4785                	li	a5,1
    80004008:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000400a:	04449783          	lh	a5,68(s1)
    8000400e:	fbb5                	bnez	a5,80003f82 <ilock+0x24>
      panic("ilock: no type");
    80004010:	00004517          	auipc	a0,0x4
    80004014:	69050513          	addi	a0,a0,1680 # 800086a0 <syscalls+0x198>
    80004018:	ffffc097          	auipc	ra,0xffffc
    8000401c:	526080e7          	jalr	1318(ra) # 8000053e <panic>

0000000080004020 <iunlock>:
{
    80004020:	1101                	addi	sp,sp,-32
    80004022:	ec06                	sd	ra,24(sp)
    80004024:	e822                	sd	s0,16(sp)
    80004026:	e426                	sd	s1,8(sp)
    80004028:	e04a                	sd	s2,0(sp)
    8000402a:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000402c:	c905                	beqz	a0,8000405c <iunlock+0x3c>
    8000402e:	84aa                	mv	s1,a0
    80004030:	01050913          	addi	s2,a0,16
    80004034:	854a                	mv	a0,s2
    80004036:	00001097          	auipc	ra,0x1
    8000403a:	c8c080e7          	jalr	-884(ra) # 80004cc2 <holdingsleep>
    8000403e:	cd19                	beqz	a0,8000405c <iunlock+0x3c>
    80004040:	449c                	lw	a5,8(s1)
    80004042:	00f05d63          	blez	a5,8000405c <iunlock+0x3c>
  releasesleep(&ip->lock);
    80004046:	854a                	mv	a0,s2
    80004048:	00001097          	auipc	ra,0x1
    8000404c:	c36080e7          	jalr	-970(ra) # 80004c7e <releasesleep>
}
    80004050:	60e2                	ld	ra,24(sp)
    80004052:	6442                	ld	s0,16(sp)
    80004054:	64a2                	ld	s1,8(sp)
    80004056:	6902                	ld	s2,0(sp)
    80004058:	6105                	addi	sp,sp,32
    8000405a:	8082                	ret
    panic("iunlock");
    8000405c:	00004517          	auipc	a0,0x4
    80004060:	65450513          	addi	a0,a0,1620 # 800086b0 <syscalls+0x1a8>
    80004064:	ffffc097          	auipc	ra,0xffffc
    80004068:	4da080e7          	jalr	1242(ra) # 8000053e <panic>

000000008000406c <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000406c:	7179                	addi	sp,sp,-48
    8000406e:	f406                	sd	ra,40(sp)
    80004070:	f022                	sd	s0,32(sp)
    80004072:	ec26                	sd	s1,24(sp)
    80004074:	e84a                	sd	s2,16(sp)
    80004076:	e44e                	sd	s3,8(sp)
    80004078:	e052                	sd	s4,0(sp)
    8000407a:	1800                	addi	s0,sp,48
    8000407c:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000407e:	05050493          	addi	s1,a0,80
    80004082:	08050913          	addi	s2,a0,128
    80004086:	a021                	j	8000408e <itrunc+0x22>
    80004088:	0491                	addi	s1,s1,4
    8000408a:	01248d63          	beq	s1,s2,800040a4 <itrunc+0x38>
    if(ip->addrs[i]){
    8000408e:	408c                	lw	a1,0(s1)
    80004090:	dde5                	beqz	a1,80004088 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80004092:	0009a503          	lw	a0,0(s3)
    80004096:	00000097          	auipc	ra,0x0
    8000409a:	90c080e7          	jalr	-1780(ra) # 800039a2 <bfree>
      ip->addrs[i] = 0;
    8000409e:	0004a023          	sw	zero,0(s1)
    800040a2:	b7dd                	j	80004088 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800040a4:	0809a583          	lw	a1,128(s3)
    800040a8:	e185                	bnez	a1,800040c8 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800040aa:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800040ae:	854e                	mv	a0,s3
    800040b0:	00000097          	auipc	ra,0x0
    800040b4:	de4080e7          	jalr	-540(ra) # 80003e94 <iupdate>
}
    800040b8:	70a2                	ld	ra,40(sp)
    800040ba:	7402                	ld	s0,32(sp)
    800040bc:	64e2                	ld	s1,24(sp)
    800040be:	6942                	ld	s2,16(sp)
    800040c0:	69a2                	ld	s3,8(sp)
    800040c2:	6a02                	ld	s4,0(sp)
    800040c4:	6145                	addi	sp,sp,48
    800040c6:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800040c8:	0009a503          	lw	a0,0(s3)
    800040cc:	fffff097          	auipc	ra,0xfffff
    800040d0:	690080e7          	jalr	1680(ra) # 8000375c <bread>
    800040d4:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800040d6:	05850493          	addi	s1,a0,88
    800040da:	45850913          	addi	s2,a0,1112
    800040de:	a811                	j	800040f2 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    800040e0:	0009a503          	lw	a0,0(s3)
    800040e4:	00000097          	auipc	ra,0x0
    800040e8:	8be080e7          	jalr	-1858(ra) # 800039a2 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    800040ec:	0491                	addi	s1,s1,4
    800040ee:	01248563          	beq	s1,s2,800040f8 <itrunc+0x8c>
      if(a[j])
    800040f2:	408c                	lw	a1,0(s1)
    800040f4:	dde5                	beqz	a1,800040ec <itrunc+0x80>
    800040f6:	b7ed                	j	800040e0 <itrunc+0x74>
    brelse(bp);
    800040f8:	8552                	mv	a0,s4
    800040fa:	fffff097          	auipc	ra,0xfffff
    800040fe:	792080e7          	jalr	1938(ra) # 8000388c <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80004102:	0809a583          	lw	a1,128(s3)
    80004106:	0009a503          	lw	a0,0(s3)
    8000410a:	00000097          	auipc	ra,0x0
    8000410e:	898080e7          	jalr	-1896(ra) # 800039a2 <bfree>
    ip->addrs[NDIRECT] = 0;
    80004112:	0809a023          	sw	zero,128(s3)
    80004116:	bf51                	j	800040aa <itrunc+0x3e>

0000000080004118 <iput>:
{
    80004118:	1101                	addi	sp,sp,-32
    8000411a:	ec06                	sd	ra,24(sp)
    8000411c:	e822                	sd	s0,16(sp)
    8000411e:	e426                	sd	s1,8(sp)
    80004120:	e04a                	sd	s2,0(sp)
    80004122:	1000                	addi	s0,sp,32
    80004124:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004126:	0001c517          	auipc	a0,0x1c
    8000412a:	16250513          	addi	a0,a0,354 # 80020288 <itable>
    8000412e:	ffffd097          	auipc	ra,0xffffd
    80004132:	ab6080e7          	jalr	-1354(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004136:	4498                	lw	a4,8(s1)
    80004138:	4785                	li	a5,1
    8000413a:	02f70363          	beq	a4,a5,80004160 <iput+0x48>
  ip->ref--;
    8000413e:	449c                	lw	a5,8(s1)
    80004140:	37fd                	addiw	a5,a5,-1
    80004142:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004144:	0001c517          	auipc	a0,0x1c
    80004148:	14450513          	addi	a0,a0,324 # 80020288 <itable>
    8000414c:	ffffd097          	auipc	ra,0xffffd
    80004150:	b4c080e7          	jalr	-1204(ra) # 80000c98 <release>
}
    80004154:	60e2                	ld	ra,24(sp)
    80004156:	6442                	ld	s0,16(sp)
    80004158:	64a2                	ld	s1,8(sp)
    8000415a:	6902                	ld	s2,0(sp)
    8000415c:	6105                	addi	sp,sp,32
    8000415e:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004160:	40bc                	lw	a5,64(s1)
    80004162:	dff1                	beqz	a5,8000413e <iput+0x26>
    80004164:	04a49783          	lh	a5,74(s1)
    80004168:	fbf9                	bnez	a5,8000413e <iput+0x26>
    acquiresleep(&ip->lock);
    8000416a:	01048913          	addi	s2,s1,16
    8000416e:	854a                	mv	a0,s2
    80004170:	00001097          	auipc	ra,0x1
    80004174:	ab8080e7          	jalr	-1352(ra) # 80004c28 <acquiresleep>
    release(&itable.lock);
    80004178:	0001c517          	auipc	a0,0x1c
    8000417c:	11050513          	addi	a0,a0,272 # 80020288 <itable>
    80004180:	ffffd097          	auipc	ra,0xffffd
    80004184:	b18080e7          	jalr	-1256(ra) # 80000c98 <release>
    itrunc(ip);
    80004188:	8526                	mv	a0,s1
    8000418a:	00000097          	auipc	ra,0x0
    8000418e:	ee2080e7          	jalr	-286(ra) # 8000406c <itrunc>
    ip->type = 0;
    80004192:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80004196:	8526                	mv	a0,s1
    80004198:	00000097          	auipc	ra,0x0
    8000419c:	cfc080e7          	jalr	-772(ra) # 80003e94 <iupdate>
    ip->valid = 0;
    800041a0:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800041a4:	854a                	mv	a0,s2
    800041a6:	00001097          	auipc	ra,0x1
    800041aa:	ad8080e7          	jalr	-1320(ra) # 80004c7e <releasesleep>
    acquire(&itable.lock);
    800041ae:	0001c517          	auipc	a0,0x1c
    800041b2:	0da50513          	addi	a0,a0,218 # 80020288 <itable>
    800041b6:	ffffd097          	auipc	ra,0xffffd
    800041ba:	a2e080e7          	jalr	-1490(ra) # 80000be4 <acquire>
    800041be:	b741                	j	8000413e <iput+0x26>

00000000800041c0 <iunlockput>:
{
    800041c0:	1101                	addi	sp,sp,-32
    800041c2:	ec06                	sd	ra,24(sp)
    800041c4:	e822                	sd	s0,16(sp)
    800041c6:	e426                	sd	s1,8(sp)
    800041c8:	1000                	addi	s0,sp,32
    800041ca:	84aa                	mv	s1,a0
  iunlock(ip);
    800041cc:	00000097          	auipc	ra,0x0
    800041d0:	e54080e7          	jalr	-428(ra) # 80004020 <iunlock>
  iput(ip);
    800041d4:	8526                	mv	a0,s1
    800041d6:	00000097          	auipc	ra,0x0
    800041da:	f42080e7          	jalr	-190(ra) # 80004118 <iput>
}
    800041de:	60e2                	ld	ra,24(sp)
    800041e0:	6442                	ld	s0,16(sp)
    800041e2:	64a2                	ld	s1,8(sp)
    800041e4:	6105                	addi	sp,sp,32
    800041e6:	8082                	ret

00000000800041e8 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800041e8:	1141                	addi	sp,sp,-16
    800041ea:	e422                	sd	s0,8(sp)
    800041ec:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800041ee:	411c                	lw	a5,0(a0)
    800041f0:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800041f2:	415c                	lw	a5,4(a0)
    800041f4:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800041f6:	04451783          	lh	a5,68(a0)
    800041fa:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800041fe:	04a51783          	lh	a5,74(a0)
    80004202:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80004206:	04c56783          	lwu	a5,76(a0)
    8000420a:	e99c                	sd	a5,16(a1)
}
    8000420c:	6422                	ld	s0,8(sp)
    8000420e:	0141                	addi	sp,sp,16
    80004210:	8082                	ret

0000000080004212 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004212:	457c                	lw	a5,76(a0)
    80004214:	0ed7e963          	bltu	a5,a3,80004306 <readi+0xf4>
{
    80004218:	7159                	addi	sp,sp,-112
    8000421a:	f486                	sd	ra,104(sp)
    8000421c:	f0a2                	sd	s0,96(sp)
    8000421e:	eca6                	sd	s1,88(sp)
    80004220:	e8ca                	sd	s2,80(sp)
    80004222:	e4ce                	sd	s3,72(sp)
    80004224:	e0d2                	sd	s4,64(sp)
    80004226:	fc56                	sd	s5,56(sp)
    80004228:	f85a                	sd	s6,48(sp)
    8000422a:	f45e                	sd	s7,40(sp)
    8000422c:	f062                	sd	s8,32(sp)
    8000422e:	ec66                	sd	s9,24(sp)
    80004230:	e86a                	sd	s10,16(sp)
    80004232:	e46e                	sd	s11,8(sp)
    80004234:	1880                	addi	s0,sp,112
    80004236:	8baa                	mv	s7,a0
    80004238:	8c2e                	mv	s8,a1
    8000423a:	8ab2                	mv	s5,a2
    8000423c:	84b6                	mv	s1,a3
    8000423e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004240:	9f35                	addw	a4,a4,a3
    return 0;
    80004242:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80004244:	0ad76063          	bltu	a4,a3,800042e4 <readi+0xd2>
  if(off + n > ip->size)
    80004248:	00e7f463          	bgeu	a5,a4,80004250 <readi+0x3e>
    n = ip->size - off;
    8000424c:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004250:	0a0b0963          	beqz	s6,80004302 <readi+0xf0>
    80004254:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004256:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    8000425a:	5cfd                	li	s9,-1
    8000425c:	a82d                	j	80004296 <readi+0x84>
    8000425e:	020a1d93          	slli	s11,s4,0x20
    80004262:	020ddd93          	srli	s11,s11,0x20
    80004266:	05890613          	addi	a2,s2,88
    8000426a:	86ee                	mv	a3,s11
    8000426c:	963a                	add	a2,a2,a4
    8000426e:	85d6                	mv	a1,s5
    80004270:	8562                	mv	a0,s8
    80004272:	fffff097          	auipc	ra,0xfffff
    80004276:	816080e7          	jalr	-2026(ra) # 80002a88 <either_copyout>
    8000427a:	05950d63          	beq	a0,s9,800042d4 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    8000427e:	854a                	mv	a0,s2
    80004280:	fffff097          	auipc	ra,0xfffff
    80004284:	60c080e7          	jalr	1548(ra) # 8000388c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004288:	013a09bb          	addw	s3,s4,s3
    8000428c:	009a04bb          	addw	s1,s4,s1
    80004290:	9aee                	add	s5,s5,s11
    80004292:	0569f763          	bgeu	s3,s6,800042e0 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004296:	000ba903          	lw	s2,0(s7)
    8000429a:	00a4d59b          	srliw	a1,s1,0xa
    8000429e:	855e                	mv	a0,s7
    800042a0:	00000097          	auipc	ra,0x0
    800042a4:	8b0080e7          	jalr	-1872(ra) # 80003b50 <bmap>
    800042a8:	0005059b          	sext.w	a1,a0
    800042ac:	854a                	mv	a0,s2
    800042ae:	fffff097          	auipc	ra,0xfffff
    800042b2:	4ae080e7          	jalr	1198(ra) # 8000375c <bread>
    800042b6:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800042b8:	3ff4f713          	andi	a4,s1,1023
    800042bc:	40ed07bb          	subw	a5,s10,a4
    800042c0:	413b06bb          	subw	a3,s6,s3
    800042c4:	8a3e                	mv	s4,a5
    800042c6:	2781                	sext.w	a5,a5
    800042c8:	0006861b          	sext.w	a2,a3
    800042cc:	f8f679e3          	bgeu	a2,a5,8000425e <readi+0x4c>
    800042d0:	8a36                	mv	s4,a3
    800042d2:	b771                	j	8000425e <readi+0x4c>
      brelse(bp);
    800042d4:	854a                	mv	a0,s2
    800042d6:	fffff097          	auipc	ra,0xfffff
    800042da:	5b6080e7          	jalr	1462(ra) # 8000388c <brelse>
      tot = -1;
    800042de:	59fd                	li	s3,-1
  }
  return tot;
    800042e0:	0009851b          	sext.w	a0,s3
}
    800042e4:	70a6                	ld	ra,104(sp)
    800042e6:	7406                	ld	s0,96(sp)
    800042e8:	64e6                	ld	s1,88(sp)
    800042ea:	6946                	ld	s2,80(sp)
    800042ec:	69a6                	ld	s3,72(sp)
    800042ee:	6a06                	ld	s4,64(sp)
    800042f0:	7ae2                	ld	s5,56(sp)
    800042f2:	7b42                	ld	s6,48(sp)
    800042f4:	7ba2                	ld	s7,40(sp)
    800042f6:	7c02                	ld	s8,32(sp)
    800042f8:	6ce2                	ld	s9,24(sp)
    800042fa:	6d42                	ld	s10,16(sp)
    800042fc:	6da2                	ld	s11,8(sp)
    800042fe:	6165                	addi	sp,sp,112
    80004300:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004302:	89da                	mv	s3,s6
    80004304:	bff1                	j	800042e0 <readi+0xce>
    return 0;
    80004306:	4501                	li	a0,0
}
    80004308:	8082                	ret

000000008000430a <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000430a:	457c                	lw	a5,76(a0)
    8000430c:	10d7e863          	bltu	a5,a3,8000441c <writei+0x112>
{
    80004310:	7159                	addi	sp,sp,-112
    80004312:	f486                	sd	ra,104(sp)
    80004314:	f0a2                	sd	s0,96(sp)
    80004316:	eca6                	sd	s1,88(sp)
    80004318:	e8ca                	sd	s2,80(sp)
    8000431a:	e4ce                	sd	s3,72(sp)
    8000431c:	e0d2                	sd	s4,64(sp)
    8000431e:	fc56                	sd	s5,56(sp)
    80004320:	f85a                	sd	s6,48(sp)
    80004322:	f45e                	sd	s7,40(sp)
    80004324:	f062                	sd	s8,32(sp)
    80004326:	ec66                	sd	s9,24(sp)
    80004328:	e86a                	sd	s10,16(sp)
    8000432a:	e46e                	sd	s11,8(sp)
    8000432c:	1880                	addi	s0,sp,112
    8000432e:	8b2a                	mv	s6,a0
    80004330:	8c2e                	mv	s8,a1
    80004332:	8ab2                	mv	s5,a2
    80004334:	8936                	mv	s2,a3
    80004336:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80004338:	00e687bb          	addw	a5,a3,a4
    8000433c:	0ed7e263          	bltu	a5,a3,80004420 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004340:	00043737          	lui	a4,0x43
    80004344:	0ef76063          	bltu	a4,a5,80004424 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004348:	0c0b8863          	beqz	s7,80004418 <writei+0x10e>
    8000434c:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    8000434e:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004352:	5cfd                	li	s9,-1
    80004354:	a091                	j	80004398 <writei+0x8e>
    80004356:	02099d93          	slli	s11,s3,0x20
    8000435a:	020ddd93          	srli	s11,s11,0x20
    8000435e:	05848513          	addi	a0,s1,88
    80004362:	86ee                	mv	a3,s11
    80004364:	8656                	mv	a2,s5
    80004366:	85e2                	mv	a1,s8
    80004368:	953a                	add	a0,a0,a4
    8000436a:	ffffe097          	auipc	ra,0xffffe
    8000436e:	774080e7          	jalr	1908(ra) # 80002ade <either_copyin>
    80004372:	07950263          	beq	a0,s9,800043d6 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004376:	8526                	mv	a0,s1
    80004378:	00000097          	auipc	ra,0x0
    8000437c:	790080e7          	jalr	1936(ra) # 80004b08 <log_write>
    brelse(bp);
    80004380:	8526                	mv	a0,s1
    80004382:	fffff097          	auipc	ra,0xfffff
    80004386:	50a080e7          	jalr	1290(ra) # 8000388c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000438a:	01498a3b          	addw	s4,s3,s4
    8000438e:	0129893b          	addw	s2,s3,s2
    80004392:	9aee                	add	s5,s5,s11
    80004394:	057a7663          	bgeu	s4,s7,800043e0 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004398:	000b2483          	lw	s1,0(s6)
    8000439c:	00a9559b          	srliw	a1,s2,0xa
    800043a0:	855a                	mv	a0,s6
    800043a2:	fffff097          	auipc	ra,0xfffff
    800043a6:	7ae080e7          	jalr	1966(ra) # 80003b50 <bmap>
    800043aa:	0005059b          	sext.w	a1,a0
    800043ae:	8526                	mv	a0,s1
    800043b0:	fffff097          	auipc	ra,0xfffff
    800043b4:	3ac080e7          	jalr	940(ra) # 8000375c <bread>
    800043b8:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800043ba:	3ff97713          	andi	a4,s2,1023
    800043be:	40ed07bb          	subw	a5,s10,a4
    800043c2:	414b86bb          	subw	a3,s7,s4
    800043c6:	89be                	mv	s3,a5
    800043c8:	2781                	sext.w	a5,a5
    800043ca:	0006861b          	sext.w	a2,a3
    800043ce:	f8f674e3          	bgeu	a2,a5,80004356 <writei+0x4c>
    800043d2:	89b6                	mv	s3,a3
    800043d4:	b749                	j	80004356 <writei+0x4c>
      brelse(bp);
    800043d6:	8526                	mv	a0,s1
    800043d8:	fffff097          	auipc	ra,0xfffff
    800043dc:	4b4080e7          	jalr	1204(ra) # 8000388c <brelse>
  }

  if(off > ip->size)
    800043e0:	04cb2783          	lw	a5,76(s6)
    800043e4:	0127f463          	bgeu	a5,s2,800043ec <writei+0xe2>
    ip->size = off;
    800043e8:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800043ec:	855a                	mv	a0,s6
    800043ee:	00000097          	auipc	ra,0x0
    800043f2:	aa6080e7          	jalr	-1370(ra) # 80003e94 <iupdate>

  return tot;
    800043f6:	000a051b          	sext.w	a0,s4
}
    800043fa:	70a6                	ld	ra,104(sp)
    800043fc:	7406                	ld	s0,96(sp)
    800043fe:	64e6                	ld	s1,88(sp)
    80004400:	6946                	ld	s2,80(sp)
    80004402:	69a6                	ld	s3,72(sp)
    80004404:	6a06                	ld	s4,64(sp)
    80004406:	7ae2                	ld	s5,56(sp)
    80004408:	7b42                	ld	s6,48(sp)
    8000440a:	7ba2                	ld	s7,40(sp)
    8000440c:	7c02                	ld	s8,32(sp)
    8000440e:	6ce2                	ld	s9,24(sp)
    80004410:	6d42                	ld	s10,16(sp)
    80004412:	6da2                	ld	s11,8(sp)
    80004414:	6165                	addi	sp,sp,112
    80004416:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004418:	8a5e                	mv	s4,s7
    8000441a:	bfc9                	j	800043ec <writei+0xe2>
    return -1;
    8000441c:	557d                	li	a0,-1
}
    8000441e:	8082                	ret
    return -1;
    80004420:	557d                	li	a0,-1
    80004422:	bfe1                	j	800043fa <writei+0xf0>
    return -1;
    80004424:	557d                	li	a0,-1
    80004426:	bfd1                	j	800043fa <writei+0xf0>

0000000080004428 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004428:	1141                	addi	sp,sp,-16
    8000442a:	e406                	sd	ra,8(sp)
    8000442c:	e022                	sd	s0,0(sp)
    8000442e:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004430:	4639                	li	a2,14
    80004432:	ffffd097          	auipc	ra,0xffffd
    80004436:	986080e7          	jalr	-1658(ra) # 80000db8 <strncmp>
}
    8000443a:	60a2                	ld	ra,8(sp)
    8000443c:	6402                	ld	s0,0(sp)
    8000443e:	0141                	addi	sp,sp,16
    80004440:	8082                	ret

0000000080004442 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004442:	7139                	addi	sp,sp,-64
    80004444:	fc06                	sd	ra,56(sp)
    80004446:	f822                	sd	s0,48(sp)
    80004448:	f426                	sd	s1,40(sp)
    8000444a:	f04a                	sd	s2,32(sp)
    8000444c:	ec4e                	sd	s3,24(sp)
    8000444e:	e852                	sd	s4,16(sp)
    80004450:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004452:	04451703          	lh	a4,68(a0)
    80004456:	4785                	li	a5,1
    80004458:	00f71a63          	bne	a4,a5,8000446c <dirlookup+0x2a>
    8000445c:	892a                	mv	s2,a0
    8000445e:	89ae                	mv	s3,a1
    80004460:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004462:	457c                	lw	a5,76(a0)
    80004464:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004466:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004468:	e79d                	bnez	a5,80004496 <dirlookup+0x54>
    8000446a:	a8a5                	j	800044e2 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    8000446c:	00004517          	auipc	a0,0x4
    80004470:	24c50513          	addi	a0,a0,588 # 800086b8 <syscalls+0x1b0>
    80004474:	ffffc097          	auipc	ra,0xffffc
    80004478:	0ca080e7          	jalr	202(ra) # 8000053e <panic>
      panic("dirlookup read");
    8000447c:	00004517          	auipc	a0,0x4
    80004480:	25450513          	addi	a0,a0,596 # 800086d0 <syscalls+0x1c8>
    80004484:	ffffc097          	auipc	ra,0xffffc
    80004488:	0ba080e7          	jalr	186(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000448c:	24c1                	addiw	s1,s1,16
    8000448e:	04c92783          	lw	a5,76(s2)
    80004492:	04f4f763          	bgeu	s1,a5,800044e0 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004496:	4741                	li	a4,16
    80004498:	86a6                	mv	a3,s1
    8000449a:	fc040613          	addi	a2,s0,-64
    8000449e:	4581                	li	a1,0
    800044a0:	854a                	mv	a0,s2
    800044a2:	00000097          	auipc	ra,0x0
    800044a6:	d70080e7          	jalr	-656(ra) # 80004212 <readi>
    800044aa:	47c1                	li	a5,16
    800044ac:	fcf518e3          	bne	a0,a5,8000447c <dirlookup+0x3a>
    if(de.inum == 0)
    800044b0:	fc045783          	lhu	a5,-64(s0)
    800044b4:	dfe1                	beqz	a5,8000448c <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800044b6:	fc240593          	addi	a1,s0,-62
    800044ba:	854e                	mv	a0,s3
    800044bc:	00000097          	auipc	ra,0x0
    800044c0:	f6c080e7          	jalr	-148(ra) # 80004428 <namecmp>
    800044c4:	f561                	bnez	a0,8000448c <dirlookup+0x4a>
      if(poff)
    800044c6:	000a0463          	beqz	s4,800044ce <dirlookup+0x8c>
        *poff = off;
    800044ca:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800044ce:	fc045583          	lhu	a1,-64(s0)
    800044d2:	00092503          	lw	a0,0(s2)
    800044d6:	fffff097          	auipc	ra,0xfffff
    800044da:	754080e7          	jalr	1876(ra) # 80003c2a <iget>
    800044de:	a011                	j	800044e2 <dirlookup+0xa0>
  return 0;
    800044e0:	4501                	li	a0,0
}
    800044e2:	70e2                	ld	ra,56(sp)
    800044e4:	7442                	ld	s0,48(sp)
    800044e6:	74a2                	ld	s1,40(sp)
    800044e8:	7902                	ld	s2,32(sp)
    800044ea:	69e2                	ld	s3,24(sp)
    800044ec:	6a42                	ld	s4,16(sp)
    800044ee:	6121                	addi	sp,sp,64
    800044f0:	8082                	ret

00000000800044f2 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800044f2:	711d                	addi	sp,sp,-96
    800044f4:	ec86                	sd	ra,88(sp)
    800044f6:	e8a2                	sd	s0,80(sp)
    800044f8:	e4a6                	sd	s1,72(sp)
    800044fa:	e0ca                	sd	s2,64(sp)
    800044fc:	fc4e                	sd	s3,56(sp)
    800044fe:	f852                	sd	s4,48(sp)
    80004500:	f456                	sd	s5,40(sp)
    80004502:	f05a                	sd	s6,32(sp)
    80004504:	ec5e                	sd	s7,24(sp)
    80004506:	e862                	sd	s8,16(sp)
    80004508:	e466                	sd	s9,8(sp)
    8000450a:	1080                	addi	s0,sp,96
    8000450c:	84aa                	mv	s1,a0
    8000450e:	8b2e                	mv	s6,a1
    80004510:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004512:	00054703          	lbu	a4,0(a0)
    80004516:	02f00793          	li	a5,47
    8000451a:	02f70363          	beq	a4,a5,80004540 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000451e:	ffffe097          	auipc	ra,0xffffe
    80004522:	83e080e7          	jalr	-1986(ra) # 80001d5c <myproc>
    80004526:	16853503          	ld	a0,360(a0)
    8000452a:	00000097          	auipc	ra,0x0
    8000452e:	9f6080e7          	jalr	-1546(ra) # 80003f20 <idup>
    80004532:	89aa                	mv	s3,a0
  while(*path == '/')
    80004534:	02f00913          	li	s2,47
  len = path - s;
    80004538:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    8000453a:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000453c:	4c05                	li	s8,1
    8000453e:	a865                	j	800045f6 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004540:	4585                	li	a1,1
    80004542:	4505                	li	a0,1
    80004544:	fffff097          	auipc	ra,0xfffff
    80004548:	6e6080e7          	jalr	1766(ra) # 80003c2a <iget>
    8000454c:	89aa                	mv	s3,a0
    8000454e:	b7dd                	j	80004534 <namex+0x42>
      iunlockput(ip);
    80004550:	854e                	mv	a0,s3
    80004552:	00000097          	auipc	ra,0x0
    80004556:	c6e080e7          	jalr	-914(ra) # 800041c0 <iunlockput>
      return 0;
    8000455a:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    8000455c:	854e                	mv	a0,s3
    8000455e:	60e6                	ld	ra,88(sp)
    80004560:	6446                	ld	s0,80(sp)
    80004562:	64a6                	ld	s1,72(sp)
    80004564:	6906                	ld	s2,64(sp)
    80004566:	79e2                	ld	s3,56(sp)
    80004568:	7a42                	ld	s4,48(sp)
    8000456a:	7aa2                	ld	s5,40(sp)
    8000456c:	7b02                	ld	s6,32(sp)
    8000456e:	6be2                	ld	s7,24(sp)
    80004570:	6c42                	ld	s8,16(sp)
    80004572:	6ca2                	ld	s9,8(sp)
    80004574:	6125                	addi	sp,sp,96
    80004576:	8082                	ret
      iunlock(ip);
    80004578:	854e                	mv	a0,s3
    8000457a:	00000097          	auipc	ra,0x0
    8000457e:	aa6080e7          	jalr	-1370(ra) # 80004020 <iunlock>
      return ip;
    80004582:	bfe9                	j	8000455c <namex+0x6a>
      iunlockput(ip);
    80004584:	854e                	mv	a0,s3
    80004586:	00000097          	auipc	ra,0x0
    8000458a:	c3a080e7          	jalr	-966(ra) # 800041c0 <iunlockput>
      return 0;
    8000458e:	89d2                	mv	s3,s4
    80004590:	b7f1                	j	8000455c <namex+0x6a>
  len = path - s;
    80004592:	40b48633          	sub	a2,s1,a1
    80004596:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    8000459a:	094cd463          	bge	s9,s4,80004622 <namex+0x130>
    memmove(name, s, DIRSIZ);
    8000459e:	4639                	li	a2,14
    800045a0:	8556                	mv	a0,s5
    800045a2:	ffffc097          	auipc	ra,0xffffc
    800045a6:	79e080e7          	jalr	1950(ra) # 80000d40 <memmove>
  while(*path == '/')
    800045aa:	0004c783          	lbu	a5,0(s1)
    800045ae:	01279763          	bne	a5,s2,800045bc <namex+0xca>
    path++;
    800045b2:	0485                	addi	s1,s1,1
  while(*path == '/')
    800045b4:	0004c783          	lbu	a5,0(s1)
    800045b8:	ff278de3          	beq	a5,s2,800045b2 <namex+0xc0>
    ilock(ip);
    800045bc:	854e                	mv	a0,s3
    800045be:	00000097          	auipc	ra,0x0
    800045c2:	9a0080e7          	jalr	-1632(ra) # 80003f5e <ilock>
    if(ip->type != T_DIR){
    800045c6:	04499783          	lh	a5,68(s3)
    800045ca:	f98793e3          	bne	a5,s8,80004550 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800045ce:	000b0563          	beqz	s6,800045d8 <namex+0xe6>
    800045d2:	0004c783          	lbu	a5,0(s1)
    800045d6:	d3cd                	beqz	a5,80004578 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800045d8:	865e                	mv	a2,s7
    800045da:	85d6                	mv	a1,s5
    800045dc:	854e                	mv	a0,s3
    800045de:	00000097          	auipc	ra,0x0
    800045e2:	e64080e7          	jalr	-412(ra) # 80004442 <dirlookup>
    800045e6:	8a2a                	mv	s4,a0
    800045e8:	dd51                	beqz	a0,80004584 <namex+0x92>
    iunlockput(ip);
    800045ea:	854e                	mv	a0,s3
    800045ec:	00000097          	auipc	ra,0x0
    800045f0:	bd4080e7          	jalr	-1068(ra) # 800041c0 <iunlockput>
    ip = next;
    800045f4:	89d2                	mv	s3,s4
  while(*path == '/')
    800045f6:	0004c783          	lbu	a5,0(s1)
    800045fa:	05279763          	bne	a5,s2,80004648 <namex+0x156>
    path++;
    800045fe:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004600:	0004c783          	lbu	a5,0(s1)
    80004604:	ff278de3          	beq	a5,s2,800045fe <namex+0x10c>
  if(*path == 0)
    80004608:	c79d                	beqz	a5,80004636 <namex+0x144>
    path++;
    8000460a:	85a6                	mv	a1,s1
  len = path - s;
    8000460c:	8a5e                	mv	s4,s7
    8000460e:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004610:	01278963          	beq	a5,s2,80004622 <namex+0x130>
    80004614:	dfbd                	beqz	a5,80004592 <namex+0xa0>
    path++;
    80004616:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004618:	0004c783          	lbu	a5,0(s1)
    8000461c:	ff279ce3          	bne	a5,s2,80004614 <namex+0x122>
    80004620:	bf8d                	j	80004592 <namex+0xa0>
    memmove(name, s, len);
    80004622:	2601                	sext.w	a2,a2
    80004624:	8556                	mv	a0,s5
    80004626:	ffffc097          	auipc	ra,0xffffc
    8000462a:	71a080e7          	jalr	1818(ra) # 80000d40 <memmove>
    name[len] = 0;
    8000462e:	9a56                	add	s4,s4,s5
    80004630:	000a0023          	sb	zero,0(s4)
    80004634:	bf9d                	j	800045aa <namex+0xb8>
  if(nameiparent){
    80004636:	f20b03e3          	beqz	s6,8000455c <namex+0x6a>
    iput(ip);
    8000463a:	854e                	mv	a0,s3
    8000463c:	00000097          	auipc	ra,0x0
    80004640:	adc080e7          	jalr	-1316(ra) # 80004118 <iput>
    return 0;
    80004644:	4981                	li	s3,0
    80004646:	bf19                	j	8000455c <namex+0x6a>
  if(*path == 0)
    80004648:	d7fd                	beqz	a5,80004636 <namex+0x144>
  while(*path != '/' && *path != 0)
    8000464a:	0004c783          	lbu	a5,0(s1)
    8000464e:	85a6                	mv	a1,s1
    80004650:	b7d1                	j	80004614 <namex+0x122>

0000000080004652 <dirlink>:
{
    80004652:	7139                	addi	sp,sp,-64
    80004654:	fc06                	sd	ra,56(sp)
    80004656:	f822                	sd	s0,48(sp)
    80004658:	f426                	sd	s1,40(sp)
    8000465a:	f04a                	sd	s2,32(sp)
    8000465c:	ec4e                	sd	s3,24(sp)
    8000465e:	e852                	sd	s4,16(sp)
    80004660:	0080                	addi	s0,sp,64
    80004662:	892a                	mv	s2,a0
    80004664:	8a2e                	mv	s4,a1
    80004666:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004668:	4601                	li	a2,0
    8000466a:	00000097          	auipc	ra,0x0
    8000466e:	dd8080e7          	jalr	-552(ra) # 80004442 <dirlookup>
    80004672:	e93d                	bnez	a0,800046e8 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004674:	04c92483          	lw	s1,76(s2)
    80004678:	c49d                	beqz	s1,800046a6 <dirlink+0x54>
    8000467a:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000467c:	4741                	li	a4,16
    8000467e:	86a6                	mv	a3,s1
    80004680:	fc040613          	addi	a2,s0,-64
    80004684:	4581                	li	a1,0
    80004686:	854a                	mv	a0,s2
    80004688:	00000097          	auipc	ra,0x0
    8000468c:	b8a080e7          	jalr	-1142(ra) # 80004212 <readi>
    80004690:	47c1                	li	a5,16
    80004692:	06f51163          	bne	a0,a5,800046f4 <dirlink+0xa2>
    if(de.inum == 0)
    80004696:	fc045783          	lhu	a5,-64(s0)
    8000469a:	c791                	beqz	a5,800046a6 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000469c:	24c1                	addiw	s1,s1,16
    8000469e:	04c92783          	lw	a5,76(s2)
    800046a2:	fcf4ede3          	bltu	s1,a5,8000467c <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800046a6:	4639                	li	a2,14
    800046a8:	85d2                	mv	a1,s4
    800046aa:	fc240513          	addi	a0,s0,-62
    800046ae:	ffffc097          	auipc	ra,0xffffc
    800046b2:	746080e7          	jalr	1862(ra) # 80000df4 <strncpy>
  de.inum = inum;
    800046b6:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800046ba:	4741                	li	a4,16
    800046bc:	86a6                	mv	a3,s1
    800046be:	fc040613          	addi	a2,s0,-64
    800046c2:	4581                	li	a1,0
    800046c4:	854a                	mv	a0,s2
    800046c6:	00000097          	auipc	ra,0x0
    800046ca:	c44080e7          	jalr	-956(ra) # 8000430a <writei>
    800046ce:	872a                	mv	a4,a0
    800046d0:	47c1                	li	a5,16
  return 0;
    800046d2:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800046d4:	02f71863          	bne	a4,a5,80004704 <dirlink+0xb2>
}
    800046d8:	70e2                	ld	ra,56(sp)
    800046da:	7442                	ld	s0,48(sp)
    800046dc:	74a2                	ld	s1,40(sp)
    800046de:	7902                	ld	s2,32(sp)
    800046e0:	69e2                	ld	s3,24(sp)
    800046e2:	6a42                	ld	s4,16(sp)
    800046e4:	6121                	addi	sp,sp,64
    800046e6:	8082                	ret
    iput(ip);
    800046e8:	00000097          	auipc	ra,0x0
    800046ec:	a30080e7          	jalr	-1488(ra) # 80004118 <iput>
    return -1;
    800046f0:	557d                	li	a0,-1
    800046f2:	b7dd                	j	800046d8 <dirlink+0x86>
      panic("dirlink read");
    800046f4:	00004517          	auipc	a0,0x4
    800046f8:	fec50513          	addi	a0,a0,-20 # 800086e0 <syscalls+0x1d8>
    800046fc:	ffffc097          	auipc	ra,0xffffc
    80004700:	e42080e7          	jalr	-446(ra) # 8000053e <panic>
    panic("dirlink");
    80004704:	00004517          	auipc	a0,0x4
    80004708:	0ec50513          	addi	a0,a0,236 # 800087f0 <syscalls+0x2e8>
    8000470c:	ffffc097          	auipc	ra,0xffffc
    80004710:	e32080e7          	jalr	-462(ra) # 8000053e <panic>

0000000080004714 <namei>:

struct inode*
namei(char *path)
{
    80004714:	1101                	addi	sp,sp,-32
    80004716:	ec06                	sd	ra,24(sp)
    80004718:	e822                	sd	s0,16(sp)
    8000471a:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000471c:	fe040613          	addi	a2,s0,-32
    80004720:	4581                	li	a1,0
    80004722:	00000097          	auipc	ra,0x0
    80004726:	dd0080e7          	jalr	-560(ra) # 800044f2 <namex>
}
    8000472a:	60e2                	ld	ra,24(sp)
    8000472c:	6442                	ld	s0,16(sp)
    8000472e:	6105                	addi	sp,sp,32
    80004730:	8082                	ret

0000000080004732 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004732:	1141                	addi	sp,sp,-16
    80004734:	e406                	sd	ra,8(sp)
    80004736:	e022                	sd	s0,0(sp)
    80004738:	0800                	addi	s0,sp,16
    8000473a:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000473c:	4585                	li	a1,1
    8000473e:	00000097          	auipc	ra,0x0
    80004742:	db4080e7          	jalr	-588(ra) # 800044f2 <namex>
}
    80004746:	60a2                	ld	ra,8(sp)
    80004748:	6402                	ld	s0,0(sp)
    8000474a:	0141                	addi	sp,sp,16
    8000474c:	8082                	ret

000000008000474e <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000474e:	1101                	addi	sp,sp,-32
    80004750:	ec06                	sd	ra,24(sp)
    80004752:	e822                	sd	s0,16(sp)
    80004754:	e426                	sd	s1,8(sp)
    80004756:	e04a                	sd	s2,0(sp)
    80004758:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000475a:	0001d917          	auipc	s2,0x1d
    8000475e:	5d690913          	addi	s2,s2,1494 # 80021d30 <log>
    80004762:	01892583          	lw	a1,24(s2)
    80004766:	02892503          	lw	a0,40(s2)
    8000476a:	fffff097          	auipc	ra,0xfffff
    8000476e:	ff2080e7          	jalr	-14(ra) # 8000375c <bread>
    80004772:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004774:	02c92683          	lw	a3,44(s2)
    80004778:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000477a:	02d05763          	blez	a3,800047a8 <write_head+0x5a>
    8000477e:	0001d797          	auipc	a5,0x1d
    80004782:	5e278793          	addi	a5,a5,1506 # 80021d60 <log+0x30>
    80004786:	05c50713          	addi	a4,a0,92
    8000478a:	36fd                	addiw	a3,a3,-1
    8000478c:	1682                	slli	a3,a3,0x20
    8000478e:	9281                	srli	a3,a3,0x20
    80004790:	068a                	slli	a3,a3,0x2
    80004792:	0001d617          	auipc	a2,0x1d
    80004796:	5d260613          	addi	a2,a2,1490 # 80021d64 <log+0x34>
    8000479a:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000479c:	4390                	lw	a2,0(a5)
    8000479e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800047a0:	0791                	addi	a5,a5,4
    800047a2:	0711                	addi	a4,a4,4
    800047a4:	fed79ce3          	bne	a5,a3,8000479c <write_head+0x4e>
  }
  bwrite(buf);
    800047a8:	8526                	mv	a0,s1
    800047aa:	fffff097          	auipc	ra,0xfffff
    800047ae:	0a4080e7          	jalr	164(ra) # 8000384e <bwrite>
  brelse(buf);
    800047b2:	8526                	mv	a0,s1
    800047b4:	fffff097          	auipc	ra,0xfffff
    800047b8:	0d8080e7          	jalr	216(ra) # 8000388c <brelse>
}
    800047bc:	60e2                	ld	ra,24(sp)
    800047be:	6442                	ld	s0,16(sp)
    800047c0:	64a2                	ld	s1,8(sp)
    800047c2:	6902                	ld	s2,0(sp)
    800047c4:	6105                	addi	sp,sp,32
    800047c6:	8082                	ret

00000000800047c8 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800047c8:	0001d797          	auipc	a5,0x1d
    800047cc:	5947a783          	lw	a5,1428(a5) # 80021d5c <log+0x2c>
    800047d0:	0af05d63          	blez	a5,8000488a <install_trans+0xc2>
{
    800047d4:	7139                	addi	sp,sp,-64
    800047d6:	fc06                	sd	ra,56(sp)
    800047d8:	f822                	sd	s0,48(sp)
    800047da:	f426                	sd	s1,40(sp)
    800047dc:	f04a                	sd	s2,32(sp)
    800047de:	ec4e                	sd	s3,24(sp)
    800047e0:	e852                	sd	s4,16(sp)
    800047e2:	e456                	sd	s5,8(sp)
    800047e4:	e05a                	sd	s6,0(sp)
    800047e6:	0080                	addi	s0,sp,64
    800047e8:	8b2a                	mv	s6,a0
    800047ea:	0001da97          	auipc	s5,0x1d
    800047ee:	576a8a93          	addi	s5,s5,1398 # 80021d60 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800047f2:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800047f4:	0001d997          	auipc	s3,0x1d
    800047f8:	53c98993          	addi	s3,s3,1340 # 80021d30 <log>
    800047fc:	a035                	j	80004828 <install_trans+0x60>
      bunpin(dbuf);
    800047fe:	8526                	mv	a0,s1
    80004800:	fffff097          	auipc	ra,0xfffff
    80004804:	166080e7          	jalr	358(ra) # 80003966 <bunpin>
    brelse(lbuf);
    80004808:	854a                	mv	a0,s2
    8000480a:	fffff097          	auipc	ra,0xfffff
    8000480e:	082080e7          	jalr	130(ra) # 8000388c <brelse>
    brelse(dbuf);
    80004812:	8526                	mv	a0,s1
    80004814:	fffff097          	auipc	ra,0xfffff
    80004818:	078080e7          	jalr	120(ra) # 8000388c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000481c:	2a05                	addiw	s4,s4,1
    8000481e:	0a91                	addi	s5,s5,4
    80004820:	02c9a783          	lw	a5,44(s3)
    80004824:	04fa5963          	bge	s4,a5,80004876 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004828:	0189a583          	lw	a1,24(s3)
    8000482c:	014585bb          	addw	a1,a1,s4
    80004830:	2585                	addiw	a1,a1,1
    80004832:	0289a503          	lw	a0,40(s3)
    80004836:	fffff097          	auipc	ra,0xfffff
    8000483a:	f26080e7          	jalr	-218(ra) # 8000375c <bread>
    8000483e:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004840:	000aa583          	lw	a1,0(s5)
    80004844:	0289a503          	lw	a0,40(s3)
    80004848:	fffff097          	auipc	ra,0xfffff
    8000484c:	f14080e7          	jalr	-236(ra) # 8000375c <bread>
    80004850:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004852:	40000613          	li	a2,1024
    80004856:	05890593          	addi	a1,s2,88
    8000485a:	05850513          	addi	a0,a0,88
    8000485e:	ffffc097          	auipc	ra,0xffffc
    80004862:	4e2080e7          	jalr	1250(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004866:	8526                	mv	a0,s1
    80004868:	fffff097          	auipc	ra,0xfffff
    8000486c:	fe6080e7          	jalr	-26(ra) # 8000384e <bwrite>
    if(recovering == 0)
    80004870:	f80b1ce3          	bnez	s6,80004808 <install_trans+0x40>
    80004874:	b769                	j	800047fe <install_trans+0x36>
}
    80004876:	70e2                	ld	ra,56(sp)
    80004878:	7442                	ld	s0,48(sp)
    8000487a:	74a2                	ld	s1,40(sp)
    8000487c:	7902                	ld	s2,32(sp)
    8000487e:	69e2                	ld	s3,24(sp)
    80004880:	6a42                	ld	s4,16(sp)
    80004882:	6aa2                	ld	s5,8(sp)
    80004884:	6b02                	ld	s6,0(sp)
    80004886:	6121                	addi	sp,sp,64
    80004888:	8082                	ret
    8000488a:	8082                	ret

000000008000488c <initlog>:
{
    8000488c:	7179                	addi	sp,sp,-48
    8000488e:	f406                	sd	ra,40(sp)
    80004890:	f022                	sd	s0,32(sp)
    80004892:	ec26                	sd	s1,24(sp)
    80004894:	e84a                	sd	s2,16(sp)
    80004896:	e44e                	sd	s3,8(sp)
    80004898:	1800                	addi	s0,sp,48
    8000489a:	892a                	mv	s2,a0
    8000489c:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000489e:	0001d497          	auipc	s1,0x1d
    800048a2:	49248493          	addi	s1,s1,1170 # 80021d30 <log>
    800048a6:	00004597          	auipc	a1,0x4
    800048aa:	e4a58593          	addi	a1,a1,-438 # 800086f0 <syscalls+0x1e8>
    800048ae:	8526                	mv	a0,s1
    800048b0:	ffffc097          	auipc	ra,0xffffc
    800048b4:	2a4080e7          	jalr	676(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    800048b8:	0149a583          	lw	a1,20(s3)
    800048bc:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800048be:	0109a783          	lw	a5,16(s3)
    800048c2:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800048c4:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800048c8:	854a                	mv	a0,s2
    800048ca:	fffff097          	auipc	ra,0xfffff
    800048ce:	e92080e7          	jalr	-366(ra) # 8000375c <bread>
  log.lh.n = lh->n;
    800048d2:	4d3c                	lw	a5,88(a0)
    800048d4:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800048d6:	02f05563          	blez	a5,80004900 <initlog+0x74>
    800048da:	05c50713          	addi	a4,a0,92
    800048de:	0001d697          	auipc	a3,0x1d
    800048e2:	48268693          	addi	a3,a3,1154 # 80021d60 <log+0x30>
    800048e6:	37fd                	addiw	a5,a5,-1
    800048e8:	1782                	slli	a5,a5,0x20
    800048ea:	9381                	srli	a5,a5,0x20
    800048ec:	078a                	slli	a5,a5,0x2
    800048ee:	06050613          	addi	a2,a0,96
    800048f2:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800048f4:	4310                	lw	a2,0(a4)
    800048f6:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800048f8:	0711                	addi	a4,a4,4
    800048fa:	0691                	addi	a3,a3,4
    800048fc:	fef71ce3          	bne	a4,a5,800048f4 <initlog+0x68>
  brelse(buf);
    80004900:	fffff097          	auipc	ra,0xfffff
    80004904:	f8c080e7          	jalr	-116(ra) # 8000388c <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004908:	4505                	li	a0,1
    8000490a:	00000097          	auipc	ra,0x0
    8000490e:	ebe080e7          	jalr	-322(ra) # 800047c8 <install_trans>
  log.lh.n = 0;
    80004912:	0001d797          	auipc	a5,0x1d
    80004916:	4407a523          	sw	zero,1098(a5) # 80021d5c <log+0x2c>
  write_head(); // clear the log
    8000491a:	00000097          	auipc	ra,0x0
    8000491e:	e34080e7          	jalr	-460(ra) # 8000474e <write_head>
}
    80004922:	70a2                	ld	ra,40(sp)
    80004924:	7402                	ld	s0,32(sp)
    80004926:	64e2                	ld	s1,24(sp)
    80004928:	6942                	ld	s2,16(sp)
    8000492a:	69a2                	ld	s3,8(sp)
    8000492c:	6145                	addi	sp,sp,48
    8000492e:	8082                	ret

0000000080004930 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004930:	1101                	addi	sp,sp,-32
    80004932:	ec06                	sd	ra,24(sp)
    80004934:	e822                	sd	s0,16(sp)
    80004936:	e426                	sd	s1,8(sp)
    80004938:	e04a                	sd	s2,0(sp)
    8000493a:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000493c:	0001d517          	auipc	a0,0x1d
    80004940:	3f450513          	addi	a0,a0,1012 # 80021d30 <log>
    80004944:	ffffc097          	auipc	ra,0xffffc
    80004948:	2a0080e7          	jalr	672(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    8000494c:	0001d497          	auipc	s1,0x1d
    80004950:	3e448493          	addi	s1,s1,996 # 80021d30 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004954:	4979                	li	s2,30
    80004956:	a039                	j	80004964 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004958:	85a6                	mv	a1,s1
    8000495a:	8526                	mv	a0,s1
    8000495c:	ffffe097          	auipc	ra,0xffffe
    80004960:	bf8080e7          	jalr	-1032(ra) # 80002554 <sleep>
    if(log.committing){
    80004964:	50dc                	lw	a5,36(s1)
    80004966:	fbed                	bnez	a5,80004958 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004968:	509c                	lw	a5,32(s1)
    8000496a:	0017871b          	addiw	a4,a5,1
    8000496e:	0007069b          	sext.w	a3,a4
    80004972:	0027179b          	slliw	a5,a4,0x2
    80004976:	9fb9                	addw	a5,a5,a4
    80004978:	0017979b          	slliw	a5,a5,0x1
    8000497c:	54d8                	lw	a4,44(s1)
    8000497e:	9fb9                	addw	a5,a5,a4
    80004980:	00f95963          	bge	s2,a5,80004992 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004984:	85a6                	mv	a1,s1
    80004986:	8526                	mv	a0,s1
    80004988:	ffffe097          	auipc	ra,0xffffe
    8000498c:	bcc080e7          	jalr	-1076(ra) # 80002554 <sleep>
    80004990:	bfd1                	j	80004964 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004992:	0001d517          	auipc	a0,0x1d
    80004996:	39e50513          	addi	a0,a0,926 # 80021d30 <log>
    8000499a:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000499c:	ffffc097          	auipc	ra,0xffffc
    800049a0:	2fc080e7          	jalr	764(ra) # 80000c98 <release>
      break;
    }
  }
}
    800049a4:	60e2                	ld	ra,24(sp)
    800049a6:	6442                	ld	s0,16(sp)
    800049a8:	64a2                	ld	s1,8(sp)
    800049aa:	6902                	ld	s2,0(sp)
    800049ac:	6105                	addi	sp,sp,32
    800049ae:	8082                	ret

00000000800049b0 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800049b0:	7139                	addi	sp,sp,-64
    800049b2:	fc06                	sd	ra,56(sp)
    800049b4:	f822                	sd	s0,48(sp)
    800049b6:	f426                	sd	s1,40(sp)
    800049b8:	f04a                	sd	s2,32(sp)
    800049ba:	ec4e                	sd	s3,24(sp)
    800049bc:	e852                	sd	s4,16(sp)
    800049be:	e456                	sd	s5,8(sp)
    800049c0:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800049c2:	0001d497          	auipc	s1,0x1d
    800049c6:	36e48493          	addi	s1,s1,878 # 80021d30 <log>
    800049ca:	8526                	mv	a0,s1
    800049cc:	ffffc097          	auipc	ra,0xffffc
    800049d0:	218080e7          	jalr	536(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    800049d4:	509c                	lw	a5,32(s1)
    800049d6:	37fd                	addiw	a5,a5,-1
    800049d8:	0007891b          	sext.w	s2,a5
    800049dc:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800049de:	50dc                	lw	a5,36(s1)
    800049e0:	efb9                	bnez	a5,80004a3e <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800049e2:	06091663          	bnez	s2,80004a4e <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800049e6:	0001d497          	auipc	s1,0x1d
    800049ea:	34a48493          	addi	s1,s1,842 # 80021d30 <log>
    800049ee:	4785                	li	a5,1
    800049f0:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800049f2:	8526                	mv	a0,s1
    800049f4:	ffffc097          	auipc	ra,0xffffc
    800049f8:	2a4080e7          	jalr	676(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800049fc:	54dc                	lw	a5,44(s1)
    800049fe:	06f04763          	bgtz	a5,80004a6c <end_op+0xbc>
    acquire(&log.lock);
    80004a02:	0001d497          	auipc	s1,0x1d
    80004a06:	32e48493          	addi	s1,s1,814 # 80021d30 <log>
    80004a0a:	8526                	mv	a0,s1
    80004a0c:	ffffc097          	auipc	ra,0xffffc
    80004a10:	1d8080e7          	jalr	472(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004a14:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004a18:	8526                	mv	a0,s1
    80004a1a:	ffffe097          	auipc	ra,0xffffe
    80004a1e:	cda080e7          	jalr	-806(ra) # 800026f4 <wakeup>
    release(&log.lock);
    80004a22:	8526                	mv	a0,s1
    80004a24:	ffffc097          	auipc	ra,0xffffc
    80004a28:	274080e7          	jalr	628(ra) # 80000c98 <release>
}
    80004a2c:	70e2                	ld	ra,56(sp)
    80004a2e:	7442                	ld	s0,48(sp)
    80004a30:	74a2                	ld	s1,40(sp)
    80004a32:	7902                	ld	s2,32(sp)
    80004a34:	69e2                	ld	s3,24(sp)
    80004a36:	6a42                	ld	s4,16(sp)
    80004a38:	6aa2                	ld	s5,8(sp)
    80004a3a:	6121                	addi	sp,sp,64
    80004a3c:	8082                	ret
    panic("log.committing");
    80004a3e:	00004517          	auipc	a0,0x4
    80004a42:	cba50513          	addi	a0,a0,-838 # 800086f8 <syscalls+0x1f0>
    80004a46:	ffffc097          	auipc	ra,0xffffc
    80004a4a:	af8080e7          	jalr	-1288(ra) # 8000053e <panic>
    wakeup(&log);
    80004a4e:	0001d497          	auipc	s1,0x1d
    80004a52:	2e248493          	addi	s1,s1,738 # 80021d30 <log>
    80004a56:	8526                	mv	a0,s1
    80004a58:	ffffe097          	auipc	ra,0xffffe
    80004a5c:	c9c080e7          	jalr	-868(ra) # 800026f4 <wakeup>
  release(&log.lock);
    80004a60:	8526                	mv	a0,s1
    80004a62:	ffffc097          	auipc	ra,0xffffc
    80004a66:	236080e7          	jalr	566(ra) # 80000c98 <release>
  if(do_commit){
    80004a6a:	b7c9                	j	80004a2c <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004a6c:	0001da97          	auipc	s5,0x1d
    80004a70:	2f4a8a93          	addi	s5,s5,756 # 80021d60 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004a74:	0001da17          	auipc	s4,0x1d
    80004a78:	2bca0a13          	addi	s4,s4,700 # 80021d30 <log>
    80004a7c:	018a2583          	lw	a1,24(s4)
    80004a80:	012585bb          	addw	a1,a1,s2
    80004a84:	2585                	addiw	a1,a1,1
    80004a86:	028a2503          	lw	a0,40(s4)
    80004a8a:	fffff097          	auipc	ra,0xfffff
    80004a8e:	cd2080e7          	jalr	-814(ra) # 8000375c <bread>
    80004a92:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004a94:	000aa583          	lw	a1,0(s5)
    80004a98:	028a2503          	lw	a0,40(s4)
    80004a9c:	fffff097          	auipc	ra,0xfffff
    80004aa0:	cc0080e7          	jalr	-832(ra) # 8000375c <bread>
    80004aa4:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004aa6:	40000613          	li	a2,1024
    80004aaa:	05850593          	addi	a1,a0,88
    80004aae:	05848513          	addi	a0,s1,88
    80004ab2:	ffffc097          	auipc	ra,0xffffc
    80004ab6:	28e080e7          	jalr	654(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    80004aba:	8526                	mv	a0,s1
    80004abc:	fffff097          	auipc	ra,0xfffff
    80004ac0:	d92080e7          	jalr	-622(ra) # 8000384e <bwrite>
    brelse(from);
    80004ac4:	854e                	mv	a0,s3
    80004ac6:	fffff097          	auipc	ra,0xfffff
    80004aca:	dc6080e7          	jalr	-570(ra) # 8000388c <brelse>
    brelse(to);
    80004ace:	8526                	mv	a0,s1
    80004ad0:	fffff097          	auipc	ra,0xfffff
    80004ad4:	dbc080e7          	jalr	-580(ra) # 8000388c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004ad8:	2905                	addiw	s2,s2,1
    80004ada:	0a91                	addi	s5,s5,4
    80004adc:	02ca2783          	lw	a5,44(s4)
    80004ae0:	f8f94ee3          	blt	s2,a5,80004a7c <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004ae4:	00000097          	auipc	ra,0x0
    80004ae8:	c6a080e7          	jalr	-918(ra) # 8000474e <write_head>
    install_trans(0); // Now install writes to home locations
    80004aec:	4501                	li	a0,0
    80004aee:	00000097          	auipc	ra,0x0
    80004af2:	cda080e7          	jalr	-806(ra) # 800047c8 <install_trans>
    log.lh.n = 0;
    80004af6:	0001d797          	auipc	a5,0x1d
    80004afa:	2607a323          	sw	zero,614(a5) # 80021d5c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004afe:	00000097          	auipc	ra,0x0
    80004b02:	c50080e7          	jalr	-944(ra) # 8000474e <write_head>
    80004b06:	bdf5                	j	80004a02 <end_op+0x52>

0000000080004b08 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004b08:	1101                	addi	sp,sp,-32
    80004b0a:	ec06                	sd	ra,24(sp)
    80004b0c:	e822                	sd	s0,16(sp)
    80004b0e:	e426                	sd	s1,8(sp)
    80004b10:	e04a                	sd	s2,0(sp)
    80004b12:	1000                	addi	s0,sp,32
    80004b14:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004b16:	0001d917          	auipc	s2,0x1d
    80004b1a:	21a90913          	addi	s2,s2,538 # 80021d30 <log>
    80004b1e:	854a                	mv	a0,s2
    80004b20:	ffffc097          	auipc	ra,0xffffc
    80004b24:	0c4080e7          	jalr	196(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004b28:	02c92603          	lw	a2,44(s2)
    80004b2c:	47f5                	li	a5,29
    80004b2e:	06c7c563          	blt	a5,a2,80004b98 <log_write+0x90>
    80004b32:	0001d797          	auipc	a5,0x1d
    80004b36:	21a7a783          	lw	a5,538(a5) # 80021d4c <log+0x1c>
    80004b3a:	37fd                	addiw	a5,a5,-1
    80004b3c:	04f65e63          	bge	a2,a5,80004b98 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004b40:	0001d797          	auipc	a5,0x1d
    80004b44:	2107a783          	lw	a5,528(a5) # 80021d50 <log+0x20>
    80004b48:	06f05063          	blez	a5,80004ba8 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004b4c:	4781                	li	a5,0
    80004b4e:	06c05563          	blez	a2,80004bb8 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004b52:	44cc                	lw	a1,12(s1)
    80004b54:	0001d717          	auipc	a4,0x1d
    80004b58:	20c70713          	addi	a4,a4,524 # 80021d60 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004b5c:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004b5e:	4314                	lw	a3,0(a4)
    80004b60:	04b68c63          	beq	a3,a1,80004bb8 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004b64:	2785                	addiw	a5,a5,1
    80004b66:	0711                	addi	a4,a4,4
    80004b68:	fef61be3          	bne	a2,a5,80004b5e <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004b6c:	0621                	addi	a2,a2,8
    80004b6e:	060a                	slli	a2,a2,0x2
    80004b70:	0001d797          	auipc	a5,0x1d
    80004b74:	1c078793          	addi	a5,a5,448 # 80021d30 <log>
    80004b78:	963e                	add	a2,a2,a5
    80004b7a:	44dc                	lw	a5,12(s1)
    80004b7c:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004b7e:	8526                	mv	a0,s1
    80004b80:	fffff097          	auipc	ra,0xfffff
    80004b84:	daa080e7          	jalr	-598(ra) # 8000392a <bpin>
    log.lh.n++;
    80004b88:	0001d717          	auipc	a4,0x1d
    80004b8c:	1a870713          	addi	a4,a4,424 # 80021d30 <log>
    80004b90:	575c                	lw	a5,44(a4)
    80004b92:	2785                	addiw	a5,a5,1
    80004b94:	d75c                	sw	a5,44(a4)
    80004b96:	a835                	j	80004bd2 <log_write+0xca>
    panic("too big a transaction");
    80004b98:	00004517          	auipc	a0,0x4
    80004b9c:	b7050513          	addi	a0,a0,-1168 # 80008708 <syscalls+0x200>
    80004ba0:	ffffc097          	auipc	ra,0xffffc
    80004ba4:	99e080e7          	jalr	-1634(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004ba8:	00004517          	auipc	a0,0x4
    80004bac:	b7850513          	addi	a0,a0,-1160 # 80008720 <syscalls+0x218>
    80004bb0:	ffffc097          	auipc	ra,0xffffc
    80004bb4:	98e080e7          	jalr	-1650(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004bb8:	00878713          	addi	a4,a5,8
    80004bbc:	00271693          	slli	a3,a4,0x2
    80004bc0:	0001d717          	auipc	a4,0x1d
    80004bc4:	17070713          	addi	a4,a4,368 # 80021d30 <log>
    80004bc8:	9736                	add	a4,a4,a3
    80004bca:	44d4                	lw	a3,12(s1)
    80004bcc:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004bce:	faf608e3          	beq	a2,a5,80004b7e <log_write+0x76>
  }
  release(&log.lock);
    80004bd2:	0001d517          	auipc	a0,0x1d
    80004bd6:	15e50513          	addi	a0,a0,350 # 80021d30 <log>
    80004bda:	ffffc097          	auipc	ra,0xffffc
    80004bde:	0be080e7          	jalr	190(ra) # 80000c98 <release>
}
    80004be2:	60e2                	ld	ra,24(sp)
    80004be4:	6442                	ld	s0,16(sp)
    80004be6:	64a2                	ld	s1,8(sp)
    80004be8:	6902                	ld	s2,0(sp)
    80004bea:	6105                	addi	sp,sp,32
    80004bec:	8082                	ret

0000000080004bee <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004bee:	1101                	addi	sp,sp,-32
    80004bf0:	ec06                	sd	ra,24(sp)
    80004bf2:	e822                	sd	s0,16(sp)
    80004bf4:	e426                	sd	s1,8(sp)
    80004bf6:	e04a                	sd	s2,0(sp)
    80004bf8:	1000                	addi	s0,sp,32
    80004bfa:	84aa                	mv	s1,a0
    80004bfc:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004bfe:	00004597          	auipc	a1,0x4
    80004c02:	b4258593          	addi	a1,a1,-1214 # 80008740 <syscalls+0x238>
    80004c06:	0521                	addi	a0,a0,8
    80004c08:	ffffc097          	auipc	ra,0xffffc
    80004c0c:	f4c080e7          	jalr	-180(ra) # 80000b54 <initlock>
  lk->name = name;
    80004c10:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004c14:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004c18:	0204a423          	sw	zero,40(s1)
}
    80004c1c:	60e2                	ld	ra,24(sp)
    80004c1e:	6442                	ld	s0,16(sp)
    80004c20:	64a2                	ld	s1,8(sp)
    80004c22:	6902                	ld	s2,0(sp)
    80004c24:	6105                	addi	sp,sp,32
    80004c26:	8082                	ret

0000000080004c28 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004c28:	1101                	addi	sp,sp,-32
    80004c2a:	ec06                	sd	ra,24(sp)
    80004c2c:	e822                	sd	s0,16(sp)
    80004c2e:	e426                	sd	s1,8(sp)
    80004c30:	e04a                	sd	s2,0(sp)
    80004c32:	1000                	addi	s0,sp,32
    80004c34:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004c36:	00850913          	addi	s2,a0,8
    80004c3a:	854a                	mv	a0,s2
    80004c3c:	ffffc097          	auipc	ra,0xffffc
    80004c40:	fa8080e7          	jalr	-88(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004c44:	409c                	lw	a5,0(s1)
    80004c46:	cb89                	beqz	a5,80004c58 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004c48:	85ca                	mv	a1,s2
    80004c4a:	8526                	mv	a0,s1
    80004c4c:	ffffe097          	auipc	ra,0xffffe
    80004c50:	908080e7          	jalr	-1784(ra) # 80002554 <sleep>
  while (lk->locked) {
    80004c54:	409c                	lw	a5,0(s1)
    80004c56:	fbed                	bnez	a5,80004c48 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004c58:	4785                	li	a5,1
    80004c5a:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004c5c:	ffffd097          	auipc	ra,0xffffd
    80004c60:	100080e7          	jalr	256(ra) # 80001d5c <myproc>
    80004c64:	453c                	lw	a5,72(a0)
    80004c66:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004c68:	854a                	mv	a0,s2
    80004c6a:	ffffc097          	auipc	ra,0xffffc
    80004c6e:	02e080e7          	jalr	46(ra) # 80000c98 <release>
}
    80004c72:	60e2                	ld	ra,24(sp)
    80004c74:	6442                	ld	s0,16(sp)
    80004c76:	64a2                	ld	s1,8(sp)
    80004c78:	6902                	ld	s2,0(sp)
    80004c7a:	6105                	addi	sp,sp,32
    80004c7c:	8082                	ret

0000000080004c7e <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004c7e:	1101                	addi	sp,sp,-32
    80004c80:	ec06                	sd	ra,24(sp)
    80004c82:	e822                	sd	s0,16(sp)
    80004c84:	e426                	sd	s1,8(sp)
    80004c86:	e04a                	sd	s2,0(sp)
    80004c88:	1000                	addi	s0,sp,32
    80004c8a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004c8c:	00850913          	addi	s2,a0,8
    80004c90:	854a                	mv	a0,s2
    80004c92:	ffffc097          	auipc	ra,0xffffc
    80004c96:	f52080e7          	jalr	-174(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004c9a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004c9e:	0204a423          	sw	zero,40(s1)
  
  wakeup(lk);
    80004ca2:	8526                	mv	a0,s1
    80004ca4:	ffffe097          	auipc	ra,0xffffe
    80004ca8:	a50080e7          	jalr	-1456(ra) # 800026f4 <wakeup>
  release(&lk->lk);
    80004cac:	854a                	mv	a0,s2
    80004cae:	ffffc097          	auipc	ra,0xffffc
    80004cb2:	fea080e7          	jalr	-22(ra) # 80000c98 <release>
}
    80004cb6:	60e2                	ld	ra,24(sp)
    80004cb8:	6442                	ld	s0,16(sp)
    80004cba:	64a2                	ld	s1,8(sp)
    80004cbc:	6902                	ld	s2,0(sp)
    80004cbe:	6105                	addi	sp,sp,32
    80004cc0:	8082                	ret

0000000080004cc2 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004cc2:	7179                	addi	sp,sp,-48
    80004cc4:	f406                	sd	ra,40(sp)
    80004cc6:	f022                	sd	s0,32(sp)
    80004cc8:	ec26                	sd	s1,24(sp)
    80004cca:	e84a                	sd	s2,16(sp)
    80004ccc:	e44e                	sd	s3,8(sp)
    80004cce:	1800                	addi	s0,sp,48
    80004cd0:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004cd2:	00850913          	addi	s2,a0,8
    80004cd6:	854a                	mv	a0,s2
    80004cd8:	ffffc097          	auipc	ra,0xffffc
    80004cdc:	f0c080e7          	jalr	-244(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004ce0:	409c                	lw	a5,0(s1)
    80004ce2:	ef99                	bnez	a5,80004d00 <holdingsleep+0x3e>
    80004ce4:	4481                	li	s1,0
  release(&lk->lk);
    80004ce6:	854a                	mv	a0,s2
    80004ce8:	ffffc097          	auipc	ra,0xffffc
    80004cec:	fb0080e7          	jalr	-80(ra) # 80000c98 <release>
  return r;
}
    80004cf0:	8526                	mv	a0,s1
    80004cf2:	70a2                	ld	ra,40(sp)
    80004cf4:	7402                	ld	s0,32(sp)
    80004cf6:	64e2                	ld	s1,24(sp)
    80004cf8:	6942                	ld	s2,16(sp)
    80004cfa:	69a2                	ld	s3,8(sp)
    80004cfc:	6145                	addi	sp,sp,48
    80004cfe:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004d00:	0284a983          	lw	s3,40(s1)
    80004d04:	ffffd097          	auipc	ra,0xffffd
    80004d08:	058080e7          	jalr	88(ra) # 80001d5c <myproc>
    80004d0c:	4524                	lw	s1,72(a0)
    80004d0e:	413484b3          	sub	s1,s1,s3
    80004d12:	0014b493          	seqz	s1,s1
    80004d16:	bfc1                	j	80004ce6 <holdingsleep+0x24>

0000000080004d18 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004d18:	1141                	addi	sp,sp,-16
    80004d1a:	e406                	sd	ra,8(sp)
    80004d1c:	e022                	sd	s0,0(sp)
    80004d1e:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004d20:	00004597          	auipc	a1,0x4
    80004d24:	a3058593          	addi	a1,a1,-1488 # 80008750 <syscalls+0x248>
    80004d28:	0001d517          	auipc	a0,0x1d
    80004d2c:	15050513          	addi	a0,a0,336 # 80021e78 <ftable>
    80004d30:	ffffc097          	auipc	ra,0xffffc
    80004d34:	e24080e7          	jalr	-476(ra) # 80000b54 <initlock>
}
    80004d38:	60a2                	ld	ra,8(sp)
    80004d3a:	6402                	ld	s0,0(sp)
    80004d3c:	0141                	addi	sp,sp,16
    80004d3e:	8082                	ret

0000000080004d40 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004d40:	1101                	addi	sp,sp,-32
    80004d42:	ec06                	sd	ra,24(sp)
    80004d44:	e822                	sd	s0,16(sp)
    80004d46:	e426                	sd	s1,8(sp)
    80004d48:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004d4a:	0001d517          	auipc	a0,0x1d
    80004d4e:	12e50513          	addi	a0,a0,302 # 80021e78 <ftable>
    80004d52:	ffffc097          	auipc	ra,0xffffc
    80004d56:	e92080e7          	jalr	-366(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004d5a:	0001d497          	auipc	s1,0x1d
    80004d5e:	13648493          	addi	s1,s1,310 # 80021e90 <ftable+0x18>
    80004d62:	0001e717          	auipc	a4,0x1e
    80004d66:	0ce70713          	addi	a4,a4,206 # 80022e30 <ftable+0xfb8>
    if(f->ref == 0){
    80004d6a:	40dc                	lw	a5,4(s1)
    80004d6c:	cf99                	beqz	a5,80004d8a <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004d6e:	02848493          	addi	s1,s1,40
    80004d72:	fee49ce3          	bne	s1,a4,80004d6a <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004d76:	0001d517          	auipc	a0,0x1d
    80004d7a:	10250513          	addi	a0,a0,258 # 80021e78 <ftable>
    80004d7e:	ffffc097          	auipc	ra,0xffffc
    80004d82:	f1a080e7          	jalr	-230(ra) # 80000c98 <release>
  return 0;
    80004d86:	4481                	li	s1,0
    80004d88:	a819                	j	80004d9e <filealloc+0x5e>
      f->ref = 1;
    80004d8a:	4785                	li	a5,1
    80004d8c:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004d8e:	0001d517          	auipc	a0,0x1d
    80004d92:	0ea50513          	addi	a0,a0,234 # 80021e78 <ftable>
    80004d96:	ffffc097          	auipc	ra,0xffffc
    80004d9a:	f02080e7          	jalr	-254(ra) # 80000c98 <release>
}
    80004d9e:	8526                	mv	a0,s1
    80004da0:	60e2                	ld	ra,24(sp)
    80004da2:	6442                	ld	s0,16(sp)
    80004da4:	64a2                	ld	s1,8(sp)
    80004da6:	6105                	addi	sp,sp,32
    80004da8:	8082                	ret

0000000080004daa <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004daa:	1101                	addi	sp,sp,-32
    80004dac:	ec06                	sd	ra,24(sp)
    80004dae:	e822                	sd	s0,16(sp)
    80004db0:	e426                	sd	s1,8(sp)
    80004db2:	1000                	addi	s0,sp,32
    80004db4:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004db6:	0001d517          	auipc	a0,0x1d
    80004dba:	0c250513          	addi	a0,a0,194 # 80021e78 <ftable>
    80004dbe:	ffffc097          	auipc	ra,0xffffc
    80004dc2:	e26080e7          	jalr	-474(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004dc6:	40dc                	lw	a5,4(s1)
    80004dc8:	02f05263          	blez	a5,80004dec <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004dcc:	2785                	addiw	a5,a5,1
    80004dce:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004dd0:	0001d517          	auipc	a0,0x1d
    80004dd4:	0a850513          	addi	a0,a0,168 # 80021e78 <ftable>
    80004dd8:	ffffc097          	auipc	ra,0xffffc
    80004ddc:	ec0080e7          	jalr	-320(ra) # 80000c98 <release>
  return f;
}
    80004de0:	8526                	mv	a0,s1
    80004de2:	60e2                	ld	ra,24(sp)
    80004de4:	6442                	ld	s0,16(sp)
    80004de6:	64a2                	ld	s1,8(sp)
    80004de8:	6105                	addi	sp,sp,32
    80004dea:	8082                	ret
    panic("filedup");
    80004dec:	00004517          	auipc	a0,0x4
    80004df0:	96c50513          	addi	a0,a0,-1684 # 80008758 <syscalls+0x250>
    80004df4:	ffffb097          	auipc	ra,0xffffb
    80004df8:	74a080e7          	jalr	1866(ra) # 8000053e <panic>

0000000080004dfc <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004dfc:	7139                	addi	sp,sp,-64
    80004dfe:	fc06                	sd	ra,56(sp)
    80004e00:	f822                	sd	s0,48(sp)
    80004e02:	f426                	sd	s1,40(sp)
    80004e04:	f04a                	sd	s2,32(sp)
    80004e06:	ec4e                	sd	s3,24(sp)
    80004e08:	e852                	sd	s4,16(sp)
    80004e0a:	e456                	sd	s5,8(sp)
    80004e0c:	0080                	addi	s0,sp,64
    80004e0e:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004e10:	0001d517          	auipc	a0,0x1d
    80004e14:	06850513          	addi	a0,a0,104 # 80021e78 <ftable>
    80004e18:	ffffc097          	auipc	ra,0xffffc
    80004e1c:	dcc080e7          	jalr	-564(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004e20:	40dc                	lw	a5,4(s1)
    80004e22:	06f05163          	blez	a5,80004e84 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004e26:	37fd                	addiw	a5,a5,-1
    80004e28:	0007871b          	sext.w	a4,a5
    80004e2c:	c0dc                	sw	a5,4(s1)
    80004e2e:	06e04363          	bgtz	a4,80004e94 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004e32:	0004a903          	lw	s2,0(s1)
    80004e36:	0094ca83          	lbu	s5,9(s1)
    80004e3a:	0104ba03          	ld	s4,16(s1)
    80004e3e:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004e42:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004e46:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004e4a:	0001d517          	auipc	a0,0x1d
    80004e4e:	02e50513          	addi	a0,a0,46 # 80021e78 <ftable>
    80004e52:	ffffc097          	auipc	ra,0xffffc
    80004e56:	e46080e7          	jalr	-442(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004e5a:	4785                	li	a5,1
    80004e5c:	04f90d63          	beq	s2,a5,80004eb6 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004e60:	3979                	addiw	s2,s2,-2
    80004e62:	4785                	li	a5,1
    80004e64:	0527e063          	bltu	a5,s2,80004ea4 <fileclose+0xa8>
    begin_op();
    80004e68:	00000097          	auipc	ra,0x0
    80004e6c:	ac8080e7          	jalr	-1336(ra) # 80004930 <begin_op>
    iput(ff.ip);
    80004e70:	854e                	mv	a0,s3
    80004e72:	fffff097          	auipc	ra,0xfffff
    80004e76:	2a6080e7          	jalr	678(ra) # 80004118 <iput>
    end_op();
    80004e7a:	00000097          	auipc	ra,0x0
    80004e7e:	b36080e7          	jalr	-1226(ra) # 800049b0 <end_op>
    80004e82:	a00d                	j	80004ea4 <fileclose+0xa8>
    panic("fileclose");
    80004e84:	00004517          	auipc	a0,0x4
    80004e88:	8dc50513          	addi	a0,a0,-1828 # 80008760 <syscalls+0x258>
    80004e8c:	ffffb097          	auipc	ra,0xffffb
    80004e90:	6b2080e7          	jalr	1714(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004e94:	0001d517          	auipc	a0,0x1d
    80004e98:	fe450513          	addi	a0,a0,-28 # 80021e78 <ftable>
    80004e9c:	ffffc097          	auipc	ra,0xffffc
    80004ea0:	dfc080e7          	jalr	-516(ra) # 80000c98 <release>
  }
}
    80004ea4:	70e2                	ld	ra,56(sp)
    80004ea6:	7442                	ld	s0,48(sp)
    80004ea8:	74a2                	ld	s1,40(sp)
    80004eaa:	7902                	ld	s2,32(sp)
    80004eac:	69e2                	ld	s3,24(sp)
    80004eae:	6a42                	ld	s4,16(sp)
    80004eb0:	6aa2                	ld	s5,8(sp)
    80004eb2:	6121                	addi	sp,sp,64
    80004eb4:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004eb6:	85d6                	mv	a1,s5
    80004eb8:	8552                	mv	a0,s4
    80004eba:	00000097          	auipc	ra,0x0
    80004ebe:	34c080e7          	jalr	844(ra) # 80005206 <pipeclose>
    80004ec2:	b7cd                	j	80004ea4 <fileclose+0xa8>

0000000080004ec4 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004ec4:	715d                	addi	sp,sp,-80
    80004ec6:	e486                	sd	ra,72(sp)
    80004ec8:	e0a2                	sd	s0,64(sp)
    80004eca:	fc26                	sd	s1,56(sp)
    80004ecc:	f84a                	sd	s2,48(sp)
    80004ece:	f44e                	sd	s3,40(sp)
    80004ed0:	0880                	addi	s0,sp,80
    80004ed2:	84aa                	mv	s1,a0
    80004ed4:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004ed6:	ffffd097          	auipc	ra,0xffffd
    80004eda:	e86080e7          	jalr	-378(ra) # 80001d5c <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004ede:	409c                	lw	a5,0(s1)
    80004ee0:	37f9                	addiw	a5,a5,-2
    80004ee2:	4705                	li	a4,1
    80004ee4:	04f76763          	bltu	a4,a5,80004f32 <filestat+0x6e>
    80004ee8:	892a                	mv	s2,a0
    ilock(f->ip);
    80004eea:	6c88                	ld	a0,24(s1)
    80004eec:	fffff097          	auipc	ra,0xfffff
    80004ef0:	072080e7          	jalr	114(ra) # 80003f5e <ilock>
    stati(f->ip, &st);
    80004ef4:	fb840593          	addi	a1,s0,-72
    80004ef8:	6c88                	ld	a0,24(s1)
    80004efa:	fffff097          	auipc	ra,0xfffff
    80004efe:	2ee080e7          	jalr	750(ra) # 800041e8 <stati>
    iunlock(f->ip);
    80004f02:	6c88                	ld	a0,24(s1)
    80004f04:	fffff097          	auipc	ra,0xfffff
    80004f08:	11c080e7          	jalr	284(ra) # 80004020 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004f0c:	46e1                	li	a3,24
    80004f0e:	fb840613          	addi	a2,s0,-72
    80004f12:	85ce                	mv	a1,s3
    80004f14:	06893503          	ld	a0,104(s2)
    80004f18:	ffffc097          	auipc	ra,0xffffc
    80004f1c:	75a080e7          	jalr	1882(ra) # 80001672 <copyout>
    80004f20:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004f24:	60a6                	ld	ra,72(sp)
    80004f26:	6406                	ld	s0,64(sp)
    80004f28:	74e2                	ld	s1,56(sp)
    80004f2a:	7942                	ld	s2,48(sp)
    80004f2c:	79a2                	ld	s3,40(sp)
    80004f2e:	6161                	addi	sp,sp,80
    80004f30:	8082                	ret
  return -1;
    80004f32:	557d                	li	a0,-1
    80004f34:	bfc5                	j	80004f24 <filestat+0x60>

0000000080004f36 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004f36:	7179                	addi	sp,sp,-48
    80004f38:	f406                	sd	ra,40(sp)
    80004f3a:	f022                	sd	s0,32(sp)
    80004f3c:	ec26                	sd	s1,24(sp)
    80004f3e:	e84a                	sd	s2,16(sp)
    80004f40:	e44e                	sd	s3,8(sp)
    80004f42:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004f44:	00854783          	lbu	a5,8(a0)
    80004f48:	c3d5                	beqz	a5,80004fec <fileread+0xb6>
    80004f4a:	84aa                	mv	s1,a0
    80004f4c:	89ae                	mv	s3,a1
    80004f4e:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004f50:	411c                	lw	a5,0(a0)
    80004f52:	4705                	li	a4,1
    80004f54:	04e78963          	beq	a5,a4,80004fa6 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004f58:	470d                	li	a4,3
    80004f5a:	04e78d63          	beq	a5,a4,80004fb4 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004f5e:	4709                	li	a4,2
    80004f60:	06e79e63          	bne	a5,a4,80004fdc <fileread+0xa6>
    ilock(f->ip);
    80004f64:	6d08                	ld	a0,24(a0)
    80004f66:	fffff097          	auipc	ra,0xfffff
    80004f6a:	ff8080e7          	jalr	-8(ra) # 80003f5e <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004f6e:	874a                	mv	a4,s2
    80004f70:	5094                	lw	a3,32(s1)
    80004f72:	864e                	mv	a2,s3
    80004f74:	4585                	li	a1,1
    80004f76:	6c88                	ld	a0,24(s1)
    80004f78:	fffff097          	auipc	ra,0xfffff
    80004f7c:	29a080e7          	jalr	666(ra) # 80004212 <readi>
    80004f80:	892a                	mv	s2,a0
    80004f82:	00a05563          	blez	a0,80004f8c <fileread+0x56>
      f->off += r;
    80004f86:	509c                	lw	a5,32(s1)
    80004f88:	9fa9                	addw	a5,a5,a0
    80004f8a:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004f8c:	6c88                	ld	a0,24(s1)
    80004f8e:	fffff097          	auipc	ra,0xfffff
    80004f92:	092080e7          	jalr	146(ra) # 80004020 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004f96:	854a                	mv	a0,s2
    80004f98:	70a2                	ld	ra,40(sp)
    80004f9a:	7402                	ld	s0,32(sp)
    80004f9c:	64e2                	ld	s1,24(sp)
    80004f9e:	6942                	ld	s2,16(sp)
    80004fa0:	69a2                	ld	s3,8(sp)
    80004fa2:	6145                	addi	sp,sp,48
    80004fa4:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004fa6:	6908                	ld	a0,16(a0)
    80004fa8:	00000097          	auipc	ra,0x0
    80004fac:	3c8080e7          	jalr	968(ra) # 80005370 <piperead>
    80004fb0:	892a                	mv	s2,a0
    80004fb2:	b7d5                	j	80004f96 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004fb4:	02451783          	lh	a5,36(a0)
    80004fb8:	03079693          	slli	a3,a5,0x30
    80004fbc:	92c1                	srli	a3,a3,0x30
    80004fbe:	4725                	li	a4,9
    80004fc0:	02d76863          	bltu	a4,a3,80004ff0 <fileread+0xba>
    80004fc4:	0792                	slli	a5,a5,0x4
    80004fc6:	0001d717          	auipc	a4,0x1d
    80004fca:	e1270713          	addi	a4,a4,-494 # 80021dd8 <devsw>
    80004fce:	97ba                	add	a5,a5,a4
    80004fd0:	639c                	ld	a5,0(a5)
    80004fd2:	c38d                	beqz	a5,80004ff4 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004fd4:	4505                	li	a0,1
    80004fd6:	9782                	jalr	a5
    80004fd8:	892a                	mv	s2,a0
    80004fda:	bf75                	j	80004f96 <fileread+0x60>
    panic("fileread");
    80004fdc:	00003517          	auipc	a0,0x3
    80004fe0:	79450513          	addi	a0,a0,1940 # 80008770 <syscalls+0x268>
    80004fe4:	ffffb097          	auipc	ra,0xffffb
    80004fe8:	55a080e7          	jalr	1370(ra) # 8000053e <panic>
    return -1;
    80004fec:	597d                	li	s2,-1
    80004fee:	b765                	j	80004f96 <fileread+0x60>
      return -1;
    80004ff0:	597d                	li	s2,-1
    80004ff2:	b755                	j	80004f96 <fileread+0x60>
    80004ff4:	597d                	li	s2,-1
    80004ff6:	b745                	j	80004f96 <fileread+0x60>

0000000080004ff8 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004ff8:	715d                	addi	sp,sp,-80
    80004ffa:	e486                	sd	ra,72(sp)
    80004ffc:	e0a2                	sd	s0,64(sp)
    80004ffe:	fc26                	sd	s1,56(sp)
    80005000:	f84a                	sd	s2,48(sp)
    80005002:	f44e                	sd	s3,40(sp)
    80005004:	f052                	sd	s4,32(sp)
    80005006:	ec56                	sd	s5,24(sp)
    80005008:	e85a                	sd	s6,16(sp)
    8000500a:	e45e                	sd	s7,8(sp)
    8000500c:	e062                	sd	s8,0(sp)
    8000500e:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80005010:	00954783          	lbu	a5,9(a0)
    80005014:	10078663          	beqz	a5,80005120 <filewrite+0x128>
    80005018:	892a                	mv	s2,a0
    8000501a:	8aae                	mv	s5,a1
    8000501c:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000501e:	411c                	lw	a5,0(a0)
    80005020:	4705                	li	a4,1
    80005022:	02e78263          	beq	a5,a4,80005046 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005026:	470d                	li	a4,3
    80005028:	02e78663          	beq	a5,a4,80005054 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000502c:	4709                	li	a4,2
    8000502e:	0ee79163          	bne	a5,a4,80005110 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80005032:	0ac05d63          	blez	a2,800050ec <filewrite+0xf4>
    int i = 0;
    80005036:	4981                	li	s3,0
    80005038:	6b05                	lui	s6,0x1
    8000503a:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    8000503e:	6b85                	lui	s7,0x1
    80005040:	c00b8b9b          	addiw	s7,s7,-1024
    80005044:	a861                	j	800050dc <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80005046:	6908                	ld	a0,16(a0)
    80005048:	00000097          	auipc	ra,0x0
    8000504c:	22e080e7          	jalr	558(ra) # 80005276 <pipewrite>
    80005050:	8a2a                	mv	s4,a0
    80005052:	a045                	j	800050f2 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80005054:	02451783          	lh	a5,36(a0)
    80005058:	03079693          	slli	a3,a5,0x30
    8000505c:	92c1                	srli	a3,a3,0x30
    8000505e:	4725                	li	a4,9
    80005060:	0cd76263          	bltu	a4,a3,80005124 <filewrite+0x12c>
    80005064:	0792                	slli	a5,a5,0x4
    80005066:	0001d717          	auipc	a4,0x1d
    8000506a:	d7270713          	addi	a4,a4,-654 # 80021dd8 <devsw>
    8000506e:	97ba                	add	a5,a5,a4
    80005070:	679c                	ld	a5,8(a5)
    80005072:	cbdd                	beqz	a5,80005128 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80005074:	4505                	li	a0,1
    80005076:	9782                	jalr	a5
    80005078:	8a2a                	mv	s4,a0
    8000507a:	a8a5                	j	800050f2 <filewrite+0xfa>
    8000507c:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80005080:	00000097          	auipc	ra,0x0
    80005084:	8b0080e7          	jalr	-1872(ra) # 80004930 <begin_op>
      ilock(f->ip);
    80005088:	01893503          	ld	a0,24(s2)
    8000508c:	fffff097          	auipc	ra,0xfffff
    80005090:	ed2080e7          	jalr	-302(ra) # 80003f5e <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80005094:	8762                	mv	a4,s8
    80005096:	02092683          	lw	a3,32(s2)
    8000509a:	01598633          	add	a2,s3,s5
    8000509e:	4585                	li	a1,1
    800050a0:	01893503          	ld	a0,24(s2)
    800050a4:	fffff097          	auipc	ra,0xfffff
    800050a8:	266080e7          	jalr	614(ra) # 8000430a <writei>
    800050ac:	84aa                	mv	s1,a0
    800050ae:	00a05763          	blez	a0,800050bc <filewrite+0xc4>
        f->off += r;
    800050b2:	02092783          	lw	a5,32(s2)
    800050b6:	9fa9                	addw	a5,a5,a0
    800050b8:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800050bc:	01893503          	ld	a0,24(s2)
    800050c0:	fffff097          	auipc	ra,0xfffff
    800050c4:	f60080e7          	jalr	-160(ra) # 80004020 <iunlock>
      end_op();
    800050c8:	00000097          	auipc	ra,0x0
    800050cc:	8e8080e7          	jalr	-1816(ra) # 800049b0 <end_op>

      if(r != n1){
    800050d0:	009c1f63          	bne	s8,s1,800050ee <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800050d4:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800050d8:	0149db63          	bge	s3,s4,800050ee <filewrite+0xf6>
      int n1 = n - i;
    800050dc:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800050e0:	84be                	mv	s1,a5
    800050e2:	2781                	sext.w	a5,a5
    800050e4:	f8fb5ce3          	bge	s6,a5,8000507c <filewrite+0x84>
    800050e8:	84de                	mv	s1,s7
    800050ea:	bf49                	j	8000507c <filewrite+0x84>
    int i = 0;
    800050ec:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800050ee:	013a1f63          	bne	s4,s3,8000510c <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800050f2:	8552                	mv	a0,s4
    800050f4:	60a6                	ld	ra,72(sp)
    800050f6:	6406                	ld	s0,64(sp)
    800050f8:	74e2                	ld	s1,56(sp)
    800050fa:	7942                	ld	s2,48(sp)
    800050fc:	79a2                	ld	s3,40(sp)
    800050fe:	7a02                	ld	s4,32(sp)
    80005100:	6ae2                	ld	s5,24(sp)
    80005102:	6b42                	ld	s6,16(sp)
    80005104:	6ba2                	ld	s7,8(sp)
    80005106:	6c02                	ld	s8,0(sp)
    80005108:	6161                	addi	sp,sp,80
    8000510a:	8082                	ret
    ret = (i == n ? n : -1);
    8000510c:	5a7d                	li	s4,-1
    8000510e:	b7d5                	j	800050f2 <filewrite+0xfa>
    panic("filewrite");
    80005110:	00003517          	auipc	a0,0x3
    80005114:	67050513          	addi	a0,a0,1648 # 80008780 <syscalls+0x278>
    80005118:	ffffb097          	auipc	ra,0xffffb
    8000511c:	426080e7          	jalr	1062(ra) # 8000053e <panic>
    return -1;
    80005120:	5a7d                	li	s4,-1
    80005122:	bfc1                	j	800050f2 <filewrite+0xfa>
      return -1;
    80005124:	5a7d                	li	s4,-1
    80005126:	b7f1                	j	800050f2 <filewrite+0xfa>
    80005128:	5a7d                	li	s4,-1
    8000512a:	b7e1                	j	800050f2 <filewrite+0xfa>

000000008000512c <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000512c:	7179                	addi	sp,sp,-48
    8000512e:	f406                	sd	ra,40(sp)
    80005130:	f022                	sd	s0,32(sp)
    80005132:	ec26                	sd	s1,24(sp)
    80005134:	e84a                	sd	s2,16(sp)
    80005136:	e44e                	sd	s3,8(sp)
    80005138:	e052                	sd	s4,0(sp)
    8000513a:	1800                	addi	s0,sp,48
    8000513c:	84aa                	mv	s1,a0
    8000513e:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80005140:	0005b023          	sd	zero,0(a1)
    80005144:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80005148:	00000097          	auipc	ra,0x0
    8000514c:	bf8080e7          	jalr	-1032(ra) # 80004d40 <filealloc>
    80005150:	e088                	sd	a0,0(s1)
    80005152:	c551                	beqz	a0,800051de <pipealloc+0xb2>
    80005154:	00000097          	auipc	ra,0x0
    80005158:	bec080e7          	jalr	-1044(ra) # 80004d40 <filealloc>
    8000515c:	00aa3023          	sd	a0,0(s4)
    80005160:	c92d                	beqz	a0,800051d2 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80005162:	ffffc097          	auipc	ra,0xffffc
    80005166:	992080e7          	jalr	-1646(ra) # 80000af4 <kalloc>
    8000516a:	892a                	mv	s2,a0
    8000516c:	c125                	beqz	a0,800051cc <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    8000516e:	4985                	li	s3,1
    80005170:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80005174:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80005178:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    8000517c:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80005180:	00003597          	auipc	a1,0x3
    80005184:	61058593          	addi	a1,a1,1552 # 80008790 <syscalls+0x288>
    80005188:	ffffc097          	auipc	ra,0xffffc
    8000518c:	9cc080e7          	jalr	-1588(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80005190:	609c                	ld	a5,0(s1)
    80005192:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80005196:	609c                	ld	a5,0(s1)
    80005198:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000519c:	609c                	ld	a5,0(s1)
    8000519e:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800051a2:	609c                	ld	a5,0(s1)
    800051a4:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800051a8:	000a3783          	ld	a5,0(s4)
    800051ac:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800051b0:	000a3783          	ld	a5,0(s4)
    800051b4:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800051b8:	000a3783          	ld	a5,0(s4)
    800051bc:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800051c0:	000a3783          	ld	a5,0(s4)
    800051c4:	0127b823          	sd	s2,16(a5)
  return 0;
    800051c8:	4501                	li	a0,0
    800051ca:	a025                	j	800051f2 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800051cc:	6088                	ld	a0,0(s1)
    800051ce:	e501                	bnez	a0,800051d6 <pipealloc+0xaa>
    800051d0:	a039                	j	800051de <pipealloc+0xb2>
    800051d2:	6088                	ld	a0,0(s1)
    800051d4:	c51d                	beqz	a0,80005202 <pipealloc+0xd6>
    fileclose(*f0);
    800051d6:	00000097          	auipc	ra,0x0
    800051da:	c26080e7          	jalr	-986(ra) # 80004dfc <fileclose>
  if(*f1)
    800051de:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800051e2:	557d                	li	a0,-1
  if(*f1)
    800051e4:	c799                	beqz	a5,800051f2 <pipealloc+0xc6>
    fileclose(*f1);
    800051e6:	853e                	mv	a0,a5
    800051e8:	00000097          	auipc	ra,0x0
    800051ec:	c14080e7          	jalr	-1004(ra) # 80004dfc <fileclose>
  return -1;
    800051f0:	557d                	li	a0,-1
}
    800051f2:	70a2                	ld	ra,40(sp)
    800051f4:	7402                	ld	s0,32(sp)
    800051f6:	64e2                	ld	s1,24(sp)
    800051f8:	6942                	ld	s2,16(sp)
    800051fa:	69a2                	ld	s3,8(sp)
    800051fc:	6a02                	ld	s4,0(sp)
    800051fe:	6145                	addi	sp,sp,48
    80005200:	8082                	ret
  return -1;
    80005202:	557d                	li	a0,-1
    80005204:	b7fd                	j	800051f2 <pipealloc+0xc6>

0000000080005206 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80005206:	1101                	addi	sp,sp,-32
    80005208:	ec06                	sd	ra,24(sp)
    8000520a:	e822                	sd	s0,16(sp)
    8000520c:	e426                	sd	s1,8(sp)
    8000520e:	e04a                	sd	s2,0(sp)
    80005210:	1000                	addi	s0,sp,32
    80005212:	84aa                	mv	s1,a0
    80005214:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80005216:	ffffc097          	auipc	ra,0xffffc
    8000521a:	9ce080e7          	jalr	-1586(ra) # 80000be4 <acquire>
  if(writable){
    8000521e:	02090d63          	beqz	s2,80005258 <pipeclose+0x52>
    pi->writeopen = 0;
    80005222:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80005226:	21848513          	addi	a0,s1,536
    8000522a:	ffffd097          	auipc	ra,0xffffd
    8000522e:	4ca080e7          	jalr	1226(ra) # 800026f4 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005232:	2204b783          	ld	a5,544(s1)
    80005236:	eb95                	bnez	a5,8000526a <pipeclose+0x64>
    release(&pi->lock);
    80005238:	8526                	mv	a0,s1
    8000523a:	ffffc097          	auipc	ra,0xffffc
    8000523e:	a5e080e7          	jalr	-1442(ra) # 80000c98 <release>
    kfree((char*)pi);
    80005242:	8526                	mv	a0,s1
    80005244:	ffffb097          	auipc	ra,0xffffb
    80005248:	7b4080e7          	jalr	1972(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    8000524c:	60e2                	ld	ra,24(sp)
    8000524e:	6442                	ld	s0,16(sp)
    80005250:	64a2                	ld	s1,8(sp)
    80005252:	6902                	ld	s2,0(sp)
    80005254:	6105                	addi	sp,sp,32
    80005256:	8082                	ret
    pi->readopen = 0;
    80005258:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    8000525c:	21c48513          	addi	a0,s1,540
    80005260:	ffffd097          	auipc	ra,0xffffd
    80005264:	494080e7          	jalr	1172(ra) # 800026f4 <wakeup>
    80005268:	b7e9                	j	80005232 <pipeclose+0x2c>
    release(&pi->lock);
    8000526a:	8526                	mv	a0,s1
    8000526c:	ffffc097          	auipc	ra,0xffffc
    80005270:	a2c080e7          	jalr	-1492(ra) # 80000c98 <release>
}
    80005274:	bfe1                	j	8000524c <pipeclose+0x46>

0000000080005276 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005276:	7159                	addi	sp,sp,-112
    80005278:	f486                	sd	ra,104(sp)
    8000527a:	f0a2                	sd	s0,96(sp)
    8000527c:	eca6                	sd	s1,88(sp)
    8000527e:	e8ca                	sd	s2,80(sp)
    80005280:	e4ce                	sd	s3,72(sp)
    80005282:	e0d2                	sd	s4,64(sp)
    80005284:	fc56                	sd	s5,56(sp)
    80005286:	f85a                	sd	s6,48(sp)
    80005288:	f45e                	sd	s7,40(sp)
    8000528a:	f062                	sd	s8,32(sp)
    8000528c:	ec66                	sd	s9,24(sp)
    8000528e:	1880                	addi	s0,sp,112
    80005290:	84aa                	mv	s1,a0
    80005292:	8aae                	mv	s5,a1
    80005294:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005296:	ffffd097          	auipc	ra,0xffffd
    8000529a:	ac6080e7          	jalr	-1338(ra) # 80001d5c <myproc>
    8000529e:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800052a0:	8526                	mv	a0,s1
    800052a2:	ffffc097          	auipc	ra,0xffffc
    800052a6:	942080e7          	jalr	-1726(ra) # 80000be4 <acquire>
  while(i < n){
    800052aa:	0d405163          	blez	s4,8000536c <pipewrite+0xf6>
    800052ae:	8ba6                	mv	s7,s1
  int i = 0;
    800052b0:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800052b2:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800052b4:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800052b8:	21c48c13          	addi	s8,s1,540
    800052bc:	a08d                	j	8000531e <pipewrite+0xa8>
      release(&pi->lock);
    800052be:	8526                	mv	a0,s1
    800052c0:	ffffc097          	auipc	ra,0xffffc
    800052c4:	9d8080e7          	jalr	-1576(ra) # 80000c98 <release>
      return -1;
    800052c8:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800052ca:	854a                	mv	a0,s2
    800052cc:	70a6                	ld	ra,104(sp)
    800052ce:	7406                	ld	s0,96(sp)
    800052d0:	64e6                	ld	s1,88(sp)
    800052d2:	6946                	ld	s2,80(sp)
    800052d4:	69a6                	ld	s3,72(sp)
    800052d6:	6a06                	ld	s4,64(sp)
    800052d8:	7ae2                	ld	s5,56(sp)
    800052da:	7b42                	ld	s6,48(sp)
    800052dc:	7ba2                	ld	s7,40(sp)
    800052de:	7c02                	ld	s8,32(sp)
    800052e0:	6ce2                	ld	s9,24(sp)
    800052e2:	6165                	addi	sp,sp,112
    800052e4:	8082                	ret
      wakeup(&pi->nread);
    800052e6:	8566                	mv	a0,s9
    800052e8:	ffffd097          	auipc	ra,0xffffd
    800052ec:	40c080e7          	jalr	1036(ra) # 800026f4 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800052f0:	85de                	mv	a1,s7
    800052f2:	8562                	mv	a0,s8
    800052f4:	ffffd097          	auipc	ra,0xffffd
    800052f8:	260080e7          	jalr	608(ra) # 80002554 <sleep>
    800052fc:	a839                	j	8000531a <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800052fe:	21c4a783          	lw	a5,540(s1)
    80005302:	0017871b          	addiw	a4,a5,1
    80005306:	20e4ae23          	sw	a4,540(s1)
    8000530a:	1ff7f793          	andi	a5,a5,511
    8000530e:	97a6                	add	a5,a5,s1
    80005310:	f9f44703          	lbu	a4,-97(s0)
    80005314:	00e78c23          	sb	a4,24(a5)
      i++;
    80005318:	2905                	addiw	s2,s2,1
  while(i < n){
    8000531a:	03495d63          	bge	s2,s4,80005354 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    8000531e:	2204a783          	lw	a5,544(s1)
    80005322:	dfd1                	beqz	a5,800052be <pipewrite+0x48>
    80005324:	0409a783          	lw	a5,64(s3)
    80005328:	fbd9                	bnez	a5,800052be <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    8000532a:	2184a783          	lw	a5,536(s1)
    8000532e:	21c4a703          	lw	a4,540(s1)
    80005332:	2007879b          	addiw	a5,a5,512
    80005336:	faf708e3          	beq	a4,a5,800052e6 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000533a:	4685                	li	a3,1
    8000533c:	01590633          	add	a2,s2,s5
    80005340:	f9f40593          	addi	a1,s0,-97
    80005344:	0689b503          	ld	a0,104(s3)
    80005348:	ffffc097          	auipc	ra,0xffffc
    8000534c:	3b6080e7          	jalr	950(ra) # 800016fe <copyin>
    80005350:	fb6517e3          	bne	a0,s6,800052fe <pipewrite+0x88>
  wakeup(&pi->nread);
    80005354:	21848513          	addi	a0,s1,536
    80005358:	ffffd097          	auipc	ra,0xffffd
    8000535c:	39c080e7          	jalr	924(ra) # 800026f4 <wakeup>
  release(&pi->lock);
    80005360:	8526                	mv	a0,s1
    80005362:	ffffc097          	auipc	ra,0xffffc
    80005366:	936080e7          	jalr	-1738(ra) # 80000c98 <release>
  return i;
    8000536a:	b785                	j	800052ca <pipewrite+0x54>
  int i = 0;
    8000536c:	4901                	li	s2,0
    8000536e:	b7dd                	j	80005354 <pipewrite+0xde>

0000000080005370 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005370:	715d                	addi	sp,sp,-80
    80005372:	e486                	sd	ra,72(sp)
    80005374:	e0a2                	sd	s0,64(sp)
    80005376:	fc26                	sd	s1,56(sp)
    80005378:	f84a                	sd	s2,48(sp)
    8000537a:	f44e                	sd	s3,40(sp)
    8000537c:	f052                	sd	s4,32(sp)
    8000537e:	ec56                	sd	s5,24(sp)
    80005380:	e85a                	sd	s6,16(sp)
    80005382:	0880                	addi	s0,sp,80
    80005384:	84aa                	mv	s1,a0
    80005386:	892e                	mv	s2,a1
    80005388:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    8000538a:	ffffd097          	auipc	ra,0xffffd
    8000538e:	9d2080e7          	jalr	-1582(ra) # 80001d5c <myproc>
    80005392:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005394:	8b26                	mv	s6,s1
    80005396:	8526                	mv	a0,s1
    80005398:	ffffc097          	auipc	ra,0xffffc
    8000539c:	84c080e7          	jalr	-1972(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800053a0:	2184a703          	lw	a4,536(s1)
    800053a4:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800053a8:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800053ac:	02f71463          	bne	a4,a5,800053d4 <piperead+0x64>
    800053b0:	2244a783          	lw	a5,548(s1)
    800053b4:	c385                	beqz	a5,800053d4 <piperead+0x64>
    if(pr->killed){
    800053b6:	040a2783          	lw	a5,64(s4)
    800053ba:	ebc1                	bnez	a5,8000544a <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800053bc:	85da                	mv	a1,s6
    800053be:	854e                	mv	a0,s3
    800053c0:	ffffd097          	auipc	ra,0xffffd
    800053c4:	194080e7          	jalr	404(ra) # 80002554 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800053c8:	2184a703          	lw	a4,536(s1)
    800053cc:	21c4a783          	lw	a5,540(s1)
    800053d0:	fef700e3          	beq	a4,a5,800053b0 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800053d4:	09505263          	blez	s5,80005458 <piperead+0xe8>
    800053d8:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800053da:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    800053dc:	2184a783          	lw	a5,536(s1)
    800053e0:	21c4a703          	lw	a4,540(s1)
    800053e4:	02f70d63          	beq	a4,a5,8000541e <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800053e8:	0017871b          	addiw	a4,a5,1
    800053ec:	20e4ac23          	sw	a4,536(s1)
    800053f0:	1ff7f793          	andi	a5,a5,511
    800053f4:	97a6                	add	a5,a5,s1
    800053f6:	0187c783          	lbu	a5,24(a5)
    800053fa:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800053fe:	4685                	li	a3,1
    80005400:	fbf40613          	addi	a2,s0,-65
    80005404:	85ca                	mv	a1,s2
    80005406:	068a3503          	ld	a0,104(s4)
    8000540a:	ffffc097          	auipc	ra,0xffffc
    8000540e:	268080e7          	jalr	616(ra) # 80001672 <copyout>
    80005412:	01650663          	beq	a0,s6,8000541e <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005416:	2985                	addiw	s3,s3,1
    80005418:	0905                	addi	s2,s2,1
    8000541a:	fd3a91e3          	bne	s5,s3,800053dc <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    8000541e:	21c48513          	addi	a0,s1,540
    80005422:	ffffd097          	auipc	ra,0xffffd
    80005426:	2d2080e7          	jalr	722(ra) # 800026f4 <wakeup>
  release(&pi->lock);
    8000542a:	8526                	mv	a0,s1
    8000542c:	ffffc097          	auipc	ra,0xffffc
    80005430:	86c080e7          	jalr	-1940(ra) # 80000c98 <release>
  return i;
}
    80005434:	854e                	mv	a0,s3
    80005436:	60a6                	ld	ra,72(sp)
    80005438:	6406                	ld	s0,64(sp)
    8000543a:	74e2                	ld	s1,56(sp)
    8000543c:	7942                	ld	s2,48(sp)
    8000543e:	79a2                	ld	s3,40(sp)
    80005440:	7a02                	ld	s4,32(sp)
    80005442:	6ae2                	ld	s5,24(sp)
    80005444:	6b42                	ld	s6,16(sp)
    80005446:	6161                	addi	sp,sp,80
    80005448:	8082                	ret
      release(&pi->lock);
    8000544a:	8526                	mv	a0,s1
    8000544c:	ffffc097          	auipc	ra,0xffffc
    80005450:	84c080e7          	jalr	-1972(ra) # 80000c98 <release>
      return -1;
    80005454:	59fd                	li	s3,-1
    80005456:	bff9                	j	80005434 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005458:	4981                	li	s3,0
    8000545a:	b7d1                	j	8000541e <piperead+0xae>

000000008000545c <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    8000545c:	df010113          	addi	sp,sp,-528
    80005460:	20113423          	sd	ra,520(sp)
    80005464:	20813023          	sd	s0,512(sp)
    80005468:	ffa6                	sd	s1,504(sp)
    8000546a:	fbca                	sd	s2,496(sp)
    8000546c:	f7ce                	sd	s3,488(sp)
    8000546e:	f3d2                	sd	s4,480(sp)
    80005470:	efd6                	sd	s5,472(sp)
    80005472:	ebda                	sd	s6,464(sp)
    80005474:	e7de                	sd	s7,456(sp)
    80005476:	e3e2                	sd	s8,448(sp)
    80005478:	ff66                	sd	s9,440(sp)
    8000547a:	fb6a                	sd	s10,432(sp)
    8000547c:	f76e                	sd	s11,424(sp)
    8000547e:	0c00                	addi	s0,sp,528
    80005480:	84aa                	mv	s1,a0
    80005482:	dea43c23          	sd	a0,-520(s0)
    80005486:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    8000548a:	ffffd097          	auipc	ra,0xffffd
    8000548e:	8d2080e7          	jalr	-1838(ra) # 80001d5c <myproc>
    80005492:	892a                	mv	s2,a0

  begin_op();
    80005494:	fffff097          	auipc	ra,0xfffff
    80005498:	49c080e7          	jalr	1180(ra) # 80004930 <begin_op>

  if((ip = namei(path)) == 0){
    8000549c:	8526                	mv	a0,s1
    8000549e:	fffff097          	auipc	ra,0xfffff
    800054a2:	276080e7          	jalr	630(ra) # 80004714 <namei>
    800054a6:	c92d                	beqz	a0,80005518 <exec+0xbc>
    800054a8:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800054aa:	fffff097          	auipc	ra,0xfffff
    800054ae:	ab4080e7          	jalr	-1356(ra) # 80003f5e <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800054b2:	04000713          	li	a4,64
    800054b6:	4681                	li	a3,0
    800054b8:	e5040613          	addi	a2,s0,-432
    800054bc:	4581                	li	a1,0
    800054be:	8526                	mv	a0,s1
    800054c0:	fffff097          	auipc	ra,0xfffff
    800054c4:	d52080e7          	jalr	-686(ra) # 80004212 <readi>
    800054c8:	04000793          	li	a5,64
    800054cc:	00f51a63          	bne	a0,a5,800054e0 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    800054d0:	e5042703          	lw	a4,-432(s0)
    800054d4:	464c47b7          	lui	a5,0x464c4
    800054d8:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800054dc:	04f70463          	beq	a4,a5,80005524 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800054e0:	8526                	mv	a0,s1
    800054e2:	fffff097          	auipc	ra,0xfffff
    800054e6:	cde080e7          	jalr	-802(ra) # 800041c0 <iunlockput>
    end_op();
    800054ea:	fffff097          	auipc	ra,0xfffff
    800054ee:	4c6080e7          	jalr	1222(ra) # 800049b0 <end_op>
  }
  return -1;
    800054f2:	557d                	li	a0,-1
}
    800054f4:	20813083          	ld	ra,520(sp)
    800054f8:	20013403          	ld	s0,512(sp)
    800054fc:	74fe                	ld	s1,504(sp)
    800054fe:	795e                	ld	s2,496(sp)
    80005500:	79be                	ld	s3,488(sp)
    80005502:	7a1e                	ld	s4,480(sp)
    80005504:	6afe                	ld	s5,472(sp)
    80005506:	6b5e                	ld	s6,464(sp)
    80005508:	6bbe                	ld	s7,456(sp)
    8000550a:	6c1e                	ld	s8,448(sp)
    8000550c:	7cfa                	ld	s9,440(sp)
    8000550e:	7d5a                	ld	s10,432(sp)
    80005510:	7dba                	ld	s11,424(sp)
    80005512:	21010113          	addi	sp,sp,528
    80005516:	8082                	ret
    end_op();
    80005518:	fffff097          	auipc	ra,0xfffff
    8000551c:	498080e7          	jalr	1176(ra) # 800049b0 <end_op>
    return -1;
    80005520:	557d                	li	a0,-1
    80005522:	bfc9                	j	800054f4 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005524:	854a                	mv	a0,s2
    80005526:	ffffd097          	auipc	ra,0xffffd
    8000552a:	8ec080e7          	jalr	-1812(ra) # 80001e12 <proc_pagetable>
    8000552e:	8baa                	mv	s7,a0
    80005530:	d945                	beqz	a0,800054e0 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005532:	e7042983          	lw	s3,-400(s0)
    80005536:	e8845783          	lhu	a5,-376(s0)
    8000553a:	c7ad                	beqz	a5,800055a4 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000553c:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000553e:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80005540:	6c85                	lui	s9,0x1
    80005542:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005546:	def43823          	sd	a5,-528(s0)
    8000554a:	a42d                	j	80005774 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    8000554c:	00003517          	auipc	a0,0x3
    80005550:	24c50513          	addi	a0,a0,588 # 80008798 <syscalls+0x290>
    80005554:	ffffb097          	auipc	ra,0xffffb
    80005558:	fea080e7          	jalr	-22(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    8000555c:	8756                	mv	a4,s5
    8000555e:	012d86bb          	addw	a3,s11,s2
    80005562:	4581                	li	a1,0
    80005564:	8526                	mv	a0,s1
    80005566:	fffff097          	auipc	ra,0xfffff
    8000556a:	cac080e7          	jalr	-852(ra) # 80004212 <readi>
    8000556e:	2501                	sext.w	a0,a0
    80005570:	1aaa9963          	bne	s5,a0,80005722 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80005574:	6785                	lui	a5,0x1
    80005576:	0127893b          	addw	s2,a5,s2
    8000557a:	77fd                	lui	a5,0xfffff
    8000557c:	01478a3b          	addw	s4,a5,s4
    80005580:	1f897163          	bgeu	s2,s8,80005762 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80005584:	02091593          	slli	a1,s2,0x20
    80005588:	9181                	srli	a1,a1,0x20
    8000558a:	95ea                	add	a1,a1,s10
    8000558c:	855e                	mv	a0,s7
    8000558e:	ffffc097          	auipc	ra,0xffffc
    80005592:	ae0080e7          	jalr	-1312(ra) # 8000106e <walkaddr>
    80005596:	862a                	mv	a2,a0
    if(pa == 0)
    80005598:	d955                	beqz	a0,8000554c <exec+0xf0>
      n = PGSIZE;
    8000559a:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    8000559c:	fd9a70e3          	bgeu	s4,s9,8000555c <exec+0x100>
      n = sz - i;
    800055a0:	8ad2                	mv	s5,s4
    800055a2:	bf6d                	j	8000555c <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800055a4:	4901                	li	s2,0
  iunlockput(ip);
    800055a6:	8526                	mv	a0,s1
    800055a8:	fffff097          	auipc	ra,0xfffff
    800055ac:	c18080e7          	jalr	-1000(ra) # 800041c0 <iunlockput>
  end_op();
    800055b0:	fffff097          	auipc	ra,0xfffff
    800055b4:	400080e7          	jalr	1024(ra) # 800049b0 <end_op>
  p = myproc();
    800055b8:	ffffc097          	auipc	ra,0xffffc
    800055bc:	7a4080e7          	jalr	1956(ra) # 80001d5c <myproc>
    800055c0:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    800055c2:	06053d03          	ld	s10,96(a0)
  sz = PGROUNDUP(sz);
    800055c6:	6785                	lui	a5,0x1
    800055c8:	17fd                	addi	a5,a5,-1
    800055ca:	993e                	add	s2,s2,a5
    800055cc:	757d                	lui	a0,0xfffff
    800055ce:	00a977b3          	and	a5,s2,a0
    800055d2:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800055d6:	6609                	lui	a2,0x2
    800055d8:	963e                	add	a2,a2,a5
    800055da:	85be                	mv	a1,a5
    800055dc:	855e                	mv	a0,s7
    800055de:	ffffc097          	auipc	ra,0xffffc
    800055e2:	e44080e7          	jalr	-444(ra) # 80001422 <uvmalloc>
    800055e6:	8b2a                	mv	s6,a0
  ip = 0;
    800055e8:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800055ea:	12050c63          	beqz	a0,80005722 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    800055ee:	75f9                	lui	a1,0xffffe
    800055f0:	95aa                	add	a1,a1,a0
    800055f2:	855e                	mv	a0,s7
    800055f4:	ffffc097          	auipc	ra,0xffffc
    800055f8:	04c080e7          	jalr	76(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    800055fc:	7c7d                	lui	s8,0xfffff
    800055fe:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80005600:	e0043783          	ld	a5,-512(s0)
    80005604:	6388                	ld	a0,0(a5)
    80005606:	c535                	beqz	a0,80005672 <exec+0x216>
    80005608:	e9040993          	addi	s3,s0,-368
    8000560c:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005610:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005612:	ffffc097          	auipc	ra,0xffffc
    80005616:	852080e7          	jalr	-1966(ra) # 80000e64 <strlen>
    8000561a:	2505                	addiw	a0,a0,1
    8000561c:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005620:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005624:	13896363          	bltu	s2,s8,8000574a <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005628:	e0043d83          	ld	s11,-512(s0)
    8000562c:	000dba03          	ld	s4,0(s11)
    80005630:	8552                	mv	a0,s4
    80005632:	ffffc097          	auipc	ra,0xffffc
    80005636:	832080e7          	jalr	-1998(ra) # 80000e64 <strlen>
    8000563a:	0015069b          	addiw	a3,a0,1
    8000563e:	8652                	mv	a2,s4
    80005640:	85ca                	mv	a1,s2
    80005642:	855e                	mv	a0,s7
    80005644:	ffffc097          	auipc	ra,0xffffc
    80005648:	02e080e7          	jalr	46(ra) # 80001672 <copyout>
    8000564c:	10054363          	bltz	a0,80005752 <exec+0x2f6>
    ustack[argc] = sp;
    80005650:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005654:	0485                	addi	s1,s1,1
    80005656:	008d8793          	addi	a5,s11,8
    8000565a:	e0f43023          	sd	a5,-512(s0)
    8000565e:	008db503          	ld	a0,8(s11)
    80005662:	c911                	beqz	a0,80005676 <exec+0x21a>
    if(argc >= MAXARG)
    80005664:	09a1                	addi	s3,s3,8
    80005666:	fb3c96e3          	bne	s9,s3,80005612 <exec+0x1b6>
  sz = sz1;
    8000566a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000566e:	4481                	li	s1,0
    80005670:	a84d                	j	80005722 <exec+0x2c6>
  sp = sz;
    80005672:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005674:	4481                	li	s1,0
  ustack[argc] = 0;
    80005676:	00349793          	slli	a5,s1,0x3
    8000567a:	f9040713          	addi	a4,s0,-112
    8000567e:	97ba                	add	a5,a5,a4
    80005680:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80005684:	00148693          	addi	a3,s1,1
    80005688:	068e                	slli	a3,a3,0x3
    8000568a:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000568e:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005692:	01897663          	bgeu	s2,s8,8000569e <exec+0x242>
  sz = sz1;
    80005696:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000569a:	4481                	li	s1,0
    8000569c:	a059                	j	80005722 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000569e:	e9040613          	addi	a2,s0,-368
    800056a2:	85ca                	mv	a1,s2
    800056a4:	855e                	mv	a0,s7
    800056a6:	ffffc097          	auipc	ra,0xffffc
    800056aa:	fcc080e7          	jalr	-52(ra) # 80001672 <copyout>
    800056ae:	0a054663          	bltz	a0,8000575a <exec+0x2fe>
  p->trapframe->a1 = sp;
    800056b2:	070ab783          	ld	a5,112(s5)
    800056b6:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800056ba:	df843783          	ld	a5,-520(s0)
    800056be:	0007c703          	lbu	a4,0(a5)
    800056c2:	cf11                	beqz	a4,800056de <exec+0x282>
    800056c4:	0785                	addi	a5,a5,1
    if(*s == '/')
    800056c6:	02f00693          	li	a3,47
    800056ca:	a039                	j	800056d8 <exec+0x27c>
      last = s+1;
    800056cc:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800056d0:	0785                	addi	a5,a5,1
    800056d2:	fff7c703          	lbu	a4,-1(a5)
    800056d6:	c701                	beqz	a4,800056de <exec+0x282>
    if(*s == '/')
    800056d8:	fed71ce3          	bne	a4,a3,800056d0 <exec+0x274>
    800056dc:	bfc5                	j	800056cc <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    800056de:	4641                	li	a2,16
    800056e0:	df843583          	ld	a1,-520(s0)
    800056e4:	170a8513          	addi	a0,s5,368
    800056e8:	ffffb097          	auipc	ra,0xffffb
    800056ec:	74a080e7          	jalr	1866(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    800056f0:	068ab503          	ld	a0,104(s5)
  p->pagetable = pagetable;
    800056f4:	077ab423          	sd	s7,104(s5)
  p->sz = sz;
    800056f8:	076ab023          	sd	s6,96(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800056fc:	070ab783          	ld	a5,112(s5)
    80005700:	e6843703          	ld	a4,-408(s0)
    80005704:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005706:	070ab783          	ld	a5,112(s5)
    8000570a:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000570e:	85ea                	mv	a1,s10
    80005710:	ffffc097          	auipc	ra,0xffffc
    80005714:	79e080e7          	jalr	1950(ra) # 80001eae <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005718:	0004851b          	sext.w	a0,s1
    8000571c:	bbe1                	j	800054f4 <exec+0x98>
    8000571e:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005722:	e0843583          	ld	a1,-504(s0)
    80005726:	855e                	mv	a0,s7
    80005728:	ffffc097          	auipc	ra,0xffffc
    8000572c:	786080e7          	jalr	1926(ra) # 80001eae <proc_freepagetable>
  if(ip){
    80005730:	da0498e3          	bnez	s1,800054e0 <exec+0x84>
  return -1;
    80005734:	557d                	li	a0,-1
    80005736:	bb7d                	j	800054f4 <exec+0x98>
    80005738:	e1243423          	sd	s2,-504(s0)
    8000573c:	b7dd                	j	80005722 <exec+0x2c6>
    8000573e:	e1243423          	sd	s2,-504(s0)
    80005742:	b7c5                	j	80005722 <exec+0x2c6>
    80005744:	e1243423          	sd	s2,-504(s0)
    80005748:	bfe9                	j	80005722 <exec+0x2c6>
  sz = sz1;
    8000574a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000574e:	4481                	li	s1,0
    80005750:	bfc9                	j	80005722 <exec+0x2c6>
  sz = sz1;
    80005752:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005756:	4481                	li	s1,0
    80005758:	b7e9                	j	80005722 <exec+0x2c6>
  sz = sz1;
    8000575a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000575e:	4481                	li	s1,0
    80005760:	b7c9                	j	80005722 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005762:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005766:	2b05                	addiw	s6,s6,1
    80005768:	0389899b          	addiw	s3,s3,56
    8000576c:	e8845783          	lhu	a5,-376(s0)
    80005770:	e2fb5be3          	bge	s6,a5,800055a6 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005774:	2981                	sext.w	s3,s3
    80005776:	03800713          	li	a4,56
    8000577a:	86ce                	mv	a3,s3
    8000577c:	e1840613          	addi	a2,s0,-488
    80005780:	4581                	li	a1,0
    80005782:	8526                	mv	a0,s1
    80005784:	fffff097          	auipc	ra,0xfffff
    80005788:	a8e080e7          	jalr	-1394(ra) # 80004212 <readi>
    8000578c:	03800793          	li	a5,56
    80005790:	f8f517e3          	bne	a0,a5,8000571e <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005794:	e1842783          	lw	a5,-488(s0)
    80005798:	4705                	li	a4,1
    8000579a:	fce796e3          	bne	a5,a4,80005766 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    8000579e:	e4043603          	ld	a2,-448(s0)
    800057a2:	e3843783          	ld	a5,-456(s0)
    800057a6:	f8f669e3          	bltu	a2,a5,80005738 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800057aa:	e2843783          	ld	a5,-472(s0)
    800057ae:	963e                	add	a2,a2,a5
    800057b0:	f8f667e3          	bltu	a2,a5,8000573e <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800057b4:	85ca                	mv	a1,s2
    800057b6:	855e                	mv	a0,s7
    800057b8:	ffffc097          	auipc	ra,0xffffc
    800057bc:	c6a080e7          	jalr	-918(ra) # 80001422 <uvmalloc>
    800057c0:	e0a43423          	sd	a0,-504(s0)
    800057c4:	d141                	beqz	a0,80005744 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    800057c6:	e2843d03          	ld	s10,-472(s0)
    800057ca:	df043783          	ld	a5,-528(s0)
    800057ce:	00fd77b3          	and	a5,s10,a5
    800057d2:	fba1                	bnez	a5,80005722 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800057d4:	e2042d83          	lw	s11,-480(s0)
    800057d8:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800057dc:	f80c03e3          	beqz	s8,80005762 <exec+0x306>
    800057e0:	8a62                	mv	s4,s8
    800057e2:	4901                	li	s2,0
    800057e4:	b345                	j	80005584 <exec+0x128>

00000000800057e6 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800057e6:	7179                	addi	sp,sp,-48
    800057e8:	f406                	sd	ra,40(sp)
    800057ea:	f022                	sd	s0,32(sp)
    800057ec:	ec26                	sd	s1,24(sp)
    800057ee:	e84a                	sd	s2,16(sp)
    800057f0:	1800                	addi	s0,sp,48
    800057f2:	892e                	mv	s2,a1
    800057f4:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800057f6:	fdc40593          	addi	a1,s0,-36
    800057fa:	ffffe097          	auipc	ra,0xffffe
    800057fe:	ba8080e7          	jalr	-1112(ra) # 800033a2 <argint>
    80005802:	04054063          	bltz	a0,80005842 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005806:	fdc42703          	lw	a4,-36(s0)
    8000580a:	47bd                	li	a5,15
    8000580c:	02e7ed63          	bltu	a5,a4,80005846 <argfd+0x60>
    80005810:	ffffc097          	auipc	ra,0xffffc
    80005814:	54c080e7          	jalr	1356(ra) # 80001d5c <myproc>
    80005818:	fdc42703          	lw	a4,-36(s0)
    8000581c:	01c70793          	addi	a5,a4,28
    80005820:	078e                	slli	a5,a5,0x3
    80005822:	953e                	add	a0,a0,a5
    80005824:	651c                	ld	a5,8(a0)
    80005826:	c395                	beqz	a5,8000584a <argfd+0x64>
    return -1;
  if(pfd)
    80005828:	00090463          	beqz	s2,80005830 <argfd+0x4a>
    *pfd = fd;
    8000582c:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005830:	4501                	li	a0,0
  if(pf)
    80005832:	c091                	beqz	s1,80005836 <argfd+0x50>
    *pf = f;
    80005834:	e09c                	sd	a5,0(s1)
}
    80005836:	70a2                	ld	ra,40(sp)
    80005838:	7402                	ld	s0,32(sp)
    8000583a:	64e2                	ld	s1,24(sp)
    8000583c:	6942                	ld	s2,16(sp)
    8000583e:	6145                	addi	sp,sp,48
    80005840:	8082                	ret
    return -1;
    80005842:	557d                	li	a0,-1
    80005844:	bfcd                	j	80005836 <argfd+0x50>
    return -1;
    80005846:	557d                	li	a0,-1
    80005848:	b7fd                	j	80005836 <argfd+0x50>
    8000584a:	557d                	li	a0,-1
    8000584c:	b7ed                	j	80005836 <argfd+0x50>

000000008000584e <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000584e:	1101                	addi	sp,sp,-32
    80005850:	ec06                	sd	ra,24(sp)
    80005852:	e822                	sd	s0,16(sp)
    80005854:	e426                	sd	s1,8(sp)
    80005856:	1000                	addi	s0,sp,32
    80005858:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000585a:	ffffc097          	auipc	ra,0xffffc
    8000585e:	502080e7          	jalr	1282(ra) # 80001d5c <myproc>
    80005862:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005864:	0e850793          	addi	a5,a0,232 # fffffffffffff0e8 <end+0xffffffff7ffd90e8>
    80005868:	4501                	li	a0,0
    8000586a:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000586c:	6398                	ld	a4,0(a5)
    8000586e:	cb19                	beqz	a4,80005884 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005870:	2505                	addiw	a0,a0,1
    80005872:	07a1                	addi	a5,a5,8
    80005874:	fed51ce3          	bne	a0,a3,8000586c <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005878:	557d                	li	a0,-1
}
    8000587a:	60e2                	ld	ra,24(sp)
    8000587c:	6442                	ld	s0,16(sp)
    8000587e:	64a2                	ld	s1,8(sp)
    80005880:	6105                	addi	sp,sp,32
    80005882:	8082                	ret
      p->ofile[fd] = f;
    80005884:	01c50793          	addi	a5,a0,28
    80005888:	078e                	slli	a5,a5,0x3
    8000588a:	963e                	add	a2,a2,a5
    8000588c:	e604                	sd	s1,8(a2)
      return fd;
    8000588e:	b7f5                	j	8000587a <fdalloc+0x2c>

0000000080005890 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005890:	715d                	addi	sp,sp,-80
    80005892:	e486                	sd	ra,72(sp)
    80005894:	e0a2                	sd	s0,64(sp)
    80005896:	fc26                	sd	s1,56(sp)
    80005898:	f84a                	sd	s2,48(sp)
    8000589a:	f44e                	sd	s3,40(sp)
    8000589c:	f052                	sd	s4,32(sp)
    8000589e:	ec56                	sd	s5,24(sp)
    800058a0:	0880                	addi	s0,sp,80
    800058a2:	89ae                	mv	s3,a1
    800058a4:	8ab2                	mv	s5,a2
    800058a6:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800058a8:	fb040593          	addi	a1,s0,-80
    800058ac:	fffff097          	auipc	ra,0xfffff
    800058b0:	e86080e7          	jalr	-378(ra) # 80004732 <nameiparent>
    800058b4:	892a                	mv	s2,a0
    800058b6:	12050f63          	beqz	a0,800059f4 <create+0x164>
    return 0;

  ilock(dp);
    800058ba:	ffffe097          	auipc	ra,0xffffe
    800058be:	6a4080e7          	jalr	1700(ra) # 80003f5e <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800058c2:	4601                	li	a2,0
    800058c4:	fb040593          	addi	a1,s0,-80
    800058c8:	854a                	mv	a0,s2
    800058ca:	fffff097          	auipc	ra,0xfffff
    800058ce:	b78080e7          	jalr	-1160(ra) # 80004442 <dirlookup>
    800058d2:	84aa                	mv	s1,a0
    800058d4:	c921                	beqz	a0,80005924 <create+0x94>
    iunlockput(dp);
    800058d6:	854a                	mv	a0,s2
    800058d8:	fffff097          	auipc	ra,0xfffff
    800058dc:	8e8080e7          	jalr	-1816(ra) # 800041c0 <iunlockput>
    ilock(ip);
    800058e0:	8526                	mv	a0,s1
    800058e2:	ffffe097          	auipc	ra,0xffffe
    800058e6:	67c080e7          	jalr	1660(ra) # 80003f5e <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800058ea:	2981                	sext.w	s3,s3
    800058ec:	4789                	li	a5,2
    800058ee:	02f99463          	bne	s3,a5,80005916 <create+0x86>
    800058f2:	0444d783          	lhu	a5,68(s1)
    800058f6:	37f9                	addiw	a5,a5,-2
    800058f8:	17c2                	slli	a5,a5,0x30
    800058fa:	93c1                	srli	a5,a5,0x30
    800058fc:	4705                	li	a4,1
    800058fe:	00f76c63          	bltu	a4,a5,80005916 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005902:	8526                	mv	a0,s1
    80005904:	60a6                	ld	ra,72(sp)
    80005906:	6406                	ld	s0,64(sp)
    80005908:	74e2                	ld	s1,56(sp)
    8000590a:	7942                	ld	s2,48(sp)
    8000590c:	79a2                	ld	s3,40(sp)
    8000590e:	7a02                	ld	s4,32(sp)
    80005910:	6ae2                	ld	s5,24(sp)
    80005912:	6161                	addi	sp,sp,80
    80005914:	8082                	ret
    iunlockput(ip);
    80005916:	8526                	mv	a0,s1
    80005918:	fffff097          	auipc	ra,0xfffff
    8000591c:	8a8080e7          	jalr	-1880(ra) # 800041c0 <iunlockput>
    return 0;
    80005920:	4481                	li	s1,0
    80005922:	b7c5                	j	80005902 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005924:	85ce                	mv	a1,s3
    80005926:	00092503          	lw	a0,0(s2)
    8000592a:	ffffe097          	auipc	ra,0xffffe
    8000592e:	49c080e7          	jalr	1180(ra) # 80003dc6 <ialloc>
    80005932:	84aa                	mv	s1,a0
    80005934:	c529                	beqz	a0,8000597e <create+0xee>
  ilock(ip);
    80005936:	ffffe097          	auipc	ra,0xffffe
    8000593a:	628080e7          	jalr	1576(ra) # 80003f5e <ilock>
  ip->major = major;
    8000593e:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005942:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005946:	4785                	li	a5,1
    80005948:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000594c:	8526                	mv	a0,s1
    8000594e:	ffffe097          	auipc	ra,0xffffe
    80005952:	546080e7          	jalr	1350(ra) # 80003e94 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005956:	2981                	sext.w	s3,s3
    80005958:	4785                	li	a5,1
    8000595a:	02f98a63          	beq	s3,a5,8000598e <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    8000595e:	40d0                	lw	a2,4(s1)
    80005960:	fb040593          	addi	a1,s0,-80
    80005964:	854a                	mv	a0,s2
    80005966:	fffff097          	auipc	ra,0xfffff
    8000596a:	cec080e7          	jalr	-788(ra) # 80004652 <dirlink>
    8000596e:	06054b63          	bltz	a0,800059e4 <create+0x154>
  iunlockput(dp);
    80005972:	854a                	mv	a0,s2
    80005974:	fffff097          	auipc	ra,0xfffff
    80005978:	84c080e7          	jalr	-1972(ra) # 800041c0 <iunlockput>
  return ip;
    8000597c:	b759                	j	80005902 <create+0x72>
    panic("create: ialloc");
    8000597e:	00003517          	auipc	a0,0x3
    80005982:	e3a50513          	addi	a0,a0,-454 # 800087b8 <syscalls+0x2b0>
    80005986:	ffffb097          	auipc	ra,0xffffb
    8000598a:	bb8080e7          	jalr	-1096(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    8000598e:	04a95783          	lhu	a5,74(s2)
    80005992:	2785                	addiw	a5,a5,1
    80005994:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005998:	854a                	mv	a0,s2
    8000599a:	ffffe097          	auipc	ra,0xffffe
    8000599e:	4fa080e7          	jalr	1274(ra) # 80003e94 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800059a2:	40d0                	lw	a2,4(s1)
    800059a4:	00003597          	auipc	a1,0x3
    800059a8:	e2458593          	addi	a1,a1,-476 # 800087c8 <syscalls+0x2c0>
    800059ac:	8526                	mv	a0,s1
    800059ae:	fffff097          	auipc	ra,0xfffff
    800059b2:	ca4080e7          	jalr	-860(ra) # 80004652 <dirlink>
    800059b6:	00054f63          	bltz	a0,800059d4 <create+0x144>
    800059ba:	00492603          	lw	a2,4(s2)
    800059be:	00003597          	auipc	a1,0x3
    800059c2:	e1258593          	addi	a1,a1,-494 # 800087d0 <syscalls+0x2c8>
    800059c6:	8526                	mv	a0,s1
    800059c8:	fffff097          	auipc	ra,0xfffff
    800059cc:	c8a080e7          	jalr	-886(ra) # 80004652 <dirlink>
    800059d0:	f80557e3          	bgez	a0,8000595e <create+0xce>
      panic("create dots");
    800059d4:	00003517          	auipc	a0,0x3
    800059d8:	e0450513          	addi	a0,a0,-508 # 800087d8 <syscalls+0x2d0>
    800059dc:	ffffb097          	auipc	ra,0xffffb
    800059e0:	b62080e7          	jalr	-1182(ra) # 8000053e <panic>
    panic("create: dirlink");
    800059e4:	00003517          	auipc	a0,0x3
    800059e8:	e0450513          	addi	a0,a0,-508 # 800087e8 <syscalls+0x2e0>
    800059ec:	ffffb097          	auipc	ra,0xffffb
    800059f0:	b52080e7          	jalr	-1198(ra) # 8000053e <panic>
    return 0;
    800059f4:	84aa                	mv	s1,a0
    800059f6:	b731                	j	80005902 <create+0x72>

00000000800059f8 <sys_dup>:
{
    800059f8:	7179                	addi	sp,sp,-48
    800059fa:	f406                	sd	ra,40(sp)
    800059fc:	f022                	sd	s0,32(sp)
    800059fe:	ec26                	sd	s1,24(sp)
    80005a00:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005a02:	fd840613          	addi	a2,s0,-40
    80005a06:	4581                	li	a1,0
    80005a08:	4501                	li	a0,0
    80005a0a:	00000097          	auipc	ra,0x0
    80005a0e:	ddc080e7          	jalr	-548(ra) # 800057e6 <argfd>
    return -1;
    80005a12:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005a14:	02054363          	bltz	a0,80005a3a <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005a18:	fd843503          	ld	a0,-40(s0)
    80005a1c:	00000097          	auipc	ra,0x0
    80005a20:	e32080e7          	jalr	-462(ra) # 8000584e <fdalloc>
    80005a24:	84aa                	mv	s1,a0
    return -1;
    80005a26:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005a28:	00054963          	bltz	a0,80005a3a <sys_dup+0x42>
  filedup(f);
    80005a2c:	fd843503          	ld	a0,-40(s0)
    80005a30:	fffff097          	auipc	ra,0xfffff
    80005a34:	37a080e7          	jalr	890(ra) # 80004daa <filedup>
  return fd;
    80005a38:	87a6                	mv	a5,s1
}
    80005a3a:	853e                	mv	a0,a5
    80005a3c:	70a2                	ld	ra,40(sp)
    80005a3e:	7402                	ld	s0,32(sp)
    80005a40:	64e2                	ld	s1,24(sp)
    80005a42:	6145                	addi	sp,sp,48
    80005a44:	8082                	ret

0000000080005a46 <sys_read>:
{
    80005a46:	7179                	addi	sp,sp,-48
    80005a48:	f406                	sd	ra,40(sp)
    80005a4a:	f022                	sd	s0,32(sp)
    80005a4c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005a4e:	fe840613          	addi	a2,s0,-24
    80005a52:	4581                	li	a1,0
    80005a54:	4501                	li	a0,0
    80005a56:	00000097          	auipc	ra,0x0
    80005a5a:	d90080e7          	jalr	-624(ra) # 800057e6 <argfd>
    return -1;
    80005a5e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005a60:	04054163          	bltz	a0,80005aa2 <sys_read+0x5c>
    80005a64:	fe440593          	addi	a1,s0,-28
    80005a68:	4509                	li	a0,2
    80005a6a:	ffffe097          	auipc	ra,0xffffe
    80005a6e:	938080e7          	jalr	-1736(ra) # 800033a2 <argint>
    return -1;
    80005a72:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005a74:	02054763          	bltz	a0,80005aa2 <sys_read+0x5c>
    80005a78:	fd840593          	addi	a1,s0,-40
    80005a7c:	4505                	li	a0,1
    80005a7e:	ffffe097          	auipc	ra,0xffffe
    80005a82:	946080e7          	jalr	-1722(ra) # 800033c4 <argaddr>
    return -1;
    80005a86:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005a88:	00054d63          	bltz	a0,80005aa2 <sys_read+0x5c>
  return fileread(f, p, n);
    80005a8c:	fe442603          	lw	a2,-28(s0)
    80005a90:	fd843583          	ld	a1,-40(s0)
    80005a94:	fe843503          	ld	a0,-24(s0)
    80005a98:	fffff097          	auipc	ra,0xfffff
    80005a9c:	49e080e7          	jalr	1182(ra) # 80004f36 <fileread>
    80005aa0:	87aa                	mv	a5,a0
}
    80005aa2:	853e                	mv	a0,a5
    80005aa4:	70a2                	ld	ra,40(sp)
    80005aa6:	7402                	ld	s0,32(sp)
    80005aa8:	6145                	addi	sp,sp,48
    80005aaa:	8082                	ret

0000000080005aac <sys_write>:
{
    80005aac:	7179                	addi	sp,sp,-48
    80005aae:	f406                	sd	ra,40(sp)
    80005ab0:	f022                	sd	s0,32(sp)
    80005ab2:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005ab4:	fe840613          	addi	a2,s0,-24
    80005ab8:	4581                	li	a1,0
    80005aba:	4501                	li	a0,0
    80005abc:	00000097          	auipc	ra,0x0
    80005ac0:	d2a080e7          	jalr	-726(ra) # 800057e6 <argfd>
    return -1;
    80005ac4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005ac6:	04054163          	bltz	a0,80005b08 <sys_write+0x5c>
    80005aca:	fe440593          	addi	a1,s0,-28
    80005ace:	4509                	li	a0,2
    80005ad0:	ffffe097          	auipc	ra,0xffffe
    80005ad4:	8d2080e7          	jalr	-1838(ra) # 800033a2 <argint>
    return -1;
    80005ad8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005ada:	02054763          	bltz	a0,80005b08 <sys_write+0x5c>
    80005ade:	fd840593          	addi	a1,s0,-40
    80005ae2:	4505                	li	a0,1
    80005ae4:	ffffe097          	auipc	ra,0xffffe
    80005ae8:	8e0080e7          	jalr	-1824(ra) # 800033c4 <argaddr>
    return -1;
    80005aec:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005aee:	00054d63          	bltz	a0,80005b08 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005af2:	fe442603          	lw	a2,-28(s0)
    80005af6:	fd843583          	ld	a1,-40(s0)
    80005afa:	fe843503          	ld	a0,-24(s0)
    80005afe:	fffff097          	auipc	ra,0xfffff
    80005b02:	4fa080e7          	jalr	1274(ra) # 80004ff8 <filewrite>
    80005b06:	87aa                	mv	a5,a0
}
    80005b08:	853e                	mv	a0,a5
    80005b0a:	70a2                	ld	ra,40(sp)
    80005b0c:	7402                	ld	s0,32(sp)
    80005b0e:	6145                	addi	sp,sp,48
    80005b10:	8082                	ret

0000000080005b12 <sys_close>:
{
    80005b12:	1101                	addi	sp,sp,-32
    80005b14:	ec06                	sd	ra,24(sp)
    80005b16:	e822                	sd	s0,16(sp)
    80005b18:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005b1a:	fe040613          	addi	a2,s0,-32
    80005b1e:	fec40593          	addi	a1,s0,-20
    80005b22:	4501                	li	a0,0
    80005b24:	00000097          	auipc	ra,0x0
    80005b28:	cc2080e7          	jalr	-830(ra) # 800057e6 <argfd>
    return -1;
    80005b2c:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005b2e:	02054463          	bltz	a0,80005b56 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005b32:	ffffc097          	auipc	ra,0xffffc
    80005b36:	22a080e7          	jalr	554(ra) # 80001d5c <myproc>
    80005b3a:	fec42783          	lw	a5,-20(s0)
    80005b3e:	07f1                	addi	a5,a5,28
    80005b40:	078e                	slli	a5,a5,0x3
    80005b42:	97aa                	add	a5,a5,a0
    80005b44:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    80005b48:	fe043503          	ld	a0,-32(s0)
    80005b4c:	fffff097          	auipc	ra,0xfffff
    80005b50:	2b0080e7          	jalr	688(ra) # 80004dfc <fileclose>
  return 0;
    80005b54:	4781                	li	a5,0
}
    80005b56:	853e                	mv	a0,a5
    80005b58:	60e2                	ld	ra,24(sp)
    80005b5a:	6442                	ld	s0,16(sp)
    80005b5c:	6105                	addi	sp,sp,32
    80005b5e:	8082                	ret

0000000080005b60 <sys_fstat>:
{
    80005b60:	1101                	addi	sp,sp,-32
    80005b62:	ec06                	sd	ra,24(sp)
    80005b64:	e822                	sd	s0,16(sp)
    80005b66:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005b68:	fe840613          	addi	a2,s0,-24
    80005b6c:	4581                	li	a1,0
    80005b6e:	4501                	li	a0,0
    80005b70:	00000097          	auipc	ra,0x0
    80005b74:	c76080e7          	jalr	-906(ra) # 800057e6 <argfd>
    return -1;
    80005b78:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005b7a:	02054563          	bltz	a0,80005ba4 <sys_fstat+0x44>
    80005b7e:	fe040593          	addi	a1,s0,-32
    80005b82:	4505                	li	a0,1
    80005b84:	ffffe097          	auipc	ra,0xffffe
    80005b88:	840080e7          	jalr	-1984(ra) # 800033c4 <argaddr>
    return -1;
    80005b8c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005b8e:	00054b63          	bltz	a0,80005ba4 <sys_fstat+0x44>
  return filestat(f, st);
    80005b92:	fe043583          	ld	a1,-32(s0)
    80005b96:	fe843503          	ld	a0,-24(s0)
    80005b9a:	fffff097          	auipc	ra,0xfffff
    80005b9e:	32a080e7          	jalr	810(ra) # 80004ec4 <filestat>
    80005ba2:	87aa                	mv	a5,a0
}
    80005ba4:	853e                	mv	a0,a5
    80005ba6:	60e2                	ld	ra,24(sp)
    80005ba8:	6442                	ld	s0,16(sp)
    80005baa:	6105                	addi	sp,sp,32
    80005bac:	8082                	ret

0000000080005bae <sys_link>:
{
    80005bae:	7169                	addi	sp,sp,-304
    80005bb0:	f606                	sd	ra,296(sp)
    80005bb2:	f222                	sd	s0,288(sp)
    80005bb4:	ee26                	sd	s1,280(sp)
    80005bb6:	ea4a                	sd	s2,272(sp)
    80005bb8:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005bba:	08000613          	li	a2,128
    80005bbe:	ed040593          	addi	a1,s0,-304
    80005bc2:	4501                	li	a0,0
    80005bc4:	ffffe097          	auipc	ra,0xffffe
    80005bc8:	822080e7          	jalr	-2014(ra) # 800033e6 <argstr>
    return -1;
    80005bcc:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005bce:	10054e63          	bltz	a0,80005cea <sys_link+0x13c>
    80005bd2:	08000613          	li	a2,128
    80005bd6:	f5040593          	addi	a1,s0,-176
    80005bda:	4505                	li	a0,1
    80005bdc:	ffffe097          	auipc	ra,0xffffe
    80005be0:	80a080e7          	jalr	-2038(ra) # 800033e6 <argstr>
    return -1;
    80005be4:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005be6:	10054263          	bltz	a0,80005cea <sys_link+0x13c>
  begin_op();
    80005bea:	fffff097          	auipc	ra,0xfffff
    80005bee:	d46080e7          	jalr	-698(ra) # 80004930 <begin_op>
  if((ip = namei(old)) == 0){
    80005bf2:	ed040513          	addi	a0,s0,-304
    80005bf6:	fffff097          	auipc	ra,0xfffff
    80005bfa:	b1e080e7          	jalr	-1250(ra) # 80004714 <namei>
    80005bfe:	84aa                	mv	s1,a0
    80005c00:	c551                	beqz	a0,80005c8c <sys_link+0xde>
  ilock(ip);
    80005c02:	ffffe097          	auipc	ra,0xffffe
    80005c06:	35c080e7          	jalr	860(ra) # 80003f5e <ilock>
  if(ip->type == T_DIR){
    80005c0a:	04449703          	lh	a4,68(s1)
    80005c0e:	4785                	li	a5,1
    80005c10:	08f70463          	beq	a4,a5,80005c98 <sys_link+0xea>
  ip->nlink++;
    80005c14:	04a4d783          	lhu	a5,74(s1)
    80005c18:	2785                	addiw	a5,a5,1
    80005c1a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005c1e:	8526                	mv	a0,s1
    80005c20:	ffffe097          	auipc	ra,0xffffe
    80005c24:	274080e7          	jalr	628(ra) # 80003e94 <iupdate>
  iunlock(ip);
    80005c28:	8526                	mv	a0,s1
    80005c2a:	ffffe097          	auipc	ra,0xffffe
    80005c2e:	3f6080e7          	jalr	1014(ra) # 80004020 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005c32:	fd040593          	addi	a1,s0,-48
    80005c36:	f5040513          	addi	a0,s0,-176
    80005c3a:	fffff097          	auipc	ra,0xfffff
    80005c3e:	af8080e7          	jalr	-1288(ra) # 80004732 <nameiparent>
    80005c42:	892a                	mv	s2,a0
    80005c44:	c935                	beqz	a0,80005cb8 <sys_link+0x10a>
  ilock(dp);
    80005c46:	ffffe097          	auipc	ra,0xffffe
    80005c4a:	318080e7          	jalr	792(ra) # 80003f5e <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005c4e:	00092703          	lw	a4,0(s2)
    80005c52:	409c                	lw	a5,0(s1)
    80005c54:	04f71d63          	bne	a4,a5,80005cae <sys_link+0x100>
    80005c58:	40d0                	lw	a2,4(s1)
    80005c5a:	fd040593          	addi	a1,s0,-48
    80005c5e:	854a                	mv	a0,s2
    80005c60:	fffff097          	auipc	ra,0xfffff
    80005c64:	9f2080e7          	jalr	-1550(ra) # 80004652 <dirlink>
    80005c68:	04054363          	bltz	a0,80005cae <sys_link+0x100>
  iunlockput(dp);
    80005c6c:	854a                	mv	a0,s2
    80005c6e:	ffffe097          	auipc	ra,0xffffe
    80005c72:	552080e7          	jalr	1362(ra) # 800041c0 <iunlockput>
  iput(ip);
    80005c76:	8526                	mv	a0,s1
    80005c78:	ffffe097          	auipc	ra,0xffffe
    80005c7c:	4a0080e7          	jalr	1184(ra) # 80004118 <iput>
  end_op();
    80005c80:	fffff097          	auipc	ra,0xfffff
    80005c84:	d30080e7          	jalr	-720(ra) # 800049b0 <end_op>
  return 0;
    80005c88:	4781                	li	a5,0
    80005c8a:	a085                	j	80005cea <sys_link+0x13c>
    end_op();
    80005c8c:	fffff097          	auipc	ra,0xfffff
    80005c90:	d24080e7          	jalr	-732(ra) # 800049b0 <end_op>
    return -1;
    80005c94:	57fd                	li	a5,-1
    80005c96:	a891                	j	80005cea <sys_link+0x13c>
    iunlockput(ip);
    80005c98:	8526                	mv	a0,s1
    80005c9a:	ffffe097          	auipc	ra,0xffffe
    80005c9e:	526080e7          	jalr	1318(ra) # 800041c0 <iunlockput>
    end_op();
    80005ca2:	fffff097          	auipc	ra,0xfffff
    80005ca6:	d0e080e7          	jalr	-754(ra) # 800049b0 <end_op>
    return -1;
    80005caa:	57fd                	li	a5,-1
    80005cac:	a83d                	j	80005cea <sys_link+0x13c>
    iunlockput(dp);
    80005cae:	854a                	mv	a0,s2
    80005cb0:	ffffe097          	auipc	ra,0xffffe
    80005cb4:	510080e7          	jalr	1296(ra) # 800041c0 <iunlockput>
  ilock(ip);
    80005cb8:	8526                	mv	a0,s1
    80005cba:	ffffe097          	auipc	ra,0xffffe
    80005cbe:	2a4080e7          	jalr	676(ra) # 80003f5e <ilock>
  ip->nlink--;
    80005cc2:	04a4d783          	lhu	a5,74(s1)
    80005cc6:	37fd                	addiw	a5,a5,-1
    80005cc8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005ccc:	8526                	mv	a0,s1
    80005cce:	ffffe097          	auipc	ra,0xffffe
    80005cd2:	1c6080e7          	jalr	454(ra) # 80003e94 <iupdate>
  iunlockput(ip);
    80005cd6:	8526                	mv	a0,s1
    80005cd8:	ffffe097          	auipc	ra,0xffffe
    80005cdc:	4e8080e7          	jalr	1256(ra) # 800041c0 <iunlockput>
  end_op();
    80005ce0:	fffff097          	auipc	ra,0xfffff
    80005ce4:	cd0080e7          	jalr	-816(ra) # 800049b0 <end_op>
  return -1;
    80005ce8:	57fd                	li	a5,-1
}
    80005cea:	853e                	mv	a0,a5
    80005cec:	70b2                	ld	ra,296(sp)
    80005cee:	7412                	ld	s0,288(sp)
    80005cf0:	64f2                	ld	s1,280(sp)
    80005cf2:	6952                	ld	s2,272(sp)
    80005cf4:	6155                	addi	sp,sp,304
    80005cf6:	8082                	ret

0000000080005cf8 <sys_unlink>:
{
    80005cf8:	7151                	addi	sp,sp,-240
    80005cfa:	f586                	sd	ra,232(sp)
    80005cfc:	f1a2                	sd	s0,224(sp)
    80005cfe:	eda6                	sd	s1,216(sp)
    80005d00:	e9ca                	sd	s2,208(sp)
    80005d02:	e5ce                	sd	s3,200(sp)
    80005d04:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005d06:	08000613          	li	a2,128
    80005d0a:	f3040593          	addi	a1,s0,-208
    80005d0e:	4501                	li	a0,0
    80005d10:	ffffd097          	auipc	ra,0xffffd
    80005d14:	6d6080e7          	jalr	1750(ra) # 800033e6 <argstr>
    80005d18:	18054163          	bltz	a0,80005e9a <sys_unlink+0x1a2>
  begin_op();
    80005d1c:	fffff097          	auipc	ra,0xfffff
    80005d20:	c14080e7          	jalr	-1004(ra) # 80004930 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005d24:	fb040593          	addi	a1,s0,-80
    80005d28:	f3040513          	addi	a0,s0,-208
    80005d2c:	fffff097          	auipc	ra,0xfffff
    80005d30:	a06080e7          	jalr	-1530(ra) # 80004732 <nameiparent>
    80005d34:	84aa                	mv	s1,a0
    80005d36:	c979                	beqz	a0,80005e0c <sys_unlink+0x114>
  ilock(dp);
    80005d38:	ffffe097          	auipc	ra,0xffffe
    80005d3c:	226080e7          	jalr	550(ra) # 80003f5e <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005d40:	00003597          	auipc	a1,0x3
    80005d44:	a8858593          	addi	a1,a1,-1400 # 800087c8 <syscalls+0x2c0>
    80005d48:	fb040513          	addi	a0,s0,-80
    80005d4c:	ffffe097          	auipc	ra,0xffffe
    80005d50:	6dc080e7          	jalr	1756(ra) # 80004428 <namecmp>
    80005d54:	14050a63          	beqz	a0,80005ea8 <sys_unlink+0x1b0>
    80005d58:	00003597          	auipc	a1,0x3
    80005d5c:	a7858593          	addi	a1,a1,-1416 # 800087d0 <syscalls+0x2c8>
    80005d60:	fb040513          	addi	a0,s0,-80
    80005d64:	ffffe097          	auipc	ra,0xffffe
    80005d68:	6c4080e7          	jalr	1732(ra) # 80004428 <namecmp>
    80005d6c:	12050e63          	beqz	a0,80005ea8 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005d70:	f2c40613          	addi	a2,s0,-212
    80005d74:	fb040593          	addi	a1,s0,-80
    80005d78:	8526                	mv	a0,s1
    80005d7a:	ffffe097          	auipc	ra,0xffffe
    80005d7e:	6c8080e7          	jalr	1736(ra) # 80004442 <dirlookup>
    80005d82:	892a                	mv	s2,a0
    80005d84:	12050263          	beqz	a0,80005ea8 <sys_unlink+0x1b0>
  ilock(ip);
    80005d88:	ffffe097          	auipc	ra,0xffffe
    80005d8c:	1d6080e7          	jalr	470(ra) # 80003f5e <ilock>
  if(ip->nlink < 1)
    80005d90:	04a91783          	lh	a5,74(s2)
    80005d94:	08f05263          	blez	a5,80005e18 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005d98:	04491703          	lh	a4,68(s2)
    80005d9c:	4785                	li	a5,1
    80005d9e:	08f70563          	beq	a4,a5,80005e28 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005da2:	4641                	li	a2,16
    80005da4:	4581                	li	a1,0
    80005da6:	fc040513          	addi	a0,s0,-64
    80005daa:	ffffb097          	auipc	ra,0xffffb
    80005dae:	f36080e7          	jalr	-202(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005db2:	4741                	li	a4,16
    80005db4:	f2c42683          	lw	a3,-212(s0)
    80005db8:	fc040613          	addi	a2,s0,-64
    80005dbc:	4581                	li	a1,0
    80005dbe:	8526                	mv	a0,s1
    80005dc0:	ffffe097          	auipc	ra,0xffffe
    80005dc4:	54a080e7          	jalr	1354(ra) # 8000430a <writei>
    80005dc8:	47c1                	li	a5,16
    80005dca:	0af51563          	bne	a0,a5,80005e74 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005dce:	04491703          	lh	a4,68(s2)
    80005dd2:	4785                	li	a5,1
    80005dd4:	0af70863          	beq	a4,a5,80005e84 <sys_unlink+0x18c>
  iunlockput(dp);
    80005dd8:	8526                	mv	a0,s1
    80005dda:	ffffe097          	auipc	ra,0xffffe
    80005dde:	3e6080e7          	jalr	998(ra) # 800041c0 <iunlockput>
  ip->nlink--;
    80005de2:	04a95783          	lhu	a5,74(s2)
    80005de6:	37fd                	addiw	a5,a5,-1
    80005de8:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005dec:	854a                	mv	a0,s2
    80005dee:	ffffe097          	auipc	ra,0xffffe
    80005df2:	0a6080e7          	jalr	166(ra) # 80003e94 <iupdate>
  iunlockput(ip);
    80005df6:	854a                	mv	a0,s2
    80005df8:	ffffe097          	auipc	ra,0xffffe
    80005dfc:	3c8080e7          	jalr	968(ra) # 800041c0 <iunlockput>
  end_op();
    80005e00:	fffff097          	auipc	ra,0xfffff
    80005e04:	bb0080e7          	jalr	-1104(ra) # 800049b0 <end_op>
  return 0;
    80005e08:	4501                	li	a0,0
    80005e0a:	a84d                	j	80005ebc <sys_unlink+0x1c4>
    end_op();
    80005e0c:	fffff097          	auipc	ra,0xfffff
    80005e10:	ba4080e7          	jalr	-1116(ra) # 800049b0 <end_op>
    return -1;
    80005e14:	557d                	li	a0,-1
    80005e16:	a05d                	j	80005ebc <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005e18:	00003517          	auipc	a0,0x3
    80005e1c:	9e050513          	addi	a0,a0,-1568 # 800087f8 <syscalls+0x2f0>
    80005e20:	ffffa097          	auipc	ra,0xffffa
    80005e24:	71e080e7          	jalr	1822(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005e28:	04c92703          	lw	a4,76(s2)
    80005e2c:	02000793          	li	a5,32
    80005e30:	f6e7f9e3          	bgeu	a5,a4,80005da2 <sys_unlink+0xaa>
    80005e34:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005e38:	4741                	li	a4,16
    80005e3a:	86ce                	mv	a3,s3
    80005e3c:	f1840613          	addi	a2,s0,-232
    80005e40:	4581                	li	a1,0
    80005e42:	854a                	mv	a0,s2
    80005e44:	ffffe097          	auipc	ra,0xffffe
    80005e48:	3ce080e7          	jalr	974(ra) # 80004212 <readi>
    80005e4c:	47c1                	li	a5,16
    80005e4e:	00f51b63          	bne	a0,a5,80005e64 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005e52:	f1845783          	lhu	a5,-232(s0)
    80005e56:	e7a1                	bnez	a5,80005e9e <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005e58:	29c1                	addiw	s3,s3,16
    80005e5a:	04c92783          	lw	a5,76(s2)
    80005e5e:	fcf9ede3          	bltu	s3,a5,80005e38 <sys_unlink+0x140>
    80005e62:	b781                	j	80005da2 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005e64:	00003517          	auipc	a0,0x3
    80005e68:	9ac50513          	addi	a0,a0,-1620 # 80008810 <syscalls+0x308>
    80005e6c:	ffffa097          	auipc	ra,0xffffa
    80005e70:	6d2080e7          	jalr	1746(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005e74:	00003517          	auipc	a0,0x3
    80005e78:	9b450513          	addi	a0,a0,-1612 # 80008828 <syscalls+0x320>
    80005e7c:	ffffa097          	auipc	ra,0xffffa
    80005e80:	6c2080e7          	jalr	1730(ra) # 8000053e <panic>
    dp->nlink--;
    80005e84:	04a4d783          	lhu	a5,74(s1)
    80005e88:	37fd                	addiw	a5,a5,-1
    80005e8a:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005e8e:	8526                	mv	a0,s1
    80005e90:	ffffe097          	auipc	ra,0xffffe
    80005e94:	004080e7          	jalr	4(ra) # 80003e94 <iupdate>
    80005e98:	b781                	j	80005dd8 <sys_unlink+0xe0>
    return -1;
    80005e9a:	557d                	li	a0,-1
    80005e9c:	a005                	j	80005ebc <sys_unlink+0x1c4>
    iunlockput(ip);
    80005e9e:	854a                	mv	a0,s2
    80005ea0:	ffffe097          	auipc	ra,0xffffe
    80005ea4:	320080e7          	jalr	800(ra) # 800041c0 <iunlockput>
  iunlockput(dp);
    80005ea8:	8526                	mv	a0,s1
    80005eaa:	ffffe097          	auipc	ra,0xffffe
    80005eae:	316080e7          	jalr	790(ra) # 800041c0 <iunlockput>
  end_op();
    80005eb2:	fffff097          	auipc	ra,0xfffff
    80005eb6:	afe080e7          	jalr	-1282(ra) # 800049b0 <end_op>
  return -1;
    80005eba:	557d                	li	a0,-1
}
    80005ebc:	70ae                	ld	ra,232(sp)
    80005ebe:	740e                	ld	s0,224(sp)
    80005ec0:	64ee                	ld	s1,216(sp)
    80005ec2:	694e                	ld	s2,208(sp)
    80005ec4:	69ae                	ld	s3,200(sp)
    80005ec6:	616d                	addi	sp,sp,240
    80005ec8:	8082                	ret

0000000080005eca <sys_open>:

uint64
sys_open(void)
{
    80005eca:	7131                	addi	sp,sp,-192
    80005ecc:	fd06                	sd	ra,184(sp)
    80005ece:	f922                	sd	s0,176(sp)
    80005ed0:	f526                	sd	s1,168(sp)
    80005ed2:	f14a                	sd	s2,160(sp)
    80005ed4:	ed4e                	sd	s3,152(sp)
    80005ed6:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005ed8:	08000613          	li	a2,128
    80005edc:	f5040593          	addi	a1,s0,-176
    80005ee0:	4501                	li	a0,0
    80005ee2:	ffffd097          	auipc	ra,0xffffd
    80005ee6:	504080e7          	jalr	1284(ra) # 800033e6 <argstr>
    return -1;
    80005eea:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005eec:	0c054163          	bltz	a0,80005fae <sys_open+0xe4>
    80005ef0:	f4c40593          	addi	a1,s0,-180
    80005ef4:	4505                	li	a0,1
    80005ef6:	ffffd097          	auipc	ra,0xffffd
    80005efa:	4ac080e7          	jalr	1196(ra) # 800033a2 <argint>
    80005efe:	0a054863          	bltz	a0,80005fae <sys_open+0xe4>

  begin_op();
    80005f02:	fffff097          	auipc	ra,0xfffff
    80005f06:	a2e080e7          	jalr	-1490(ra) # 80004930 <begin_op>

  if(omode & O_CREATE){
    80005f0a:	f4c42783          	lw	a5,-180(s0)
    80005f0e:	2007f793          	andi	a5,a5,512
    80005f12:	cbdd                	beqz	a5,80005fc8 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005f14:	4681                	li	a3,0
    80005f16:	4601                	li	a2,0
    80005f18:	4589                	li	a1,2
    80005f1a:	f5040513          	addi	a0,s0,-176
    80005f1e:	00000097          	auipc	ra,0x0
    80005f22:	972080e7          	jalr	-1678(ra) # 80005890 <create>
    80005f26:	892a                	mv	s2,a0
    if(ip == 0){
    80005f28:	c959                	beqz	a0,80005fbe <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005f2a:	04491703          	lh	a4,68(s2)
    80005f2e:	478d                	li	a5,3
    80005f30:	00f71763          	bne	a4,a5,80005f3e <sys_open+0x74>
    80005f34:	04695703          	lhu	a4,70(s2)
    80005f38:	47a5                	li	a5,9
    80005f3a:	0ce7ec63          	bltu	a5,a4,80006012 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005f3e:	fffff097          	auipc	ra,0xfffff
    80005f42:	e02080e7          	jalr	-510(ra) # 80004d40 <filealloc>
    80005f46:	89aa                	mv	s3,a0
    80005f48:	10050263          	beqz	a0,8000604c <sys_open+0x182>
    80005f4c:	00000097          	auipc	ra,0x0
    80005f50:	902080e7          	jalr	-1790(ra) # 8000584e <fdalloc>
    80005f54:	84aa                	mv	s1,a0
    80005f56:	0e054663          	bltz	a0,80006042 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005f5a:	04491703          	lh	a4,68(s2)
    80005f5e:	478d                	li	a5,3
    80005f60:	0cf70463          	beq	a4,a5,80006028 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005f64:	4789                	li	a5,2
    80005f66:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005f6a:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005f6e:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005f72:	f4c42783          	lw	a5,-180(s0)
    80005f76:	0017c713          	xori	a4,a5,1
    80005f7a:	8b05                	andi	a4,a4,1
    80005f7c:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005f80:	0037f713          	andi	a4,a5,3
    80005f84:	00e03733          	snez	a4,a4
    80005f88:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005f8c:	4007f793          	andi	a5,a5,1024
    80005f90:	c791                	beqz	a5,80005f9c <sys_open+0xd2>
    80005f92:	04491703          	lh	a4,68(s2)
    80005f96:	4789                	li	a5,2
    80005f98:	08f70f63          	beq	a4,a5,80006036 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005f9c:	854a                	mv	a0,s2
    80005f9e:	ffffe097          	auipc	ra,0xffffe
    80005fa2:	082080e7          	jalr	130(ra) # 80004020 <iunlock>
  end_op();
    80005fa6:	fffff097          	auipc	ra,0xfffff
    80005faa:	a0a080e7          	jalr	-1526(ra) # 800049b0 <end_op>

  return fd;
}
    80005fae:	8526                	mv	a0,s1
    80005fb0:	70ea                	ld	ra,184(sp)
    80005fb2:	744a                	ld	s0,176(sp)
    80005fb4:	74aa                	ld	s1,168(sp)
    80005fb6:	790a                	ld	s2,160(sp)
    80005fb8:	69ea                	ld	s3,152(sp)
    80005fba:	6129                	addi	sp,sp,192
    80005fbc:	8082                	ret
      end_op();
    80005fbe:	fffff097          	auipc	ra,0xfffff
    80005fc2:	9f2080e7          	jalr	-1550(ra) # 800049b0 <end_op>
      return -1;
    80005fc6:	b7e5                	j	80005fae <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005fc8:	f5040513          	addi	a0,s0,-176
    80005fcc:	ffffe097          	auipc	ra,0xffffe
    80005fd0:	748080e7          	jalr	1864(ra) # 80004714 <namei>
    80005fd4:	892a                	mv	s2,a0
    80005fd6:	c905                	beqz	a0,80006006 <sys_open+0x13c>
    ilock(ip);
    80005fd8:	ffffe097          	auipc	ra,0xffffe
    80005fdc:	f86080e7          	jalr	-122(ra) # 80003f5e <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005fe0:	04491703          	lh	a4,68(s2)
    80005fe4:	4785                	li	a5,1
    80005fe6:	f4f712e3          	bne	a4,a5,80005f2a <sys_open+0x60>
    80005fea:	f4c42783          	lw	a5,-180(s0)
    80005fee:	dba1                	beqz	a5,80005f3e <sys_open+0x74>
      iunlockput(ip);
    80005ff0:	854a                	mv	a0,s2
    80005ff2:	ffffe097          	auipc	ra,0xffffe
    80005ff6:	1ce080e7          	jalr	462(ra) # 800041c0 <iunlockput>
      end_op();
    80005ffa:	fffff097          	auipc	ra,0xfffff
    80005ffe:	9b6080e7          	jalr	-1610(ra) # 800049b0 <end_op>
      return -1;
    80006002:	54fd                	li	s1,-1
    80006004:	b76d                	j	80005fae <sys_open+0xe4>
      end_op();
    80006006:	fffff097          	auipc	ra,0xfffff
    8000600a:	9aa080e7          	jalr	-1622(ra) # 800049b0 <end_op>
      return -1;
    8000600e:	54fd                	li	s1,-1
    80006010:	bf79                	j	80005fae <sys_open+0xe4>
    iunlockput(ip);
    80006012:	854a                	mv	a0,s2
    80006014:	ffffe097          	auipc	ra,0xffffe
    80006018:	1ac080e7          	jalr	428(ra) # 800041c0 <iunlockput>
    end_op();
    8000601c:	fffff097          	auipc	ra,0xfffff
    80006020:	994080e7          	jalr	-1644(ra) # 800049b0 <end_op>
    return -1;
    80006024:	54fd                	li	s1,-1
    80006026:	b761                	j	80005fae <sys_open+0xe4>
    f->type = FD_DEVICE;
    80006028:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    8000602c:	04691783          	lh	a5,70(s2)
    80006030:	02f99223          	sh	a5,36(s3)
    80006034:	bf2d                	j	80005f6e <sys_open+0xa4>
    itrunc(ip);
    80006036:	854a                	mv	a0,s2
    80006038:	ffffe097          	auipc	ra,0xffffe
    8000603c:	034080e7          	jalr	52(ra) # 8000406c <itrunc>
    80006040:	bfb1                	j	80005f9c <sys_open+0xd2>
      fileclose(f);
    80006042:	854e                	mv	a0,s3
    80006044:	fffff097          	auipc	ra,0xfffff
    80006048:	db8080e7          	jalr	-584(ra) # 80004dfc <fileclose>
    iunlockput(ip);
    8000604c:	854a                	mv	a0,s2
    8000604e:	ffffe097          	auipc	ra,0xffffe
    80006052:	172080e7          	jalr	370(ra) # 800041c0 <iunlockput>
    end_op();
    80006056:	fffff097          	auipc	ra,0xfffff
    8000605a:	95a080e7          	jalr	-1702(ra) # 800049b0 <end_op>
    return -1;
    8000605e:	54fd                	li	s1,-1
    80006060:	b7b9                	j	80005fae <sys_open+0xe4>

0000000080006062 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80006062:	7175                	addi	sp,sp,-144
    80006064:	e506                	sd	ra,136(sp)
    80006066:	e122                	sd	s0,128(sp)
    80006068:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000606a:	fffff097          	auipc	ra,0xfffff
    8000606e:	8c6080e7          	jalr	-1850(ra) # 80004930 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80006072:	08000613          	li	a2,128
    80006076:	f7040593          	addi	a1,s0,-144
    8000607a:	4501                	li	a0,0
    8000607c:	ffffd097          	auipc	ra,0xffffd
    80006080:	36a080e7          	jalr	874(ra) # 800033e6 <argstr>
    80006084:	02054963          	bltz	a0,800060b6 <sys_mkdir+0x54>
    80006088:	4681                	li	a3,0
    8000608a:	4601                	li	a2,0
    8000608c:	4585                	li	a1,1
    8000608e:	f7040513          	addi	a0,s0,-144
    80006092:	fffff097          	auipc	ra,0xfffff
    80006096:	7fe080e7          	jalr	2046(ra) # 80005890 <create>
    8000609a:	cd11                	beqz	a0,800060b6 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000609c:	ffffe097          	auipc	ra,0xffffe
    800060a0:	124080e7          	jalr	292(ra) # 800041c0 <iunlockput>
  end_op();
    800060a4:	fffff097          	auipc	ra,0xfffff
    800060a8:	90c080e7          	jalr	-1780(ra) # 800049b0 <end_op>
  return 0;
    800060ac:	4501                	li	a0,0
}
    800060ae:	60aa                	ld	ra,136(sp)
    800060b0:	640a                	ld	s0,128(sp)
    800060b2:	6149                	addi	sp,sp,144
    800060b4:	8082                	ret
    end_op();
    800060b6:	fffff097          	auipc	ra,0xfffff
    800060ba:	8fa080e7          	jalr	-1798(ra) # 800049b0 <end_op>
    return -1;
    800060be:	557d                	li	a0,-1
    800060c0:	b7fd                	j	800060ae <sys_mkdir+0x4c>

00000000800060c2 <sys_mknod>:

uint64
sys_mknod(void)
{
    800060c2:	7135                	addi	sp,sp,-160
    800060c4:	ed06                	sd	ra,152(sp)
    800060c6:	e922                	sd	s0,144(sp)
    800060c8:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800060ca:	fffff097          	auipc	ra,0xfffff
    800060ce:	866080e7          	jalr	-1946(ra) # 80004930 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800060d2:	08000613          	li	a2,128
    800060d6:	f7040593          	addi	a1,s0,-144
    800060da:	4501                	li	a0,0
    800060dc:	ffffd097          	auipc	ra,0xffffd
    800060e0:	30a080e7          	jalr	778(ra) # 800033e6 <argstr>
    800060e4:	04054a63          	bltz	a0,80006138 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800060e8:	f6c40593          	addi	a1,s0,-148
    800060ec:	4505                	li	a0,1
    800060ee:	ffffd097          	auipc	ra,0xffffd
    800060f2:	2b4080e7          	jalr	692(ra) # 800033a2 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800060f6:	04054163          	bltz	a0,80006138 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800060fa:	f6840593          	addi	a1,s0,-152
    800060fe:	4509                	li	a0,2
    80006100:	ffffd097          	auipc	ra,0xffffd
    80006104:	2a2080e7          	jalr	674(ra) # 800033a2 <argint>
     argint(1, &major) < 0 ||
    80006108:	02054863          	bltz	a0,80006138 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000610c:	f6841683          	lh	a3,-152(s0)
    80006110:	f6c41603          	lh	a2,-148(s0)
    80006114:	458d                	li	a1,3
    80006116:	f7040513          	addi	a0,s0,-144
    8000611a:	fffff097          	auipc	ra,0xfffff
    8000611e:	776080e7          	jalr	1910(ra) # 80005890 <create>
     argint(2, &minor) < 0 ||
    80006122:	c919                	beqz	a0,80006138 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006124:	ffffe097          	auipc	ra,0xffffe
    80006128:	09c080e7          	jalr	156(ra) # 800041c0 <iunlockput>
  end_op();
    8000612c:	fffff097          	auipc	ra,0xfffff
    80006130:	884080e7          	jalr	-1916(ra) # 800049b0 <end_op>
  return 0;
    80006134:	4501                	li	a0,0
    80006136:	a031                	j	80006142 <sys_mknod+0x80>
    end_op();
    80006138:	fffff097          	auipc	ra,0xfffff
    8000613c:	878080e7          	jalr	-1928(ra) # 800049b0 <end_op>
    return -1;
    80006140:	557d                	li	a0,-1
}
    80006142:	60ea                	ld	ra,152(sp)
    80006144:	644a                	ld	s0,144(sp)
    80006146:	610d                	addi	sp,sp,160
    80006148:	8082                	ret

000000008000614a <sys_chdir>:

uint64
sys_chdir(void)
{
    8000614a:	7135                	addi	sp,sp,-160
    8000614c:	ed06                	sd	ra,152(sp)
    8000614e:	e922                	sd	s0,144(sp)
    80006150:	e526                	sd	s1,136(sp)
    80006152:	e14a                	sd	s2,128(sp)
    80006154:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80006156:	ffffc097          	auipc	ra,0xffffc
    8000615a:	c06080e7          	jalr	-1018(ra) # 80001d5c <myproc>
    8000615e:	892a                	mv	s2,a0
  
  begin_op();
    80006160:	ffffe097          	auipc	ra,0xffffe
    80006164:	7d0080e7          	jalr	2000(ra) # 80004930 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80006168:	08000613          	li	a2,128
    8000616c:	f6040593          	addi	a1,s0,-160
    80006170:	4501                	li	a0,0
    80006172:	ffffd097          	auipc	ra,0xffffd
    80006176:	274080e7          	jalr	628(ra) # 800033e6 <argstr>
    8000617a:	04054b63          	bltz	a0,800061d0 <sys_chdir+0x86>
    8000617e:	f6040513          	addi	a0,s0,-160
    80006182:	ffffe097          	auipc	ra,0xffffe
    80006186:	592080e7          	jalr	1426(ra) # 80004714 <namei>
    8000618a:	84aa                	mv	s1,a0
    8000618c:	c131                	beqz	a0,800061d0 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    8000618e:	ffffe097          	auipc	ra,0xffffe
    80006192:	dd0080e7          	jalr	-560(ra) # 80003f5e <ilock>
  if(ip->type != T_DIR){
    80006196:	04449703          	lh	a4,68(s1)
    8000619a:	4785                	li	a5,1
    8000619c:	04f71063          	bne	a4,a5,800061dc <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800061a0:	8526                	mv	a0,s1
    800061a2:	ffffe097          	auipc	ra,0xffffe
    800061a6:	e7e080e7          	jalr	-386(ra) # 80004020 <iunlock>
  iput(p->cwd);
    800061aa:	16893503          	ld	a0,360(s2)
    800061ae:	ffffe097          	auipc	ra,0xffffe
    800061b2:	f6a080e7          	jalr	-150(ra) # 80004118 <iput>
  end_op();
    800061b6:	ffffe097          	auipc	ra,0xffffe
    800061ba:	7fa080e7          	jalr	2042(ra) # 800049b0 <end_op>
  p->cwd = ip;
    800061be:	16993423          	sd	s1,360(s2)
  return 0;
    800061c2:	4501                	li	a0,0
}
    800061c4:	60ea                	ld	ra,152(sp)
    800061c6:	644a                	ld	s0,144(sp)
    800061c8:	64aa                	ld	s1,136(sp)
    800061ca:	690a                	ld	s2,128(sp)
    800061cc:	610d                	addi	sp,sp,160
    800061ce:	8082                	ret
    end_op();
    800061d0:	ffffe097          	auipc	ra,0xffffe
    800061d4:	7e0080e7          	jalr	2016(ra) # 800049b0 <end_op>
    return -1;
    800061d8:	557d                	li	a0,-1
    800061da:	b7ed                	j	800061c4 <sys_chdir+0x7a>
    iunlockput(ip);
    800061dc:	8526                	mv	a0,s1
    800061de:	ffffe097          	auipc	ra,0xffffe
    800061e2:	fe2080e7          	jalr	-30(ra) # 800041c0 <iunlockput>
    end_op();
    800061e6:	ffffe097          	auipc	ra,0xffffe
    800061ea:	7ca080e7          	jalr	1994(ra) # 800049b0 <end_op>
    return -1;
    800061ee:	557d                	li	a0,-1
    800061f0:	bfd1                	j	800061c4 <sys_chdir+0x7a>

00000000800061f2 <sys_exec>:

uint64
sys_exec(void)
{
    800061f2:	7145                	addi	sp,sp,-464
    800061f4:	e786                	sd	ra,456(sp)
    800061f6:	e3a2                	sd	s0,448(sp)
    800061f8:	ff26                	sd	s1,440(sp)
    800061fa:	fb4a                	sd	s2,432(sp)
    800061fc:	f74e                	sd	s3,424(sp)
    800061fe:	f352                	sd	s4,416(sp)
    80006200:	ef56                	sd	s5,408(sp)
    80006202:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006204:	08000613          	li	a2,128
    80006208:	f4040593          	addi	a1,s0,-192
    8000620c:	4501                	li	a0,0
    8000620e:	ffffd097          	auipc	ra,0xffffd
    80006212:	1d8080e7          	jalr	472(ra) # 800033e6 <argstr>
    return -1;
    80006216:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006218:	0c054a63          	bltz	a0,800062ec <sys_exec+0xfa>
    8000621c:	e3840593          	addi	a1,s0,-456
    80006220:	4505                	li	a0,1
    80006222:	ffffd097          	auipc	ra,0xffffd
    80006226:	1a2080e7          	jalr	418(ra) # 800033c4 <argaddr>
    8000622a:	0c054163          	bltz	a0,800062ec <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    8000622e:	10000613          	li	a2,256
    80006232:	4581                	li	a1,0
    80006234:	e4040513          	addi	a0,s0,-448
    80006238:	ffffb097          	auipc	ra,0xffffb
    8000623c:	aa8080e7          	jalr	-1368(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006240:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80006244:	89a6                	mv	s3,s1
    80006246:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80006248:	02000a13          	li	s4,32
    8000624c:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006250:	00391513          	slli	a0,s2,0x3
    80006254:	e3040593          	addi	a1,s0,-464
    80006258:	e3843783          	ld	a5,-456(s0)
    8000625c:	953e                	add	a0,a0,a5
    8000625e:	ffffd097          	auipc	ra,0xffffd
    80006262:	0aa080e7          	jalr	170(ra) # 80003308 <fetchaddr>
    80006266:	02054a63          	bltz	a0,8000629a <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    8000626a:	e3043783          	ld	a5,-464(s0)
    8000626e:	c3b9                	beqz	a5,800062b4 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006270:	ffffb097          	auipc	ra,0xffffb
    80006274:	884080e7          	jalr	-1916(ra) # 80000af4 <kalloc>
    80006278:	85aa                	mv	a1,a0
    8000627a:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    8000627e:	cd11                	beqz	a0,8000629a <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006280:	6605                	lui	a2,0x1
    80006282:	e3043503          	ld	a0,-464(s0)
    80006286:	ffffd097          	auipc	ra,0xffffd
    8000628a:	0d4080e7          	jalr	212(ra) # 8000335a <fetchstr>
    8000628e:	00054663          	bltz	a0,8000629a <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80006292:	0905                	addi	s2,s2,1
    80006294:	09a1                	addi	s3,s3,8
    80006296:	fb491be3          	bne	s2,s4,8000624c <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000629a:	10048913          	addi	s2,s1,256
    8000629e:	6088                	ld	a0,0(s1)
    800062a0:	c529                	beqz	a0,800062ea <sys_exec+0xf8>
    kfree(argv[i]);
    800062a2:	ffffa097          	auipc	ra,0xffffa
    800062a6:	756080e7          	jalr	1878(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800062aa:	04a1                	addi	s1,s1,8
    800062ac:	ff2499e3          	bne	s1,s2,8000629e <sys_exec+0xac>
  return -1;
    800062b0:	597d                	li	s2,-1
    800062b2:	a82d                	j	800062ec <sys_exec+0xfa>
      argv[i] = 0;
    800062b4:	0a8e                	slli	s5,s5,0x3
    800062b6:	fc040793          	addi	a5,s0,-64
    800062ba:	9abe                	add	s5,s5,a5
    800062bc:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    800062c0:	e4040593          	addi	a1,s0,-448
    800062c4:	f4040513          	addi	a0,s0,-192
    800062c8:	fffff097          	auipc	ra,0xfffff
    800062cc:	194080e7          	jalr	404(ra) # 8000545c <exec>
    800062d0:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800062d2:	10048993          	addi	s3,s1,256
    800062d6:	6088                	ld	a0,0(s1)
    800062d8:	c911                	beqz	a0,800062ec <sys_exec+0xfa>
    kfree(argv[i]);
    800062da:	ffffa097          	auipc	ra,0xffffa
    800062de:	71e080e7          	jalr	1822(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800062e2:	04a1                	addi	s1,s1,8
    800062e4:	ff3499e3          	bne	s1,s3,800062d6 <sys_exec+0xe4>
    800062e8:	a011                	j	800062ec <sys_exec+0xfa>
  return -1;
    800062ea:	597d                	li	s2,-1
}
    800062ec:	854a                	mv	a0,s2
    800062ee:	60be                	ld	ra,456(sp)
    800062f0:	641e                	ld	s0,448(sp)
    800062f2:	74fa                	ld	s1,440(sp)
    800062f4:	795a                	ld	s2,432(sp)
    800062f6:	79ba                	ld	s3,424(sp)
    800062f8:	7a1a                	ld	s4,416(sp)
    800062fa:	6afa                	ld	s5,408(sp)
    800062fc:	6179                	addi	sp,sp,464
    800062fe:	8082                	ret

0000000080006300 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006300:	7139                	addi	sp,sp,-64
    80006302:	fc06                	sd	ra,56(sp)
    80006304:	f822                	sd	s0,48(sp)
    80006306:	f426                	sd	s1,40(sp)
    80006308:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    8000630a:	ffffc097          	auipc	ra,0xffffc
    8000630e:	a52080e7          	jalr	-1454(ra) # 80001d5c <myproc>
    80006312:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80006314:	fd840593          	addi	a1,s0,-40
    80006318:	4501                	li	a0,0
    8000631a:	ffffd097          	auipc	ra,0xffffd
    8000631e:	0aa080e7          	jalr	170(ra) # 800033c4 <argaddr>
    return -1;
    80006322:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80006324:	0e054063          	bltz	a0,80006404 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80006328:	fc840593          	addi	a1,s0,-56
    8000632c:	fd040513          	addi	a0,s0,-48
    80006330:	fffff097          	auipc	ra,0xfffff
    80006334:	dfc080e7          	jalr	-516(ra) # 8000512c <pipealloc>
    return -1;
    80006338:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    8000633a:	0c054563          	bltz	a0,80006404 <sys_pipe+0x104>
  fd0 = -1;
    8000633e:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006342:	fd043503          	ld	a0,-48(s0)
    80006346:	fffff097          	auipc	ra,0xfffff
    8000634a:	508080e7          	jalr	1288(ra) # 8000584e <fdalloc>
    8000634e:	fca42223          	sw	a0,-60(s0)
    80006352:	08054c63          	bltz	a0,800063ea <sys_pipe+0xea>
    80006356:	fc843503          	ld	a0,-56(s0)
    8000635a:	fffff097          	auipc	ra,0xfffff
    8000635e:	4f4080e7          	jalr	1268(ra) # 8000584e <fdalloc>
    80006362:	fca42023          	sw	a0,-64(s0)
    80006366:	06054863          	bltz	a0,800063d6 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000636a:	4691                	li	a3,4
    8000636c:	fc440613          	addi	a2,s0,-60
    80006370:	fd843583          	ld	a1,-40(s0)
    80006374:	74a8                	ld	a0,104(s1)
    80006376:	ffffb097          	auipc	ra,0xffffb
    8000637a:	2fc080e7          	jalr	764(ra) # 80001672 <copyout>
    8000637e:	02054063          	bltz	a0,8000639e <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006382:	4691                	li	a3,4
    80006384:	fc040613          	addi	a2,s0,-64
    80006388:	fd843583          	ld	a1,-40(s0)
    8000638c:	0591                	addi	a1,a1,4
    8000638e:	74a8                	ld	a0,104(s1)
    80006390:	ffffb097          	auipc	ra,0xffffb
    80006394:	2e2080e7          	jalr	738(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006398:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000639a:	06055563          	bgez	a0,80006404 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    8000639e:	fc442783          	lw	a5,-60(s0)
    800063a2:	07f1                	addi	a5,a5,28
    800063a4:	078e                	slli	a5,a5,0x3
    800063a6:	97a6                	add	a5,a5,s1
    800063a8:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    800063ac:	fc042503          	lw	a0,-64(s0)
    800063b0:	0571                	addi	a0,a0,28
    800063b2:	050e                	slli	a0,a0,0x3
    800063b4:	9526                	add	a0,a0,s1
    800063b6:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    800063ba:	fd043503          	ld	a0,-48(s0)
    800063be:	fffff097          	auipc	ra,0xfffff
    800063c2:	a3e080e7          	jalr	-1474(ra) # 80004dfc <fileclose>
    fileclose(wf);
    800063c6:	fc843503          	ld	a0,-56(s0)
    800063ca:	fffff097          	auipc	ra,0xfffff
    800063ce:	a32080e7          	jalr	-1486(ra) # 80004dfc <fileclose>
    return -1;
    800063d2:	57fd                	li	a5,-1
    800063d4:	a805                	j	80006404 <sys_pipe+0x104>
    if(fd0 >= 0)
    800063d6:	fc442783          	lw	a5,-60(s0)
    800063da:	0007c863          	bltz	a5,800063ea <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    800063de:	01c78513          	addi	a0,a5,28
    800063e2:	050e                	slli	a0,a0,0x3
    800063e4:	9526                	add	a0,a0,s1
    800063e6:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    800063ea:	fd043503          	ld	a0,-48(s0)
    800063ee:	fffff097          	auipc	ra,0xfffff
    800063f2:	a0e080e7          	jalr	-1522(ra) # 80004dfc <fileclose>
    fileclose(wf);
    800063f6:	fc843503          	ld	a0,-56(s0)
    800063fa:	fffff097          	auipc	ra,0xfffff
    800063fe:	a02080e7          	jalr	-1534(ra) # 80004dfc <fileclose>
    return -1;
    80006402:	57fd                	li	a5,-1
}
    80006404:	853e                	mv	a0,a5
    80006406:	70e2                	ld	ra,56(sp)
    80006408:	7442                	ld	s0,48(sp)
    8000640a:	74a2                	ld	s1,40(sp)
    8000640c:	6121                	addi	sp,sp,64
    8000640e:	8082                	ret

0000000080006410 <kernelvec>:
    80006410:	7111                	addi	sp,sp,-256
    80006412:	e006                	sd	ra,0(sp)
    80006414:	e40a                	sd	sp,8(sp)
    80006416:	e80e                	sd	gp,16(sp)
    80006418:	ec12                	sd	tp,24(sp)
    8000641a:	f016                	sd	t0,32(sp)
    8000641c:	f41a                	sd	t1,40(sp)
    8000641e:	f81e                	sd	t2,48(sp)
    80006420:	fc22                	sd	s0,56(sp)
    80006422:	e0a6                	sd	s1,64(sp)
    80006424:	e4aa                	sd	a0,72(sp)
    80006426:	e8ae                	sd	a1,80(sp)
    80006428:	ecb2                	sd	a2,88(sp)
    8000642a:	f0b6                	sd	a3,96(sp)
    8000642c:	f4ba                	sd	a4,104(sp)
    8000642e:	f8be                	sd	a5,112(sp)
    80006430:	fcc2                	sd	a6,120(sp)
    80006432:	e146                	sd	a7,128(sp)
    80006434:	e54a                	sd	s2,136(sp)
    80006436:	e94e                	sd	s3,144(sp)
    80006438:	ed52                	sd	s4,152(sp)
    8000643a:	f156                	sd	s5,160(sp)
    8000643c:	f55a                	sd	s6,168(sp)
    8000643e:	f95e                	sd	s7,176(sp)
    80006440:	fd62                	sd	s8,184(sp)
    80006442:	e1e6                	sd	s9,192(sp)
    80006444:	e5ea                	sd	s10,200(sp)
    80006446:	e9ee                	sd	s11,208(sp)
    80006448:	edf2                	sd	t3,216(sp)
    8000644a:	f1f6                	sd	t4,224(sp)
    8000644c:	f5fa                	sd	t5,232(sp)
    8000644e:	f9fe                	sd	t6,240(sp)
    80006450:	d85fc0ef          	jal	ra,800031d4 <kerneltrap>
    80006454:	6082                	ld	ra,0(sp)
    80006456:	6122                	ld	sp,8(sp)
    80006458:	61c2                	ld	gp,16(sp)
    8000645a:	7282                	ld	t0,32(sp)
    8000645c:	7322                	ld	t1,40(sp)
    8000645e:	73c2                	ld	t2,48(sp)
    80006460:	7462                	ld	s0,56(sp)
    80006462:	6486                	ld	s1,64(sp)
    80006464:	6526                	ld	a0,72(sp)
    80006466:	65c6                	ld	a1,80(sp)
    80006468:	6666                	ld	a2,88(sp)
    8000646a:	7686                	ld	a3,96(sp)
    8000646c:	7726                	ld	a4,104(sp)
    8000646e:	77c6                	ld	a5,112(sp)
    80006470:	7866                	ld	a6,120(sp)
    80006472:	688a                	ld	a7,128(sp)
    80006474:	692a                	ld	s2,136(sp)
    80006476:	69ca                	ld	s3,144(sp)
    80006478:	6a6a                	ld	s4,152(sp)
    8000647a:	7a8a                	ld	s5,160(sp)
    8000647c:	7b2a                	ld	s6,168(sp)
    8000647e:	7bca                	ld	s7,176(sp)
    80006480:	7c6a                	ld	s8,184(sp)
    80006482:	6c8e                	ld	s9,192(sp)
    80006484:	6d2e                	ld	s10,200(sp)
    80006486:	6dce                	ld	s11,208(sp)
    80006488:	6e6e                	ld	t3,216(sp)
    8000648a:	7e8e                	ld	t4,224(sp)
    8000648c:	7f2e                	ld	t5,232(sp)
    8000648e:	7fce                	ld	t6,240(sp)
    80006490:	6111                	addi	sp,sp,256
    80006492:	10200073          	sret
    80006496:	00000013          	nop
    8000649a:	00000013          	nop
    8000649e:	0001                	nop

00000000800064a0 <timervec>:
    800064a0:	34051573          	csrrw	a0,mscratch,a0
    800064a4:	e10c                	sd	a1,0(a0)
    800064a6:	e510                	sd	a2,8(a0)
    800064a8:	e914                	sd	a3,16(a0)
    800064aa:	6d0c                	ld	a1,24(a0)
    800064ac:	7110                	ld	a2,32(a0)
    800064ae:	6194                	ld	a3,0(a1)
    800064b0:	96b2                	add	a3,a3,a2
    800064b2:	e194                	sd	a3,0(a1)
    800064b4:	4589                	li	a1,2
    800064b6:	14459073          	csrw	sip,a1
    800064ba:	6914                	ld	a3,16(a0)
    800064bc:	6510                	ld	a2,8(a0)
    800064be:	610c                	ld	a1,0(a0)
    800064c0:	34051573          	csrrw	a0,mscratch,a0
    800064c4:	30200073          	mret
	...

00000000800064ca <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800064ca:	1141                	addi	sp,sp,-16
    800064cc:	e422                	sd	s0,8(sp)
    800064ce:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800064d0:	0c0007b7          	lui	a5,0xc000
    800064d4:	4705                	li	a4,1
    800064d6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800064d8:	c3d8                	sw	a4,4(a5)
}
    800064da:	6422                	ld	s0,8(sp)
    800064dc:	0141                	addi	sp,sp,16
    800064de:	8082                	ret

00000000800064e0 <plicinithart>:

void
plicinithart(void)
{
    800064e0:	1141                	addi	sp,sp,-16
    800064e2:	e406                	sd	ra,8(sp)
    800064e4:	e022                	sd	s0,0(sp)
    800064e6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800064e8:	ffffc097          	auipc	ra,0xffffc
    800064ec:	848080e7          	jalr	-1976(ra) # 80001d30 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800064f0:	0085171b          	slliw	a4,a0,0x8
    800064f4:	0c0027b7          	lui	a5,0xc002
    800064f8:	97ba                	add	a5,a5,a4
    800064fa:	40200713          	li	a4,1026
    800064fe:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006502:	00d5151b          	slliw	a0,a0,0xd
    80006506:	0c2017b7          	lui	a5,0xc201
    8000650a:	953e                	add	a0,a0,a5
    8000650c:	00052023          	sw	zero,0(a0)
}
    80006510:	60a2                	ld	ra,8(sp)
    80006512:	6402                	ld	s0,0(sp)
    80006514:	0141                	addi	sp,sp,16
    80006516:	8082                	ret

0000000080006518 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006518:	1141                	addi	sp,sp,-16
    8000651a:	e406                	sd	ra,8(sp)
    8000651c:	e022                	sd	s0,0(sp)
    8000651e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006520:	ffffc097          	auipc	ra,0xffffc
    80006524:	810080e7          	jalr	-2032(ra) # 80001d30 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006528:	00d5179b          	slliw	a5,a0,0xd
    8000652c:	0c201537          	lui	a0,0xc201
    80006530:	953e                	add	a0,a0,a5
  return irq;
}
    80006532:	4148                	lw	a0,4(a0)
    80006534:	60a2                	ld	ra,8(sp)
    80006536:	6402                	ld	s0,0(sp)
    80006538:	0141                	addi	sp,sp,16
    8000653a:	8082                	ret

000000008000653c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000653c:	1101                	addi	sp,sp,-32
    8000653e:	ec06                	sd	ra,24(sp)
    80006540:	e822                	sd	s0,16(sp)
    80006542:	e426                	sd	s1,8(sp)
    80006544:	1000                	addi	s0,sp,32
    80006546:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006548:	ffffb097          	auipc	ra,0xffffb
    8000654c:	7e8080e7          	jalr	2024(ra) # 80001d30 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006550:	00d5151b          	slliw	a0,a0,0xd
    80006554:	0c2017b7          	lui	a5,0xc201
    80006558:	97aa                	add	a5,a5,a0
    8000655a:	c3c4                	sw	s1,4(a5)
}
    8000655c:	60e2                	ld	ra,24(sp)
    8000655e:	6442                	ld	s0,16(sp)
    80006560:	64a2                	ld	s1,8(sp)
    80006562:	6105                	addi	sp,sp,32
    80006564:	8082                	ret

0000000080006566 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006566:	1141                	addi	sp,sp,-16
    80006568:	e406                	sd	ra,8(sp)
    8000656a:	e022                	sd	s0,0(sp)
    8000656c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000656e:	479d                	li	a5,7
    80006570:	06a7c963          	blt	a5,a0,800065e2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006574:	0001d797          	auipc	a5,0x1d
    80006578:	a8c78793          	addi	a5,a5,-1396 # 80023000 <disk>
    8000657c:	00a78733          	add	a4,a5,a0
    80006580:	6789                	lui	a5,0x2
    80006582:	97ba                	add	a5,a5,a4
    80006584:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006588:	e7ad                	bnez	a5,800065f2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000658a:	00451793          	slli	a5,a0,0x4
    8000658e:	0001f717          	auipc	a4,0x1f
    80006592:	a7270713          	addi	a4,a4,-1422 # 80025000 <disk+0x2000>
    80006596:	6314                	ld	a3,0(a4)
    80006598:	96be                	add	a3,a3,a5
    8000659a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000659e:	6314                	ld	a3,0(a4)
    800065a0:	96be                	add	a3,a3,a5
    800065a2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    800065a6:	6314                	ld	a3,0(a4)
    800065a8:	96be                	add	a3,a3,a5
    800065aa:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    800065ae:	6318                	ld	a4,0(a4)
    800065b0:	97ba                	add	a5,a5,a4
    800065b2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    800065b6:	0001d797          	auipc	a5,0x1d
    800065ba:	a4a78793          	addi	a5,a5,-1462 # 80023000 <disk>
    800065be:	97aa                	add	a5,a5,a0
    800065c0:	6509                	lui	a0,0x2
    800065c2:	953e                	add	a0,a0,a5
    800065c4:	4785                	li	a5,1
    800065c6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    800065ca:	0001f517          	auipc	a0,0x1f
    800065ce:	a4e50513          	addi	a0,a0,-1458 # 80025018 <disk+0x2018>
    800065d2:	ffffc097          	auipc	ra,0xffffc
    800065d6:	122080e7          	jalr	290(ra) # 800026f4 <wakeup>
}
    800065da:	60a2                	ld	ra,8(sp)
    800065dc:	6402                	ld	s0,0(sp)
    800065de:	0141                	addi	sp,sp,16
    800065e0:	8082                	ret
    panic("free_desc 1");
    800065e2:	00002517          	auipc	a0,0x2
    800065e6:	25650513          	addi	a0,a0,598 # 80008838 <syscalls+0x330>
    800065ea:	ffffa097          	auipc	ra,0xffffa
    800065ee:	f54080e7          	jalr	-172(ra) # 8000053e <panic>
    panic("free_desc 2");
    800065f2:	00002517          	auipc	a0,0x2
    800065f6:	25650513          	addi	a0,a0,598 # 80008848 <syscalls+0x340>
    800065fa:	ffffa097          	auipc	ra,0xffffa
    800065fe:	f44080e7          	jalr	-188(ra) # 8000053e <panic>

0000000080006602 <virtio_disk_init>:
{
    80006602:	1101                	addi	sp,sp,-32
    80006604:	ec06                	sd	ra,24(sp)
    80006606:	e822                	sd	s0,16(sp)
    80006608:	e426                	sd	s1,8(sp)
    8000660a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000660c:	00002597          	auipc	a1,0x2
    80006610:	24c58593          	addi	a1,a1,588 # 80008858 <syscalls+0x350>
    80006614:	0001f517          	auipc	a0,0x1f
    80006618:	b1450513          	addi	a0,a0,-1260 # 80025128 <disk+0x2128>
    8000661c:	ffffa097          	auipc	ra,0xffffa
    80006620:	538080e7          	jalr	1336(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006624:	100017b7          	lui	a5,0x10001
    80006628:	4398                	lw	a4,0(a5)
    8000662a:	2701                	sext.w	a4,a4
    8000662c:	747277b7          	lui	a5,0x74727
    80006630:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006634:	0ef71163          	bne	a4,a5,80006716 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006638:	100017b7          	lui	a5,0x10001
    8000663c:	43dc                	lw	a5,4(a5)
    8000663e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006640:	4705                	li	a4,1
    80006642:	0ce79a63          	bne	a5,a4,80006716 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006646:	100017b7          	lui	a5,0x10001
    8000664a:	479c                	lw	a5,8(a5)
    8000664c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000664e:	4709                	li	a4,2
    80006650:	0ce79363          	bne	a5,a4,80006716 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006654:	100017b7          	lui	a5,0x10001
    80006658:	47d8                	lw	a4,12(a5)
    8000665a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000665c:	554d47b7          	lui	a5,0x554d4
    80006660:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006664:	0af71963          	bne	a4,a5,80006716 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006668:	100017b7          	lui	a5,0x10001
    8000666c:	4705                	li	a4,1
    8000666e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006670:	470d                	li	a4,3
    80006672:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006674:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006676:	c7ffe737          	lui	a4,0xc7ffe
    8000667a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000667e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006680:	2701                	sext.w	a4,a4
    80006682:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006684:	472d                	li	a4,11
    80006686:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006688:	473d                	li	a4,15
    8000668a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000668c:	6705                	lui	a4,0x1
    8000668e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006690:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006694:	5bdc                	lw	a5,52(a5)
    80006696:	2781                	sext.w	a5,a5
  if(max == 0)
    80006698:	c7d9                	beqz	a5,80006726 <virtio_disk_init+0x124>
  if(max < NUM)
    8000669a:	471d                	li	a4,7
    8000669c:	08f77d63          	bgeu	a4,a5,80006736 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800066a0:	100014b7          	lui	s1,0x10001
    800066a4:	47a1                	li	a5,8
    800066a6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    800066a8:	6609                	lui	a2,0x2
    800066aa:	4581                	li	a1,0
    800066ac:	0001d517          	auipc	a0,0x1d
    800066b0:	95450513          	addi	a0,a0,-1708 # 80023000 <disk>
    800066b4:	ffffa097          	auipc	ra,0xffffa
    800066b8:	62c080e7          	jalr	1580(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800066bc:	0001d717          	auipc	a4,0x1d
    800066c0:	94470713          	addi	a4,a4,-1724 # 80023000 <disk>
    800066c4:	00c75793          	srli	a5,a4,0xc
    800066c8:	2781                	sext.w	a5,a5
    800066ca:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    800066cc:	0001f797          	auipc	a5,0x1f
    800066d0:	93478793          	addi	a5,a5,-1740 # 80025000 <disk+0x2000>
    800066d4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    800066d6:	0001d717          	auipc	a4,0x1d
    800066da:	9aa70713          	addi	a4,a4,-1622 # 80023080 <disk+0x80>
    800066de:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800066e0:	0001e717          	auipc	a4,0x1e
    800066e4:	92070713          	addi	a4,a4,-1760 # 80024000 <disk+0x1000>
    800066e8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800066ea:	4705                	li	a4,1
    800066ec:	00e78c23          	sb	a4,24(a5)
    800066f0:	00e78ca3          	sb	a4,25(a5)
    800066f4:	00e78d23          	sb	a4,26(a5)
    800066f8:	00e78da3          	sb	a4,27(a5)
    800066fc:	00e78e23          	sb	a4,28(a5)
    80006700:	00e78ea3          	sb	a4,29(a5)
    80006704:	00e78f23          	sb	a4,30(a5)
    80006708:	00e78fa3          	sb	a4,31(a5)
}
    8000670c:	60e2                	ld	ra,24(sp)
    8000670e:	6442                	ld	s0,16(sp)
    80006710:	64a2                	ld	s1,8(sp)
    80006712:	6105                	addi	sp,sp,32
    80006714:	8082                	ret
    panic("could not find virtio disk");
    80006716:	00002517          	auipc	a0,0x2
    8000671a:	15250513          	addi	a0,a0,338 # 80008868 <syscalls+0x360>
    8000671e:	ffffa097          	auipc	ra,0xffffa
    80006722:	e20080e7          	jalr	-480(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006726:	00002517          	auipc	a0,0x2
    8000672a:	16250513          	addi	a0,a0,354 # 80008888 <syscalls+0x380>
    8000672e:	ffffa097          	auipc	ra,0xffffa
    80006732:	e10080e7          	jalr	-496(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006736:	00002517          	auipc	a0,0x2
    8000673a:	17250513          	addi	a0,a0,370 # 800088a8 <syscalls+0x3a0>
    8000673e:	ffffa097          	auipc	ra,0xffffa
    80006742:	e00080e7          	jalr	-512(ra) # 8000053e <panic>

0000000080006746 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006746:	7159                	addi	sp,sp,-112
    80006748:	f486                	sd	ra,104(sp)
    8000674a:	f0a2                	sd	s0,96(sp)
    8000674c:	eca6                	sd	s1,88(sp)
    8000674e:	e8ca                	sd	s2,80(sp)
    80006750:	e4ce                	sd	s3,72(sp)
    80006752:	e0d2                	sd	s4,64(sp)
    80006754:	fc56                	sd	s5,56(sp)
    80006756:	f85a                	sd	s6,48(sp)
    80006758:	f45e                	sd	s7,40(sp)
    8000675a:	f062                	sd	s8,32(sp)
    8000675c:	ec66                	sd	s9,24(sp)
    8000675e:	e86a                	sd	s10,16(sp)
    80006760:	1880                	addi	s0,sp,112
    80006762:	892a                	mv	s2,a0
    80006764:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006766:	00c52c83          	lw	s9,12(a0)
    8000676a:	001c9c9b          	slliw	s9,s9,0x1
    8000676e:	1c82                	slli	s9,s9,0x20
    80006770:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006774:	0001f517          	auipc	a0,0x1f
    80006778:	9b450513          	addi	a0,a0,-1612 # 80025128 <disk+0x2128>
    8000677c:	ffffa097          	auipc	ra,0xffffa
    80006780:	468080e7          	jalr	1128(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006784:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006786:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006788:	0001db97          	auipc	s7,0x1d
    8000678c:	878b8b93          	addi	s7,s7,-1928 # 80023000 <disk>
    80006790:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006792:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006794:	8a4e                	mv	s4,s3
    80006796:	a051                	j	8000681a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006798:	00fb86b3          	add	a3,s7,a5
    8000679c:	96da                	add	a3,a3,s6
    8000679e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800067a2:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800067a4:	0207c563          	bltz	a5,800067ce <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800067a8:	2485                	addiw	s1,s1,1
    800067aa:	0711                	addi	a4,a4,4
    800067ac:	25548063          	beq	s1,s5,800069ec <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    800067b0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800067b2:	0001f697          	auipc	a3,0x1f
    800067b6:	86668693          	addi	a3,a3,-1946 # 80025018 <disk+0x2018>
    800067ba:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800067bc:	0006c583          	lbu	a1,0(a3)
    800067c0:	fde1                	bnez	a1,80006798 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800067c2:	2785                	addiw	a5,a5,1
    800067c4:	0685                	addi	a3,a3,1
    800067c6:	ff879be3          	bne	a5,s8,800067bc <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800067ca:	57fd                	li	a5,-1
    800067cc:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800067ce:	02905a63          	blez	s1,80006802 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800067d2:	f9042503          	lw	a0,-112(s0)
    800067d6:	00000097          	auipc	ra,0x0
    800067da:	d90080e7          	jalr	-624(ra) # 80006566 <free_desc>
      for(int j = 0; j < i; j++)
    800067de:	4785                	li	a5,1
    800067e0:	0297d163          	bge	a5,s1,80006802 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800067e4:	f9442503          	lw	a0,-108(s0)
    800067e8:	00000097          	auipc	ra,0x0
    800067ec:	d7e080e7          	jalr	-642(ra) # 80006566 <free_desc>
      for(int j = 0; j < i; j++)
    800067f0:	4789                	li	a5,2
    800067f2:	0097d863          	bge	a5,s1,80006802 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800067f6:	f9842503          	lw	a0,-104(s0)
    800067fa:	00000097          	auipc	ra,0x0
    800067fe:	d6c080e7          	jalr	-660(ra) # 80006566 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006802:	0001f597          	auipc	a1,0x1f
    80006806:	92658593          	addi	a1,a1,-1754 # 80025128 <disk+0x2128>
    8000680a:	0001f517          	auipc	a0,0x1f
    8000680e:	80e50513          	addi	a0,a0,-2034 # 80025018 <disk+0x2018>
    80006812:	ffffc097          	auipc	ra,0xffffc
    80006816:	d42080e7          	jalr	-702(ra) # 80002554 <sleep>
  for(int i = 0; i < 3; i++){
    8000681a:	f9040713          	addi	a4,s0,-112
    8000681e:	84ce                	mv	s1,s3
    80006820:	bf41                	j	800067b0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006822:	20058713          	addi	a4,a1,512
    80006826:	00471693          	slli	a3,a4,0x4
    8000682a:	0001c717          	auipc	a4,0x1c
    8000682e:	7d670713          	addi	a4,a4,2006 # 80023000 <disk>
    80006832:	9736                	add	a4,a4,a3
    80006834:	4685                	li	a3,1
    80006836:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000683a:	20058713          	addi	a4,a1,512
    8000683e:	00471693          	slli	a3,a4,0x4
    80006842:	0001c717          	auipc	a4,0x1c
    80006846:	7be70713          	addi	a4,a4,1982 # 80023000 <disk>
    8000684a:	9736                	add	a4,a4,a3
    8000684c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006850:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006854:	7679                	lui	a2,0xffffe
    80006856:	963e                	add	a2,a2,a5
    80006858:	0001e697          	auipc	a3,0x1e
    8000685c:	7a868693          	addi	a3,a3,1960 # 80025000 <disk+0x2000>
    80006860:	6298                	ld	a4,0(a3)
    80006862:	9732                	add	a4,a4,a2
    80006864:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006866:	6298                	ld	a4,0(a3)
    80006868:	9732                	add	a4,a4,a2
    8000686a:	4541                	li	a0,16
    8000686c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000686e:	6298                	ld	a4,0(a3)
    80006870:	9732                	add	a4,a4,a2
    80006872:	4505                	li	a0,1
    80006874:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006878:	f9442703          	lw	a4,-108(s0)
    8000687c:	6288                	ld	a0,0(a3)
    8000687e:	962a                	add	a2,a2,a0
    80006880:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006884:	0712                	slli	a4,a4,0x4
    80006886:	6290                	ld	a2,0(a3)
    80006888:	963a                	add	a2,a2,a4
    8000688a:	05890513          	addi	a0,s2,88
    8000688e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006890:	6294                	ld	a3,0(a3)
    80006892:	96ba                	add	a3,a3,a4
    80006894:	40000613          	li	a2,1024
    80006898:	c690                	sw	a2,8(a3)
  if(write)
    8000689a:	140d0063          	beqz	s10,800069da <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000689e:	0001e697          	auipc	a3,0x1e
    800068a2:	7626b683          	ld	a3,1890(a3) # 80025000 <disk+0x2000>
    800068a6:	96ba                	add	a3,a3,a4
    800068a8:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800068ac:	0001c817          	auipc	a6,0x1c
    800068b0:	75480813          	addi	a6,a6,1876 # 80023000 <disk>
    800068b4:	0001e517          	auipc	a0,0x1e
    800068b8:	74c50513          	addi	a0,a0,1868 # 80025000 <disk+0x2000>
    800068bc:	6114                	ld	a3,0(a0)
    800068be:	96ba                	add	a3,a3,a4
    800068c0:	00c6d603          	lhu	a2,12(a3)
    800068c4:	00166613          	ori	a2,a2,1
    800068c8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800068cc:	f9842683          	lw	a3,-104(s0)
    800068d0:	6110                	ld	a2,0(a0)
    800068d2:	9732                	add	a4,a4,a2
    800068d4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800068d8:	20058613          	addi	a2,a1,512
    800068dc:	0612                	slli	a2,a2,0x4
    800068de:	9642                	add	a2,a2,a6
    800068e0:	577d                	li	a4,-1
    800068e2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800068e6:	00469713          	slli	a4,a3,0x4
    800068ea:	6114                	ld	a3,0(a0)
    800068ec:	96ba                	add	a3,a3,a4
    800068ee:	03078793          	addi	a5,a5,48
    800068f2:	97c2                	add	a5,a5,a6
    800068f4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    800068f6:	611c                	ld	a5,0(a0)
    800068f8:	97ba                	add	a5,a5,a4
    800068fa:	4685                	li	a3,1
    800068fc:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800068fe:	611c                	ld	a5,0(a0)
    80006900:	97ba                	add	a5,a5,a4
    80006902:	4809                	li	a6,2
    80006904:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006908:	611c                	ld	a5,0(a0)
    8000690a:	973e                	add	a4,a4,a5
    8000690c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006910:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006914:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006918:	6518                	ld	a4,8(a0)
    8000691a:	00275783          	lhu	a5,2(a4)
    8000691e:	8b9d                	andi	a5,a5,7
    80006920:	0786                	slli	a5,a5,0x1
    80006922:	97ba                	add	a5,a5,a4
    80006924:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006928:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000692c:	6518                	ld	a4,8(a0)
    8000692e:	00275783          	lhu	a5,2(a4)
    80006932:	2785                	addiw	a5,a5,1
    80006934:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006938:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000693c:	100017b7          	lui	a5,0x10001
    80006940:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006944:	00492703          	lw	a4,4(s2)
    80006948:	4785                	li	a5,1
    8000694a:	02f71163          	bne	a4,a5,8000696c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000694e:	0001e997          	auipc	s3,0x1e
    80006952:	7da98993          	addi	s3,s3,2010 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006956:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006958:	85ce                	mv	a1,s3
    8000695a:	854a                	mv	a0,s2
    8000695c:	ffffc097          	auipc	ra,0xffffc
    80006960:	bf8080e7          	jalr	-1032(ra) # 80002554 <sleep>
  while(b->disk == 1) {
    80006964:	00492783          	lw	a5,4(s2)
    80006968:	fe9788e3          	beq	a5,s1,80006958 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000696c:	f9042903          	lw	s2,-112(s0)
    80006970:	20090793          	addi	a5,s2,512
    80006974:	00479713          	slli	a4,a5,0x4
    80006978:	0001c797          	auipc	a5,0x1c
    8000697c:	68878793          	addi	a5,a5,1672 # 80023000 <disk>
    80006980:	97ba                	add	a5,a5,a4
    80006982:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006986:	0001e997          	auipc	s3,0x1e
    8000698a:	67a98993          	addi	s3,s3,1658 # 80025000 <disk+0x2000>
    8000698e:	00491713          	slli	a4,s2,0x4
    80006992:	0009b783          	ld	a5,0(s3)
    80006996:	97ba                	add	a5,a5,a4
    80006998:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000699c:	854a                	mv	a0,s2
    8000699e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800069a2:	00000097          	auipc	ra,0x0
    800069a6:	bc4080e7          	jalr	-1084(ra) # 80006566 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800069aa:	8885                	andi	s1,s1,1
    800069ac:	f0ed                	bnez	s1,8000698e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800069ae:	0001e517          	auipc	a0,0x1e
    800069b2:	77a50513          	addi	a0,a0,1914 # 80025128 <disk+0x2128>
    800069b6:	ffffa097          	auipc	ra,0xffffa
    800069ba:	2e2080e7          	jalr	738(ra) # 80000c98 <release>
}
    800069be:	70a6                	ld	ra,104(sp)
    800069c0:	7406                	ld	s0,96(sp)
    800069c2:	64e6                	ld	s1,88(sp)
    800069c4:	6946                	ld	s2,80(sp)
    800069c6:	69a6                	ld	s3,72(sp)
    800069c8:	6a06                	ld	s4,64(sp)
    800069ca:	7ae2                	ld	s5,56(sp)
    800069cc:	7b42                	ld	s6,48(sp)
    800069ce:	7ba2                	ld	s7,40(sp)
    800069d0:	7c02                	ld	s8,32(sp)
    800069d2:	6ce2                	ld	s9,24(sp)
    800069d4:	6d42                	ld	s10,16(sp)
    800069d6:	6165                	addi	sp,sp,112
    800069d8:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800069da:	0001e697          	auipc	a3,0x1e
    800069de:	6266b683          	ld	a3,1574(a3) # 80025000 <disk+0x2000>
    800069e2:	96ba                	add	a3,a3,a4
    800069e4:	4609                	li	a2,2
    800069e6:	00c69623          	sh	a2,12(a3)
    800069ea:	b5c9                	j	800068ac <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800069ec:	f9042583          	lw	a1,-112(s0)
    800069f0:	20058793          	addi	a5,a1,512
    800069f4:	0792                	slli	a5,a5,0x4
    800069f6:	0001c517          	auipc	a0,0x1c
    800069fa:	6b250513          	addi	a0,a0,1714 # 800230a8 <disk+0xa8>
    800069fe:	953e                	add	a0,a0,a5
  if(write)
    80006a00:	e20d11e3          	bnez	s10,80006822 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006a04:	20058713          	addi	a4,a1,512
    80006a08:	00471693          	slli	a3,a4,0x4
    80006a0c:	0001c717          	auipc	a4,0x1c
    80006a10:	5f470713          	addi	a4,a4,1524 # 80023000 <disk>
    80006a14:	9736                	add	a4,a4,a3
    80006a16:	0a072423          	sw	zero,168(a4)
    80006a1a:	b505                	j	8000683a <virtio_disk_rw+0xf4>

0000000080006a1c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006a1c:	1101                	addi	sp,sp,-32
    80006a1e:	ec06                	sd	ra,24(sp)
    80006a20:	e822                	sd	s0,16(sp)
    80006a22:	e426                	sd	s1,8(sp)
    80006a24:	e04a                	sd	s2,0(sp)
    80006a26:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006a28:	0001e517          	auipc	a0,0x1e
    80006a2c:	70050513          	addi	a0,a0,1792 # 80025128 <disk+0x2128>
    80006a30:	ffffa097          	auipc	ra,0xffffa
    80006a34:	1b4080e7          	jalr	436(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006a38:	10001737          	lui	a4,0x10001
    80006a3c:	533c                	lw	a5,96(a4)
    80006a3e:	8b8d                	andi	a5,a5,3
    80006a40:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006a42:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006a46:	0001e797          	auipc	a5,0x1e
    80006a4a:	5ba78793          	addi	a5,a5,1466 # 80025000 <disk+0x2000>
    80006a4e:	6b94                	ld	a3,16(a5)
    80006a50:	0207d703          	lhu	a4,32(a5)
    80006a54:	0026d783          	lhu	a5,2(a3)
    80006a58:	06f70163          	beq	a4,a5,80006aba <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006a5c:	0001c917          	auipc	s2,0x1c
    80006a60:	5a490913          	addi	s2,s2,1444 # 80023000 <disk>
    80006a64:	0001e497          	auipc	s1,0x1e
    80006a68:	59c48493          	addi	s1,s1,1436 # 80025000 <disk+0x2000>
    __sync_synchronize();
    80006a6c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006a70:	6898                	ld	a4,16(s1)
    80006a72:	0204d783          	lhu	a5,32(s1)
    80006a76:	8b9d                	andi	a5,a5,7
    80006a78:	078e                	slli	a5,a5,0x3
    80006a7a:	97ba                	add	a5,a5,a4
    80006a7c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006a7e:	20078713          	addi	a4,a5,512
    80006a82:	0712                	slli	a4,a4,0x4
    80006a84:	974a                	add	a4,a4,s2
    80006a86:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    80006a8a:	e731                	bnez	a4,80006ad6 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006a8c:	20078793          	addi	a5,a5,512
    80006a90:	0792                	slli	a5,a5,0x4
    80006a92:	97ca                	add	a5,a5,s2
    80006a94:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006a96:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006a9a:	ffffc097          	auipc	ra,0xffffc
    80006a9e:	c5a080e7          	jalr	-934(ra) # 800026f4 <wakeup>

    disk.used_idx += 1;
    80006aa2:	0204d783          	lhu	a5,32(s1)
    80006aa6:	2785                	addiw	a5,a5,1
    80006aa8:	17c2                	slli	a5,a5,0x30
    80006aaa:	93c1                	srli	a5,a5,0x30
    80006aac:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006ab0:	6898                	ld	a4,16(s1)
    80006ab2:	00275703          	lhu	a4,2(a4)
    80006ab6:	faf71be3          	bne	a4,a5,80006a6c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    80006aba:	0001e517          	auipc	a0,0x1e
    80006abe:	66e50513          	addi	a0,a0,1646 # 80025128 <disk+0x2128>
    80006ac2:	ffffa097          	auipc	ra,0xffffa
    80006ac6:	1d6080e7          	jalr	470(ra) # 80000c98 <release>
}
    80006aca:	60e2                	ld	ra,24(sp)
    80006acc:	6442                	ld	s0,16(sp)
    80006ace:	64a2                	ld	s1,8(sp)
    80006ad0:	6902                	ld	s2,0(sp)
    80006ad2:	6105                	addi	sp,sp,32
    80006ad4:	8082                	ret
      panic("virtio_disk_intr status");
    80006ad6:	00002517          	auipc	a0,0x2
    80006ada:	df250513          	addi	a0,a0,-526 # 800088c8 <syscalls+0x3c0>
    80006ade:	ffffa097          	auipc	ra,0xffffa
    80006ae2:	a60080e7          	jalr	-1440(ra) # 8000053e <panic>

0000000080006ae6 <cas>:
    80006ae6:	100522af          	lr.w	t0,(a0)
    80006aea:	00b29563          	bne	t0,a1,80006af4 <fail>
    80006aee:	18c5252f          	sc.w	a0,a2,(a0)
    80006af2:	8082                	ret

0000000080006af4 <fail>:
    80006af4:	4505                	li	a0,1
    80006af6:	8082                	ret
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
