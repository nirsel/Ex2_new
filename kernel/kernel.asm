
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	90013103          	ld	sp,-1792(sp) # 80008900 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000068:	79c78793          	addi	a5,a5,1948 # 80006800 <timervec>
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
    80000130:	cb0080e7          	jalr	-848(ra) # 80002ddc <either_copyin>
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
    800001c8:	ddc080e7          	jalr	-548(ra) # 80001fa0 <myproc>
    800001cc:	413c                	lw	a5,64(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	64c080e7          	jalr	1612(ra) # 80002820 <sleep>
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
    80000214:	b76080e7          	jalr	-1162(ra) # 80002d86 <either_copyout>
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
    800002f6:	b40080e7          	jalr	-1216(ra) # 80002e32 <procdump>
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
    8000044a:	57c080e7          	jalr	1404(ra) # 800029c2 <wakeup>
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
    80000570:	d9c50513          	addi	a0,a0,-612 # 80008308 <digits+0x2c8>
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
    800008a4:	122080e7          	jalr	290(ra) # 800029c2 <wakeup>
    
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
    80000930:	ef4080e7          	jalr	-268(ra) # 80002820 <sleep>
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
    80000b82:	406080e7          	jalr	1030(ra) # 80001f84 <mycpu>
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
    80000bb4:	3d4080e7          	jalr	980(ra) # 80001f84 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	3c8080e7          	jalr	968(ra) # 80001f84 <mycpu>
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
    80000bd8:	3b0080e7          	jalr	944(ra) # 80001f84 <mycpu>
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
    80000c18:	370080e7          	jalr	880(ra) # 80001f84 <mycpu>
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
    80000c44:	344080e7          	jalr	836(ra) # 80001f84 <mycpu>
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
    80000e9a:	0de080e7          	jalr	222(ra) # 80001f74 <cpuid>
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
    80000eb6:	0c2080e7          	jalr	194(ra) # 80001f74 <cpuid>
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
    80000ed8:	392080e7          	jalr	914(ra) # 80003266 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00006097          	auipc	ra,0x6
    80000ee0:	964080e7          	jalr	-1692(ra) # 80006840 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	6e8080e7          	jalr	1768(ra) # 800025cc <scheduler>
    consoleinit();
    80000eec:	fffff097          	auipc	ra,0xfffff
    80000ef0:	564080e7          	jalr	1380(ra) # 80000450 <consoleinit>
    printfinit();
    80000ef4:	00000097          	auipc	ra,0x0
    80000ef8:	87a080e7          	jalr	-1926(ra) # 8000076e <printfinit>
    printf("\n");
    80000efc:	00007517          	auipc	a0,0x7
    80000f00:	40c50513          	addi	a0,a0,1036 # 80008308 <digits+0x2c8>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	684080e7          	jalr	1668(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	19450513          	addi	a0,a0,404 # 800080a0 <digits+0x60>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	3ec50513          	addi	a0,a0,1004 # 80008308 <digits+0x2c8>
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
    80000f48:	f3e080e7          	jalr	-194(ra) # 80001e82 <procinit>
    trapinit();      // trap vectors
    80000f4c:	00002097          	auipc	ra,0x2
    80000f50:	2f2080e7          	jalr	754(ra) # 8000323e <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	312080e7          	jalr	786(ra) # 80003266 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00006097          	auipc	ra,0x6
    80000f60:	8ce080e7          	jalr	-1842(ra) # 8000682a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00006097          	auipc	ra,0x6
    80000f68:	8dc080e7          	jalr	-1828(ra) # 80006840 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00003097          	auipc	ra,0x3
    80000f70:	ab8080e7          	jalr	-1352(ra) # 80003a24 <binit>
    iinit();         // inode table
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	148080e7          	jalr	328(ra) # 800040bc <iinit>
    fileinit();      // file table
    80000f7c:	00004097          	auipc	ra,0x4
    80000f80:	0f2080e7          	jalr	242(ra) # 8000506e <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00006097          	auipc	ra,0x6
    80000f88:	9de080e7          	jalr	-1570(ra) # 80006962 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	398080e7          	jalr	920(ra) # 80002324 <userinit>
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
    80001244:	bac080e7          	jalr	-1108(ra) # 80001dec <proc_mapstacks>
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
    8000184c:	567d                	li	a2,-1
    8000184e:	dfb0                	sw	a2,120(a5)
  unused_list.counter = __INT64_MAX__;
    80001850:	577d                	li	a4,-1
    80001852:	00175693          	srli	a3,a4,0x1
    80001856:	efd4                	sd	a3,152(a5)
  unused_list.last = -1;
    80001858:	dff8                	sw	a4,124(a5)
  
  sleeping_list.head = -1;
    8000185a:	0ac7a023          	sw	a2,160(a5)
  sleeping_list.last = -1;
    8000185e:	0ac7a223          	sw	a2,164(a5)
  sleeping_list.counter = __INT64_MAX__;
    80001862:	e3f4                	sd	a3,192(a5)
  zombie_list.head = -1;
    80001864:	0ce7a423          	sw	a4,200(a5)
  zombie_list.last = -1;
    80001868:	0ce7a623          	sw	a4,204(a5)
  zombie_list.counter = __INT64_MAX__;
    8000186c:	f7f4                	sd	a3,232(a5)
  struct processList* p;
  for (p = runnable_cpu_lists; p<&runnable_cpu_lists[current_cpu_number]; p++){
    8000186e:	00010697          	auipc	a3,0x10
    80001872:	aaa68693          	addi	a3,a3,-1366 # 80011318 <unused_list>
      
      p->head = -1;
    80001876:	c398                	sw	a4,0(a5)
      p->last = -1;
    80001878:	c3d8                	sw	a4,4(a5)
      p->counter = 0;
    8000187a:	0207b023          	sd	zero,32(a5)
  for (p = runnable_cpu_lists; p<&runnable_cpu_lists[current_cpu_number]; p++){
    8000187e:	02878793          	addi	a5,a5,40
    80001882:	fed79ae3          	bne	a5,a3,80001876 <lists_init+0x38>
  }
  
}
    80001886:	6422                	ld	s0,8(sp)
    80001888:	0141                	addi	sp,sp,16
    8000188a:	8082                	ret

000000008000188c <get_balanced_cpu>:
  }

  return 0;
}

int get_balanced_cpu(void){
    8000188c:	1141                	addi	sp,sp,-16
    8000188e:	e422                	sd	s0,8(sp)
    80001890:	0800                	addi	s0,sp,16

    uint64 min = runnable_cpu_lists[0].counter;
    80001892:	00010797          	auipc	a5,0x10
    80001896:	a0e78793          	addi	a5,a5,-1522 # 800112a0 <runnable_cpu_lists>
    8000189a:	7398                	ld	a4,32(a5)
    if (current_cpu_number < 2)
      return 0;
    int index;
    struct processList* p = &runnable_cpu_lists[1];
    for (index=1;p<&runnable_cpu_lists[current_cpu_number];p++){
        if (p->counter<min){
    8000189c:	67bc                	ld	a5,72(a5)
    for (index=1;p<&runnable_cpu_lists[current_cpu_number];p++){
    8000189e:	4505                	li	a0,1
        if (p->counter<min){
    800018a0:	00e7e463          	bltu	a5,a4,800018a8 <get_balanced_cpu+0x1c>
    uint64 min = runnable_cpu_lists[0].counter;
    800018a4:	87ba                	mv	a5,a4
    int min_cpu = 0;
    800018a6:	4501                	li	a0,0
        if (p->counter<min){
    800018a8:	00010717          	auipc	a4,0x10
    800018ac:	a6873703          	ld	a4,-1432(a4) # 80011310 <runnable_cpu_lists+0x70>
    800018b0:	00f77363          	bgeu	a4,a5,800018b6 <get_balanced_cpu+0x2a>
            min = p->counter;
            min_cpu = index;
        }
        index++;
    800018b4:	4509                	li	a0,2
    }

    return min_cpu;

}
    800018b6:	6422                	ld	s0,8(sp)
    800018b8:	0141                	addi	sp,sp,16
    800018ba:	8082                	ret

00000000800018bc <remove_link>:
void remove_link(struct processList* list, int index){  // index = the process index in proc
    800018bc:	715d                	addi	sp,sp,-80
    800018be:	e486                	sd	ra,72(sp)
    800018c0:	e0a2                	sd	s0,64(sp)
    800018c2:	fc26                	sd	s1,56(sp)
    800018c4:	f84a                	sd	s2,48(sp)
    800018c6:	f44e                	sd	s3,40(sp)
    800018c8:	f052                	sd	s4,32(sp)
    800018ca:	ec56                	sd	s5,24(sp)
    800018cc:	e85a                	sd	s6,16(sp)
    800018ce:	e45e                	sd	s7,8(sp)
    800018d0:	0880                	addi	s0,sp,80
    800018d2:	8aaa                	mv	s5,a0
    800018d4:	8a2e                	mv	s4,a1
  //printf("start remove proc with index %d\n", index);
  acquire(&list->head_lock);
    800018d6:	00850913          	addi	s2,a0,8
    800018da:	854a                	mv	a0,s2
    800018dc:	fffff097          	auipc	ra,0xfffff
    800018e0:	308080e7          	jalr	776(ra) # 80000be4 <acquire>
  if (list->head == -1){  //empty list
    800018e4:	000aa503          	lw	a0,0(s5) # fffffffffffff000 <end+0xffffffff7ffd9000>
    800018e8:	57fd                	li	a5,-1
    800018ea:	0cf50a63          	beq	a0,a5,800019be <remove_link+0x102>
    release(&list->head_lock);
    return;
  }
  acquire(&proc[list->head].list_lock);
    800018ee:	19000793          	li	a5,400
    800018f2:	02f50533          	mul	a0,a0,a5
    800018f6:	00010797          	auipc	a5,0x10
    800018fa:	ee278793          	addi	a5,a5,-286 # 800117d8 <proc+0x18>
    800018fe:	953e                	add	a0,a0,a5
    80001900:	fffff097          	auipc	ra,0xfffff
    80001904:	2e4080e7          	jalr	740(ra) # 80000be4 <acquire>
  struct proc* head = &proc[list->head];
    80001908:	000aab83          	lw	s7,0(s5)
  if (list->head == list->last){  //list of size 1
    8000190c:	004aa783          	lw	a5,4(s5)
    80001910:	0b778d63          	beq	a5,s7,800019ca <remove_link+0x10e>
      release(&head->list_lock);
      release(&list->head_lock);
      return;
  }
  else{  //list of size > 1 and removing the head
    if (head->proc_index == index){
    80001914:	19000793          	li	a5,400
    80001918:	02fb8733          	mul	a4,s7,a5
    8000191c:	00010797          	auipc	a5,0x10
    80001920:	ea478793          	addi	a5,a5,-348 # 800117c0 <proc>
    80001924:	97ba                	add	a5,a5,a4
    80001926:	1847a783          	lw	a5,388(a5)
    8000192a:	11478163          	beq	a5,s4,80001a2c <remove_link+0x170>
  struct proc* head = &proc[list->head];
    8000192e:	19000493          	li	s1,400
    80001932:	029b8bb3          	mul	s7,s7,s1
    80001936:	00010997          	auipc	s3,0x10
    8000193a:	e8a98993          	addi	s3,s3,-374 # 800117c0 <proc>
    8000193e:	9bce                	add	s7,s7,s3
      release(&list->head_lock);
      return;
    }
  }
  
  acquire(&proc[head->next_proc_index].list_lock);
    80001940:	180ba503          	lw	a0,384(s7) # fffffffffffff180 <end+0xffffffff7ffd9180>
    80001944:	02950533          	mul	a0,a0,s1
    80001948:	0561                	addi	a0,a0,24
    8000194a:	954e                	add	a0,a0,s3
    8000194c:	fffff097          	auipc	ra,0xfffff
    80001950:	298080e7          	jalr	664(ra) # 80000be4 <acquire>
  struct proc* next = &proc[head->next_proc_index];
    80001954:	180ba783          	lw	a5,384(s7)
    80001958:	029784b3          	mul	s1,a5,s1
    8000195c:	94ce                	add	s1,s1,s3
  release(&list->head_lock);
    8000195e:	854a                	mv	a0,s2
    80001960:	fffff097          	auipc	ra,0xfffff
    80001964:	338080e7          	jalr	824(ra) # 80000c98 <release>
  while(next->proc_index != index && next->next_proc_index != -1){
    80001968:	1844a703          	lw	a4,388(s1)
    8000196c:	5b7d                	li	s6,-1
      release(&head->list_lock);
      head = next;
      acquire(&proc[head->next_proc_index].list_lock);
    8000196e:	19000993          	li	s3,400
    80001972:	00010917          	auipc	s2,0x10
    80001976:	e4e90913          	addi	s2,s2,-434 # 800117c0 <proc>
  while(next->proc_index != index && next->next_proc_index != -1){
    8000197a:	0eea0363          	beq	s4,a4,80001a60 <remove_link+0x1a4>
    8000197e:	1804a783          	lw	a5,384(s1)
    80001982:	0f678f63          	beq	a5,s6,80001a80 <remove_link+0x1c4>
      release(&head->list_lock);
    80001986:	018b8513          	addi	a0,s7,24
    8000198a:	fffff097          	auipc	ra,0xfffff
    8000198e:	30e080e7          	jalr	782(ra) # 80000c98 <release>
      acquire(&proc[head->next_proc_index].list_lock);
    80001992:	1804a503          	lw	a0,384(s1)
    80001996:	03350533          	mul	a0,a0,s3
    8000199a:	0561                	addi	a0,a0,24
    8000199c:	954a                	add	a0,a0,s2
    8000199e:	fffff097          	auipc	ra,0xfffff
    800019a2:	246080e7          	jalr	582(ra) # 80000be4 <acquire>
      next = &proc[next->next_proc_index];
    800019a6:	1804a783          	lw	a5,384(s1)
    800019aa:	033787b3          	mul	a5,a5,s3
    800019ae:	97ca                	add	a5,a5,s2
  while(next->proc_index != index && next->next_proc_index != -1){
    800019b0:	1847a703          	lw	a4,388(a5)
    800019b4:	8ba6                	mv	s7,s1
    800019b6:	0b470763          	beq	a4,s4,80001a64 <remove_link+0x1a8>
      next = &proc[next->next_proc_index];
    800019ba:	84be                	mv	s1,a5
    800019bc:	b7c9                	j	8000197e <remove_link+0xc2>
    release(&list->head_lock);
    800019be:	854a                	mv	a0,s2
    800019c0:	fffff097          	auipc	ra,0xfffff
    800019c4:	2d8080e7          	jalr	728(ra) # 80000c98 <release>
    return;
    800019c8:	a8d1                	j	80001a9c <remove_link+0x1e0>
    if (head->proc_index == index){
    800019ca:	19000793          	li	a5,400
    800019ce:	02fb8733          	mul	a4,s7,a5
    800019d2:	00010797          	auipc	a5,0x10
    800019d6:	dee78793          	addi	a5,a5,-530 # 800117c0 <proc>
    800019da:	97ba                	add	a5,a5,a4
    800019dc:	1847a783          	lw	a5,388(a5)
    800019e0:	03478563          	beq	a5,s4,80001a0a <remove_link+0x14e>
      release(&head->list_lock);
    800019e4:	19000513          	li	a0,400
    800019e8:	02ab8bb3          	mul	s7,s7,a0
    800019ec:	00010517          	auipc	a0,0x10
    800019f0:	dec50513          	addi	a0,a0,-532 # 800117d8 <proc+0x18>
    800019f4:	955e                	add	a0,a0,s7
    800019f6:	fffff097          	auipc	ra,0xfffff
    800019fa:	2a2080e7          	jalr	674(ra) # 80000c98 <release>
      release(&list->head_lock);
    800019fe:	854a                	mv	a0,s2
    80001a00:	fffff097          	auipc	ra,0xfffff
    80001a04:	298080e7          	jalr	664(ra) # 80000c98 <release>
      return;
    80001a08:	a851                	j	80001a9c <remove_link+0x1e0>
      list->head = -1;
    80001a0a:	577d                	li	a4,-1
    80001a0c:	00eaa023          	sw	a4,0(s5)
      list->last = -1;
    80001a10:	00eaa223          	sw	a4,4(s5)
      head->next_proc_index = -1;
    80001a14:	19000793          	li	a5,400
    80001a18:	02fb86b3          	mul	a3,s7,a5
    80001a1c:	00010797          	auipc	a5,0x10
    80001a20:	da478793          	addi	a5,a5,-604 # 800117c0 <proc>
    80001a24:	97b6                	add	a5,a5,a3
    80001a26:	18e7a023          	sw	a4,384(a5)
    80001a2a:	bf6d                	j	800019e4 <remove_link+0x128>
      list->head = head->next_proc_index;
    80001a2c:	00010517          	auipc	a0,0x10
    80001a30:	d9450513          	addi	a0,a0,-620 # 800117c0 <proc>
    80001a34:	8bba                	mv	s7,a4
    80001a36:	00e507b3          	add	a5,a0,a4
    80001a3a:	1807a703          	lw	a4,384(a5)
    80001a3e:	00eaa023          	sw	a4,0(s5)
      head->next_proc_index = -1;
    80001a42:	577d                	li	a4,-1
    80001a44:	18e7a023          	sw	a4,384(a5)
      release(&head->list_lock);
    80001a48:	0be1                	addi	s7,s7,24
    80001a4a:	955e                	add	a0,a0,s7
    80001a4c:	fffff097          	auipc	ra,0xfffff
    80001a50:	24c080e7          	jalr	588(ra) # 80000c98 <release>
      release(&list->head_lock);
    80001a54:	854a                	mv	a0,s2
    80001a56:	fffff097          	auipc	ra,0xfffff
    80001a5a:	242080e7          	jalr	578(ra) # 80000c98 <release>
      return;
    80001a5e:	a83d                	j	80001a9c <remove_link+0x1e0>
  struct proc* next = &proc[head->next_proc_index];
    80001a60:	87a6                	mv	a5,s1
  struct proc* head = &proc[list->head];
    80001a62:	84de                	mv	s1,s7
  }
  if (next->proc_index == index){
      head->next_proc_index = next->next_proc_index;
    80001a64:	1807a703          	lw	a4,384(a5)
    80001a68:	18e4a023          	sw	a4,384(s1)
      next->next_proc_index = -1;
    80001a6c:	577d                	li	a4,-1
    80001a6e:	18e7a023          	sw	a4,384(a5)
      if (next->next_proc_index == -1){
          list->last = head->proc_index;
    80001a72:	1844a703          	lw	a4,388(s1)
    80001a76:	00eaa223          	sw	a4,4(s5)
    80001a7a:	8ba6                	mv	s7,s1
    80001a7c:	84be                	mv	s1,a5
    80001a7e:	a019                	j	80001a84 <remove_link+0x1c8>
  if (next->proc_index == index){
    80001a80:	02ea0963          	beq	s4,a4,80001ab2 <remove_link+0x1f6>
      }
    }
  release(&head->list_lock);
    80001a84:	018b8513          	addi	a0,s7,24
    80001a88:	fffff097          	auipc	ra,0xfffff
    80001a8c:	210080e7          	jalr	528(ra) # 80000c98 <release>
  release(&next->list_lock);
    80001a90:	01848513          	addi	a0,s1,24
    80001a94:	fffff097          	auipc	ra,0xfffff
    80001a98:	204080e7          	jalr	516(ra) # 80000c98 <release>


}
    80001a9c:	60a6                	ld	ra,72(sp)
    80001a9e:	6406                	ld	s0,64(sp)
    80001aa0:	74e2                	ld	s1,56(sp)
    80001aa2:	7942                	ld	s2,48(sp)
    80001aa4:	79a2                	ld	s3,40(sp)
    80001aa6:	7a02                	ld	s4,32(sp)
    80001aa8:	6ae2                	ld	s5,24(sp)
    80001aaa:	6b42                	ld	s6,16(sp)
    80001aac:	6ba2                	ld	s7,8(sp)
    80001aae:	6161                	addi	sp,sp,80
    80001ab0:	8082                	ret
    80001ab2:	87a6                	mv	a5,s1
    80001ab4:	84de                	mv	s1,s7
    80001ab6:	b77d                	j	80001a64 <remove_link+0x1a8>

0000000080001ab8 <increment_counter>:

uint64 increment_counter(struct processList* list){
    80001ab8:	7179                	addi	sp,sp,-48
    80001aba:	f406                	sd	ra,40(sp)
    80001abc:	f022                	sd	s0,32(sp)
    80001abe:	ec26                	sd	s1,24(sp)
    80001ac0:	e84a                	sd	s2,16(sp)
    80001ac2:	e44e                	sd	s3,8(sp)
    80001ac4:	1800                	addi	s0,sp,48
    80001ac6:	892a                	mv	s2,a0
  uint64 old;
  do {
    old = list->counter;
  } while(cas(&list->counter, old,old+1));
    80001ac8:	02050993          	addi	s3,a0,32
    old = list->counter;
    80001acc:	02093483          	ld	s1,32(s2)
  } while(cas(&list->counter, old,old+1));
    80001ad0:	0014861b          	addiw	a2,s1,1
    80001ad4:	0004859b          	sext.w	a1,s1
    80001ad8:	854e                	mv	a0,s3
    80001ada:	00005097          	auipc	ra,0x5
    80001ade:	36c080e7          	jalr	876(ra) # 80006e46 <cas>
    80001ae2:	f56d                	bnez	a0,80001acc <increment_counter+0x14>

  return old+1;
}
    80001ae4:	00148513          	addi	a0,s1,1
    80001ae8:	70a2                	ld	ra,40(sp)
    80001aea:	7402                	ld	s0,32(sp)
    80001aec:	64e2                	ld	s1,24(sp)
    80001aee:	6942                	ld	s2,16(sp)
    80001af0:	69a2                	ld	s3,8(sp)
    80001af2:	6145                	addi	sp,sp,48
    80001af4:	8082                	ret

0000000080001af6 <steal_proc>:
struct proc* steal_proc(int curr_cpu){
    80001af6:	715d                	addi	sp,sp,-80
    80001af8:	e486                	sd	ra,72(sp)
    80001afa:	e0a2                	sd	s0,64(sp)
    80001afc:	fc26                	sd	s1,56(sp)
    80001afe:	f84a                	sd	s2,48(sp)
    80001b00:	f44e                	sd	s3,40(sp)
    80001b02:	f052                	sd	s4,32(sp)
    80001b04:	ec56                	sd	s5,24(sp)
    80001b06:	e85a                	sd	s6,16(sp)
    80001b08:	e45e                	sd	s7,8(sp)
    80001b0a:	0880                	addi	s0,sp,80
    80001b0c:	89aa                	mv	s3,a0
  for (index = 0; index< current_cpu_number; index++){
    80001b0e:	0000f917          	auipc	s2,0xf
    80001b12:	79290913          	addi	s2,s2,1938 # 800112a0 <runnable_cpu_lists>
    80001b16:	4481                	li	s1,0
        if (curr_list->head != -1){
    80001b18:	5b7d                	li	s6,-1
  for (index = 0; index< current_cpu_number; index++){
    80001b1a:	4a8d                	li	s5,3
    80001b1c:	a07d                	j	80001bca <steal_proc+0xd4>
          acquire(&proc[curr_list->head].list_lock);
    80001b1e:	19000913          	li	s2,400
    80001b22:	032787b3          	mul	a5,a5,s2
    80001b26:	01878513          	addi	a0,a5,24
    80001b2a:	00010a97          	auipc	s5,0x10
    80001b2e:	c96a8a93          	addi	s5,s5,-874 # 800117c0 <proc>
    80001b32:	9556                	add	a0,a0,s5
    80001b34:	fffff097          	auipc	ra,0xfffff
    80001b38:	0b0080e7          	jalr	176(ra) # 80000be4 <acquire>
          p = &proc[curr_list->head];
    80001b3c:	0000fb17          	auipc	s6,0xf
    80001b40:	764b0b13          	addi	s6,s6,1892 # 800112a0 <runnable_cpu_lists>
    80001b44:	00249793          	slli	a5,s1,0x2
    80001b48:	97a6                	add	a5,a5,s1
    80001b4a:	078e                	slli	a5,a5,0x3
    80001b4c:	97da                	add	a5,a5,s6
    80001b4e:	0007ab83          	lw	s7,0(a5)
    80001b52:	032b8bb3          	mul	s7,s7,s2
    80001b56:	015b8933          	add	s2,s7,s5
          curr_list->head = p->next_proc_index;
    80001b5a:	18092703          	lw	a4,384(s2)
    80001b5e:	c398                	sw	a4,0(a5)
          acquire(&p->lock);
    80001b60:	854a                	mv	a0,s2
    80001b62:	fffff097          	auipc	ra,0xfffff
    80001b66:	082080e7          	jalr	130(ra) # 80000be4 <acquire>
          printf("cpu number %d stole proc index %d from cpu %d, index is %d\n", curr_cpu, p->proc_index, p->affiliated_cpu, index);
    80001b6a:	8726                	mv	a4,s1
    80001b6c:	18892683          	lw	a3,392(s2)
    80001b70:	18492603          	lw	a2,388(s2)
    80001b74:	85ce                	mv	a1,s3
    80001b76:	00006517          	auipc	a0,0x6
    80001b7a:	66250513          	addi	a0,a0,1634 # 800081d8 <digits+0x198>
    80001b7e:	fffff097          	auipc	ra,0xfffff
    80001b82:	a0a080e7          	jalr	-1526(ra) # 80000588 <printf>
          p->affiliated_cpu = curr_cpu;
    80001b86:	19392423          	sw	s3,392(s2)
          release(&p->lock);
    80001b8a:	854a                	mv	a0,s2
    80001b8c:	fffff097          	auipc	ra,0xfffff
    80001b90:	10c080e7          	jalr	268(ra) # 80000c98 <release>
          increment_counter(&runnable_cpu_lists[curr_cpu]);
    80001b94:	00299513          	slli	a0,s3,0x2
    80001b98:	954e                	add	a0,a0,s3
    80001b9a:	050e                	slli	a0,a0,0x3
    80001b9c:	955a                	add	a0,a0,s6
    80001b9e:	00000097          	auipc	ra,0x0
    80001ba2:	f1a080e7          	jalr	-230(ra) # 80001ab8 <increment_counter>
          release(&curr_list->head_lock);
    80001ba6:	8552                	mv	a0,s4
    80001ba8:	fffff097          	auipc	ra,0xfffff
    80001bac:	0f0080e7          	jalr	240(ra) # 80000c98 <release>
          release(&p->list_lock);
    80001bb0:	018b8513          	addi	a0,s7,24
    80001bb4:	9556                	add	a0,a0,s5
    80001bb6:	fffff097          	auipc	ra,0xfffff
    80001bba:	0e2080e7          	jalr	226(ra) # 80000c98 <release>
          return p;
    80001bbe:	a815                	j	80001bf2 <steal_proc+0xfc>
  for (index = 0; index< current_cpu_number; index++){
    80001bc0:	2485                	addiw	s1,s1,1
    80001bc2:	02890913          	addi	s2,s2,40
    80001bc6:	03548563          	beq	s1,s5,80001bf0 <steal_proc+0xfa>
    if (index != curr_cpu){
    80001bca:	fe998be3          	beq	s3,s1,80001bc0 <steal_proc+0xca>
        acquire(&runnable_cpu_lists[index].head_lock);
    80001bce:	00890a13          	addi	s4,s2,8
    80001bd2:	8552                	mv	a0,s4
    80001bd4:	fffff097          	auipc	ra,0xfffff
    80001bd8:	010080e7          	jalr	16(ra) # 80000be4 <acquire>
        if (curr_list->head != -1){
    80001bdc:	00092783          	lw	a5,0(s2)
    80001be0:	f3679fe3          	bne	a5,s6,80001b1e <steal_proc+0x28>
          release(&runnable_cpu_lists[index].head_lock);
    80001be4:	8552                	mv	a0,s4
    80001be6:	fffff097          	auipc	ra,0xfffff
    80001bea:	0b2080e7          	jalr	178(ra) # 80000c98 <release>
    80001bee:	bfc9                	j	80001bc0 <steal_proc+0xca>
  return 0;
    80001bf0:	4901                	li	s2,0
}
    80001bf2:	854a                	mv	a0,s2
    80001bf4:	60a6                	ld	ra,72(sp)
    80001bf6:	6406                	ld	s0,64(sp)
    80001bf8:	74e2                	ld	s1,56(sp)
    80001bfa:	7942                	ld	s2,48(sp)
    80001bfc:	79a2                	ld	s3,40(sp)
    80001bfe:	7a02                	ld	s4,32(sp)
    80001c00:	6ae2                	ld	s5,24(sp)
    80001c02:	6b42                	ld	s6,16(sp)
    80001c04:	6ba2                	ld	s7,8(sp)
    80001c06:	6161                	addi	sp,sp,80
    80001c08:	8082                	ret

0000000080001c0a <add_link>:

void add_link(struct processList* list, int index, int is_yield){ // index = the process index in proc
    80001c0a:	715d                	addi	sp,sp,-80
    80001c0c:	e486                	sd	ra,72(sp)
    80001c0e:	e0a2                	sd	s0,64(sp)
    80001c10:	fc26                	sd	s1,56(sp)
    80001c12:	f84a                	sd	s2,48(sp)
    80001c14:	f44e                	sd	s3,40(sp)
    80001c16:	f052                	sd	s4,32(sp)
    80001c18:	ec56                	sd	s5,24(sp)
    80001c1a:	e85a                	sd	s6,16(sp)
    80001c1c:	e45e                	sd	s7,8(sp)
    80001c1e:	0880                	addi	s0,sp,80
    80001c20:	84aa                	mv	s1,a0
    80001c22:	892e                	mv	s2,a1
    80001c24:	8ab2                	mv	s5,a2
 
  acquire(&list->head_lock);
    80001c26:	00850b13          	addi	s6,a0,8
    80001c2a:	855a                	mv	a0,s6
    80001c2c:	fffff097          	auipc	ra,0xfffff
    80001c30:	fb8080e7          	jalr	-72(ra) # 80000be4 <acquire>
  acquire(&proc[index].list_lock);
    80001c34:	19000993          	li	s3,400
    80001c38:	033909b3          	mul	s3,s2,s3
    80001c3c:	00010797          	auipc	a5,0x10
    80001c40:	b9c78793          	addi	a5,a5,-1124 # 800117d8 <proc+0x18>
    80001c44:	99be                	add	s3,s3,a5
    80001c46:	854e                	mv	a0,s3
    80001c48:	fffff097          	auipc	ra,0xfffff
    80001c4c:	f9c080e7          	jalr	-100(ra) # 80000be4 <acquire>
  //printf("index to insert is %d\n",index);
  //printf("list head is %d\n", list->head);
  //printf("list last is %d\n", list->last);
  //procdump();
  
  if (list->head == -1){  //empty list
    80001c50:	0004ab83          	lw	s7,0(s1)
    80001c54:	57fd                	li	a5,-1
    80001c56:	0cfb8563          	beq	s7,a5,80001d20 <add_link+0x116>
    }
    //printf("finished add_link\n");
    return;
  }
  struct proc* head = &proc[list->head];
  acquire(&head->list_lock);
    80001c5a:	19000a13          	li	s4,400
    80001c5e:	034b8a33          	mul	s4,s7,s4
    80001c62:	00010797          	auipc	a5,0x10
    80001c66:	b7678793          	addi	a5,a5,-1162 # 800117d8 <proc+0x18>
    80001c6a:	9a3e                	add	s4,s4,a5
    80001c6c:	8552                	mv	a0,s4
    80001c6e:	fffff097          	auipc	ra,0xfffff
    80001c72:	f76080e7          	jalr	-138(ra) # 80000be4 <acquire>
  if (list->head == list->last){  //list of size 1
    80001c76:	4098                	lw	a4,0(s1)
    80001c78:	40dc                	lw	a5,4(s1)
    80001c7a:	0ef70e63          	beq	a4,a5,80001d76 <add_link+0x16c>
      release(&head->list_lock);
      release(&list->head_lock);
      release(&proc[index].list_lock);
      return;
  }
  release(&list->head_lock);
    80001c7e:	855a                	mv	a0,s6
    80001c80:	fffff097          	auipc	ra,0xfffff
    80001c84:	018080e7          	jalr	24(ra) # 80000c98 <release>
  release(&head->list_lock);
    80001c88:	8552                	mv	a0,s4
    80001c8a:	fffff097          	auipc	ra,0xfffff
    80001c8e:	00e080e7          	jalr	14(ra) # 80000c98 <release>
  acquire(&proc[list->last].list_lock);
    80001c92:	40c8                	lw	a0,4(s1)
    80001c94:	19000b93          	li	s7,400
    80001c98:	03750533          	mul	a0,a0,s7
    80001c9c:	0561                	addi	a0,a0,24
    80001c9e:	00010a17          	auipc	s4,0x10
    80001ca2:	b22a0a13          	addi	s4,s4,-1246 # 800117c0 <proc>
    80001ca6:	9552                	add	a0,a0,s4
    80001ca8:	fffff097          	auipc	ra,0xfffff
    80001cac:	f3c080e7          	jalr	-196(ra) # 80000be4 <acquire>
  struct proc* last = &proc[list->last];
    80001cb0:	0044ab03          	lw	s6,4(s1)
  last->next_proc_index = index;
    80001cb4:	037b07b3          	mul	a5,s6,s7
    80001cb8:	97d2                	add	a5,a5,s4
    80001cba:	1927a023          	sw	s2,384(a5)
  list->last = index;
    80001cbe:	0124a223          	sw	s2,4(s1)
  p->next_proc_index = -1;
    80001cc2:	03790933          	mul	s2,s2,s7
    80001cc6:	9952                	add	s2,s2,s4
    80001cc8:	57fd                	li	a5,-1
    80001cca:	18f92023          	sw	a5,384(s2)
  if (balance && list->counter != __INT64_MAX__ && !is_yield){
    80001cce:	00007797          	auipc	a5,0x7
    80001cd2:	bea7a783          	lw	a5,-1046(a5) # 800088b8 <balance>
    80001cd6:	cb81                	beqz	a5,80001ce6 <add_link+0xdc>
    80001cd8:	7098                	ld	a4,32(s1)
    80001cda:	57fd                	li	a5,-1
    80001cdc:	8385                	srli	a5,a5,0x1
    80001cde:	00f70463          	beq	a4,a5,80001ce6 <add_link+0xdc>
    80001ce2:	0e0a8f63          	beqz	s5,80001de0 <add_link+0x1d6>
    increment_counter(list);
  }
  release(&last->list_lock);
    80001ce6:	19000513          	li	a0,400
    80001cea:	02ab0b33          	mul	s6,s6,a0
    80001cee:	00010517          	auipc	a0,0x10
    80001cf2:	aea50513          	addi	a0,a0,-1302 # 800117d8 <proc+0x18>
    80001cf6:	955a                	add	a0,a0,s6
    80001cf8:	fffff097          	auipc	ra,0xfffff
    80001cfc:	fa0080e7          	jalr	-96(ra) # 80000c98 <release>
  release(&proc[index].list_lock);
    80001d00:	854e                	mv	a0,s3
    80001d02:	fffff097          	auipc	ra,0xfffff
    80001d06:	f96080e7          	jalr	-106(ra) # 80000c98 <release>
  
  return;


}
    80001d0a:	60a6                	ld	ra,72(sp)
    80001d0c:	6406                	ld	s0,64(sp)
    80001d0e:	74e2                	ld	s1,56(sp)
    80001d10:	7942                	ld	s2,48(sp)
    80001d12:	79a2                	ld	s3,40(sp)
    80001d14:	7a02                	ld	s4,32(sp)
    80001d16:	6ae2                	ld	s5,24(sp)
    80001d18:	6b42                	ld	s6,16(sp)
    80001d1a:	6ba2                	ld	s7,8(sp)
    80001d1c:	6161                	addi	sp,sp,80
    80001d1e:	8082                	ret
    list->head = index;
    80001d20:	0124a023          	sw	s2,0(s1)
    list->last = index;
    80001d24:	0124a223          	sw	s2,4(s1)
    p->next_proc_index = -1;
    80001d28:	19000593          	li	a1,400
    80001d2c:	02b905b3          	mul	a1,s2,a1
    80001d30:	00010917          	auipc	s2,0x10
    80001d34:	a9090913          	addi	s2,s2,-1392 # 800117c0 <proc>
    80001d38:	992e                	add	s2,s2,a1
    80001d3a:	18f92023          	sw	a5,384(s2)
    release(&list->head_lock);
    80001d3e:	855a                	mv	a0,s6
    80001d40:	fffff097          	auipc	ra,0xfffff
    80001d44:	f58080e7          	jalr	-168(ra) # 80000c98 <release>
    release(&proc[index].list_lock);
    80001d48:	854e                	mv	a0,s3
    80001d4a:	fffff097          	auipc	ra,0xfffff
    80001d4e:	f4e080e7          	jalr	-178(ra) # 80000c98 <release>
    if (balance && !is_yield && list->counter != __INT64_MAX__ ){
    80001d52:	00007797          	auipc	a5,0x7
    80001d56:	b667a783          	lw	a5,-1178(a5) # 800088b8 <balance>
    80001d5a:	dbc5                	beqz	a5,80001d0a <add_link+0x100>
    80001d5c:	fa0a97e3          	bnez	s5,80001d0a <add_link+0x100>
    80001d60:	7098                	ld	a4,32(s1)
    80001d62:	57fd                	li	a5,-1
    80001d64:	8385                	srli	a5,a5,0x1
    80001d66:	faf702e3          	beq	a4,a5,80001d0a <add_link+0x100>
      increment_counter(list);
    80001d6a:	8526                	mv	a0,s1
    80001d6c:	00000097          	auipc	ra,0x0
    80001d70:	d4c080e7          	jalr	-692(ra) # 80001ab8 <increment_counter>
    80001d74:	bf59                	j	80001d0a <add_link+0x100>
      head->next_proc_index = index;
    80001d76:	00010717          	auipc	a4,0x10
    80001d7a:	a4a70713          	addi	a4,a4,-1462 # 800117c0 <proc>
    80001d7e:	19000593          	li	a1,400
    80001d82:	02bb87b3          	mul	a5,s7,a1
    80001d86:	97ba                	add	a5,a5,a4
    80001d88:	1927a023          	sw	s2,384(a5)
      list->last = index;
    80001d8c:	0124a223          	sw	s2,4(s1)
      p->next_proc_index = -1;
    80001d90:	02b90933          	mul	s2,s2,a1
    80001d94:	974a                	add	a4,a4,s2
    80001d96:	57fd                	li	a5,-1
    80001d98:	18f72023          	sw	a5,384(a4)
      if (balance && list->counter != __INT64_MAX__ && !is_yield){
    80001d9c:	00007797          	auipc	a5,0x7
    80001da0:	b1c7a783          	lw	a5,-1252(a5) # 800088b8 <balance>
    80001da4:	cb81                	beqz	a5,80001db4 <add_link+0x1aa>
    80001da6:	7098                	ld	a4,32(s1)
    80001da8:	57fd                	li	a5,-1
    80001daa:	8385                	srli	a5,a5,0x1
    80001dac:	00f70463          	beq	a4,a5,80001db4 <add_link+0x1aa>
    80001db0:	020a8263          	beqz	s5,80001dd4 <add_link+0x1ca>
      release(&head->list_lock);
    80001db4:	8552                	mv	a0,s4
    80001db6:	fffff097          	auipc	ra,0xfffff
    80001dba:	ee2080e7          	jalr	-286(ra) # 80000c98 <release>
      release(&list->head_lock);
    80001dbe:	855a                	mv	a0,s6
    80001dc0:	fffff097          	auipc	ra,0xfffff
    80001dc4:	ed8080e7          	jalr	-296(ra) # 80000c98 <release>
      release(&proc[index].list_lock);
    80001dc8:	854e                	mv	a0,s3
    80001dca:	fffff097          	auipc	ra,0xfffff
    80001dce:	ece080e7          	jalr	-306(ra) # 80000c98 <release>
      return;
    80001dd2:	bf25                	j	80001d0a <add_link+0x100>
        increment_counter(list);
    80001dd4:	8526                	mv	a0,s1
    80001dd6:	00000097          	auipc	ra,0x0
    80001dda:	ce2080e7          	jalr	-798(ra) # 80001ab8 <increment_counter>
    80001dde:	bfd9                	j	80001db4 <add_link+0x1aa>
    increment_counter(list);
    80001de0:	8526                	mv	a0,s1
    80001de2:	00000097          	auipc	ra,0x0
    80001de6:	cd6080e7          	jalr	-810(ra) # 80001ab8 <increment_counter>
    80001dea:	bdf5                	j	80001ce6 <add_link+0xdc>

0000000080001dec <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001dec:	7139                	addi	sp,sp,-64
    80001dee:	fc06                	sd	ra,56(sp)
    80001df0:	f822                	sd	s0,48(sp)
    80001df2:	f426                	sd	s1,40(sp)
    80001df4:	f04a                	sd	s2,32(sp)
    80001df6:	ec4e                	sd	s3,24(sp)
    80001df8:	e852                	sd	s4,16(sp)
    80001dfa:	e456                	sd	s5,8(sp)
    80001dfc:	e05a                	sd	s6,0(sp)
    80001dfe:	0080                	addi	s0,sp,64
    80001e00:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e02:	00010497          	auipc	s1,0x10
    80001e06:	9be48493          	addi	s1,s1,-1602 # 800117c0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001e0a:	8b26                	mv	s6,s1
    80001e0c:	00006a97          	auipc	s5,0x6
    80001e10:	1f4a8a93          	addi	s5,s5,500 # 80008000 <etext>
    80001e14:	04000937          	lui	s2,0x4000
    80001e18:	197d                	addi	s2,s2,-1
    80001e1a:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e1c:	00016a17          	auipc	s4,0x16
    80001e20:	da4a0a13          	addi	s4,s4,-604 # 80017bc0 <tickslock>
    char *pa = kalloc();
    80001e24:	fffff097          	auipc	ra,0xfffff
    80001e28:	cd0080e7          	jalr	-816(ra) # 80000af4 <kalloc>
    80001e2c:	862a                	mv	a2,a0
    if(pa == 0)
    80001e2e:	c131                	beqz	a0,80001e72 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001e30:	416485b3          	sub	a1,s1,s6
    80001e34:	8591                	srai	a1,a1,0x4
    80001e36:	000ab783          	ld	a5,0(s5)
    80001e3a:	02f585b3          	mul	a1,a1,a5
    80001e3e:	2585                	addiw	a1,a1,1
    80001e40:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001e44:	4719                	li	a4,6
    80001e46:	6685                	lui	a3,0x1
    80001e48:	40b905b3          	sub	a1,s2,a1
    80001e4c:	854e                	mv	a0,s3
    80001e4e:	fffff097          	auipc	ra,0xfffff
    80001e52:	302080e7          	jalr	770(ra) # 80001150 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e56:	19048493          	addi	s1,s1,400
    80001e5a:	fd4495e3          	bne	s1,s4,80001e24 <proc_mapstacks+0x38>
  }
}
    80001e5e:	70e2                	ld	ra,56(sp)
    80001e60:	7442                	ld	s0,48(sp)
    80001e62:	74a2                	ld	s1,40(sp)
    80001e64:	7902                	ld	s2,32(sp)
    80001e66:	69e2                	ld	s3,24(sp)
    80001e68:	6a42                	ld	s4,16(sp)
    80001e6a:	6aa2                	ld	s5,8(sp)
    80001e6c:	6b02                	ld	s6,0(sp)
    80001e6e:	6121                	addi	sp,sp,64
    80001e70:	8082                	ret
      panic("kalloc");
    80001e72:	00006517          	auipc	a0,0x6
    80001e76:	3a650513          	addi	a0,a0,934 # 80008218 <digits+0x1d8>
    80001e7a:	ffffe097          	auipc	ra,0xffffe
    80001e7e:	6c4080e7          	jalr	1732(ra) # 8000053e <panic>

0000000080001e82 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    80001e82:	715d                	addi	sp,sp,-80
    80001e84:	e486                	sd	ra,72(sp)
    80001e86:	e0a2                	sd	s0,64(sp)
    80001e88:	fc26                	sd	s1,56(sp)
    80001e8a:	f84a                	sd	s2,48(sp)
    80001e8c:	f44e                	sd	s3,40(sp)
    80001e8e:	f052                	sd	s4,32(sp)
    80001e90:	ec56                	sd	s5,24(sp)
    80001e92:	e85a                	sd	s6,16(sp)
    80001e94:	e45e                	sd	s7,8(sp)
    80001e96:	e062                	sd	s8,0(sp)
    80001e98:	0880                	addi	s0,sp,80
  lists_init();
    80001e9a:	00000097          	auipc	ra,0x0
    80001e9e:	9a4080e7          	jalr	-1628(ra) # 8000183e <lists_init>
  struct proc *p;
  int index = 0;
  initlock(&pid_lock, "nextpid");
    80001ea2:	00006597          	auipc	a1,0x6
    80001ea6:	37e58593          	addi	a1,a1,894 # 80008220 <digits+0x1e0>
    80001eaa:	0000f517          	auipc	a0,0xf
    80001eae:	4e650513          	addi	a0,a0,1254 # 80011390 <pid_lock>
    80001eb2:	fffff097          	auipc	ra,0xfffff
    80001eb6:	ca2080e7          	jalr	-862(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001eba:	00006597          	auipc	a1,0x6
    80001ebe:	36e58593          	addi	a1,a1,878 # 80008228 <digits+0x1e8>
    80001ec2:	0000f517          	auipc	a0,0xf
    80001ec6:	4e650513          	addi	a0,a0,1254 # 800113a8 <wait_lock>
    80001eca:	fffff097          	auipc	ra,0xfffff
    80001ece:	c8a080e7          	jalr	-886(ra) # 80000b54 <initlock>
  int index = 0;
    80001ed2:	4901                	li	s2,0
  //printf("start procinit\n");
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ed4:	00010497          	auipc	s1,0x10
    80001ed8:	8ec48493          	addi	s1,s1,-1812 # 800117c0 <proc>
      initlock(&p->lock, "proc");
    80001edc:	00006c17          	auipc	s8,0x6
    80001ee0:	35cc0c13          	addi	s8,s8,860 # 80008238 <digits+0x1f8>
      p->kstack = KSTACK((int) (p - proc));
    80001ee4:	8ba6                	mv	s7,s1
    80001ee6:	00006b17          	auipc	s6,0x6
    80001eea:	11ab0b13          	addi	s6,s6,282 # 80008000 <etext>
    80001eee:	040009b7          	lui	s3,0x4000
    80001ef2:	19fd                	addi	s3,s3,-1
    80001ef4:	09b2                	slli	s3,s3,0xc
      p->proc_index=index;
      p->next_proc_index = index + 1;
      //printf("proc is %d\n", index);
      add_link(&unused_list, index, 0);
    80001ef6:	0000fa97          	auipc	s5,0xf
    80001efa:	422a8a93          	addi	s5,s5,1058 # 80011318 <unused_list>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001efe:	00016a17          	auipc	s4,0x16
    80001f02:	cc2a0a13          	addi	s4,s4,-830 # 80017bc0 <tickslock>
      initlock(&p->lock, "proc");
    80001f06:	85e2                	mv	a1,s8
    80001f08:	8526                	mv	a0,s1
    80001f0a:	fffff097          	auipc	ra,0xfffff
    80001f0e:	c4a080e7          	jalr	-950(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001f12:	417487b3          	sub	a5,s1,s7
    80001f16:	8791                	srai	a5,a5,0x4
    80001f18:	000b3703          	ld	a4,0(s6)
    80001f1c:	02e787b3          	mul	a5,a5,a4
    80001f20:	2785                	addiw	a5,a5,1
    80001f22:	00d7979b          	slliw	a5,a5,0xd
    80001f26:	40f987b3          	sub	a5,s3,a5
    80001f2a:	ecbc                	sd	a5,88(s1)
      p->proc_index=index;
    80001f2c:	1924a223          	sw	s2,388(s1)
      p->next_proc_index = index + 1;
    80001f30:	85ca                	mv	a1,s2
    80001f32:	0019079b          	addiw	a5,s2,1
    80001f36:	0007891b          	sext.w	s2,a5
    80001f3a:	18f4a023          	sw	a5,384(s1)
      add_link(&unused_list, index, 0);
    80001f3e:	4601                	li	a2,0
    80001f40:	8556                	mv	a0,s5
    80001f42:	00000097          	auipc	ra,0x0
    80001f46:	cc8080e7          	jalr	-824(ra) # 80001c0a <add_link>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001f4a:	19048493          	addi	s1,s1,400
    80001f4e:	fb449ce3          	bne	s1,s4,80001f06 <procinit+0x84>
      index++;
  }

  p = &proc[NPROC-1];
  p->next_proc_index = -1;
    80001f52:	57fd                	li	a5,-1
    80001f54:	00016717          	auipc	a4,0x16
    80001f58:	c4f72e23          	sw	a5,-932(a4) # 80017bb0 <proc+0x63f0>
}
    80001f5c:	60a6                	ld	ra,72(sp)
    80001f5e:	6406                	ld	s0,64(sp)
    80001f60:	74e2                	ld	s1,56(sp)
    80001f62:	7942                	ld	s2,48(sp)
    80001f64:	79a2                	ld	s3,40(sp)
    80001f66:	7a02                	ld	s4,32(sp)
    80001f68:	6ae2                	ld	s5,24(sp)
    80001f6a:	6b42                	ld	s6,16(sp)
    80001f6c:	6ba2                	ld	s7,8(sp)
    80001f6e:	6c02                	ld	s8,0(sp)
    80001f70:	6161                	addi	sp,sp,80
    80001f72:	8082                	ret

0000000080001f74 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001f74:	1141                	addi	sp,sp,-16
    80001f76:	e422                	sd	s0,8(sp)
    80001f78:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f7a:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001f7c:	2501                	sext.w	a0,a0
    80001f7e:	6422                	ld	s0,8(sp)
    80001f80:	0141                	addi	sp,sp,16
    80001f82:	8082                	ret

0000000080001f84 <mycpu>:


// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001f84:	1141                	addi	sp,sp,-16
    80001f86:	e422                	sd	s0,8(sp)
    80001f88:	0800                	addi	s0,sp,16
    80001f8a:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001f8c:	2781                	sext.w	a5,a5
    80001f8e:	079e                	slli	a5,a5,0x7
  return c;
}
    80001f90:	0000f517          	auipc	a0,0xf
    80001f94:	43050513          	addi	a0,a0,1072 # 800113c0 <cpus>
    80001f98:	953e                	add	a0,a0,a5
    80001f9a:	6422                	ld	s0,8(sp)
    80001f9c:	0141                	addi	sp,sp,16
    80001f9e:	8082                	ret

0000000080001fa0 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001fa0:	1101                	addi	sp,sp,-32
    80001fa2:	ec06                	sd	ra,24(sp)
    80001fa4:	e822                	sd	s0,16(sp)
    80001fa6:	e426                	sd	s1,8(sp)
    80001fa8:	1000                	addi	s0,sp,32
  push_off();
    80001faa:	fffff097          	auipc	ra,0xfffff
    80001fae:	bee080e7          	jalr	-1042(ra) # 80000b98 <push_off>
    80001fb2:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001fb4:	2781                	sext.w	a5,a5
    80001fb6:	079e                	slli	a5,a5,0x7
    80001fb8:	0000f717          	auipc	a4,0xf
    80001fbc:	2e870713          	addi	a4,a4,744 # 800112a0 <runnable_cpu_lists>
    80001fc0:	97ba                	add	a5,a5,a4
    80001fc2:	1207b483          	ld	s1,288(a5)
  pop_off();
    80001fc6:	fffff097          	auipc	ra,0xfffff
    80001fca:	c72080e7          	jalr	-910(ra) # 80000c38 <pop_off>
  return p;
}
    80001fce:	8526                	mv	a0,s1
    80001fd0:	60e2                	ld	ra,24(sp)
    80001fd2:	6442                	ld	s0,16(sp)
    80001fd4:	64a2                	ld	s1,8(sp)
    80001fd6:	6105                	addi	sp,sp,32
    80001fd8:	8082                	ret

0000000080001fda <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001fda:	1141                	addi	sp,sp,-16
    80001fdc:	e406                	sd	ra,8(sp)
    80001fde:	e022                	sd	s0,0(sp)
    80001fe0:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001fe2:	00000097          	auipc	ra,0x0
    80001fe6:	fbe080e7          	jalr	-66(ra) # 80001fa0 <myproc>
    80001fea:	fffff097          	auipc	ra,0xfffff
    80001fee:	cae080e7          	jalr	-850(ra) # 80000c98 <release>

  if (first) {
    80001ff2:	00007797          	auipc	a5,0x7
    80001ff6:	8be7a783          	lw	a5,-1858(a5) # 800088b0 <first.1752>
    80001ffa:	eb89                	bnez	a5,8000200c <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001ffc:	00001097          	auipc	ra,0x1
    80002000:	282080e7          	jalr	642(ra) # 8000327e <usertrapret>
}
    80002004:	60a2                	ld	ra,8(sp)
    80002006:	6402                	ld	s0,0(sp)
    80002008:	0141                	addi	sp,sp,16
    8000200a:	8082                	ret
    first = 0;
    8000200c:	00007797          	auipc	a5,0x7
    80002010:	8a07a223          	sw	zero,-1884(a5) # 800088b0 <first.1752>
    fsinit(ROOTDEV);
    80002014:	4505                	li	a0,1
    80002016:	00002097          	auipc	ra,0x2
    8000201a:	026080e7          	jalr	38(ra) # 8000403c <fsinit>
    8000201e:	bff9                	j	80001ffc <forkret+0x22>

0000000080002020 <allocpid>:
allocpid() {
    80002020:	1101                	addi	sp,sp,-32
    80002022:	ec06                	sd	ra,24(sp)
    80002024:	e822                	sd	s0,16(sp)
    80002026:	e426                	sd	s1,8(sp)
    80002028:	e04a                	sd	s2,0(sp)
    8000202a:	1000                	addi	s0,sp,32
    pid = nextpid;
    8000202c:	00007917          	auipc	s2,0x7
    80002030:	88890913          	addi	s2,s2,-1912 # 800088b4 <nextpid>
    80002034:	00092483          	lw	s1,0(s2)
  } while (cas(&nextpid, pid, pid+1));
    80002038:	0014861b          	addiw	a2,s1,1
    8000203c:	85a6                	mv	a1,s1
    8000203e:	854a                	mv	a0,s2
    80002040:	00005097          	auipc	ra,0x5
    80002044:	e06080e7          	jalr	-506(ra) # 80006e46 <cas>
    80002048:	f575                	bnez	a0,80002034 <allocpid+0x14>
}
    8000204a:	8526                	mv	a0,s1
    8000204c:	60e2                	ld	ra,24(sp)
    8000204e:	6442                	ld	s0,16(sp)
    80002050:	64a2                	ld	s1,8(sp)
    80002052:	6902                	ld	s2,0(sp)
    80002054:	6105                	addi	sp,sp,32
    80002056:	8082                	ret

0000000080002058 <proc_pagetable>:
{
    80002058:	1101                	addi	sp,sp,-32
    8000205a:	ec06                	sd	ra,24(sp)
    8000205c:	e822                	sd	s0,16(sp)
    8000205e:	e426                	sd	s1,8(sp)
    80002060:	e04a                	sd	s2,0(sp)
    80002062:	1000                	addi	s0,sp,32
    80002064:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80002066:	fffff097          	auipc	ra,0xfffff
    8000206a:	2d4080e7          	jalr	724(ra) # 8000133a <uvmcreate>
    8000206e:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80002070:	c121                	beqz	a0,800020b0 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80002072:	4729                	li	a4,10
    80002074:	00005697          	auipc	a3,0x5
    80002078:	f8c68693          	addi	a3,a3,-116 # 80007000 <_trampoline>
    8000207c:	6605                	lui	a2,0x1
    8000207e:	040005b7          	lui	a1,0x4000
    80002082:	15fd                	addi	a1,a1,-1
    80002084:	05b2                	slli	a1,a1,0xc
    80002086:	fffff097          	auipc	ra,0xfffff
    8000208a:	02a080e7          	jalr	42(ra) # 800010b0 <mappages>
    8000208e:	02054863          	bltz	a0,800020be <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80002092:	4719                	li	a4,6
    80002094:	07093683          	ld	a3,112(s2)
    80002098:	6605                	lui	a2,0x1
    8000209a:	020005b7          	lui	a1,0x2000
    8000209e:	15fd                	addi	a1,a1,-1
    800020a0:	05b6                	slli	a1,a1,0xd
    800020a2:	8526                	mv	a0,s1
    800020a4:	fffff097          	auipc	ra,0xfffff
    800020a8:	00c080e7          	jalr	12(ra) # 800010b0 <mappages>
    800020ac:	02054163          	bltz	a0,800020ce <proc_pagetable+0x76>
}
    800020b0:	8526                	mv	a0,s1
    800020b2:	60e2                	ld	ra,24(sp)
    800020b4:	6442                	ld	s0,16(sp)
    800020b6:	64a2                	ld	s1,8(sp)
    800020b8:	6902                	ld	s2,0(sp)
    800020ba:	6105                	addi	sp,sp,32
    800020bc:	8082                	ret
    uvmfree(pagetable, 0);
    800020be:	4581                	li	a1,0
    800020c0:	8526                	mv	a0,s1
    800020c2:	fffff097          	auipc	ra,0xfffff
    800020c6:	474080e7          	jalr	1140(ra) # 80001536 <uvmfree>
    return 0;
    800020ca:	4481                	li	s1,0
    800020cc:	b7d5                	j	800020b0 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    800020ce:	4681                	li	a3,0
    800020d0:	4605                	li	a2,1
    800020d2:	040005b7          	lui	a1,0x4000
    800020d6:	15fd                	addi	a1,a1,-1
    800020d8:	05b2                	slli	a1,a1,0xc
    800020da:	8526                	mv	a0,s1
    800020dc:	fffff097          	auipc	ra,0xfffff
    800020e0:	19a080e7          	jalr	410(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    800020e4:	4581                	li	a1,0
    800020e6:	8526                	mv	a0,s1
    800020e8:	fffff097          	auipc	ra,0xfffff
    800020ec:	44e080e7          	jalr	1102(ra) # 80001536 <uvmfree>
    return 0;
    800020f0:	4481                	li	s1,0
    800020f2:	bf7d                	j	800020b0 <proc_pagetable+0x58>

00000000800020f4 <proc_freepagetable>:
{
    800020f4:	1101                	addi	sp,sp,-32
    800020f6:	ec06                	sd	ra,24(sp)
    800020f8:	e822                	sd	s0,16(sp)
    800020fa:	e426                	sd	s1,8(sp)
    800020fc:	e04a                	sd	s2,0(sp)
    800020fe:	1000                	addi	s0,sp,32
    80002100:	84aa                	mv	s1,a0
    80002102:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80002104:	4681                	li	a3,0
    80002106:	4605                	li	a2,1
    80002108:	040005b7          	lui	a1,0x4000
    8000210c:	15fd                	addi	a1,a1,-1
    8000210e:	05b2                	slli	a1,a1,0xc
    80002110:	fffff097          	auipc	ra,0xfffff
    80002114:	166080e7          	jalr	358(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80002118:	4681                	li	a3,0
    8000211a:	4605                	li	a2,1
    8000211c:	020005b7          	lui	a1,0x2000
    80002120:	15fd                	addi	a1,a1,-1
    80002122:	05b6                	slli	a1,a1,0xd
    80002124:	8526                	mv	a0,s1
    80002126:	fffff097          	auipc	ra,0xfffff
    8000212a:	150080e7          	jalr	336(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    8000212e:	85ca                	mv	a1,s2
    80002130:	8526                	mv	a0,s1
    80002132:	fffff097          	auipc	ra,0xfffff
    80002136:	404080e7          	jalr	1028(ra) # 80001536 <uvmfree>
}
    8000213a:	60e2                	ld	ra,24(sp)
    8000213c:	6442                	ld	s0,16(sp)
    8000213e:	64a2                	ld	s1,8(sp)
    80002140:	6902                	ld	s2,0(sp)
    80002142:	6105                	addi	sp,sp,32
    80002144:	8082                	ret

0000000080002146 <freeproc>:
{
    80002146:	1101                	addi	sp,sp,-32
    80002148:	ec06                	sd	ra,24(sp)
    8000214a:	e822                	sd	s0,16(sp)
    8000214c:	e426                	sd	s1,8(sp)
    8000214e:	1000                	addi	s0,sp,32
    80002150:	84aa                	mv	s1,a0
  if(p->trapframe)
    80002152:	7928                	ld	a0,112(a0)
    80002154:	c509                	beqz	a0,8000215e <freeproc+0x18>
    kfree((void*)p->trapframe);
    80002156:	fffff097          	auipc	ra,0xfffff
    8000215a:	8a2080e7          	jalr	-1886(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    8000215e:	0604b823          	sd	zero,112(s1)
  if(p->pagetable)
    80002162:	74a8                	ld	a0,104(s1)
    80002164:	c511                	beqz	a0,80002170 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80002166:	70ac                	ld	a1,96(s1)
    80002168:	00000097          	auipc	ra,0x0
    8000216c:	f8c080e7          	jalr	-116(ra) # 800020f4 <proc_freepagetable>
  remove_link(&zombie_list, p->proc_index);
    80002170:	1844a583          	lw	a1,388(s1)
    80002174:	0000f517          	auipc	a0,0xf
    80002178:	1f450513          	addi	a0,a0,500 # 80011368 <zombie_list>
    8000217c:	fffff097          	auipc	ra,0xfffff
    80002180:	740080e7          	jalr	1856(ra) # 800018bc <remove_link>
  add_link(&unused_list, p->proc_index, 0);
    80002184:	4601                	li	a2,0
    80002186:	1844a583          	lw	a1,388(s1)
    8000218a:	0000f517          	auipc	a0,0xf
    8000218e:	18e50513          	addi	a0,a0,398 # 80011318 <unused_list>
    80002192:	00000097          	auipc	ra,0x0
    80002196:	a78080e7          	jalr	-1416(ra) # 80001c0a <add_link>
  p->pagetable = 0;
    8000219a:	0604b423          	sd	zero,104(s1)
  p->sz = 0;
    8000219e:	0604b023          	sd	zero,96(s1)
  p->pid = 0;
    800021a2:	0404a423          	sw	zero,72(s1)
  p->parent = 0;
    800021a6:	0404b823          	sd	zero,80(s1)
  p->name[0] = 0;
    800021aa:	16048823          	sb	zero,368(s1)
  p->chan = 0;
    800021ae:	0204bc23          	sd	zero,56(s1)
  p->killed = 0;
    800021b2:	0404a023          	sw	zero,64(s1)
  p->xstate = 0;
    800021b6:	0404a223          	sw	zero,68(s1)
  p->state = UNUSED;
    800021ba:	0204a823          	sw	zero,48(s1)
}
    800021be:	60e2                	ld	ra,24(sp)
    800021c0:	6442                	ld	s0,16(sp)
    800021c2:	64a2                	ld	s1,8(sp)
    800021c4:	6105                	addi	sp,sp,32
    800021c6:	8082                	ret

00000000800021c8 <allocproc>:
{
    800021c8:	7139                	addi	sp,sp,-64
    800021ca:	fc06                	sd	ra,56(sp)
    800021cc:	f822                	sd	s0,48(sp)
    800021ce:	f426                	sd	s1,40(sp)
    800021d0:	f04a                	sd	s2,32(sp)
    800021d2:	ec4e                	sd	s3,24(sp)
    800021d4:	e852                	sd	s4,16(sp)
    800021d6:	e456                	sd	s5,8(sp)
    800021d8:	0080                	addi	s0,sp,64
  acquire(&unused_list.head_lock);
    800021da:	0000f517          	auipc	a0,0xf
    800021de:	14650513          	addi	a0,a0,326 # 80011320 <unused_list+0x8>
    800021e2:	fffff097          	auipc	ra,0xfffff
    800021e6:	a02080e7          	jalr	-1534(ra) # 80000be4 <acquire>
  if (unused_list.head == -1){
    800021ea:	0000f497          	auipc	s1,0xf
    800021ee:	12e4a483          	lw	s1,302(s1) # 80011318 <unused_list>
    800021f2:	57fd                	li	a5,-1
    800021f4:	0cf48b63          	beq	s1,a5,800022ca <allocproc+0x102>
  struct proc *p = &proc[unused_list.head];
    800021f8:	19000793          	li	a5,400
    800021fc:	02f484b3          	mul	s1,s1,a5
    80002200:	0000f797          	auipc	a5,0xf
    80002204:	5c078793          	addi	a5,a5,1472 # 800117c0 <proc>
    80002208:	94be                	add	s1,s1,a5
  release(&unused_list.head_lock);
    8000220a:	0000f517          	auipc	a0,0xf
    8000220e:	11650513          	addi	a0,a0,278 # 80011320 <unused_list+0x8>
    80002212:	fffff097          	auipc	ra,0xfffff
    80002216:	a86080e7          	jalr	-1402(ra) # 80000c98 <release>
  acquire(&p->lock);
    8000221a:	8526                	mv	a0,s1
    8000221c:	fffff097          	auipc	ra,0xfffff
    80002220:	9c8080e7          	jalr	-1592(ra) # 80000be4 <acquire>
  while(p->state != UNUSED){
    80002224:	589c                	lw	a5,48(s1)
    80002226:	cf9d                	beqz	a5,80002264 <allocproc+0x9c>
    if (unused_list.head == -1)
    80002228:	0000f997          	auipc	s3,0xf
    8000222c:	07898993          	addi	s3,s3,120 # 800112a0 <runnable_cpu_lists>
    80002230:	597d                	li	s2,-1
    p = &proc[unused_list.head];
    80002232:	19000a93          	li	s5,400
    80002236:	0000fa17          	auipc	s4,0xf
    8000223a:	58aa0a13          	addi	s4,s4,1418 # 800117c0 <proc>
    release(&p->lock);
    8000223e:	8526                	mv	a0,s1
    80002240:	fffff097          	auipc	ra,0xfffff
    80002244:	a58080e7          	jalr	-1448(ra) # 80000c98 <release>
    if (unused_list.head == -1)
    80002248:	0789a483          	lw	s1,120(s3)
    8000224c:	0d248163          	beq	s1,s2,8000230e <allocproc+0x146>
    p = &proc[unused_list.head];
    80002250:	035484b3          	mul	s1,s1,s5
    80002254:	94d2                	add	s1,s1,s4
    acquire(&p->lock);
    80002256:	8526                	mv	a0,s1
    80002258:	fffff097          	auipc	ra,0xfffff
    8000225c:	98c080e7          	jalr	-1652(ra) # 80000be4 <acquire>
  while(p->state != UNUSED){
    80002260:	589c                	lw	a5,48(s1)
    80002262:	fff1                	bnez	a5,8000223e <allocproc+0x76>
  remove_link(&unused_list, p->proc_index);
    80002264:	1844a583          	lw	a1,388(s1)
    80002268:	0000f517          	auipc	a0,0xf
    8000226c:	0b050513          	addi	a0,a0,176 # 80011318 <unused_list>
    80002270:	fffff097          	auipc	ra,0xfffff
    80002274:	64c080e7          	jalr	1612(ra) # 800018bc <remove_link>
  p->pid = allocpid();
    80002278:	00000097          	auipc	ra,0x0
    8000227c:	da8080e7          	jalr	-600(ra) # 80002020 <allocpid>
    80002280:	c4a8                	sw	a0,72(s1)
  p->state = USED;
    80002282:	4785                	li	a5,1
    80002284:	d89c                	sw	a5,48(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80002286:	fffff097          	auipc	ra,0xfffff
    8000228a:	86e080e7          	jalr	-1938(ra) # 80000af4 <kalloc>
    8000228e:	892a                	mv	s2,a0
    80002290:	f8a8                	sd	a0,112(s1)
    80002292:	c531                	beqz	a0,800022de <allocproc+0x116>
  p->pagetable = proc_pagetable(p);
    80002294:	8526                	mv	a0,s1
    80002296:	00000097          	auipc	ra,0x0
    8000229a:	dc2080e7          	jalr	-574(ra) # 80002058 <proc_pagetable>
    8000229e:	892a                	mv	s2,a0
    800022a0:	f4a8                	sd	a0,104(s1)
  if(p->pagetable == 0){
    800022a2:	c931                	beqz	a0,800022f6 <allocproc+0x12e>
  memset(&p->context, 0, sizeof(p->context));
    800022a4:	07000613          	li	a2,112
    800022a8:	4581                	li	a1,0
    800022aa:	07848513          	addi	a0,s1,120
    800022ae:	fffff097          	auipc	ra,0xfffff
    800022b2:	a32080e7          	jalr	-1486(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    800022b6:	00000797          	auipc	a5,0x0
    800022ba:	d2478793          	addi	a5,a5,-732 # 80001fda <forkret>
    800022be:	fcbc                	sd	a5,120(s1)
  p->context.sp = p->kstack + PGSIZE;
    800022c0:	6cbc                	ld	a5,88(s1)
    800022c2:	6705                	lui	a4,0x1
    800022c4:	97ba                	add	a5,a5,a4
    800022c6:	e0dc                	sd	a5,128(s1)
  return p;
    800022c8:	a0a1                	j	80002310 <allocproc+0x148>
    release(&unused_list.head_lock);
    800022ca:	0000f517          	auipc	a0,0xf
    800022ce:	05650513          	addi	a0,a0,86 # 80011320 <unused_list+0x8>
    800022d2:	fffff097          	auipc	ra,0xfffff
    800022d6:	9c6080e7          	jalr	-1594(ra) # 80000c98 <release>
    return 0;
    800022da:	4481                	li	s1,0
    800022dc:	a815                	j	80002310 <allocproc+0x148>
    freeproc(p);
    800022de:	8526                	mv	a0,s1
    800022e0:	00000097          	auipc	ra,0x0
    800022e4:	e66080e7          	jalr	-410(ra) # 80002146 <freeproc>
    release(&p->lock);
    800022e8:	8526                	mv	a0,s1
    800022ea:	fffff097          	auipc	ra,0xfffff
    800022ee:	9ae080e7          	jalr	-1618(ra) # 80000c98 <release>
    return 0;
    800022f2:	84ca                	mv	s1,s2
    800022f4:	a831                	j	80002310 <allocproc+0x148>
    freeproc(p);
    800022f6:	8526                	mv	a0,s1
    800022f8:	00000097          	auipc	ra,0x0
    800022fc:	e4e080e7          	jalr	-434(ra) # 80002146 <freeproc>
    release(&p->lock);
    80002300:	8526                	mv	a0,s1
    80002302:	fffff097          	auipc	ra,0xfffff
    80002306:	996080e7          	jalr	-1642(ra) # 80000c98 <release>
    return 0;
    8000230a:	84ca                	mv	s1,s2
    8000230c:	a011                	j	80002310 <allocproc+0x148>
      return 0;
    8000230e:	4481                	li	s1,0
}
    80002310:	8526                	mv	a0,s1
    80002312:	70e2                	ld	ra,56(sp)
    80002314:	7442                	ld	s0,48(sp)
    80002316:	74a2                	ld	s1,40(sp)
    80002318:	7902                	ld	s2,32(sp)
    8000231a:	69e2                	ld	s3,24(sp)
    8000231c:	6a42                	ld	s4,16(sp)
    8000231e:	6aa2                	ld	s5,8(sp)
    80002320:	6121                	addi	sp,sp,64
    80002322:	8082                	ret

0000000080002324 <userinit>:
{
    80002324:	1101                	addi	sp,sp,-32
    80002326:	ec06                	sd	ra,24(sp)
    80002328:	e822                	sd	s0,16(sp)
    8000232a:	e426                	sd	s1,8(sp)
    8000232c:	1000                	addi	s0,sp,32
  p = allocproc();
    8000232e:	00000097          	auipc	ra,0x0
    80002332:	e9a080e7          	jalr	-358(ra) # 800021c8 <allocproc>
    80002336:	84aa                	mv	s1,a0
  initproc = p;
    80002338:	00007797          	auipc	a5,0x7
    8000233c:	cea7b823          	sd	a0,-784(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80002340:	03400613          	li	a2,52
    80002344:	00006597          	auipc	a1,0x6
    80002348:	57c58593          	addi	a1,a1,1404 # 800088c0 <initcode>
    8000234c:	7528                	ld	a0,104(a0)
    8000234e:	fffff097          	auipc	ra,0xfffff
    80002352:	01a080e7          	jalr	26(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    80002356:	6785                	lui	a5,0x1
    80002358:	f0bc                	sd	a5,96(s1)
  p->trapframe->epc = 0;      // user program counter
    8000235a:	78b8                	ld	a4,112(s1)
    8000235c:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80002360:	78b8                	ld	a4,112(s1)
    80002362:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80002364:	4641                	li	a2,16
    80002366:	00006597          	auipc	a1,0x6
    8000236a:	eda58593          	addi	a1,a1,-294 # 80008240 <digits+0x200>
    8000236e:	17048513          	addi	a0,s1,368
    80002372:	fffff097          	auipc	ra,0xfffff
    80002376:	ac0080e7          	jalr	-1344(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    8000237a:	00006517          	auipc	a0,0x6
    8000237e:	ed650513          	addi	a0,a0,-298 # 80008250 <digits+0x210>
    80002382:	00002097          	auipc	ra,0x2
    80002386:	6e8080e7          	jalr	1768(ra) # 80004a6a <namei>
    8000238a:	16a4b423          	sd	a0,360(s1)
  p->affiliated_cpu = 0;
    8000238e:	1804a423          	sw	zero,392(s1)
  p->state = RUNNABLE;
    80002392:	478d                	li	a5,3
    80002394:	d89c                	sw	a5,48(s1)
  add_link(&runnable_cpu_lists[0], p->proc_index, 0); // init_proc index is 0
    80002396:	4601                	li	a2,0
    80002398:	1844a583          	lw	a1,388(s1)
    8000239c:	0000f517          	auipc	a0,0xf
    800023a0:	f0450513          	addi	a0,a0,-252 # 800112a0 <runnable_cpu_lists>
    800023a4:	00000097          	auipc	ra,0x0
    800023a8:	866080e7          	jalr	-1946(ra) # 80001c0a <add_link>
  release(&p->lock);
    800023ac:	8526                	mv	a0,s1
    800023ae:	fffff097          	auipc	ra,0xfffff
    800023b2:	8ea080e7          	jalr	-1814(ra) # 80000c98 <release>
}
    800023b6:	60e2                	ld	ra,24(sp)
    800023b8:	6442                	ld	s0,16(sp)
    800023ba:	64a2                	ld	s1,8(sp)
    800023bc:	6105                	addi	sp,sp,32
    800023be:	8082                	ret

00000000800023c0 <growproc>:
{
    800023c0:	1101                	addi	sp,sp,-32
    800023c2:	ec06                	sd	ra,24(sp)
    800023c4:	e822                	sd	s0,16(sp)
    800023c6:	e426                	sd	s1,8(sp)
    800023c8:	e04a                	sd	s2,0(sp)
    800023ca:	1000                	addi	s0,sp,32
    800023cc:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800023ce:	00000097          	auipc	ra,0x0
    800023d2:	bd2080e7          	jalr	-1070(ra) # 80001fa0 <myproc>
    800023d6:	892a                	mv	s2,a0
  sz = p->sz;
    800023d8:	712c                	ld	a1,96(a0)
    800023da:	0005861b          	sext.w	a2,a1
  if(n > 0){
    800023de:	00904f63          	bgtz	s1,800023fc <growproc+0x3c>
  } else if(n < 0){
    800023e2:	0204cc63          	bltz	s1,8000241a <growproc+0x5a>
  p->sz = sz;
    800023e6:	1602                	slli	a2,a2,0x20
    800023e8:	9201                	srli	a2,a2,0x20
    800023ea:	06c93023          	sd	a2,96(s2)
  return 0;
    800023ee:	4501                	li	a0,0
}
    800023f0:	60e2                	ld	ra,24(sp)
    800023f2:	6442                	ld	s0,16(sp)
    800023f4:	64a2                	ld	s1,8(sp)
    800023f6:	6902                	ld	s2,0(sp)
    800023f8:	6105                	addi	sp,sp,32
    800023fa:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    800023fc:	9e25                	addw	a2,a2,s1
    800023fe:	1602                	slli	a2,a2,0x20
    80002400:	9201                	srli	a2,a2,0x20
    80002402:	1582                	slli	a1,a1,0x20
    80002404:	9181                	srli	a1,a1,0x20
    80002406:	7528                	ld	a0,104(a0)
    80002408:	fffff097          	auipc	ra,0xfffff
    8000240c:	01a080e7          	jalr	26(ra) # 80001422 <uvmalloc>
    80002410:	0005061b          	sext.w	a2,a0
    80002414:	fa69                	bnez	a2,800023e6 <growproc+0x26>
      return -1;
    80002416:	557d                	li	a0,-1
    80002418:	bfe1                	j	800023f0 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    8000241a:	9e25                	addw	a2,a2,s1
    8000241c:	1602                	slli	a2,a2,0x20
    8000241e:	9201                	srli	a2,a2,0x20
    80002420:	1582                	slli	a1,a1,0x20
    80002422:	9181                	srli	a1,a1,0x20
    80002424:	7528                	ld	a0,104(a0)
    80002426:	fffff097          	auipc	ra,0xfffff
    8000242a:	fb4080e7          	jalr	-76(ra) # 800013da <uvmdealloc>
    8000242e:	0005061b          	sext.w	a2,a0
    80002432:	bf55                	j	800023e6 <growproc+0x26>

0000000080002434 <fork>:
{
    80002434:	7179                	addi	sp,sp,-48
    80002436:	f406                	sd	ra,40(sp)
    80002438:	f022                	sd	s0,32(sp)
    8000243a:	ec26                	sd	s1,24(sp)
    8000243c:	e84a                	sd	s2,16(sp)
    8000243e:	e44e                	sd	s3,8(sp)
    80002440:	e052                	sd	s4,0(sp)
    80002442:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002444:	00000097          	auipc	ra,0x0
    80002448:	b5c080e7          	jalr	-1188(ra) # 80001fa0 <myproc>
    8000244c:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    8000244e:	00000097          	auipc	ra,0x0
    80002452:	d7a080e7          	jalr	-646(ra) # 800021c8 <allocproc>
    80002456:	16050963          	beqz	a0,800025c8 <fork+0x194>
    8000245a:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    8000245c:	06093603          	ld	a2,96(s2)
    80002460:	752c                	ld	a1,104(a0)
    80002462:	06893503          	ld	a0,104(s2)
    80002466:	fffff097          	auipc	ra,0xfffff
    8000246a:	108080e7          	jalr	264(ra) # 8000156e <uvmcopy>
    8000246e:	04054663          	bltz	a0,800024ba <fork+0x86>
  np->sz = p->sz;
    80002472:	06093783          	ld	a5,96(s2)
    80002476:	06f9b023          	sd	a5,96(s3)
  *(np->trapframe) = *(p->trapframe);
    8000247a:	07093683          	ld	a3,112(s2)
    8000247e:	87b6                	mv	a5,a3
    80002480:	0709b703          	ld	a4,112(s3)
    80002484:	12068693          	addi	a3,a3,288
    80002488:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    8000248c:	6788                	ld	a0,8(a5)
    8000248e:	6b8c                	ld	a1,16(a5)
    80002490:	6f90                	ld	a2,24(a5)
    80002492:	01073023          	sd	a6,0(a4)
    80002496:	e708                	sd	a0,8(a4)
    80002498:	eb0c                	sd	a1,16(a4)
    8000249a:	ef10                	sd	a2,24(a4)
    8000249c:	02078793          	addi	a5,a5,32
    800024a0:	02070713          	addi	a4,a4,32
    800024a4:	fed792e3          	bne	a5,a3,80002488 <fork+0x54>
  np->trapframe->a0 = 0;
    800024a8:	0709b783          	ld	a5,112(s3)
    800024ac:	0607b823          	sd	zero,112(a5)
    800024b0:	0e800493          	li	s1,232
  for(i = 0; i < NOFILE; i++)
    800024b4:	16800a13          	li	s4,360
    800024b8:	a03d                	j	800024e6 <fork+0xb2>
    freeproc(np);
    800024ba:	854e                	mv	a0,s3
    800024bc:	00000097          	auipc	ra,0x0
    800024c0:	c8a080e7          	jalr	-886(ra) # 80002146 <freeproc>
    release(&np->lock);
    800024c4:	854e                	mv	a0,s3
    800024c6:	ffffe097          	auipc	ra,0xffffe
    800024ca:	7d2080e7          	jalr	2002(ra) # 80000c98 <release>
    return -1;
    800024ce:	5a7d                	li	s4,-1
    800024d0:	a8e1                	j	800025a8 <fork+0x174>
      np->ofile[i] = filedup(p->ofile[i]);
    800024d2:	00003097          	auipc	ra,0x3
    800024d6:	c2e080e7          	jalr	-978(ra) # 80005100 <filedup>
    800024da:	009987b3          	add	a5,s3,s1
    800024de:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    800024e0:	04a1                	addi	s1,s1,8
    800024e2:	01448763          	beq	s1,s4,800024f0 <fork+0xbc>
    if(p->ofile[i])
    800024e6:	009907b3          	add	a5,s2,s1
    800024ea:	6388                	ld	a0,0(a5)
    800024ec:	f17d                	bnez	a0,800024d2 <fork+0x9e>
    800024ee:	bfcd                	j	800024e0 <fork+0xac>
  np->cwd = idup(p->cwd);
    800024f0:	16893503          	ld	a0,360(s2)
    800024f4:	00002097          	auipc	ra,0x2
    800024f8:	d82080e7          	jalr	-638(ra) # 80004276 <idup>
    800024fc:	16a9b423          	sd	a0,360(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002500:	4641                	li	a2,16
    80002502:	17090593          	addi	a1,s2,368
    80002506:	17098513          	addi	a0,s3,368
    8000250a:	fffff097          	auipc	ra,0xfffff
    8000250e:	928080e7          	jalr	-1752(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80002512:	0489aa03          	lw	s4,72(s3)
  release(&np->lock);
    80002516:	854e                	mv	a0,s3
    80002518:	ffffe097          	auipc	ra,0xffffe
    8000251c:	780080e7          	jalr	1920(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80002520:	0000f497          	auipc	s1,0xf
    80002524:	e8848493          	addi	s1,s1,-376 # 800113a8 <wait_lock>
    80002528:	8526                	mv	a0,s1
    8000252a:	ffffe097          	auipc	ra,0xffffe
    8000252e:	6ba080e7          	jalr	1722(ra) # 80000be4 <acquire>
  np->parent = p;
    80002532:	0529b823          	sd	s2,80(s3)
  release(&wait_lock);
    80002536:	8526                	mv	a0,s1
    80002538:	ffffe097          	auipc	ra,0xffffe
    8000253c:	760080e7          	jalr	1888(ra) # 80000c98 <release>
  acquire(&np->lock);
    80002540:	854e                	mv	a0,s3
    80002542:	ffffe097          	auipc	ra,0xffffe
    80002546:	6a2080e7          	jalr	1698(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    8000254a:	478d                	li	a5,3
    8000254c:	02f9a823          	sw	a5,48(s3)
  acquire(&p->list_lock);
    80002550:	01890493          	addi	s1,s2,24
    80002554:	8526                	mv	a0,s1
    80002556:	ffffe097          	auipc	ra,0xffffe
    8000255a:	68e080e7          	jalr	1678(ra) # 80000be4 <acquire>
  np-> affiliated_cpu = p-> affiliated_cpu;
    8000255e:	18892783          	lw	a5,392(s2)
    80002562:	18f9a423          	sw	a5,392(s3)
  release(&p->list_lock);
    80002566:	8526                	mv	a0,s1
    80002568:	ffffe097          	auipc	ra,0xffffe
    8000256c:	730080e7          	jalr	1840(ra) # 80000c98 <release>
  if (balance){
    80002570:	00006797          	auipc	a5,0x6
    80002574:	3487a783          	lw	a5,840(a5) # 800088b8 <balance>
    80002578:	e3a9                	bnez	a5,800025ba <fork+0x186>
  int cpu_to_add = np->affiliated_cpu;
    8000257a:	1889a503          	lw	a0,392(s3)
  add_link(&runnable_cpu_lists[cpu_to_add], np->proc_index, 0);
    8000257e:	00251793          	slli	a5,a0,0x2
    80002582:	97aa                	add	a5,a5,a0
    80002584:	078e                	slli	a5,a5,0x3
    80002586:	4601                	li	a2,0
    80002588:	1849a583          	lw	a1,388(s3)
    8000258c:	0000f517          	auipc	a0,0xf
    80002590:	d1450513          	addi	a0,a0,-748 # 800112a0 <runnable_cpu_lists>
    80002594:	953e                	add	a0,a0,a5
    80002596:	fffff097          	auipc	ra,0xfffff
    8000259a:	674080e7          	jalr	1652(ra) # 80001c0a <add_link>
  release(&np->lock);
    8000259e:	854e                	mv	a0,s3
    800025a0:	ffffe097          	auipc	ra,0xffffe
    800025a4:	6f8080e7          	jalr	1784(ra) # 80000c98 <release>
}
    800025a8:	8552                	mv	a0,s4
    800025aa:	70a2                	ld	ra,40(sp)
    800025ac:	7402                	ld	s0,32(sp)
    800025ae:	64e2                	ld	s1,24(sp)
    800025b0:	6942                	ld	s2,16(sp)
    800025b2:	69a2                	ld	s3,8(sp)
    800025b4:	6a02                	ld	s4,0(sp)
    800025b6:	6145                	addi	sp,sp,48
    800025b8:	8082                	ret
    cpu_to_add = get_balanced_cpu();
    800025ba:	fffff097          	auipc	ra,0xfffff
    800025be:	2d2080e7          	jalr	722(ra) # 8000188c <get_balanced_cpu>
    np->affiliated_cpu = cpu_to_add;
    800025c2:	18a9a423          	sw	a0,392(s3)
    800025c6:	bf65                	j	8000257e <fork+0x14a>
    return -1;
    800025c8:	5a7d                	li	s4,-1
    800025ca:	bff9                	j	800025a8 <fork+0x174>

00000000800025cc <scheduler>:
{
    800025cc:	7119                	addi	sp,sp,-128
    800025ce:	fc86                	sd	ra,120(sp)
    800025d0:	f8a2                	sd	s0,112(sp)
    800025d2:	f4a6                	sd	s1,104(sp)
    800025d4:	f0ca                	sd	s2,96(sp)
    800025d6:	ecce                	sd	s3,88(sp)
    800025d8:	e8d2                	sd	s4,80(sp)
    800025da:	e4d6                	sd	s5,72(sp)
    800025dc:	e0da                	sd	s6,64(sp)
    800025de:	fc5e                	sd	s7,56(sp)
    800025e0:	f862                	sd	s8,48(sp)
    800025e2:	f466                	sd	s9,40(sp)
    800025e4:	f06a                	sd	s10,32(sp)
    800025e6:	ec6e                	sd	s11,24(sp)
    800025e8:	0100                	addi	s0,sp,128
    800025ea:	8712                	mv	a4,tp
  int id = r_tp();
    800025ec:	2701                	sext.w	a4,a4
    800025ee:	8d12                	mv	s10,tp
    800025f0:	2d01                	sext.w	s10,s10
  struct processList* ready_list = &runnable_cpu_lists[cpu_id];
    800025f2:	002d1793          	slli	a5,s10,0x2
    800025f6:	97ea                	add	a5,a5,s10
    800025f8:	078e                	slli	a5,a5,0x3
    800025fa:	0000f917          	auipc	s2,0xf
    800025fe:	ca690913          	addi	s2,s2,-858 # 800112a0 <runnable_cpu_lists>
    80002602:	00f90cb3          	add	s9,s2,a5
  c->proc = 0;
    80002606:	00771693          	slli	a3,a4,0x7
    8000260a:	00d90633          	add	a2,s2,a3
    8000260e:	12063023          	sd	zero,288(a2) # 1120 <_entry-0x7fffeee0>
    acquire(&ready_list->head_lock);
    80002612:	07a1                	addi	a5,a5,8
    80002614:	993e                	add	s2,s2,a5
        swtch(&c->context, &p->context);
    80002616:	0000f797          	auipc	a5,0xf
    8000261a:	db278793          	addi	a5,a5,-590 # 800113c8 <cpus+0x8>
    8000261e:	97b6                	add	a5,a5,a3
    80002620:	f8f43423          	sd	a5,-120(s0)
    printf("");
    80002624:	00006b17          	auipc	s6,0x6
    80002628:	dc4b0b13          	addi	s6,s6,-572 # 800083e8 <states.1804+0xa0>
    if (ready_list->head == -1){
    8000262c:	8a66                	mv	s4,s9
    8000262e:	5afd                	li	s5,-1
        c->proc = p;
    80002630:	8db2                	mv	s11,a2
      p = &proc[ready_list->head];
    80002632:	0000fc17          	auipc	s8,0xf
    80002636:	18ec0c13          	addi	s8,s8,398 # 800117c0 <proc>
        if (balance){
    8000263a:	00006b97          	auipc	s7,0x6
    8000263e:	27eb8b93          	addi	s7,s7,638 # 800088b8 <balance>
    80002642:	a089                	j	80002684 <scheduler+0xb8>
      p = &proc[ready_list->head];
    80002644:	19000513          	li	a0,400
    80002648:	02a484b3          	mul	s1,s1,a0
    8000264c:	94e2                	add	s1,s1,s8
      release(&ready_list->head_lock);
    8000264e:	854a                	mv	a0,s2
    80002650:	ffffe097          	auipc	ra,0xffffe
    80002654:	648080e7          	jalr	1608(ra) # 80000c98 <release>
      remove_link(ready_list, p->proc_index);
    80002658:	1844a583          	lw	a1,388(s1)
    8000265c:	8566                	mv	a0,s9
    8000265e:	fffff097          	auipc	ra,0xfffff
    80002662:	25e080e7          	jalr	606(ra) # 800018bc <remove_link>
    acquire(&p->lock);
    80002666:	89a6                	mv	s3,s1
    80002668:	8526                	mv	a0,s1
    8000266a:	ffffe097          	auipc	ra,0xffffe
    8000266e:	57a080e7          	jalr	1402(ra) # 80000be4 <acquire>
    if(p->state == RUNNABLE) {
    80002672:	5898                	lw	a4,48(s1)
    80002674:	478d                	li	a5,3
    80002676:	04f70b63          	beq	a4,a5,800026cc <scheduler+0x100>
    release(&p->lock);
    8000267a:	854e                	mv	a0,s3
    8000267c:	ffffe097          	auipc	ra,0xffffe
    80002680:	61c080e7          	jalr	1564(ra) # 80000c98 <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002684:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002688:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000268c:	10079073          	csrw	sstatus,a5
    printf("");
    80002690:	855a                	mv	a0,s6
    80002692:	ffffe097          	auipc	ra,0xffffe
    80002696:	ef6080e7          	jalr	-266(ra) # 80000588 <printf>
    acquire(&ready_list->head_lock);
    8000269a:	854a                	mv	a0,s2
    8000269c:	ffffe097          	auipc	ra,0xffffe
    800026a0:	548080e7          	jalr	1352(ra) # 80000be4 <acquire>
    if (ready_list->head == -1){
    800026a4:	000a2483          	lw	s1,0(s4)
    800026a8:	f9549ee3          	bne	s1,s5,80002644 <scheduler+0x78>
        release(&ready_list->head_lock);
    800026ac:	854a                	mv	a0,s2
    800026ae:	ffffe097          	auipc	ra,0xffffe
    800026b2:	5ea080e7          	jalr	1514(ra) # 80000c98 <release>
        if (balance){
    800026b6:	000ba783          	lw	a5,0(s7)
    800026ba:	d7e9                	beqz	a5,80002684 <scheduler+0xb8>
          p = steal_proc(cpu_id);
    800026bc:	856a                	mv	a0,s10
    800026be:	fffff097          	auipc	ra,0xfffff
    800026c2:	438080e7          	jalr	1080(ra) # 80001af6 <steal_proc>
    800026c6:	84aa                	mv	s1,a0
          if (p == 0)
    800026c8:	fd59                	bnez	a0,80002666 <scheduler+0x9a>
    800026ca:	bf6d                	j	80002684 <scheduler+0xb8>
        p->state = RUNNING;
    800026cc:	4791                	li	a5,4
    800026ce:	d89c                	sw	a5,48(s1)
        c->proc = p;
    800026d0:	129db023          	sd	s1,288(s11)
        swtch(&c->context, &p->context);
    800026d4:	07848593          	addi	a1,s1,120
    800026d8:	f8843503          	ld	a0,-120(s0)
    800026dc:	00001097          	auipc	ra,0x1
    800026e0:	af8080e7          	jalr	-1288(ra) # 800031d4 <swtch>
        c->proc = 0;
    800026e4:	120db023          	sd	zero,288(s11)
    800026e8:	bf49                	j	8000267a <scheduler+0xae>

00000000800026ea <sched>:
{
    800026ea:	7179                	addi	sp,sp,-48
    800026ec:	f406                	sd	ra,40(sp)
    800026ee:	f022                	sd	s0,32(sp)
    800026f0:	ec26                	sd	s1,24(sp)
    800026f2:	e84a                	sd	s2,16(sp)
    800026f4:	e44e                	sd	s3,8(sp)
    800026f6:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800026f8:	00000097          	auipc	ra,0x0
    800026fc:	8a8080e7          	jalr	-1880(ra) # 80001fa0 <myproc>
    80002700:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002702:	ffffe097          	auipc	ra,0xffffe
    80002706:	468080e7          	jalr	1128(ra) # 80000b6a <holding>
    8000270a:	c93d                	beqz	a0,80002780 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000270c:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    8000270e:	2781                	sext.w	a5,a5
    80002710:	079e                	slli	a5,a5,0x7
    80002712:	0000f717          	auipc	a4,0xf
    80002716:	b8e70713          	addi	a4,a4,-1138 # 800112a0 <runnable_cpu_lists>
    8000271a:	97ba                	add	a5,a5,a4
    8000271c:	1987a703          	lw	a4,408(a5)
    80002720:	4785                	li	a5,1
    80002722:	06f71763          	bne	a4,a5,80002790 <sched+0xa6>
  if(p->state == RUNNING)
    80002726:	5898                	lw	a4,48(s1)
    80002728:	4791                	li	a5,4
    8000272a:	06f70b63          	beq	a4,a5,800027a0 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000272e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002732:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002734:	efb5                	bnez	a5,800027b0 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002736:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002738:	0000f917          	auipc	s2,0xf
    8000273c:	b6890913          	addi	s2,s2,-1176 # 800112a0 <runnable_cpu_lists>
    80002740:	2781                	sext.w	a5,a5
    80002742:	079e                	slli	a5,a5,0x7
    80002744:	97ca                	add	a5,a5,s2
    80002746:	19c7a983          	lw	s3,412(a5)
    8000274a:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000274c:	2781                	sext.w	a5,a5
    8000274e:	079e                	slli	a5,a5,0x7
    80002750:	0000f597          	auipc	a1,0xf
    80002754:	c7858593          	addi	a1,a1,-904 # 800113c8 <cpus+0x8>
    80002758:	95be                	add	a1,a1,a5
    8000275a:	07848513          	addi	a0,s1,120
    8000275e:	00001097          	auipc	ra,0x1
    80002762:	a76080e7          	jalr	-1418(ra) # 800031d4 <swtch>
    80002766:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002768:	2781                	sext.w	a5,a5
    8000276a:	079e                	slli	a5,a5,0x7
    8000276c:	97ca                	add	a5,a5,s2
    8000276e:	1937ae23          	sw	s3,412(a5)
}
    80002772:	70a2                	ld	ra,40(sp)
    80002774:	7402                	ld	s0,32(sp)
    80002776:	64e2                	ld	s1,24(sp)
    80002778:	6942                	ld	s2,16(sp)
    8000277a:	69a2                	ld	s3,8(sp)
    8000277c:	6145                	addi	sp,sp,48
    8000277e:	8082                	ret
    panic("sched p->lock");
    80002780:	00006517          	auipc	a0,0x6
    80002784:	ad850513          	addi	a0,a0,-1320 # 80008258 <digits+0x218>
    80002788:	ffffe097          	auipc	ra,0xffffe
    8000278c:	db6080e7          	jalr	-586(ra) # 8000053e <panic>
    panic("sched locks");
    80002790:	00006517          	auipc	a0,0x6
    80002794:	ad850513          	addi	a0,a0,-1320 # 80008268 <digits+0x228>
    80002798:	ffffe097          	auipc	ra,0xffffe
    8000279c:	da6080e7          	jalr	-602(ra) # 8000053e <panic>
    panic("sched running");
    800027a0:	00006517          	auipc	a0,0x6
    800027a4:	ad850513          	addi	a0,a0,-1320 # 80008278 <digits+0x238>
    800027a8:	ffffe097          	auipc	ra,0xffffe
    800027ac:	d96080e7          	jalr	-618(ra) # 8000053e <panic>
    panic("sched interruptible");
    800027b0:	00006517          	auipc	a0,0x6
    800027b4:	ad850513          	addi	a0,a0,-1320 # 80008288 <digits+0x248>
    800027b8:	ffffe097          	auipc	ra,0xffffe
    800027bc:	d86080e7          	jalr	-634(ra) # 8000053e <panic>

00000000800027c0 <yield>:
{
    800027c0:	1101                	addi	sp,sp,-32
    800027c2:	ec06                	sd	ra,24(sp)
    800027c4:	e822                	sd	s0,16(sp)
    800027c6:	e426                	sd	s1,8(sp)
    800027c8:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800027ca:	fffff097          	auipc	ra,0xfffff
    800027ce:	7d6080e7          	jalr	2006(ra) # 80001fa0 <myproc>
    800027d2:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800027d4:	ffffe097          	auipc	ra,0xffffe
    800027d8:	410080e7          	jalr	1040(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    800027dc:	478d                	li	a5,3
    800027de:	d89c                	sw	a5,48(s1)
  add_link(&runnable_cpu_lists[p->affiliated_cpu], p->proc_index,1);
    800027e0:	1884a503          	lw	a0,392(s1)
    800027e4:	00251793          	slli	a5,a0,0x2
    800027e8:	97aa                	add	a5,a5,a0
    800027ea:	078e                	slli	a5,a5,0x3
    800027ec:	4605                	li	a2,1
    800027ee:	1844a583          	lw	a1,388(s1)
    800027f2:	0000f517          	auipc	a0,0xf
    800027f6:	aae50513          	addi	a0,a0,-1362 # 800112a0 <runnable_cpu_lists>
    800027fa:	953e                	add	a0,a0,a5
    800027fc:	fffff097          	auipc	ra,0xfffff
    80002800:	40e080e7          	jalr	1038(ra) # 80001c0a <add_link>
  sched();
    80002804:	00000097          	auipc	ra,0x0
    80002808:	ee6080e7          	jalr	-282(ra) # 800026ea <sched>
  release(&p->lock);
    8000280c:	8526                	mv	a0,s1
    8000280e:	ffffe097          	auipc	ra,0xffffe
    80002812:	48a080e7          	jalr	1162(ra) # 80000c98 <release>
}
    80002816:	60e2                	ld	ra,24(sp)
    80002818:	6442                	ld	s0,16(sp)
    8000281a:	64a2                	ld	s1,8(sp)
    8000281c:	6105                	addi	sp,sp,32
    8000281e:	8082                	ret

0000000080002820 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002820:	7179                	addi	sp,sp,-48
    80002822:	f406                	sd	ra,40(sp)
    80002824:	f022                	sd	s0,32(sp)
    80002826:	ec26                	sd	s1,24(sp)
    80002828:	e84a                	sd	s2,16(sp)
    8000282a:	e44e                	sd	s3,8(sp)
    8000282c:	1800                	addi	s0,sp,48
    8000282e:	89aa                	mv	s3,a0
    80002830:	892e                	mv	s2,a1

  
  struct proc *p = myproc();
    80002832:	fffff097          	auipc	ra,0xfffff
    80002836:	76e080e7          	jalr	1902(ra) # 80001fa0 <myproc>
    8000283a:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    8000283c:	ffffe097          	auipc	ra,0xffffe
    80002840:	3a8080e7          	jalr	936(ra) # 80000be4 <acquire>
  //printf("start sleep for proc index %d\n", p->proc_index);
  release(lk);
    80002844:	854a                	mv	a0,s2
    80002846:	ffffe097          	auipc	ra,0xffffe
    8000284a:	452080e7          	jalr	1106(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    8000284e:	0334bc23          	sd	s3,56(s1)
  p->state = SLEEPING;
    80002852:	4789                	li	a5,2
    80002854:	d89c                	sw	a5,48(s1)
  
  add_link(&sleeping_list, p->proc_index, 0);
    80002856:	4601                	li	a2,0
    80002858:	1844a583          	lw	a1,388(s1)
    8000285c:	0000f517          	auipc	a0,0xf
    80002860:	ae450513          	addi	a0,a0,-1308 # 80011340 <sleeping_list>
    80002864:	fffff097          	auipc	ra,0xfffff
    80002868:	3a6080e7          	jalr	934(ra) # 80001c0a <add_link>
  //printf("after adding link to sleeping list\n");
  sched();
    8000286c:	00000097          	auipc	ra,0x0
    80002870:	e7e080e7          	jalr	-386(ra) # 800026ea <sched>

  // Tidy up.
  p->chan = 0;
    80002874:	0204bc23          	sd	zero,56(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002878:	8526                	mv	a0,s1
    8000287a:	ffffe097          	auipc	ra,0xffffe
    8000287e:	41e080e7          	jalr	1054(ra) # 80000c98 <release>
  
  acquire(lk);
    80002882:	854a                	mv	a0,s2
    80002884:	ffffe097          	auipc	ra,0xffffe
    80002888:	360080e7          	jalr	864(ra) # 80000be4 <acquire>
  //printf("finish sleep procedure\n");
}
    8000288c:	70a2                	ld	ra,40(sp)
    8000288e:	7402                	ld	s0,32(sp)
    80002890:	64e2                	ld	s1,24(sp)
    80002892:	6942                	ld	s2,16(sp)
    80002894:	69a2                	ld	s3,8(sp)
    80002896:	6145                	addi	sp,sp,48
    80002898:	8082                	ret

000000008000289a <wait>:
{
    8000289a:	715d                	addi	sp,sp,-80
    8000289c:	e486                	sd	ra,72(sp)
    8000289e:	e0a2                	sd	s0,64(sp)
    800028a0:	fc26                	sd	s1,56(sp)
    800028a2:	f84a                	sd	s2,48(sp)
    800028a4:	f44e                	sd	s3,40(sp)
    800028a6:	f052                	sd	s4,32(sp)
    800028a8:	ec56                	sd	s5,24(sp)
    800028aa:	e85a                	sd	s6,16(sp)
    800028ac:	e45e                	sd	s7,8(sp)
    800028ae:	e062                	sd	s8,0(sp)
    800028b0:	0880                	addi	s0,sp,80
    800028b2:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800028b4:	fffff097          	auipc	ra,0xfffff
    800028b8:	6ec080e7          	jalr	1772(ra) # 80001fa0 <myproc>
    800028bc:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800028be:	0000f517          	auipc	a0,0xf
    800028c2:	aea50513          	addi	a0,a0,-1302 # 800113a8 <wait_lock>
    800028c6:	ffffe097          	auipc	ra,0xffffe
    800028ca:	31e080e7          	jalr	798(ra) # 80000be4 <acquire>
    havekids = 0;
    800028ce:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800028d0:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    800028d2:	00015997          	auipc	s3,0x15
    800028d6:	2ee98993          	addi	s3,s3,750 # 80017bc0 <tickslock>
        havekids = 1;
    800028da:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800028dc:	0000fc17          	auipc	s8,0xf
    800028e0:	accc0c13          	addi	s8,s8,-1332 # 800113a8 <wait_lock>
    havekids = 0;
    800028e4:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800028e6:	0000f497          	auipc	s1,0xf
    800028ea:	eda48493          	addi	s1,s1,-294 # 800117c0 <proc>
    800028ee:	a0bd                	j	8000295c <wait+0xc2>
          pid = np->pid;
    800028f0:	0484a983          	lw	s3,72(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800028f4:	000b0e63          	beqz	s6,80002910 <wait+0x76>
    800028f8:	4691                	li	a3,4
    800028fa:	04448613          	addi	a2,s1,68
    800028fe:	85da                	mv	a1,s6
    80002900:	06893503          	ld	a0,104(s2)
    80002904:	fffff097          	auipc	ra,0xfffff
    80002908:	d6e080e7          	jalr	-658(ra) # 80001672 <copyout>
    8000290c:	02054563          	bltz	a0,80002936 <wait+0x9c>
          freeproc(np);
    80002910:	8526                	mv	a0,s1
    80002912:	00000097          	auipc	ra,0x0
    80002916:	834080e7          	jalr	-1996(ra) # 80002146 <freeproc>
          release(&np->lock);
    8000291a:	8526                	mv	a0,s1
    8000291c:	ffffe097          	auipc	ra,0xffffe
    80002920:	37c080e7          	jalr	892(ra) # 80000c98 <release>
          release(&wait_lock);
    80002924:	0000f517          	auipc	a0,0xf
    80002928:	a8450513          	addi	a0,a0,-1404 # 800113a8 <wait_lock>
    8000292c:	ffffe097          	auipc	ra,0xffffe
    80002930:	36c080e7          	jalr	876(ra) # 80000c98 <release>
          return pid;
    80002934:	a09d                	j	8000299a <wait+0x100>
            release(&np->lock);
    80002936:	8526                	mv	a0,s1
    80002938:	ffffe097          	auipc	ra,0xffffe
    8000293c:	360080e7          	jalr	864(ra) # 80000c98 <release>
            release(&wait_lock);
    80002940:	0000f517          	auipc	a0,0xf
    80002944:	a6850513          	addi	a0,a0,-1432 # 800113a8 <wait_lock>
    80002948:	ffffe097          	auipc	ra,0xffffe
    8000294c:	350080e7          	jalr	848(ra) # 80000c98 <release>
            return -1;
    80002950:	59fd                	li	s3,-1
    80002952:	a0a1                	j	8000299a <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002954:	19048493          	addi	s1,s1,400
    80002958:	03348463          	beq	s1,s3,80002980 <wait+0xe6>
      if(np->parent == p){
    8000295c:	68bc                	ld	a5,80(s1)
    8000295e:	ff279be3          	bne	a5,s2,80002954 <wait+0xba>
        acquire(&np->lock);
    80002962:	8526                	mv	a0,s1
    80002964:	ffffe097          	auipc	ra,0xffffe
    80002968:	280080e7          	jalr	640(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    8000296c:	589c                	lw	a5,48(s1)
    8000296e:	f94781e3          	beq	a5,s4,800028f0 <wait+0x56>
        release(&np->lock);
    80002972:	8526                	mv	a0,s1
    80002974:	ffffe097          	auipc	ra,0xffffe
    80002978:	324080e7          	jalr	804(ra) # 80000c98 <release>
        havekids = 1;
    8000297c:	8756                	mv	a4,s5
    8000297e:	bfd9                	j	80002954 <wait+0xba>
    if(!havekids || p->killed){
    80002980:	c701                	beqz	a4,80002988 <wait+0xee>
    80002982:	04092783          	lw	a5,64(s2)
    80002986:	c79d                	beqz	a5,800029b4 <wait+0x11a>
      release(&wait_lock);
    80002988:	0000f517          	auipc	a0,0xf
    8000298c:	a2050513          	addi	a0,a0,-1504 # 800113a8 <wait_lock>
    80002990:	ffffe097          	auipc	ra,0xffffe
    80002994:	308080e7          	jalr	776(ra) # 80000c98 <release>
      return -1;
    80002998:	59fd                	li	s3,-1
}
    8000299a:	854e                	mv	a0,s3
    8000299c:	60a6                	ld	ra,72(sp)
    8000299e:	6406                	ld	s0,64(sp)
    800029a0:	74e2                	ld	s1,56(sp)
    800029a2:	7942                	ld	s2,48(sp)
    800029a4:	79a2                	ld	s3,40(sp)
    800029a6:	7a02                	ld	s4,32(sp)
    800029a8:	6ae2                	ld	s5,24(sp)
    800029aa:	6b42                	ld	s6,16(sp)
    800029ac:	6ba2                	ld	s7,8(sp)
    800029ae:	6c02                	ld	s8,0(sp)
    800029b0:	6161                	addi	sp,sp,80
    800029b2:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800029b4:	85e2                	mv	a1,s8
    800029b6:	854a                	mv	a0,s2
    800029b8:	00000097          	auipc	ra,0x0
    800029bc:	e68080e7          	jalr	-408(ra) # 80002820 <sleep>
    havekids = 0;
    800029c0:	b715                	j	800028e4 <wait+0x4a>

00000000800029c2 <wakeup>:

}

void
wakeup(void *chan)
{
    800029c2:	711d                	addi	sp,sp,-96
    800029c4:	ec86                	sd	ra,88(sp)
    800029c6:	e8a2                	sd	s0,80(sp)
    800029c8:	e4a6                	sd	s1,72(sp)
    800029ca:	e0ca                	sd	s2,64(sp)
    800029cc:	fc4e                	sd	s3,56(sp)
    800029ce:	f852                	sd	s4,48(sp)
    800029d0:	f456                	sd	s5,40(sp)
    800029d2:	f05a                	sd	s6,32(sp)
    800029d4:	ec5e                	sd	s7,24(sp)
    800029d6:	e862                	sd	s8,16(sp)
    800029d8:	e466                	sd	s9,8(sp)
    800029da:	e06a                	sd	s10,0(sp)
    800029dc:	1080                	addi	s0,sp,96
    800029de:	8baa                	mv	s7,a0
  
  while(1) // Keep looping until no process is waken up
  {
    
    //Loop until finds process that needs to be waken up
    acquire(&sleeping_list.head_lock);
    800029e0:	0000fd17          	auipc	s10,0xf
    800029e4:	8c0d0d13          	addi	s10,s10,-1856 # 800112a0 <runnable_cpu_lists>
    800029e8:	0000fc97          	auipc	s9,0xf
    800029ec:	960c8c93          	addi	s9,s9,-1696 # 80011348 <sleeping_list+0x8>
    if (sleeping_list.head == -1) //empty list
    800029f0:	5c7d                	li	s8,-1
    800029f2:	19000a93          	li	s5,400
      
      release(&sleeping_list.head_lock);
      return;
    }
    //non-empty:
    curr = &proc[sleeping_list.head];
    800029f6:	0000fa17          	auipc	s4,0xf
    800029fa:	dcaa0a13          	addi	s4,s4,-566 # 800117c0 <proc>
    800029fe:	a0bd                	j	80002a6c <wakeup+0xaa>
      release(&sleeping_list.head_lock);
    80002a00:	0000f517          	auipc	a0,0xf
    80002a04:	94850513          	addi	a0,a0,-1720 # 80011348 <sleeping_list+0x8>
    80002a08:	ffffe097          	auipc	ra,0xffffe
    80002a0c:	290080e7          	jalr	656(ra) # 80000c98 <release>
      return;
    80002a10:	a235                	j	80002b3c <wakeup+0x17a>
    {
      //printf("found proc to wakeup - pid is %d and proc index is %d\n", curr->pid, curr->proc_index);
      curr->state = RUNNABLE;
      cpu_to_add = curr->affiliated_cpu;
      if (balance){
          cpu_to_add = get_balanced_cpu();
    80002a12:	fffff097          	auipc	ra,0xfffff
    80002a16:	e7a080e7          	jalr	-390(ra) # 8000188c <get_balanced_cpu>
    80002a1a:	8b2a                	mv	s6,a0
          curr->affiliated_cpu = cpu_to_add;
    80002a1c:	035487b3          	mul	a5,s1,s5
    80002a20:	97d2                	add	a5,a5,s4
    80002a22:	18a7a423          	sw	a0,392(a5)
      }
      struct processList* cpuList = &runnable_cpu_lists[cpu_to_add];
      release(&curr->list_lock);
    80002a26:	854a                	mv	a0,s2
    80002a28:	ffffe097          	auipc	ra,0xffffe
    80002a2c:	270080e7          	jalr	624(ra) # 80000c98 <release>
      remove_link(&sleeping_list, curr->proc_index);
    80002a30:	035484b3          	mul	s1,s1,s5
    80002a34:	94d2                	add	s1,s1,s4
    80002a36:	1844a583          	lw	a1,388(s1)
    80002a3a:	0000f517          	auipc	a0,0xf
    80002a3e:	90650513          	addi	a0,a0,-1786 # 80011340 <sleeping_list>
    80002a42:	fffff097          	auipc	ra,0xfffff
    80002a46:	e7a080e7          	jalr	-390(ra) # 800018bc <remove_link>
      struct processList* cpuList = &runnable_cpu_lists[cpu_to_add];
    80002a4a:	002b1513          	slli	a0,s6,0x2
    80002a4e:	955a                	add	a0,a0,s6
    80002a50:	050e                	slli	a0,a0,0x3
      add_link(cpuList, curr->proc_index, 0);
    80002a52:	4601                	li	a2,0
    80002a54:	1844a583          	lw	a1,388(s1)
    80002a58:	956a                	add	a0,a0,s10
    80002a5a:	fffff097          	auipc	ra,0xfffff
    80002a5e:	1b0080e7          	jalr	432(ra) # 80001c0a <add_link>
      release(&curr->lock);
    80002a62:	854e                	mv	a0,s3
    80002a64:	ffffe097          	auipc	ra,0xffffe
    80002a68:	234080e7          	jalr	564(ra) # 80000c98 <release>
    acquire(&sleeping_list.head_lock);
    80002a6c:	8566                	mv	a0,s9
    80002a6e:	ffffe097          	auipc	ra,0xffffe
    80002a72:	176080e7          	jalr	374(ra) # 80000be4 <acquire>
    if (sleeping_list.head == -1) //empty list
    80002a76:	0a0d2483          	lw	s1,160(s10)
    80002a7a:	f98483e3          	beq	s1,s8,80002a00 <wakeup+0x3e>
    curr = &proc[sleeping_list.head];
    80002a7e:	03548533          	mul	a0,s1,s5
    80002a82:	014509b3          	add	s3,a0,s4
    acquire(&curr->list_lock);
    80002a86:	0561                	addi	a0,a0,24
    80002a88:	01450933          	add	s2,a0,s4
    80002a8c:	854a                	mv	a0,s2
    80002a8e:	ffffe097          	auipc	ra,0xffffe
    80002a92:	156080e7          	jalr	342(ra) # 80000be4 <acquire>
    release(&sleeping_list.head_lock);
    80002a96:	8566                	mv	a0,s9
    80002a98:	ffffe097          	auipc	ra,0xffffe
    80002a9c:	200080e7          	jalr	512(ra) # 80000c98 <release>
    acquire(&curr->lock);
    80002aa0:	854e                	mv	a0,s3
    80002aa2:	ffffe097          	auipc	ra,0xffffe
    80002aa6:	142080e7          	jalr	322(ra) # 80000be4 <acquire>
    if(curr->chan == chan) //needs to wake up
    80002aaa:	0389b783          	ld	a5,56(s3)
    80002aae:	01779d63          	bne	a5,s7,80002ac8 <wakeup+0x106>
      curr->state = RUNNABLE;
    80002ab2:	470d                	li	a4,3
    80002ab4:	02e9a823          	sw	a4,48(s3)
      if (balance){
    80002ab8:	00006797          	auipc	a5,0x6
    80002abc:	e007a783          	lw	a5,-512(a5) # 800088b8 <balance>
    80002ac0:	fba9                	bnez	a5,80002a12 <wakeup+0x50>
      cpu_to_add = curr->affiliated_cpu;
    80002ac2:	1889ab03          	lw	s6,392(s3)
    80002ac6:	b785                	j	80002a26 <wakeup+0x64>
      continue; //another iteration on list
    }
    release(&curr->lock);
    80002ac8:	854e                	mv	a0,s3
    80002aca:	ffffe097          	auipc	ra,0xffffe
    80002ace:	1ce080e7          	jalr	462(ra) # 80000c98 <release>
    int finished = 1;
    while(curr->next_proc_index!= -1) //loop to find process that needs to be waken up
    80002ad2:	035484b3          	mul	s1,s1,s5
    80002ad6:	94d2                	add	s1,s1,s4
    80002ad8:	1804a483          	lw	s1,384(s1)
    80002adc:	05848a63          	beq	s1,s8,80002b30 <wakeup+0x16e>
    {
      next = &proc[curr->next_proc_index];
    80002ae0:	035487b3          	mul	a5,s1,s5
    80002ae4:	8b4e                	mv	s6,s3
    80002ae6:	014789b3          	add	s3,a5,s4
      acquire(&next->list_lock);
    80002aea:	07e1                	addi	a5,a5,24
    80002aec:	01478933          	add	s2,a5,s4
    80002af0:	854a                	mv	a0,s2
    80002af2:	ffffe097          	auipc	ra,0xffffe
    80002af6:	0f2080e7          	jalr	242(ra) # 80000be4 <acquire>
      release(&curr->list_lock);
    80002afa:	018b0513          	addi	a0,s6,24
    80002afe:	ffffe097          	auipc	ra,0xffffe
    80002b02:	19a080e7          	jalr	410(ra) # 80000c98 <release>
      curr = next;

      acquire(&curr->lock);
    80002b06:	854e                	mv	a0,s3
    80002b08:	ffffe097          	auipc	ra,0xffffe
    80002b0c:	0dc080e7          	jalr	220(ra) # 80000be4 <acquire>
      if(curr->chan == chan) //needs to wake up
    80002b10:	0389b783          	ld	a5,56(s3)
    80002b14:	05778263          	beq	a5,s7,80002b58 <wakeup+0x196>
        add_link(cpuList, curr->proc_index, 0);
        release(&curr->lock);
        finished = 0;
        break; //another iteration on list
      }
      release(&curr->lock);
    80002b18:	854e                	mv	a0,s3
    80002b1a:	ffffe097          	auipc	ra,0xffffe
    80002b1e:	17e080e7          	jalr	382(ra) # 80000c98 <release>
    while(curr->next_proc_index!= -1) //loop to find process that needs to be waken up
    80002b22:	035484b3          	mul	s1,s1,s5
    80002b26:	94d2                	add	s1,s1,s4
    80002b28:	1804a483          	lw	s1,384(s1)
    80002b2c:	fb849ae3          	bne	s1,s8,80002ae0 <wakeup+0x11e>
    }
    if(finished == 1) //full iteration with no wakeup
    {
      //printf("exiting wakeup\n");
      release(&curr->list_lock);
    80002b30:	01898513          	addi	a0,s3,24
    80002b34:	ffffe097          	auipc	ra,0xffffe
    80002b38:	164080e7          	jalr	356(ra) # 80000c98 <release>
      return;
    }
  }
}
    80002b3c:	60e6                	ld	ra,88(sp)
    80002b3e:	6446                	ld	s0,80(sp)
    80002b40:	64a6                	ld	s1,72(sp)
    80002b42:	6906                	ld	s2,64(sp)
    80002b44:	79e2                	ld	s3,56(sp)
    80002b46:	7a42                	ld	s4,48(sp)
    80002b48:	7aa2                	ld	s5,40(sp)
    80002b4a:	7b02                	ld	s6,32(sp)
    80002b4c:	6be2                	ld	s7,24(sp)
    80002b4e:	6c42                	ld	s8,16(sp)
    80002b50:	6ca2                	ld	s9,8(sp)
    80002b52:	6d02                	ld	s10,0(sp)
    80002b54:	6125                	addi	sp,sp,96
    80002b56:	8082                	ret
        curr->state = RUNNABLE;
    80002b58:	470d                	li	a4,3
    80002b5a:	02e9a823          	sw	a4,48(s3)
        if (balance){
    80002b5e:	00006797          	auipc	a5,0x6
    80002b62:	d5a7a783          	lw	a5,-678(a5) # 800088b8 <balance>
    80002b66:	e7b9                	bnez	a5,80002bb4 <wakeup+0x1f2>
        cpu_to_add = curr->affiliated_cpu;
    80002b68:	1889ab03          	lw	s6,392(s3)
        release(&curr->list_lock);
    80002b6c:	854a                	mv	a0,s2
    80002b6e:	ffffe097          	auipc	ra,0xffffe
    80002b72:	12a080e7          	jalr	298(ra) # 80000c98 <release>
        remove_link(&sleeping_list, curr->proc_index);
    80002b76:	035484b3          	mul	s1,s1,s5
    80002b7a:	94d2                	add	s1,s1,s4
    80002b7c:	1844a583          	lw	a1,388(s1)
    80002b80:	0000e517          	auipc	a0,0xe
    80002b84:	7c050513          	addi	a0,a0,1984 # 80011340 <sleeping_list>
    80002b88:	fffff097          	auipc	ra,0xfffff
    80002b8c:	d34080e7          	jalr	-716(ra) # 800018bc <remove_link>
        struct processList* cpuList = &runnable_cpu_lists[cpu_to_add];
    80002b90:	002b1513          	slli	a0,s6,0x2
    80002b94:	955a                	add	a0,a0,s6
    80002b96:	050e                	slli	a0,a0,0x3
        add_link(cpuList, curr->proc_index, 0);
    80002b98:	4601                	li	a2,0
    80002b9a:	1844a583          	lw	a1,388(s1)
    80002b9e:	956a                	add	a0,a0,s10
    80002ba0:	fffff097          	auipc	ra,0xfffff
    80002ba4:	06a080e7          	jalr	106(ra) # 80001c0a <add_link>
        release(&curr->lock);
    80002ba8:	854e                	mv	a0,s3
    80002baa:	ffffe097          	auipc	ra,0xffffe
    80002bae:	0ee080e7          	jalr	238(ra) # 80000c98 <release>
    if(finished == 1) //full iteration with no wakeup
    80002bb2:	bd6d                	j	80002a6c <wakeup+0xaa>
            cpu_to_add = get_balanced_cpu();
    80002bb4:	fffff097          	auipc	ra,0xfffff
    80002bb8:	cd8080e7          	jalr	-808(ra) # 8000188c <get_balanced_cpu>
    80002bbc:	8b2a                	mv	s6,a0
            curr->affiliated_cpu = cpu_to_add;
    80002bbe:	035487b3          	mul	a5,s1,s5
    80002bc2:	97d2                	add	a5,a5,s4
    80002bc4:	18a7a423          	sw	a0,392(a5)
    80002bc8:	b755                	j	80002b6c <wakeup+0x1aa>

0000000080002bca <reparent>:
{
    80002bca:	7179                	addi	sp,sp,-48
    80002bcc:	f406                	sd	ra,40(sp)
    80002bce:	f022                	sd	s0,32(sp)
    80002bd0:	ec26                	sd	s1,24(sp)
    80002bd2:	e84a                	sd	s2,16(sp)
    80002bd4:	e44e                	sd	s3,8(sp)
    80002bd6:	e052                	sd	s4,0(sp)
    80002bd8:	1800                	addi	s0,sp,48
    80002bda:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002bdc:	0000f497          	auipc	s1,0xf
    80002be0:	be448493          	addi	s1,s1,-1052 # 800117c0 <proc>
      pp->parent = initproc;
    80002be4:	00006a17          	auipc	s4,0x6
    80002be8:	444a0a13          	addi	s4,s4,1092 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002bec:	00015997          	auipc	s3,0x15
    80002bf0:	fd498993          	addi	s3,s3,-44 # 80017bc0 <tickslock>
    80002bf4:	a029                	j	80002bfe <reparent+0x34>
    80002bf6:	19048493          	addi	s1,s1,400
    80002bfa:	01348d63          	beq	s1,s3,80002c14 <reparent+0x4a>
    if(pp->parent == p){
    80002bfe:	68bc                	ld	a5,80(s1)
    80002c00:	ff279be3          	bne	a5,s2,80002bf6 <reparent+0x2c>
      pp->parent = initproc;
    80002c04:	000a3503          	ld	a0,0(s4)
    80002c08:	e8a8                	sd	a0,80(s1)
      wakeup(initproc);
    80002c0a:	00000097          	auipc	ra,0x0
    80002c0e:	db8080e7          	jalr	-584(ra) # 800029c2 <wakeup>
    80002c12:	b7d5                	j	80002bf6 <reparent+0x2c>
}
    80002c14:	70a2                	ld	ra,40(sp)
    80002c16:	7402                	ld	s0,32(sp)
    80002c18:	64e2                	ld	s1,24(sp)
    80002c1a:	6942                	ld	s2,16(sp)
    80002c1c:	69a2                	ld	s3,8(sp)
    80002c1e:	6a02                	ld	s4,0(sp)
    80002c20:	6145                	addi	sp,sp,48
    80002c22:	8082                	ret

0000000080002c24 <exit>:
{
    80002c24:	7179                	addi	sp,sp,-48
    80002c26:	f406                	sd	ra,40(sp)
    80002c28:	f022                	sd	s0,32(sp)
    80002c2a:	ec26                	sd	s1,24(sp)
    80002c2c:	e84a                	sd	s2,16(sp)
    80002c2e:	e44e                	sd	s3,8(sp)
    80002c30:	e052                	sd	s4,0(sp)
    80002c32:	1800                	addi	s0,sp,48
    80002c34:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002c36:	fffff097          	auipc	ra,0xfffff
    80002c3a:	36a080e7          	jalr	874(ra) # 80001fa0 <myproc>
    80002c3e:	89aa                	mv	s3,a0
  if(p == initproc)
    80002c40:	00006797          	auipc	a5,0x6
    80002c44:	3e87b783          	ld	a5,1000(a5) # 80009028 <initproc>
    80002c48:	0e850493          	addi	s1,a0,232
    80002c4c:	16850913          	addi	s2,a0,360
    80002c50:	02a79363          	bne	a5,a0,80002c76 <exit+0x52>
    panic("init exiting");
    80002c54:	00005517          	auipc	a0,0x5
    80002c58:	64c50513          	addi	a0,a0,1612 # 800082a0 <digits+0x260>
    80002c5c:	ffffe097          	auipc	ra,0xffffe
    80002c60:	8e2080e7          	jalr	-1822(ra) # 8000053e <panic>
      fileclose(f);
    80002c64:	00002097          	auipc	ra,0x2
    80002c68:	4ee080e7          	jalr	1262(ra) # 80005152 <fileclose>
      p->ofile[fd] = 0;
    80002c6c:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002c70:	04a1                	addi	s1,s1,8
    80002c72:	01248563          	beq	s1,s2,80002c7c <exit+0x58>
    if(p->ofile[fd]){
    80002c76:	6088                	ld	a0,0(s1)
    80002c78:	f575                	bnez	a0,80002c64 <exit+0x40>
    80002c7a:	bfdd                	j	80002c70 <exit+0x4c>
  begin_op();
    80002c7c:	00002097          	auipc	ra,0x2
    80002c80:	00a080e7          	jalr	10(ra) # 80004c86 <begin_op>
  iput(p->cwd);
    80002c84:	1689b503          	ld	a0,360(s3)
    80002c88:	00001097          	auipc	ra,0x1
    80002c8c:	7e6080e7          	jalr	2022(ra) # 8000446e <iput>
  end_op();
    80002c90:	00002097          	auipc	ra,0x2
    80002c94:	076080e7          	jalr	118(ra) # 80004d06 <end_op>
  p->cwd = 0;
    80002c98:	1609b423          	sd	zero,360(s3)
  acquire(&wait_lock);
    80002c9c:	0000e497          	auipc	s1,0xe
    80002ca0:	70c48493          	addi	s1,s1,1804 # 800113a8 <wait_lock>
    80002ca4:	8526                	mv	a0,s1
    80002ca6:	ffffe097          	auipc	ra,0xffffe
    80002caa:	f3e080e7          	jalr	-194(ra) # 80000be4 <acquire>
  reparent(p);
    80002cae:	854e                	mv	a0,s3
    80002cb0:	00000097          	auipc	ra,0x0
    80002cb4:	f1a080e7          	jalr	-230(ra) # 80002bca <reparent>
  wakeup(p->parent);
    80002cb8:	0509b503          	ld	a0,80(s3)
    80002cbc:	00000097          	auipc	ra,0x0
    80002cc0:	d06080e7          	jalr	-762(ra) # 800029c2 <wakeup>
  acquire(&p->lock);
    80002cc4:	854e                	mv	a0,s3
    80002cc6:	ffffe097          	auipc	ra,0xffffe
    80002cca:	f1e080e7          	jalr	-226(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002cce:	0549a223          	sw	s4,68(s3)
  p->state = ZOMBIE;
    80002cd2:	4795                	li	a5,5
    80002cd4:	02f9a823          	sw	a5,48(s3)
  p->affiliated_cpu = 0;
    80002cd8:	1809a423          	sw	zero,392(s3)
  add_link(&zombie_list, p->proc_index, 0);
    80002cdc:	4601                	li	a2,0
    80002cde:	1849a583          	lw	a1,388(s3)
    80002ce2:	0000e517          	auipc	a0,0xe
    80002ce6:	68650513          	addi	a0,a0,1670 # 80011368 <zombie_list>
    80002cea:	fffff097          	auipc	ra,0xfffff
    80002cee:	f20080e7          	jalr	-224(ra) # 80001c0a <add_link>
  release(&wait_lock);
    80002cf2:	8526                	mv	a0,s1
    80002cf4:	ffffe097          	auipc	ra,0xffffe
    80002cf8:	fa4080e7          	jalr	-92(ra) # 80000c98 <release>
  sched();
    80002cfc:	00000097          	auipc	ra,0x0
    80002d00:	9ee080e7          	jalr	-1554(ra) # 800026ea <sched>
  panic("zombie exit");
    80002d04:	00005517          	auipc	a0,0x5
    80002d08:	5ac50513          	addi	a0,a0,1452 # 800082b0 <digits+0x270>
    80002d0c:	ffffe097          	auipc	ra,0xffffe
    80002d10:	832080e7          	jalr	-1998(ra) # 8000053e <panic>

0000000080002d14 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002d14:	7179                	addi	sp,sp,-48
    80002d16:	f406                	sd	ra,40(sp)
    80002d18:	f022                	sd	s0,32(sp)
    80002d1a:	ec26                	sd	s1,24(sp)
    80002d1c:	e84a                	sd	s2,16(sp)
    80002d1e:	e44e                	sd	s3,8(sp)
    80002d20:	1800                	addi	s0,sp,48
    80002d22:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002d24:	0000f497          	auipc	s1,0xf
    80002d28:	a9c48493          	addi	s1,s1,-1380 # 800117c0 <proc>
    80002d2c:	00015997          	auipc	s3,0x15
    80002d30:	e9498993          	addi	s3,s3,-364 # 80017bc0 <tickslock>
    acquire(&p->lock);
    80002d34:	8526                	mv	a0,s1
    80002d36:	ffffe097          	auipc	ra,0xffffe
    80002d3a:	eae080e7          	jalr	-338(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    80002d3e:	44bc                	lw	a5,72(s1)
    80002d40:	01278d63          	beq	a5,s2,80002d5a <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002d44:	8526                	mv	a0,s1
    80002d46:	ffffe097          	auipc	ra,0xffffe
    80002d4a:	f52080e7          	jalr	-174(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002d4e:	19048493          	addi	s1,s1,400
    80002d52:	ff3491e3          	bne	s1,s3,80002d34 <kill+0x20>
  }
  return -1;
    80002d56:	557d                	li	a0,-1
    80002d58:	a829                	j	80002d72 <kill+0x5e>
      p->killed = 1;
    80002d5a:	4785                	li	a5,1
    80002d5c:	c0bc                	sw	a5,64(s1)
      if(p->state == SLEEPING){
    80002d5e:	5898                	lw	a4,48(s1)
    80002d60:	4789                	li	a5,2
    80002d62:	00f70f63          	beq	a4,a5,80002d80 <kill+0x6c>
      release(&p->lock);
    80002d66:	8526                	mv	a0,s1
    80002d68:	ffffe097          	auipc	ra,0xffffe
    80002d6c:	f30080e7          	jalr	-208(ra) # 80000c98 <release>
      return 0;
    80002d70:	4501                	li	a0,0
}
    80002d72:	70a2                	ld	ra,40(sp)
    80002d74:	7402                	ld	s0,32(sp)
    80002d76:	64e2                	ld	s1,24(sp)
    80002d78:	6942                	ld	s2,16(sp)
    80002d7a:	69a2                	ld	s3,8(sp)
    80002d7c:	6145                	addi	sp,sp,48
    80002d7e:	8082                	ret
        p->state = RUNNABLE;
    80002d80:	478d                	li	a5,3
    80002d82:	d89c                	sw	a5,48(s1)
    80002d84:	b7cd                	j	80002d66 <kill+0x52>

0000000080002d86 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002d86:	7179                	addi	sp,sp,-48
    80002d88:	f406                	sd	ra,40(sp)
    80002d8a:	f022                	sd	s0,32(sp)
    80002d8c:	ec26                	sd	s1,24(sp)
    80002d8e:	e84a                	sd	s2,16(sp)
    80002d90:	e44e                	sd	s3,8(sp)
    80002d92:	e052                	sd	s4,0(sp)
    80002d94:	1800                	addi	s0,sp,48
    80002d96:	84aa                	mv	s1,a0
    80002d98:	892e                	mv	s2,a1
    80002d9a:	89b2                	mv	s3,a2
    80002d9c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002d9e:	fffff097          	auipc	ra,0xfffff
    80002da2:	202080e7          	jalr	514(ra) # 80001fa0 <myproc>
  if(user_dst){
    80002da6:	c08d                	beqz	s1,80002dc8 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002da8:	86d2                	mv	a3,s4
    80002daa:	864e                	mv	a2,s3
    80002dac:	85ca                	mv	a1,s2
    80002dae:	7528                	ld	a0,104(a0)
    80002db0:	fffff097          	auipc	ra,0xfffff
    80002db4:	8c2080e7          	jalr	-1854(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002db8:	70a2                	ld	ra,40(sp)
    80002dba:	7402                	ld	s0,32(sp)
    80002dbc:	64e2                	ld	s1,24(sp)
    80002dbe:	6942                	ld	s2,16(sp)
    80002dc0:	69a2                	ld	s3,8(sp)
    80002dc2:	6a02                	ld	s4,0(sp)
    80002dc4:	6145                	addi	sp,sp,48
    80002dc6:	8082                	ret
    memmove((char *)dst, src, len);
    80002dc8:	000a061b          	sext.w	a2,s4
    80002dcc:	85ce                	mv	a1,s3
    80002dce:	854a                	mv	a0,s2
    80002dd0:	ffffe097          	auipc	ra,0xffffe
    80002dd4:	f70080e7          	jalr	-144(ra) # 80000d40 <memmove>
    return 0;
    80002dd8:	8526                	mv	a0,s1
    80002dda:	bff9                	j	80002db8 <either_copyout+0x32>

0000000080002ddc <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002ddc:	7179                	addi	sp,sp,-48
    80002dde:	f406                	sd	ra,40(sp)
    80002de0:	f022                	sd	s0,32(sp)
    80002de2:	ec26                	sd	s1,24(sp)
    80002de4:	e84a                	sd	s2,16(sp)
    80002de6:	e44e                	sd	s3,8(sp)
    80002de8:	e052                	sd	s4,0(sp)
    80002dea:	1800                	addi	s0,sp,48
    80002dec:	892a                	mv	s2,a0
    80002dee:	84ae                	mv	s1,a1
    80002df0:	89b2                	mv	s3,a2
    80002df2:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002df4:	fffff097          	auipc	ra,0xfffff
    80002df8:	1ac080e7          	jalr	428(ra) # 80001fa0 <myproc>
  if(user_src){
    80002dfc:	c08d                	beqz	s1,80002e1e <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002dfe:	86d2                	mv	a3,s4
    80002e00:	864e                	mv	a2,s3
    80002e02:	85ca                	mv	a1,s2
    80002e04:	7528                	ld	a0,104(a0)
    80002e06:	fffff097          	auipc	ra,0xfffff
    80002e0a:	8f8080e7          	jalr	-1800(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002e0e:	70a2                	ld	ra,40(sp)
    80002e10:	7402                	ld	s0,32(sp)
    80002e12:	64e2                	ld	s1,24(sp)
    80002e14:	6942                	ld	s2,16(sp)
    80002e16:	69a2                	ld	s3,8(sp)
    80002e18:	6a02                	ld	s4,0(sp)
    80002e1a:	6145                	addi	sp,sp,48
    80002e1c:	8082                	ret
    memmove(dst, (char*)src, len);
    80002e1e:	000a061b          	sext.w	a2,s4
    80002e22:	85ce                	mv	a1,s3
    80002e24:	854a                	mv	a0,s2
    80002e26:	ffffe097          	auipc	ra,0xffffe
    80002e2a:	f1a080e7          	jalr	-230(ra) # 80000d40 <memmove>
    return 0;
    80002e2e:	8526                	mv	a0,s1
    80002e30:	bff9                	j	80002e0e <either_copyin+0x32>

0000000080002e32 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002e32:	715d                	addi	sp,sp,-80
    80002e34:	e486                	sd	ra,72(sp)
    80002e36:	e0a2                	sd	s0,64(sp)
    80002e38:	fc26                	sd	s1,56(sp)
    80002e3a:	f84a                	sd	s2,48(sp)
    80002e3c:	f44e                	sd	s3,40(sp)
    80002e3e:	f052                	sd	s4,32(sp)
    80002e40:	ec56                	sd	s5,24(sp)
    80002e42:	e85a                	sd	s6,16(sp)
    80002e44:	e45e                	sd	s7,8(sp)
    80002e46:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002e48:	00005517          	auipc	a0,0x5
    80002e4c:	4c050513          	addi	a0,a0,1216 # 80008308 <digits+0x2c8>
    80002e50:	ffffd097          	auipc	ra,0xffffd
    80002e54:	738080e7          	jalr	1848(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002e58:	0000f497          	auipc	s1,0xf
    80002e5c:	ad848493          	addi	s1,s1,-1320 # 80011930 <proc+0x170>
    80002e60:	00015917          	auipc	s2,0x15
    80002e64:	ed090913          	addi	s2,s2,-304 # 80017d30 <bcache+0x158>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002e68:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002e6a:	00005997          	auipc	s3,0x5
    80002e6e:	45698993          	addi	s3,s3,1110 # 800082c0 <digits+0x280>
    printf("%d %s %s", p->pid, state, p->name);
    80002e72:	00005a97          	auipc	s5,0x5
    80002e76:	456a8a93          	addi	s5,s5,1110 # 800082c8 <digits+0x288>
    printf("\n");
    80002e7a:	00005a17          	auipc	s4,0x5
    80002e7e:	48ea0a13          	addi	s4,s4,1166 # 80008308 <digits+0x2c8>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002e82:	00005b97          	auipc	s7,0x5
    80002e86:	4c6b8b93          	addi	s7,s7,1222 # 80008348 <states.1804>
    80002e8a:	a00d                	j	80002eac <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002e8c:	ed86a583          	lw	a1,-296(a3)
    80002e90:	8556                	mv	a0,s5
    80002e92:	ffffd097          	auipc	ra,0xffffd
    80002e96:	6f6080e7          	jalr	1782(ra) # 80000588 <printf>
    printf("\n");
    80002e9a:	8552                	mv	a0,s4
    80002e9c:	ffffd097          	auipc	ra,0xffffd
    80002ea0:	6ec080e7          	jalr	1772(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002ea4:	19048493          	addi	s1,s1,400
    80002ea8:	03248163          	beq	s1,s2,80002eca <procdump+0x98>
    if(p->state == UNUSED)
    80002eac:	86a6                	mv	a3,s1
    80002eae:	ec04a783          	lw	a5,-320(s1)
    80002eb2:	dbed                	beqz	a5,80002ea4 <procdump+0x72>
      state = "???";
    80002eb4:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002eb6:	fcfb6be3          	bltu	s6,a5,80002e8c <procdump+0x5a>
    80002eba:	1782                	slli	a5,a5,0x20
    80002ebc:	9381                	srli	a5,a5,0x20
    80002ebe:	078e                	slli	a5,a5,0x3
    80002ec0:	97de                	add	a5,a5,s7
    80002ec2:	6390                	ld	a2,0(a5)
    80002ec4:	f661                	bnez	a2,80002e8c <procdump+0x5a>
      state = "???";
    80002ec6:	864e                	mv	a2,s3
    80002ec8:	b7d1                	j	80002e8c <procdump+0x5a>
  }
}
    80002eca:	60a6                	ld	ra,72(sp)
    80002ecc:	6406                	ld	s0,64(sp)
    80002ece:	74e2                	ld	s1,56(sp)
    80002ed0:	7942                	ld	s2,48(sp)
    80002ed2:	79a2                	ld	s3,40(sp)
    80002ed4:	7a02                	ld	s4,32(sp)
    80002ed6:	6ae2                	ld	s5,24(sp)
    80002ed8:	6b42                	ld	s6,16(sp)
    80002eda:	6ba2                	ld	s7,8(sp)
    80002edc:	6161                	addi	sp,sp,80
    80002ede:	8082                	ret

0000000080002ee0 <wakeup2>:
{
    80002ee0:	7159                	addi	sp,sp,-112
    80002ee2:	f486                	sd	ra,104(sp)
    80002ee4:	f0a2                	sd	s0,96(sp)
    80002ee6:	eca6                	sd	s1,88(sp)
    80002ee8:	e8ca                	sd	s2,80(sp)
    80002eea:	e4ce                	sd	s3,72(sp)
    80002eec:	e0d2                	sd	s4,64(sp)
    80002eee:	fc56                	sd	s5,56(sp)
    80002ef0:	f85a                	sd	s6,48(sp)
    80002ef2:	f45e                	sd	s7,40(sp)
    80002ef4:	f062                	sd	s8,32(sp)
    80002ef6:	ec66                	sd	s9,24(sp)
    80002ef8:	e86a                	sd	s10,16(sp)
    80002efa:	e46e                	sd	s11,8(sp)
    80002efc:	1880                	addi	s0,sp,112
    80002efe:	8b2a                	mv	s6,a0
  acquire(&sleeping_list.head_lock);
    80002f00:	0000e517          	auipc	a0,0xe
    80002f04:	44850513          	addi	a0,a0,1096 # 80011348 <sleeping_list+0x8>
    80002f08:	ffffe097          	auipc	ra,0xffffe
    80002f0c:	cdc080e7          	jalr	-804(ra) # 80000be4 <acquire>
  if (sleeping_list.head == -1){
    80002f10:	0000e797          	auipc	a5,0xe
    80002f14:	4307a783          	lw	a5,1072(a5) # 80011340 <sleeping_list>
    80002f18:	577d                	li	a4,-1
    80002f1a:	0ae78c63          	beq	a5,a4,80002fd2 <wakeup2+0xf2>
  acquire(&proc[sleeping_list.head].list_lock);
    80002f1e:	19000913          	li	s2,400
    80002f22:	032787b3          	mul	a5,a5,s2
    80002f26:	01878513          	addi	a0,a5,24
    80002f2a:	0000f997          	auipc	s3,0xf
    80002f2e:	89698993          	addi	s3,s3,-1898 # 800117c0 <proc>
    80002f32:	954e                	add	a0,a0,s3
    80002f34:	ffffe097          	auipc	ra,0xffffe
    80002f38:	cb0080e7          	jalr	-848(ra) # 80000be4 <acquire>
  p = &proc[sleeping_list.head];
    80002f3c:	0000e497          	auipc	s1,0xe
    80002f40:	4044a483          	lw	s1,1028(s1) # 80011340 <sleeping_list>
    80002f44:	03248933          	mul	s2,s1,s2
    80002f48:	994e                	add	s2,s2,s3
  acquire(&p->lock);
    80002f4a:	854a                	mv	a0,s2
    80002f4c:	ffffe097          	auipc	ra,0xffffe
    80002f50:	c98080e7          	jalr	-872(ra) # 80000be4 <acquire>
  if(p!=myproc()&&p->chan == chan) {
    80002f54:	fffff097          	auipc	ra,0xfffff
    80002f58:	04c080e7          	jalr	76(ra) # 80001fa0 <myproc>
    80002f5c:	00a90663          	beq	s2,a0,80002f68 <wakeup2+0x88>
    80002f60:	03893783          	ld	a5,56(s2)
    80002f64:	09678c63          	beq	a5,s6,80002ffc <wakeup2+0x11c>
        release(&sleeping_list.head_lock);
    80002f68:	0000e517          	auipc	a0,0xe
    80002f6c:	3e050513          	addi	a0,a0,992 # 80011348 <sleeping_list+0x8>
    80002f70:	ffffe097          	auipc	ra,0xffffe
    80002f74:	d28080e7          	jalr	-728(ra) # 80000c98 <release>
        release(&proc[sleeping_list.head].list_lock);
    80002f78:	0000e797          	auipc	a5,0xe
    80002f7c:	3c87a783          	lw	a5,968(a5) # 80011340 <sleeping_list>
    80002f80:	19000513          	li	a0,400
    80002f84:	02a787b3          	mul	a5,a5,a0
    80002f88:	0000f517          	auipc	a0,0xf
    80002f8c:	85050513          	addi	a0,a0,-1968 # 800117d8 <proc+0x18>
    80002f90:	953e                	add	a0,a0,a5
    80002f92:	ffffe097          	auipc	ra,0xffffe
    80002f96:	d06080e7          	jalr	-762(ra) # 80000c98 <release>
  release(&p->lock);
    80002f9a:	854a                	mv	a0,s2
    80002f9c:	ffffe097          	auipc	ra,0xffffe
    80002fa0:	cfc080e7          	jalr	-772(ra) # 80000c98 <release>
  printf("exiting wakeup\n");
    80002fa4:	00005517          	auipc	a0,0x5
    80002fa8:	36c50513          	addi	a0,a0,876 # 80008310 <digits+0x2d0>
    80002fac:	ffffd097          	auipc	ra,0xffffd
    80002fb0:	5dc080e7          	jalr	1500(ra) # 80000588 <printf>
}
    80002fb4:	70a6                	ld	ra,104(sp)
    80002fb6:	7406                	ld	s0,96(sp)
    80002fb8:	64e6                	ld	s1,88(sp)
    80002fba:	6946                	ld	s2,80(sp)
    80002fbc:	69a6                	ld	s3,72(sp)
    80002fbe:	6a06                	ld	s4,64(sp)
    80002fc0:	7ae2                	ld	s5,56(sp)
    80002fc2:	7b42                	ld	s6,48(sp)
    80002fc4:	7ba2                	ld	s7,40(sp)
    80002fc6:	7c02                	ld	s8,32(sp)
    80002fc8:	6ce2                	ld	s9,24(sp)
    80002fca:	6d42                	ld	s10,16(sp)
    80002fcc:	6da2                	ld	s11,8(sp)
    80002fce:	6165                	addi	sp,sp,112
    80002fd0:	8082                	ret
    printf("sleeping list is empty\n");
    80002fd2:	00005517          	auipc	a0,0x5
    80002fd6:	30650513          	addi	a0,a0,774 # 800082d8 <digits+0x298>
    80002fda:	ffffd097          	auipc	ra,0xffffd
    80002fde:	5ae080e7          	jalr	1454(ra) # 80000588 <printf>
    release(&sleeping_list.head_lock);
    80002fe2:	0000e517          	auipc	a0,0xe
    80002fe6:	36650513          	addi	a0,a0,870 # 80011348 <sleeping_list+0x8>
    80002fea:	ffffe097          	auipc	ra,0xffffe
    80002fee:	cae080e7          	jalr	-850(ra) # 80000c98 <release>
    procdump();
    80002ff2:	00000097          	auipc	ra,0x0
    80002ff6:	e40080e7          	jalr	-448(ra) # 80002e32 <procdump>
    return;
    80002ffa:	bf6d                	j	80002fb4 <wakeup2+0xd4>
        printf("waking up proc number %d\n", p->pid);
    80002ffc:	8ace                	mv	s5,s3
    80002ffe:	19000b93          	li	s7,400
    80003002:	04892583          	lw	a1,72(s2)
    80003006:	00005517          	auipc	a0,0x5
    8000300a:	2ea50513          	addi	a0,a0,746 # 800082f0 <digits+0x2b0>
    8000300e:	ffffd097          	auipc	ra,0xffffd
    80003012:	57a080e7          	jalr	1402(ra) # 80000588 <printf>
        p->state = RUNNABLE;
    80003016:	478d                	li	a5,3
    80003018:	02f92823          	sw	a5,48(s2)
        next_link_index = p->next_proc_index;
    8000301c:	18092983          	lw	s3,384(s2)
        release(&sleeping_list.head_lock);
    80003020:	0000ea17          	auipc	s4,0xe
    80003024:	280a0a13          	addi	s4,s4,640 # 800112a0 <runnable_cpu_lists>
    80003028:	0000e517          	auipc	a0,0xe
    8000302c:	32050513          	addi	a0,a0,800 # 80011348 <sleeping_list+0x8>
    80003030:	ffffe097          	auipc	ra,0xffffe
    80003034:	c68080e7          	jalr	-920(ra) # 80000c98 <release>
        release(&proc[sleeping_list.head].list_lock);
    80003038:	0a0a2503          	lw	a0,160(s4)
    8000303c:	03750533          	mul	a0,a0,s7
    80003040:	0561                	addi	a0,a0,24
    80003042:	9556                	add	a0,a0,s5
    80003044:	ffffe097          	auipc	ra,0xffffe
    80003048:	c54080e7          	jalr	-940(ra) # 80000c98 <release>
        remove_link(&sleeping_list, p->proc_index);
    8000304c:	18492583          	lw	a1,388(s2)
    80003050:	0000e517          	auipc	a0,0xe
    80003054:	2f050513          	addi	a0,a0,752 # 80011340 <sleeping_list>
    80003058:	fffff097          	auipc	ra,0xfffff
    8000305c:	864080e7          	jalr	-1948(ra) # 800018bc <remove_link>
        add_link(&runnable_cpu_lists[p->affiliated_cpu], p->proc_index, 0);
    80003060:	18892783          	lw	a5,392(s2)
    80003064:	00279513          	slli	a0,a5,0x2
    80003068:	953e                	add	a0,a0,a5
    8000306a:	050e                	slli	a0,a0,0x3
    8000306c:	4601                	li	a2,0
    8000306e:	18492583          	lw	a1,388(s2)
    80003072:	9552                	add	a0,a0,s4
    80003074:	fffff097          	auipc	ra,0xfffff
    80003078:	b96080e7          	jalr	-1130(ra) # 80001c0a <add_link>
  release(&p->lock);
    8000307c:	854a                	mv	a0,s2
    8000307e:	ffffe097          	auipc	ra,0xffffe
    80003082:	c1a080e7          	jalr	-998(ra) # 80000c98 <release>
  while(next_link_index != -1){   // TODO: NOT SAFE!!
    80003086:	57fd                	li	a5,-1
    80003088:	f0f98ee3          	beq	s3,a5,80002fa4 <wakeup2+0xc4>
    8000308c:	19000a93          	li	s5,400
    acquire(&proc[next_link_index].list_lock);
    80003090:	0000ea17          	auipc	s4,0xe
    80003094:	730a0a13          	addi	s4,s4,1840 # 800117c0 <proc>
        p->state = RUNNABLE;
    80003098:	4d0d                	li	s10,3
        remove_link(&sleeping_list, p->proc_index);
    8000309a:	0000ec97          	auipc	s9,0xe
    8000309e:	206c8c93          	addi	s9,s9,518 # 800112a0 <runnable_cpu_lists>
    800030a2:	0000ec17          	auipc	s8,0xe
    800030a6:	29ec0c13          	addi	s8,s8,670 # 80011340 <sleeping_list>
  while(next_link_index != -1){   // TODO: NOT SAFE!!
    800030aa:	5bfd                	li	s7,-1
    800030ac:	a829                	j	800030c6 <wakeup2+0x1e6>
        release(&proc[next_link_index].list_lock);
    800030ae:	854a                	mv	a0,s2
    800030b0:	ffffe097          	auipc	ra,0xffffe
    800030b4:	be8080e7          	jalr	-1048(ra) # 80000c98 <release>
    release(&p->lock);
    800030b8:	8526                	mv	a0,s1
    800030ba:	ffffe097          	auipc	ra,0xffffe
    800030be:	bde080e7          	jalr	-1058(ra) # 80000c98 <release>
  while(next_link_index != -1){   // TODO: NOT SAFE!!
    800030c2:	ef7981e3          	beq	s3,s7,80002fa4 <wakeup2+0xc4>
    acquire(&proc[next_link_index].list_lock);
    800030c6:	035984b3          	mul	s1,s3,s5
    800030ca:	01848913          	addi	s2,s1,24
    800030ce:	9952                	add	s2,s2,s4
    800030d0:	854a                	mv	a0,s2
    800030d2:	ffffe097          	auipc	ra,0xffffe
    800030d6:	b12080e7          	jalr	-1262(ra) # 80000be4 <acquire>
    p = &proc[next_link_index];
    800030da:	94d2                	add	s1,s1,s4
    acquire(&p->lock);
    800030dc:	8526                	mv	a0,s1
    800030de:	ffffe097          	auipc	ra,0xffffe
    800030e2:	b06080e7          	jalr	-1274(ra) # 80000be4 <acquire>
      if(p!=myproc()&&p->chan == chan) {
    800030e6:	fffff097          	auipc	ra,0xfffff
    800030ea:	eba080e7          	jalr	-326(ra) # 80001fa0 <myproc>
    800030ee:	fca480e3          	beq	s1,a0,800030ae <wakeup2+0x1ce>
    800030f2:	7c9c                	ld	a5,56(s1)
    800030f4:	fb679de3          	bne	a5,s6,800030ae <wakeup2+0x1ce>
        p->state = RUNNABLE;
    800030f8:	03a4a823          	sw	s10,48(s1)
        release(&proc[next_link_index].list_lock);
    800030fc:	854a                	mv	a0,s2
    800030fe:	ffffe097          	auipc	ra,0xffffe
    80003102:	b9a080e7          	jalr	-1126(ra) # 80000c98 <release>
        next_link_index = p->next_proc_index;
    80003106:	1804a983          	lw	s3,384(s1)
        remove_link(&sleeping_list, p->proc_index);
    8000310a:	1844a583          	lw	a1,388(s1)
    8000310e:	8562                	mv	a0,s8
    80003110:	ffffe097          	auipc	ra,0xffffe
    80003114:	7ac080e7          	jalr	1964(ra) # 800018bc <remove_link>
        add_link(&runnable_cpu_lists[p->affiliated_cpu], p->proc_index, 0);
    80003118:	1884a783          	lw	a5,392(s1)
    8000311c:	00279513          	slli	a0,a5,0x2
    80003120:	953e                	add	a0,a0,a5
    80003122:	050e                	slli	a0,a0,0x3
    80003124:	4601                	li	a2,0
    80003126:	1844a583          	lw	a1,388(s1)
    8000312a:	9566                	add	a0,a0,s9
    8000312c:	fffff097          	auipc	ra,0xfffff
    80003130:	ade080e7          	jalr	-1314(ra) # 80001c0a <add_link>
    80003134:	b751                	j	800030b8 <wakeup2+0x1d8>

0000000080003136 <set_cpu>:

int set_cpu(int cpu_num){
  if (cpu_num >= current_cpu_number)
    80003136:	4789                	li	a5,2
    80003138:	04a7c463          	blt	a5,a0,80003180 <set_cpu+0x4a>
int set_cpu(int cpu_num){
    8000313c:	1101                	addi	sp,sp,-32
    8000313e:	ec06                	sd	ra,24(sp)
    80003140:	e822                	sd	s0,16(sp)
    80003142:	e426                	sd	s1,8(sp)
    80003144:	e04a                	sd	s2,0(sp)
    80003146:	1000                	addi	s0,sp,32
    80003148:	84aa                	mv	s1,a0
    return -1;
  
  struct proc* my_proc = myproc();
    8000314a:	fffff097          	auipc	ra,0xfffff
    8000314e:	e56080e7          	jalr	-426(ra) # 80001fa0 <myproc>
    80003152:	892a                	mv	s2,a0
  acquire(&my_proc->lock);
    80003154:	ffffe097          	auipc	ra,0xffffe
    80003158:	a90080e7          	jalr	-1392(ra) # 80000be4 <acquire>
  my_proc -> affiliated_cpu = cpu_num; 
    8000315c:	18992423          	sw	s1,392(s2)
  release(&my_proc->lock);
    80003160:	854a                	mv	a0,s2
    80003162:	ffffe097          	auipc	ra,0xffffe
    80003166:	b36080e7          	jalr	-1226(ra) # 80000c98 <release>
  yield();
    8000316a:	fffff097          	auipc	ra,0xfffff
    8000316e:	656080e7          	jalr	1622(ra) # 800027c0 <yield>

  return cpu_num;
    80003172:	8526                	mv	a0,s1

}
    80003174:	60e2                	ld	ra,24(sp)
    80003176:	6442                	ld	s0,16(sp)
    80003178:	64a2                	ld	s1,8(sp)
    8000317a:	6902                	ld	s2,0(sp)
    8000317c:	6105                	addi	sp,sp,32
    8000317e:	8082                	ret
    return -1;
    80003180:	557d                	li	a0,-1
}
    80003182:	8082                	ret

0000000080003184 <get_cpu>:

int get_cpu(void){
    80003184:	1141                	addi	sp,sp,-16
    80003186:	e422                	sd	s0,8(sp)
    80003188:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000318a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000318e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003190:	10079073          	csrw	sstatus,a5
  asm volatile("mv %0, tp" : "=r" (x) );
    80003194:	8512                	mv	a0,tp
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003196:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000319a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000319e:	10079073          	csrw	sstatus,a5
  intr_off();
  int res = cpuid();
  intr_on();
  
  return res;
}
    800031a2:	2501                	sext.w	a0,a0
    800031a4:	6422                	ld	s0,8(sp)
    800031a6:	0141                	addi	sp,sp,16
    800031a8:	8082                	ret

00000000800031aa <cpu_process_count>:

int cpu_process_count(int cpu_num){
    800031aa:	1141                	addi	sp,sp,-16
    800031ac:	e422                	sd	s0,8(sp)
    800031ae:	0800                	addi	s0,sp,16
  if (cpu_num >= current_cpu_number){
    800031b0:	4789                	li	a5,2
    800031b2:	00a7cf63          	blt	a5,a0,800031d0 <cpu_process_count+0x26>
    return -1;
  }
  
  return runnable_cpu_lists[cpu_num].counter;
    800031b6:	00251793          	slli	a5,a0,0x2
    800031ba:	953e                	add	a0,a0,a5
    800031bc:	050e                	slli	a0,a0,0x3
    800031be:	0000e797          	auipc	a5,0xe
    800031c2:	0e278793          	addi	a5,a5,226 # 800112a0 <runnable_cpu_lists>
    800031c6:	953e                	add	a0,a0,a5
    800031c8:	5108                	lw	a0,32(a0)
}
    800031ca:	6422                	ld	s0,8(sp)
    800031cc:	0141                	addi	sp,sp,16
    800031ce:	8082                	ret
    return -1;
    800031d0:	557d                	li	a0,-1
    800031d2:	bfe5                	j	800031ca <cpu_process_count+0x20>

00000000800031d4 <swtch>:
    800031d4:	00153023          	sd	ra,0(a0)
    800031d8:	00253423          	sd	sp,8(a0)
    800031dc:	e900                	sd	s0,16(a0)
    800031de:	ed04                	sd	s1,24(a0)
    800031e0:	03253023          	sd	s2,32(a0)
    800031e4:	03353423          	sd	s3,40(a0)
    800031e8:	03453823          	sd	s4,48(a0)
    800031ec:	03553c23          	sd	s5,56(a0)
    800031f0:	05653023          	sd	s6,64(a0)
    800031f4:	05753423          	sd	s7,72(a0)
    800031f8:	05853823          	sd	s8,80(a0)
    800031fc:	05953c23          	sd	s9,88(a0)
    80003200:	07a53023          	sd	s10,96(a0)
    80003204:	07b53423          	sd	s11,104(a0)
    80003208:	0005b083          	ld	ra,0(a1)
    8000320c:	0085b103          	ld	sp,8(a1)
    80003210:	6980                	ld	s0,16(a1)
    80003212:	6d84                	ld	s1,24(a1)
    80003214:	0205b903          	ld	s2,32(a1)
    80003218:	0285b983          	ld	s3,40(a1)
    8000321c:	0305ba03          	ld	s4,48(a1)
    80003220:	0385ba83          	ld	s5,56(a1)
    80003224:	0405bb03          	ld	s6,64(a1)
    80003228:	0485bb83          	ld	s7,72(a1)
    8000322c:	0505bc03          	ld	s8,80(a1)
    80003230:	0585bc83          	ld	s9,88(a1)
    80003234:	0605bd03          	ld	s10,96(a1)
    80003238:	0685bd83          	ld	s11,104(a1)
    8000323c:	8082                	ret

000000008000323e <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000323e:	1141                	addi	sp,sp,-16
    80003240:	e406                	sd	ra,8(sp)
    80003242:	e022                	sd	s0,0(sp)
    80003244:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80003246:	00005597          	auipc	a1,0x5
    8000324a:	13258593          	addi	a1,a1,306 # 80008378 <states.1804+0x30>
    8000324e:	00015517          	auipc	a0,0x15
    80003252:	97250513          	addi	a0,a0,-1678 # 80017bc0 <tickslock>
    80003256:	ffffe097          	auipc	ra,0xffffe
    8000325a:	8fe080e7          	jalr	-1794(ra) # 80000b54 <initlock>
}
    8000325e:	60a2                	ld	ra,8(sp)
    80003260:	6402                	ld	s0,0(sp)
    80003262:	0141                	addi	sp,sp,16
    80003264:	8082                	ret

0000000080003266 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80003266:	1141                	addi	sp,sp,-16
    80003268:	e422                	sd	s0,8(sp)
    8000326a:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000326c:	00003797          	auipc	a5,0x3
    80003270:	50478793          	addi	a5,a5,1284 # 80006770 <kernelvec>
    80003274:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80003278:	6422                	ld	s0,8(sp)
    8000327a:	0141                	addi	sp,sp,16
    8000327c:	8082                	ret

000000008000327e <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000327e:	1141                	addi	sp,sp,-16
    80003280:	e406                	sd	ra,8(sp)
    80003282:	e022                	sd	s0,0(sp)
    80003284:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80003286:	fffff097          	auipc	ra,0xfffff
    8000328a:	d1a080e7          	jalr	-742(ra) # 80001fa0 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000328e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80003292:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003294:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80003298:	00004617          	auipc	a2,0x4
    8000329c:	d6860613          	addi	a2,a2,-664 # 80007000 <_trampoline>
    800032a0:	00004697          	auipc	a3,0x4
    800032a4:	d6068693          	addi	a3,a3,-672 # 80007000 <_trampoline>
    800032a8:	8e91                	sub	a3,a3,a2
    800032aa:	040007b7          	lui	a5,0x4000
    800032ae:	17fd                	addi	a5,a5,-1
    800032b0:	07b2                	slli	a5,a5,0xc
    800032b2:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800032b4:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800032b8:	7938                	ld	a4,112(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800032ba:	180026f3          	csrr	a3,satp
    800032be:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800032c0:	7938                	ld	a4,112(a0)
    800032c2:	6d34                	ld	a3,88(a0)
    800032c4:	6585                	lui	a1,0x1
    800032c6:	96ae                	add	a3,a3,a1
    800032c8:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800032ca:	7938                	ld	a4,112(a0)
    800032cc:	00000697          	auipc	a3,0x0
    800032d0:	13868693          	addi	a3,a3,312 # 80003404 <usertrap>
    800032d4:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800032d6:	7938                	ld	a4,112(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800032d8:	8692                	mv	a3,tp
    800032da:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800032dc:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800032e0:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800032e4:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800032e8:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800032ec:	7938                	ld	a4,112(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800032ee:	6f18                	ld	a4,24(a4)
    800032f0:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800032f4:	752c                	ld	a1,104(a0)
    800032f6:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800032f8:	00004717          	auipc	a4,0x4
    800032fc:	d9870713          	addi	a4,a4,-616 # 80007090 <userret>
    80003300:	8f11                	sub	a4,a4,a2
    80003302:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80003304:	577d                	li	a4,-1
    80003306:	177e                	slli	a4,a4,0x3f
    80003308:	8dd9                	or	a1,a1,a4
    8000330a:	02000537          	lui	a0,0x2000
    8000330e:	157d                	addi	a0,a0,-1
    80003310:	0536                	slli	a0,a0,0xd
    80003312:	9782                	jalr	a5
}
    80003314:	60a2                	ld	ra,8(sp)
    80003316:	6402                	ld	s0,0(sp)
    80003318:	0141                	addi	sp,sp,16
    8000331a:	8082                	ret

000000008000331c <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000331c:	1101                	addi	sp,sp,-32
    8000331e:	ec06                	sd	ra,24(sp)
    80003320:	e822                	sd	s0,16(sp)
    80003322:	e426                	sd	s1,8(sp)
    80003324:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80003326:	00015497          	auipc	s1,0x15
    8000332a:	89a48493          	addi	s1,s1,-1894 # 80017bc0 <tickslock>
    8000332e:	8526                	mv	a0,s1
    80003330:	ffffe097          	auipc	ra,0xffffe
    80003334:	8b4080e7          	jalr	-1868(ra) # 80000be4 <acquire>
  ticks++;
    80003338:	00006517          	auipc	a0,0x6
    8000333c:	cf850513          	addi	a0,a0,-776 # 80009030 <ticks>
    80003340:	411c                	lw	a5,0(a0)
    80003342:	2785                	addiw	a5,a5,1
    80003344:	c11c                	sw	a5,0(a0)
  //printf("clockintr\n");
  wakeup(&ticks);
    80003346:	fffff097          	auipc	ra,0xfffff
    8000334a:	67c080e7          	jalr	1660(ra) # 800029c2 <wakeup>
  release(&tickslock);
    8000334e:	8526                	mv	a0,s1
    80003350:	ffffe097          	auipc	ra,0xffffe
    80003354:	948080e7          	jalr	-1720(ra) # 80000c98 <release>
}
    80003358:	60e2                	ld	ra,24(sp)
    8000335a:	6442                	ld	s0,16(sp)
    8000335c:	64a2                	ld	s1,8(sp)
    8000335e:	6105                	addi	sp,sp,32
    80003360:	8082                	ret

0000000080003362 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80003362:	1101                	addi	sp,sp,-32
    80003364:	ec06                	sd	ra,24(sp)
    80003366:	e822                	sd	s0,16(sp)
    80003368:	e426                	sd	s1,8(sp)
    8000336a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000336c:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80003370:	00074d63          	bltz	a4,8000338a <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80003374:	57fd                	li	a5,-1
    80003376:	17fe                	slli	a5,a5,0x3f
    80003378:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000337a:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000337c:	06f70363          	beq	a4,a5,800033e2 <devintr+0x80>
  }
}
    80003380:	60e2                	ld	ra,24(sp)
    80003382:	6442                	ld	s0,16(sp)
    80003384:	64a2                	ld	s1,8(sp)
    80003386:	6105                	addi	sp,sp,32
    80003388:	8082                	ret
     (scause & 0xff) == 9){
    8000338a:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    8000338e:	46a5                	li	a3,9
    80003390:	fed792e3          	bne	a5,a3,80003374 <devintr+0x12>
    int irq = plic_claim();
    80003394:	00003097          	auipc	ra,0x3
    80003398:	4e4080e7          	jalr	1252(ra) # 80006878 <plic_claim>
    8000339c:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000339e:	47a9                	li	a5,10
    800033a0:	02f50763          	beq	a0,a5,800033ce <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800033a4:	4785                	li	a5,1
    800033a6:	02f50963          	beq	a0,a5,800033d8 <devintr+0x76>
    return 1;
    800033aa:	4505                	li	a0,1
    } else if(irq){
    800033ac:	d8f1                	beqz	s1,80003380 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800033ae:	85a6                	mv	a1,s1
    800033b0:	00005517          	auipc	a0,0x5
    800033b4:	fd050513          	addi	a0,a0,-48 # 80008380 <states.1804+0x38>
    800033b8:	ffffd097          	auipc	ra,0xffffd
    800033bc:	1d0080e7          	jalr	464(ra) # 80000588 <printf>
      plic_complete(irq);
    800033c0:	8526                	mv	a0,s1
    800033c2:	00003097          	auipc	ra,0x3
    800033c6:	4da080e7          	jalr	1242(ra) # 8000689c <plic_complete>
    return 1;
    800033ca:	4505                	li	a0,1
    800033cc:	bf55                	j	80003380 <devintr+0x1e>
      uartintr();
    800033ce:	ffffd097          	auipc	ra,0xffffd
    800033d2:	5da080e7          	jalr	1498(ra) # 800009a8 <uartintr>
    800033d6:	b7ed                	j	800033c0 <devintr+0x5e>
      virtio_disk_intr();
    800033d8:	00004097          	auipc	ra,0x4
    800033dc:	9a4080e7          	jalr	-1628(ra) # 80006d7c <virtio_disk_intr>
    800033e0:	b7c5                	j	800033c0 <devintr+0x5e>
    if(cpuid() == 0){
    800033e2:	fffff097          	auipc	ra,0xfffff
    800033e6:	b92080e7          	jalr	-1134(ra) # 80001f74 <cpuid>
    800033ea:	c901                	beqz	a0,800033fa <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800033ec:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800033f0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800033f2:	14479073          	csrw	sip,a5
    return 2;
    800033f6:	4509                	li	a0,2
    800033f8:	b761                	j	80003380 <devintr+0x1e>
      clockintr();
    800033fa:	00000097          	auipc	ra,0x0
    800033fe:	f22080e7          	jalr	-222(ra) # 8000331c <clockintr>
    80003402:	b7ed                	j	800033ec <devintr+0x8a>

0000000080003404 <usertrap>:
{
    80003404:	1101                	addi	sp,sp,-32
    80003406:	ec06                	sd	ra,24(sp)
    80003408:	e822                	sd	s0,16(sp)
    8000340a:	e426                	sd	s1,8(sp)
    8000340c:	e04a                	sd	s2,0(sp)
    8000340e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003410:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80003414:	1007f793          	andi	a5,a5,256
    80003418:	e3ad                	bnez	a5,8000347a <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000341a:	00003797          	auipc	a5,0x3
    8000341e:	35678793          	addi	a5,a5,854 # 80006770 <kernelvec>
    80003422:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80003426:	fffff097          	auipc	ra,0xfffff
    8000342a:	b7a080e7          	jalr	-1158(ra) # 80001fa0 <myproc>
    8000342e:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80003430:	793c                	ld	a5,112(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003432:	14102773          	csrr	a4,sepc
    80003436:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003438:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    8000343c:	47a1                	li	a5,8
    8000343e:	04f71c63          	bne	a4,a5,80003496 <usertrap+0x92>
    if(p->killed)
    80003442:	413c                	lw	a5,64(a0)
    80003444:	e3b9                	bnez	a5,8000348a <usertrap+0x86>
    p->trapframe->epc += 4;
    80003446:	78b8                	ld	a4,112(s1)
    80003448:	6f1c                	ld	a5,24(a4)
    8000344a:	0791                	addi	a5,a5,4
    8000344c:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000344e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80003452:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003456:	10079073          	csrw	sstatus,a5
    syscall();
    8000345a:	00000097          	auipc	ra,0x0
    8000345e:	2e0080e7          	jalr	736(ra) # 8000373a <syscall>
  if(p->killed)
    80003462:	40bc                	lw	a5,64(s1)
    80003464:	ebc1                	bnez	a5,800034f4 <usertrap+0xf0>
  usertrapret();
    80003466:	00000097          	auipc	ra,0x0
    8000346a:	e18080e7          	jalr	-488(ra) # 8000327e <usertrapret>
}
    8000346e:	60e2                	ld	ra,24(sp)
    80003470:	6442                	ld	s0,16(sp)
    80003472:	64a2                	ld	s1,8(sp)
    80003474:	6902                	ld	s2,0(sp)
    80003476:	6105                	addi	sp,sp,32
    80003478:	8082                	ret
    panic("usertrap: not from user mode");
    8000347a:	00005517          	auipc	a0,0x5
    8000347e:	f2650513          	addi	a0,a0,-218 # 800083a0 <states.1804+0x58>
    80003482:	ffffd097          	auipc	ra,0xffffd
    80003486:	0bc080e7          	jalr	188(ra) # 8000053e <panic>
      exit(-1);
    8000348a:	557d                	li	a0,-1
    8000348c:	fffff097          	auipc	ra,0xfffff
    80003490:	798080e7          	jalr	1944(ra) # 80002c24 <exit>
    80003494:	bf4d                	j	80003446 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80003496:	00000097          	auipc	ra,0x0
    8000349a:	ecc080e7          	jalr	-308(ra) # 80003362 <devintr>
    8000349e:	892a                	mv	s2,a0
    800034a0:	c501                	beqz	a0,800034a8 <usertrap+0xa4>
  if(p->killed)
    800034a2:	40bc                	lw	a5,64(s1)
    800034a4:	c3a1                	beqz	a5,800034e4 <usertrap+0xe0>
    800034a6:	a815                	j	800034da <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800034a8:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800034ac:	44b0                	lw	a2,72(s1)
    800034ae:	00005517          	auipc	a0,0x5
    800034b2:	f1250513          	addi	a0,a0,-238 # 800083c0 <states.1804+0x78>
    800034b6:	ffffd097          	auipc	ra,0xffffd
    800034ba:	0d2080e7          	jalr	210(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800034be:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800034c2:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800034c6:	00005517          	auipc	a0,0x5
    800034ca:	f2a50513          	addi	a0,a0,-214 # 800083f0 <states.1804+0xa8>
    800034ce:	ffffd097          	auipc	ra,0xffffd
    800034d2:	0ba080e7          	jalr	186(ra) # 80000588 <printf>
    p->killed = 1;
    800034d6:	4785                	li	a5,1
    800034d8:	c0bc                	sw	a5,64(s1)
    exit(-1);
    800034da:	557d                	li	a0,-1
    800034dc:	fffff097          	auipc	ra,0xfffff
    800034e0:	748080e7          	jalr	1864(ra) # 80002c24 <exit>
  if(which_dev == 2)
    800034e4:	4789                	li	a5,2
    800034e6:	f8f910e3          	bne	s2,a5,80003466 <usertrap+0x62>
    yield();
    800034ea:	fffff097          	auipc	ra,0xfffff
    800034ee:	2d6080e7          	jalr	726(ra) # 800027c0 <yield>
    800034f2:	bf95                	j	80003466 <usertrap+0x62>
  int which_dev = 0;
    800034f4:	4901                	li	s2,0
    800034f6:	b7d5                	j	800034da <usertrap+0xd6>

00000000800034f8 <kerneltrap>:
{
    800034f8:	7179                	addi	sp,sp,-48
    800034fa:	f406                	sd	ra,40(sp)
    800034fc:	f022                	sd	s0,32(sp)
    800034fe:	ec26                	sd	s1,24(sp)
    80003500:	e84a                	sd	s2,16(sp)
    80003502:	e44e                	sd	s3,8(sp)
    80003504:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003506:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000350a:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000350e:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80003512:	1004f793          	andi	a5,s1,256
    80003516:	cb85                	beqz	a5,80003546 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003518:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000351c:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    8000351e:	ef85                	bnez	a5,80003556 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80003520:	00000097          	auipc	ra,0x0
    80003524:	e42080e7          	jalr	-446(ra) # 80003362 <devintr>
    80003528:	cd1d                	beqz	a0,80003566 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000352a:	4789                	li	a5,2
    8000352c:	06f50a63          	beq	a0,a5,800035a0 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80003530:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003534:	10049073          	csrw	sstatus,s1
}
    80003538:	70a2                	ld	ra,40(sp)
    8000353a:	7402                	ld	s0,32(sp)
    8000353c:	64e2                	ld	s1,24(sp)
    8000353e:	6942                	ld	s2,16(sp)
    80003540:	69a2                	ld	s3,8(sp)
    80003542:	6145                	addi	sp,sp,48
    80003544:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80003546:	00005517          	auipc	a0,0x5
    8000354a:	eca50513          	addi	a0,a0,-310 # 80008410 <states.1804+0xc8>
    8000354e:	ffffd097          	auipc	ra,0xffffd
    80003552:	ff0080e7          	jalr	-16(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80003556:	00005517          	auipc	a0,0x5
    8000355a:	ee250513          	addi	a0,a0,-286 # 80008438 <states.1804+0xf0>
    8000355e:	ffffd097          	auipc	ra,0xffffd
    80003562:	fe0080e7          	jalr	-32(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80003566:	85ce                	mv	a1,s3
    80003568:	00005517          	auipc	a0,0x5
    8000356c:	ef050513          	addi	a0,a0,-272 # 80008458 <states.1804+0x110>
    80003570:	ffffd097          	auipc	ra,0xffffd
    80003574:	018080e7          	jalr	24(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003578:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000357c:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003580:	00005517          	auipc	a0,0x5
    80003584:	ee850513          	addi	a0,a0,-280 # 80008468 <states.1804+0x120>
    80003588:	ffffd097          	auipc	ra,0xffffd
    8000358c:	000080e7          	jalr	ra # 80000588 <printf>
    panic("kerneltrap");
    80003590:	00005517          	auipc	a0,0x5
    80003594:	ef050513          	addi	a0,a0,-272 # 80008480 <states.1804+0x138>
    80003598:	ffffd097          	auipc	ra,0xffffd
    8000359c:	fa6080e7          	jalr	-90(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800035a0:	fffff097          	auipc	ra,0xfffff
    800035a4:	a00080e7          	jalr	-1536(ra) # 80001fa0 <myproc>
    800035a8:	d541                	beqz	a0,80003530 <kerneltrap+0x38>
    800035aa:	fffff097          	auipc	ra,0xfffff
    800035ae:	9f6080e7          	jalr	-1546(ra) # 80001fa0 <myproc>
    800035b2:	5918                	lw	a4,48(a0)
    800035b4:	4791                	li	a5,4
    800035b6:	f6f71de3          	bne	a4,a5,80003530 <kerneltrap+0x38>
    yield();
    800035ba:	fffff097          	auipc	ra,0xfffff
    800035be:	206080e7          	jalr	518(ra) # 800027c0 <yield>
    800035c2:	b7bd                	j	80003530 <kerneltrap+0x38>

00000000800035c4 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800035c4:	1101                	addi	sp,sp,-32
    800035c6:	ec06                	sd	ra,24(sp)
    800035c8:	e822                	sd	s0,16(sp)
    800035ca:	e426                	sd	s1,8(sp)
    800035cc:	1000                	addi	s0,sp,32
    800035ce:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800035d0:	fffff097          	auipc	ra,0xfffff
    800035d4:	9d0080e7          	jalr	-1584(ra) # 80001fa0 <myproc>
  switch (n) {
    800035d8:	4795                	li	a5,5
    800035da:	0497e163          	bltu	a5,s1,8000361c <argraw+0x58>
    800035de:	048a                	slli	s1,s1,0x2
    800035e0:	00005717          	auipc	a4,0x5
    800035e4:	ed870713          	addi	a4,a4,-296 # 800084b8 <states.1804+0x170>
    800035e8:	94ba                	add	s1,s1,a4
    800035ea:	409c                	lw	a5,0(s1)
    800035ec:	97ba                	add	a5,a5,a4
    800035ee:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800035f0:	793c                	ld	a5,112(a0)
    800035f2:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800035f4:	60e2                	ld	ra,24(sp)
    800035f6:	6442                	ld	s0,16(sp)
    800035f8:	64a2                	ld	s1,8(sp)
    800035fa:	6105                	addi	sp,sp,32
    800035fc:	8082                	ret
    return p->trapframe->a1;
    800035fe:	793c                	ld	a5,112(a0)
    80003600:	7fa8                	ld	a0,120(a5)
    80003602:	bfcd                	j	800035f4 <argraw+0x30>
    return p->trapframe->a2;
    80003604:	793c                	ld	a5,112(a0)
    80003606:	63c8                	ld	a0,128(a5)
    80003608:	b7f5                	j	800035f4 <argraw+0x30>
    return p->trapframe->a3;
    8000360a:	793c                	ld	a5,112(a0)
    8000360c:	67c8                	ld	a0,136(a5)
    8000360e:	b7dd                	j	800035f4 <argraw+0x30>
    return p->trapframe->a4;
    80003610:	793c                	ld	a5,112(a0)
    80003612:	6bc8                	ld	a0,144(a5)
    80003614:	b7c5                	j	800035f4 <argraw+0x30>
    return p->trapframe->a5;
    80003616:	793c                	ld	a5,112(a0)
    80003618:	6fc8                	ld	a0,152(a5)
    8000361a:	bfe9                	j	800035f4 <argraw+0x30>
  panic("argraw");
    8000361c:	00005517          	auipc	a0,0x5
    80003620:	e7450513          	addi	a0,a0,-396 # 80008490 <states.1804+0x148>
    80003624:	ffffd097          	auipc	ra,0xffffd
    80003628:	f1a080e7          	jalr	-230(ra) # 8000053e <panic>

000000008000362c <fetchaddr>:
{
    8000362c:	1101                	addi	sp,sp,-32
    8000362e:	ec06                	sd	ra,24(sp)
    80003630:	e822                	sd	s0,16(sp)
    80003632:	e426                	sd	s1,8(sp)
    80003634:	e04a                	sd	s2,0(sp)
    80003636:	1000                	addi	s0,sp,32
    80003638:	84aa                	mv	s1,a0
    8000363a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000363c:	fffff097          	auipc	ra,0xfffff
    80003640:	964080e7          	jalr	-1692(ra) # 80001fa0 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80003644:	713c                	ld	a5,96(a0)
    80003646:	02f4f863          	bgeu	s1,a5,80003676 <fetchaddr+0x4a>
    8000364a:	00848713          	addi	a4,s1,8
    8000364e:	02e7e663          	bltu	a5,a4,8000367a <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80003652:	46a1                	li	a3,8
    80003654:	8626                	mv	a2,s1
    80003656:	85ca                	mv	a1,s2
    80003658:	7528                	ld	a0,104(a0)
    8000365a:	ffffe097          	auipc	ra,0xffffe
    8000365e:	0a4080e7          	jalr	164(ra) # 800016fe <copyin>
    80003662:	00a03533          	snez	a0,a0
    80003666:	40a00533          	neg	a0,a0
}
    8000366a:	60e2                	ld	ra,24(sp)
    8000366c:	6442                	ld	s0,16(sp)
    8000366e:	64a2                	ld	s1,8(sp)
    80003670:	6902                	ld	s2,0(sp)
    80003672:	6105                	addi	sp,sp,32
    80003674:	8082                	ret
    return -1;
    80003676:	557d                	li	a0,-1
    80003678:	bfcd                	j	8000366a <fetchaddr+0x3e>
    8000367a:	557d                	li	a0,-1
    8000367c:	b7fd                	j	8000366a <fetchaddr+0x3e>

000000008000367e <fetchstr>:
{
    8000367e:	7179                	addi	sp,sp,-48
    80003680:	f406                	sd	ra,40(sp)
    80003682:	f022                	sd	s0,32(sp)
    80003684:	ec26                	sd	s1,24(sp)
    80003686:	e84a                	sd	s2,16(sp)
    80003688:	e44e                	sd	s3,8(sp)
    8000368a:	1800                	addi	s0,sp,48
    8000368c:	892a                	mv	s2,a0
    8000368e:	84ae                	mv	s1,a1
    80003690:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003692:	fffff097          	auipc	ra,0xfffff
    80003696:	90e080e7          	jalr	-1778(ra) # 80001fa0 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    8000369a:	86ce                	mv	a3,s3
    8000369c:	864a                	mv	a2,s2
    8000369e:	85a6                	mv	a1,s1
    800036a0:	7528                	ld	a0,104(a0)
    800036a2:	ffffe097          	auipc	ra,0xffffe
    800036a6:	0e8080e7          	jalr	232(ra) # 8000178a <copyinstr>
  if(err < 0)
    800036aa:	00054763          	bltz	a0,800036b8 <fetchstr+0x3a>
  return strlen(buf);
    800036ae:	8526                	mv	a0,s1
    800036b0:	ffffd097          	auipc	ra,0xffffd
    800036b4:	7b4080e7          	jalr	1972(ra) # 80000e64 <strlen>
}
    800036b8:	70a2                	ld	ra,40(sp)
    800036ba:	7402                	ld	s0,32(sp)
    800036bc:	64e2                	ld	s1,24(sp)
    800036be:	6942                	ld	s2,16(sp)
    800036c0:	69a2                	ld	s3,8(sp)
    800036c2:	6145                	addi	sp,sp,48
    800036c4:	8082                	ret

00000000800036c6 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    800036c6:	1101                	addi	sp,sp,-32
    800036c8:	ec06                	sd	ra,24(sp)
    800036ca:	e822                	sd	s0,16(sp)
    800036cc:	e426                	sd	s1,8(sp)
    800036ce:	1000                	addi	s0,sp,32
    800036d0:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800036d2:	00000097          	auipc	ra,0x0
    800036d6:	ef2080e7          	jalr	-270(ra) # 800035c4 <argraw>
    800036da:	c088                	sw	a0,0(s1)
  return 0;
}
    800036dc:	4501                	li	a0,0
    800036de:	60e2                	ld	ra,24(sp)
    800036e0:	6442                	ld	s0,16(sp)
    800036e2:	64a2                	ld	s1,8(sp)
    800036e4:	6105                	addi	sp,sp,32
    800036e6:	8082                	ret

00000000800036e8 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    800036e8:	1101                	addi	sp,sp,-32
    800036ea:	ec06                	sd	ra,24(sp)
    800036ec:	e822                	sd	s0,16(sp)
    800036ee:	e426                	sd	s1,8(sp)
    800036f0:	1000                	addi	s0,sp,32
    800036f2:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800036f4:	00000097          	auipc	ra,0x0
    800036f8:	ed0080e7          	jalr	-304(ra) # 800035c4 <argraw>
    800036fc:	e088                	sd	a0,0(s1)
  return 0;
}
    800036fe:	4501                	li	a0,0
    80003700:	60e2                	ld	ra,24(sp)
    80003702:	6442                	ld	s0,16(sp)
    80003704:	64a2                	ld	s1,8(sp)
    80003706:	6105                	addi	sp,sp,32
    80003708:	8082                	ret

000000008000370a <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    8000370a:	1101                	addi	sp,sp,-32
    8000370c:	ec06                	sd	ra,24(sp)
    8000370e:	e822                	sd	s0,16(sp)
    80003710:	e426                	sd	s1,8(sp)
    80003712:	e04a                	sd	s2,0(sp)
    80003714:	1000                	addi	s0,sp,32
    80003716:	84ae                	mv	s1,a1
    80003718:	8932                	mv	s2,a2
  *ip = argraw(n);
    8000371a:	00000097          	auipc	ra,0x0
    8000371e:	eaa080e7          	jalr	-342(ra) # 800035c4 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80003722:	864a                	mv	a2,s2
    80003724:	85a6                	mv	a1,s1
    80003726:	00000097          	auipc	ra,0x0
    8000372a:	f58080e7          	jalr	-168(ra) # 8000367e <fetchstr>
}
    8000372e:	60e2                	ld	ra,24(sp)
    80003730:	6442                	ld	s0,16(sp)
    80003732:	64a2                	ld	s1,8(sp)
    80003734:	6902                	ld	s2,0(sp)
    80003736:	6105                	addi	sp,sp,32
    80003738:	8082                	ret

000000008000373a <syscall>:
[SYS_cpu_process_count] sys_cpu_process_count,
};

void
syscall(void)
{
    8000373a:	1101                	addi	sp,sp,-32
    8000373c:	ec06                	sd	ra,24(sp)
    8000373e:	e822                	sd	s0,16(sp)
    80003740:	e426                	sd	s1,8(sp)
    80003742:	e04a                	sd	s2,0(sp)
    80003744:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80003746:	fffff097          	auipc	ra,0xfffff
    8000374a:	85a080e7          	jalr	-1958(ra) # 80001fa0 <myproc>
    8000374e:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80003750:	07053903          	ld	s2,112(a0)
    80003754:	0a893783          	ld	a5,168(s2)
    80003758:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    8000375c:	37fd                	addiw	a5,a5,-1
    8000375e:	475d                	li	a4,23
    80003760:	00f76f63          	bltu	a4,a5,8000377e <syscall+0x44>
    80003764:	00369713          	slli	a4,a3,0x3
    80003768:	00005797          	auipc	a5,0x5
    8000376c:	d6878793          	addi	a5,a5,-664 # 800084d0 <syscalls>
    80003770:	97ba                	add	a5,a5,a4
    80003772:	639c                	ld	a5,0(a5)
    80003774:	c789                	beqz	a5,8000377e <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80003776:	9782                	jalr	a5
    80003778:	06a93823          	sd	a0,112(s2)
    8000377c:	a839                	j	8000379a <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    8000377e:	17048613          	addi	a2,s1,368
    80003782:	44ac                	lw	a1,72(s1)
    80003784:	00005517          	auipc	a0,0x5
    80003788:	d1450513          	addi	a0,a0,-748 # 80008498 <states.1804+0x150>
    8000378c:	ffffd097          	auipc	ra,0xffffd
    80003790:	dfc080e7          	jalr	-516(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003794:	78bc                	ld	a5,112(s1)
    80003796:	577d                	li	a4,-1
    80003798:	fbb8                	sd	a4,112(a5)
  }
}
    8000379a:	60e2                	ld	ra,24(sp)
    8000379c:	6442                	ld	s0,16(sp)
    8000379e:	64a2                	ld	s1,8(sp)
    800037a0:	6902                	ld	s2,0(sp)
    800037a2:	6105                	addi	sp,sp,32
    800037a4:	8082                	ret

00000000800037a6 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    800037a6:	1101                	addi	sp,sp,-32
    800037a8:	ec06                	sd	ra,24(sp)
    800037aa:	e822                	sd	s0,16(sp)
    800037ac:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    800037ae:	fec40593          	addi	a1,s0,-20
    800037b2:	4501                	li	a0,0
    800037b4:	00000097          	auipc	ra,0x0
    800037b8:	f12080e7          	jalr	-238(ra) # 800036c6 <argint>
    return -1;
    800037bc:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800037be:	00054963          	bltz	a0,800037d0 <sys_exit+0x2a>
  exit(n);
    800037c2:	fec42503          	lw	a0,-20(s0)
    800037c6:	fffff097          	auipc	ra,0xfffff
    800037ca:	45e080e7          	jalr	1118(ra) # 80002c24 <exit>
  return 0;  // not reached
    800037ce:	4781                	li	a5,0
}
    800037d0:	853e                	mv	a0,a5
    800037d2:	60e2                	ld	ra,24(sp)
    800037d4:	6442                	ld	s0,16(sp)
    800037d6:	6105                	addi	sp,sp,32
    800037d8:	8082                	ret

00000000800037da <sys_getpid>:

uint64
sys_getpid(void)
{
    800037da:	1141                	addi	sp,sp,-16
    800037dc:	e406                	sd	ra,8(sp)
    800037de:	e022                	sd	s0,0(sp)
    800037e0:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800037e2:	ffffe097          	auipc	ra,0xffffe
    800037e6:	7be080e7          	jalr	1982(ra) # 80001fa0 <myproc>
}
    800037ea:	4528                	lw	a0,72(a0)
    800037ec:	60a2                	ld	ra,8(sp)
    800037ee:	6402                	ld	s0,0(sp)
    800037f0:	0141                	addi	sp,sp,16
    800037f2:	8082                	ret

00000000800037f4 <sys_fork>:

uint64
sys_fork(void)
{
    800037f4:	1141                	addi	sp,sp,-16
    800037f6:	e406                	sd	ra,8(sp)
    800037f8:	e022                	sd	s0,0(sp)
    800037fa:	0800                	addi	s0,sp,16
  return fork();
    800037fc:	fffff097          	auipc	ra,0xfffff
    80003800:	c38080e7          	jalr	-968(ra) # 80002434 <fork>
}
    80003804:	60a2                	ld	ra,8(sp)
    80003806:	6402                	ld	s0,0(sp)
    80003808:	0141                	addi	sp,sp,16
    8000380a:	8082                	ret

000000008000380c <sys_wait>:

uint64
sys_wait(void)
{
    8000380c:	1101                	addi	sp,sp,-32
    8000380e:	ec06                	sd	ra,24(sp)
    80003810:	e822                	sd	s0,16(sp)
    80003812:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80003814:	fe840593          	addi	a1,s0,-24
    80003818:	4501                	li	a0,0
    8000381a:	00000097          	auipc	ra,0x0
    8000381e:	ece080e7          	jalr	-306(ra) # 800036e8 <argaddr>
    80003822:	87aa                	mv	a5,a0
    return -1;
    80003824:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80003826:	0007c863          	bltz	a5,80003836 <sys_wait+0x2a>
  return wait(p);
    8000382a:	fe843503          	ld	a0,-24(s0)
    8000382e:	fffff097          	auipc	ra,0xfffff
    80003832:	06c080e7          	jalr	108(ra) # 8000289a <wait>
}
    80003836:	60e2                	ld	ra,24(sp)
    80003838:	6442                	ld	s0,16(sp)
    8000383a:	6105                	addi	sp,sp,32
    8000383c:	8082                	ret

000000008000383e <sys_sbrk>:

uint64
sys_sbrk(void)
{
    8000383e:	7179                	addi	sp,sp,-48
    80003840:	f406                	sd	ra,40(sp)
    80003842:	f022                	sd	s0,32(sp)
    80003844:	ec26                	sd	s1,24(sp)
    80003846:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80003848:	fdc40593          	addi	a1,s0,-36
    8000384c:	4501                	li	a0,0
    8000384e:	00000097          	auipc	ra,0x0
    80003852:	e78080e7          	jalr	-392(ra) # 800036c6 <argint>
    80003856:	87aa                	mv	a5,a0
    return -1;
    80003858:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    8000385a:	0207c063          	bltz	a5,8000387a <sys_sbrk+0x3c>
  addr = myproc()->sz;
    8000385e:	ffffe097          	auipc	ra,0xffffe
    80003862:	742080e7          	jalr	1858(ra) # 80001fa0 <myproc>
    80003866:	5124                	lw	s1,96(a0)
  if(growproc(n) < 0)
    80003868:	fdc42503          	lw	a0,-36(s0)
    8000386c:	fffff097          	auipc	ra,0xfffff
    80003870:	b54080e7          	jalr	-1196(ra) # 800023c0 <growproc>
    80003874:	00054863          	bltz	a0,80003884 <sys_sbrk+0x46>
    return -1;
  return addr;
    80003878:	8526                	mv	a0,s1
}
    8000387a:	70a2                	ld	ra,40(sp)
    8000387c:	7402                	ld	s0,32(sp)
    8000387e:	64e2                	ld	s1,24(sp)
    80003880:	6145                	addi	sp,sp,48
    80003882:	8082                	ret
    return -1;
    80003884:	557d                	li	a0,-1
    80003886:	bfd5                	j	8000387a <sys_sbrk+0x3c>

0000000080003888 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003888:	7139                	addi	sp,sp,-64
    8000388a:	fc06                	sd	ra,56(sp)
    8000388c:	f822                	sd	s0,48(sp)
    8000388e:	f426                	sd	s1,40(sp)
    80003890:	f04a                	sd	s2,32(sp)
    80003892:	ec4e                	sd	s3,24(sp)
    80003894:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003896:	fcc40593          	addi	a1,s0,-52
    8000389a:	4501                	li	a0,0
    8000389c:	00000097          	auipc	ra,0x0
    800038a0:	e2a080e7          	jalr	-470(ra) # 800036c6 <argint>
    return -1;
    800038a4:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800038a6:	06054563          	bltz	a0,80003910 <sys_sleep+0x88>
  acquire(&tickslock);
    800038aa:	00014517          	auipc	a0,0x14
    800038ae:	31650513          	addi	a0,a0,790 # 80017bc0 <tickslock>
    800038b2:	ffffd097          	auipc	ra,0xffffd
    800038b6:	332080e7          	jalr	818(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    800038ba:	00005917          	auipc	s2,0x5
    800038be:	77692903          	lw	s2,1910(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    800038c2:	fcc42783          	lw	a5,-52(s0)
    800038c6:	cf85                	beqz	a5,800038fe <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800038c8:	00014997          	auipc	s3,0x14
    800038cc:	2f898993          	addi	s3,s3,760 # 80017bc0 <tickslock>
    800038d0:	00005497          	auipc	s1,0x5
    800038d4:	76048493          	addi	s1,s1,1888 # 80009030 <ticks>
    if(myproc()->killed){
    800038d8:	ffffe097          	auipc	ra,0xffffe
    800038dc:	6c8080e7          	jalr	1736(ra) # 80001fa0 <myproc>
    800038e0:	413c                	lw	a5,64(a0)
    800038e2:	ef9d                	bnez	a5,80003920 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    800038e4:	85ce                	mv	a1,s3
    800038e6:	8526                	mv	a0,s1
    800038e8:	fffff097          	auipc	ra,0xfffff
    800038ec:	f38080e7          	jalr	-200(ra) # 80002820 <sleep>
  while(ticks - ticks0 < n){
    800038f0:	409c                	lw	a5,0(s1)
    800038f2:	412787bb          	subw	a5,a5,s2
    800038f6:	fcc42703          	lw	a4,-52(s0)
    800038fa:	fce7efe3          	bltu	a5,a4,800038d8 <sys_sleep+0x50>
  }
  release(&tickslock);
    800038fe:	00014517          	auipc	a0,0x14
    80003902:	2c250513          	addi	a0,a0,706 # 80017bc0 <tickslock>
    80003906:	ffffd097          	auipc	ra,0xffffd
    8000390a:	392080e7          	jalr	914(ra) # 80000c98 <release>
  return 0;
    8000390e:	4781                	li	a5,0
}
    80003910:	853e                	mv	a0,a5
    80003912:	70e2                	ld	ra,56(sp)
    80003914:	7442                	ld	s0,48(sp)
    80003916:	74a2                	ld	s1,40(sp)
    80003918:	7902                	ld	s2,32(sp)
    8000391a:	69e2                	ld	s3,24(sp)
    8000391c:	6121                	addi	sp,sp,64
    8000391e:	8082                	ret
      release(&tickslock);
    80003920:	00014517          	auipc	a0,0x14
    80003924:	2a050513          	addi	a0,a0,672 # 80017bc0 <tickslock>
    80003928:	ffffd097          	auipc	ra,0xffffd
    8000392c:	370080e7          	jalr	880(ra) # 80000c98 <release>
      return -1;
    80003930:	57fd                	li	a5,-1
    80003932:	bff9                	j	80003910 <sys_sleep+0x88>

0000000080003934 <sys_kill>:

uint64
sys_kill(void)
{
    80003934:	1101                	addi	sp,sp,-32
    80003936:	ec06                	sd	ra,24(sp)
    80003938:	e822                	sd	s0,16(sp)
    8000393a:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    8000393c:	fec40593          	addi	a1,s0,-20
    80003940:	4501                	li	a0,0
    80003942:	00000097          	auipc	ra,0x0
    80003946:	d84080e7          	jalr	-636(ra) # 800036c6 <argint>
    8000394a:	87aa                	mv	a5,a0
    return -1;
    8000394c:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    8000394e:	0007c863          	bltz	a5,8000395e <sys_kill+0x2a>
  return kill(pid);
    80003952:	fec42503          	lw	a0,-20(s0)
    80003956:	fffff097          	auipc	ra,0xfffff
    8000395a:	3be080e7          	jalr	958(ra) # 80002d14 <kill>
}
    8000395e:	60e2                	ld	ra,24(sp)
    80003960:	6442                	ld	s0,16(sp)
    80003962:	6105                	addi	sp,sp,32
    80003964:	8082                	ret

0000000080003966 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003966:	1101                	addi	sp,sp,-32
    80003968:	ec06                	sd	ra,24(sp)
    8000396a:	e822                	sd	s0,16(sp)
    8000396c:	e426                	sd	s1,8(sp)
    8000396e:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003970:	00014517          	auipc	a0,0x14
    80003974:	25050513          	addi	a0,a0,592 # 80017bc0 <tickslock>
    80003978:	ffffd097          	auipc	ra,0xffffd
    8000397c:	26c080e7          	jalr	620(ra) # 80000be4 <acquire>
  xticks = ticks;
    80003980:	00005497          	auipc	s1,0x5
    80003984:	6b04a483          	lw	s1,1712(s1) # 80009030 <ticks>
  release(&tickslock);
    80003988:	00014517          	auipc	a0,0x14
    8000398c:	23850513          	addi	a0,a0,568 # 80017bc0 <tickslock>
    80003990:	ffffd097          	auipc	ra,0xffffd
    80003994:	308080e7          	jalr	776(ra) # 80000c98 <release>
  return xticks;
}
    80003998:	02049513          	slli	a0,s1,0x20
    8000399c:	9101                	srli	a0,a0,0x20
    8000399e:	60e2                	ld	ra,24(sp)
    800039a0:	6442                	ld	s0,16(sp)
    800039a2:	64a2                	ld	s1,8(sp)
    800039a4:	6105                	addi	sp,sp,32
    800039a6:	8082                	ret

00000000800039a8 <sys_set_cpu>:

uint64
sys_set_cpu(void){
    800039a8:	1101                	addi	sp,sp,-32
    800039aa:	ec06                	sd	ra,24(sp)
    800039ac:	e822                	sd	s0,16(sp)
    800039ae:	1000                	addi	s0,sp,32
  int cpid;
  if(argint(0, &cpid) < 0)
    800039b0:	fec40593          	addi	a1,s0,-20
    800039b4:	4501                	li	a0,0
    800039b6:	00000097          	auipc	ra,0x0
    800039ba:	d10080e7          	jalr	-752(ra) # 800036c6 <argint>
    800039be:	87aa                	mv	a5,a0
    return -1;
    800039c0:	557d                	li	a0,-1
  if(argint(0, &cpid) < 0)
    800039c2:	0007c863          	bltz	a5,800039d2 <sys_set_cpu+0x2a>

  return set_cpu(cpid);
    800039c6:	fec42503          	lw	a0,-20(s0)
    800039ca:	fffff097          	auipc	ra,0xfffff
    800039ce:	76c080e7          	jalr	1900(ra) # 80003136 <set_cpu>

}
    800039d2:	60e2                	ld	ra,24(sp)
    800039d4:	6442                	ld	s0,16(sp)
    800039d6:	6105                	addi	sp,sp,32
    800039d8:	8082                	ret

00000000800039da <sys_get_cpu>:

uint64
sys_get_cpu(void){
    800039da:	1141                	addi	sp,sp,-16
    800039dc:	e406                	sd	ra,8(sp)
    800039de:	e022                	sd	s0,0(sp)
    800039e0:	0800                	addi	s0,sp,16
  return get_cpu();
    800039e2:	fffff097          	auipc	ra,0xfffff
    800039e6:	7a2080e7          	jalr	1954(ra) # 80003184 <get_cpu>
}
    800039ea:	60a2                	ld	ra,8(sp)
    800039ec:	6402                	ld	s0,0(sp)
    800039ee:	0141                	addi	sp,sp,16
    800039f0:	8082                	ret

00000000800039f2 <sys_cpu_process_count>:

uint64
sys_cpu_process_count(void){
    800039f2:	1101                	addi	sp,sp,-32
    800039f4:	ec06                	sd	ra,24(sp)
    800039f6:	e822                	sd	s0,16(sp)
    800039f8:	1000                	addi	s0,sp,32
  int cpid;
  if (argint(0, &cpid) < 0)
    800039fa:	fec40593          	addi	a1,s0,-20
    800039fe:	4501                	li	a0,0
    80003a00:	00000097          	auipc	ra,0x0
    80003a04:	cc6080e7          	jalr	-826(ra) # 800036c6 <argint>
    80003a08:	87aa                	mv	a5,a0
    return -1;
    80003a0a:	557d                	li	a0,-1
  if (argint(0, &cpid) < 0)
    80003a0c:	0007c863          	bltz	a5,80003a1c <sys_cpu_process_count+0x2a>
  return cpu_process_count(cpid);
    80003a10:	fec42503          	lw	a0,-20(s0)
    80003a14:	fffff097          	auipc	ra,0xfffff
    80003a18:	796080e7          	jalr	1942(ra) # 800031aa <cpu_process_count>
}
    80003a1c:	60e2                	ld	ra,24(sp)
    80003a1e:	6442                	ld	s0,16(sp)
    80003a20:	6105                	addi	sp,sp,32
    80003a22:	8082                	ret

0000000080003a24 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003a24:	7179                	addi	sp,sp,-48
    80003a26:	f406                	sd	ra,40(sp)
    80003a28:	f022                	sd	s0,32(sp)
    80003a2a:	ec26                	sd	s1,24(sp)
    80003a2c:	e84a                	sd	s2,16(sp)
    80003a2e:	e44e                	sd	s3,8(sp)
    80003a30:	e052                	sd	s4,0(sp)
    80003a32:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003a34:	00005597          	auipc	a1,0x5
    80003a38:	b6458593          	addi	a1,a1,-1180 # 80008598 <syscalls+0xc8>
    80003a3c:	00014517          	auipc	a0,0x14
    80003a40:	19c50513          	addi	a0,a0,412 # 80017bd8 <bcache>
    80003a44:	ffffd097          	auipc	ra,0xffffd
    80003a48:	110080e7          	jalr	272(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003a4c:	0001c797          	auipc	a5,0x1c
    80003a50:	18c78793          	addi	a5,a5,396 # 8001fbd8 <bcache+0x8000>
    80003a54:	0001c717          	auipc	a4,0x1c
    80003a58:	3ec70713          	addi	a4,a4,1004 # 8001fe40 <bcache+0x8268>
    80003a5c:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003a60:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003a64:	00014497          	auipc	s1,0x14
    80003a68:	18c48493          	addi	s1,s1,396 # 80017bf0 <bcache+0x18>
    b->next = bcache.head.next;
    80003a6c:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003a6e:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003a70:	00005a17          	auipc	s4,0x5
    80003a74:	b30a0a13          	addi	s4,s4,-1232 # 800085a0 <syscalls+0xd0>
    b->next = bcache.head.next;
    80003a78:	2b893783          	ld	a5,696(s2)
    80003a7c:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003a7e:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003a82:	85d2                	mv	a1,s4
    80003a84:	01048513          	addi	a0,s1,16
    80003a88:	00001097          	auipc	ra,0x1
    80003a8c:	4bc080e7          	jalr	1212(ra) # 80004f44 <initsleeplock>
    bcache.head.next->prev = b;
    80003a90:	2b893783          	ld	a5,696(s2)
    80003a94:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003a96:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003a9a:	45848493          	addi	s1,s1,1112
    80003a9e:	fd349de3          	bne	s1,s3,80003a78 <binit+0x54>
  }
}
    80003aa2:	70a2                	ld	ra,40(sp)
    80003aa4:	7402                	ld	s0,32(sp)
    80003aa6:	64e2                	ld	s1,24(sp)
    80003aa8:	6942                	ld	s2,16(sp)
    80003aaa:	69a2                	ld	s3,8(sp)
    80003aac:	6a02                	ld	s4,0(sp)
    80003aae:	6145                	addi	sp,sp,48
    80003ab0:	8082                	ret

0000000080003ab2 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003ab2:	7179                	addi	sp,sp,-48
    80003ab4:	f406                	sd	ra,40(sp)
    80003ab6:	f022                	sd	s0,32(sp)
    80003ab8:	ec26                	sd	s1,24(sp)
    80003aba:	e84a                	sd	s2,16(sp)
    80003abc:	e44e                	sd	s3,8(sp)
    80003abe:	1800                	addi	s0,sp,48
    80003ac0:	89aa                	mv	s3,a0
    80003ac2:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003ac4:	00014517          	auipc	a0,0x14
    80003ac8:	11450513          	addi	a0,a0,276 # 80017bd8 <bcache>
    80003acc:	ffffd097          	auipc	ra,0xffffd
    80003ad0:	118080e7          	jalr	280(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003ad4:	0001c497          	auipc	s1,0x1c
    80003ad8:	3bc4b483          	ld	s1,956(s1) # 8001fe90 <bcache+0x82b8>
    80003adc:	0001c797          	auipc	a5,0x1c
    80003ae0:	36478793          	addi	a5,a5,868 # 8001fe40 <bcache+0x8268>
    80003ae4:	02f48f63          	beq	s1,a5,80003b22 <bread+0x70>
    80003ae8:	873e                	mv	a4,a5
    80003aea:	a021                	j	80003af2 <bread+0x40>
    80003aec:	68a4                	ld	s1,80(s1)
    80003aee:	02e48a63          	beq	s1,a4,80003b22 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003af2:	449c                	lw	a5,8(s1)
    80003af4:	ff379ce3          	bne	a5,s3,80003aec <bread+0x3a>
    80003af8:	44dc                	lw	a5,12(s1)
    80003afa:	ff2799e3          	bne	a5,s2,80003aec <bread+0x3a>
      b->refcnt++;
    80003afe:	40bc                	lw	a5,64(s1)
    80003b00:	2785                	addiw	a5,a5,1
    80003b02:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003b04:	00014517          	auipc	a0,0x14
    80003b08:	0d450513          	addi	a0,a0,212 # 80017bd8 <bcache>
    80003b0c:	ffffd097          	auipc	ra,0xffffd
    80003b10:	18c080e7          	jalr	396(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003b14:	01048513          	addi	a0,s1,16
    80003b18:	00001097          	auipc	ra,0x1
    80003b1c:	466080e7          	jalr	1126(ra) # 80004f7e <acquiresleep>
      return b;
    80003b20:	a8b9                	j	80003b7e <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003b22:	0001c497          	auipc	s1,0x1c
    80003b26:	3664b483          	ld	s1,870(s1) # 8001fe88 <bcache+0x82b0>
    80003b2a:	0001c797          	auipc	a5,0x1c
    80003b2e:	31678793          	addi	a5,a5,790 # 8001fe40 <bcache+0x8268>
    80003b32:	00f48863          	beq	s1,a5,80003b42 <bread+0x90>
    80003b36:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003b38:	40bc                	lw	a5,64(s1)
    80003b3a:	cf81                	beqz	a5,80003b52 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003b3c:	64a4                	ld	s1,72(s1)
    80003b3e:	fee49de3          	bne	s1,a4,80003b38 <bread+0x86>
  panic("bget: no buffers");
    80003b42:	00005517          	auipc	a0,0x5
    80003b46:	a6650513          	addi	a0,a0,-1434 # 800085a8 <syscalls+0xd8>
    80003b4a:	ffffd097          	auipc	ra,0xffffd
    80003b4e:	9f4080e7          	jalr	-1548(ra) # 8000053e <panic>
      b->dev = dev;
    80003b52:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003b56:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003b5a:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003b5e:	4785                	li	a5,1
    80003b60:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003b62:	00014517          	auipc	a0,0x14
    80003b66:	07650513          	addi	a0,a0,118 # 80017bd8 <bcache>
    80003b6a:	ffffd097          	auipc	ra,0xffffd
    80003b6e:	12e080e7          	jalr	302(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003b72:	01048513          	addi	a0,s1,16
    80003b76:	00001097          	auipc	ra,0x1
    80003b7a:	408080e7          	jalr	1032(ra) # 80004f7e <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003b7e:	409c                	lw	a5,0(s1)
    80003b80:	cb89                	beqz	a5,80003b92 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003b82:	8526                	mv	a0,s1
    80003b84:	70a2                	ld	ra,40(sp)
    80003b86:	7402                	ld	s0,32(sp)
    80003b88:	64e2                	ld	s1,24(sp)
    80003b8a:	6942                	ld	s2,16(sp)
    80003b8c:	69a2                	ld	s3,8(sp)
    80003b8e:	6145                	addi	sp,sp,48
    80003b90:	8082                	ret
    virtio_disk_rw(b, 0);
    80003b92:	4581                	li	a1,0
    80003b94:	8526                	mv	a0,s1
    80003b96:	00003097          	auipc	ra,0x3
    80003b9a:	f10080e7          	jalr	-240(ra) # 80006aa6 <virtio_disk_rw>
    b->valid = 1;
    80003b9e:	4785                	li	a5,1
    80003ba0:	c09c                	sw	a5,0(s1)
  return b;
    80003ba2:	b7c5                	j	80003b82 <bread+0xd0>

0000000080003ba4 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003ba4:	1101                	addi	sp,sp,-32
    80003ba6:	ec06                	sd	ra,24(sp)
    80003ba8:	e822                	sd	s0,16(sp)
    80003baa:	e426                	sd	s1,8(sp)
    80003bac:	1000                	addi	s0,sp,32
    80003bae:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003bb0:	0541                	addi	a0,a0,16
    80003bb2:	00001097          	auipc	ra,0x1
    80003bb6:	466080e7          	jalr	1126(ra) # 80005018 <holdingsleep>
    80003bba:	cd01                	beqz	a0,80003bd2 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003bbc:	4585                	li	a1,1
    80003bbe:	8526                	mv	a0,s1
    80003bc0:	00003097          	auipc	ra,0x3
    80003bc4:	ee6080e7          	jalr	-282(ra) # 80006aa6 <virtio_disk_rw>
}
    80003bc8:	60e2                	ld	ra,24(sp)
    80003bca:	6442                	ld	s0,16(sp)
    80003bcc:	64a2                	ld	s1,8(sp)
    80003bce:	6105                	addi	sp,sp,32
    80003bd0:	8082                	ret
    panic("bwrite");
    80003bd2:	00005517          	auipc	a0,0x5
    80003bd6:	9ee50513          	addi	a0,a0,-1554 # 800085c0 <syscalls+0xf0>
    80003bda:	ffffd097          	auipc	ra,0xffffd
    80003bde:	964080e7          	jalr	-1692(ra) # 8000053e <panic>

0000000080003be2 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003be2:	1101                	addi	sp,sp,-32
    80003be4:	ec06                	sd	ra,24(sp)
    80003be6:	e822                	sd	s0,16(sp)
    80003be8:	e426                	sd	s1,8(sp)
    80003bea:	e04a                	sd	s2,0(sp)
    80003bec:	1000                	addi	s0,sp,32
    80003bee:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003bf0:	01050913          	addi	s2,a0,16
    80003bf4:	854a                	mv	a0,s2
    80003bf6:	00001097          	auipc	ra,0x1
    80003bfa:	422080e7          	jalr	1058(ra) # 80005018 <holdingsleep>
    80003bfe:	c92d                	beqz	a0,80003c70 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003c00:	854a                	mv	a0,s2
    80003c02:	00001097          	auipc	ra,0x1
    80003c06:	3d2080e7          	jalr	978(ra) # 80004fd4 <releasesleep>

  acquire(&bcache.lock);
    80003c0a:	00014517          	auipc	a0,0x14
    80003c0e:	fce50513          	addi	a0,a0,-50 # 80017bd8 <bcache>
    80003c12:	ffffd097          	auipc	ra,0xffffd
    80003c16:	fd2080e7          	jalr	-46(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003c1a:	40bc                	lw	a5,64(s1)
    80003c1c:	37fd                	addiw	a5,a5,-1
    80003c1e:	0007871b          	sext.w	a4,a5
    80003c22:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003c24:	eb05                	bnez	a4,80003c54 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003c26:	68bc                	ld	a5,80(s1)
    80003c28:	64b8                	ld	a4,72(s1)
    80003c2a:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003c2c:	64bc                	ld	a5,72(s1)
    80003c2e:	68b8                	ld	a4,80(s1)
    80003c30:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003c32:	0001c797          	auipc	a5,0x1c
    80003c36:	fa678793          	addi	a5,a5,-90 # 8001fbd8 <bcache+0x8000>
    80003c3a:	2b87b703          	ld	a4,696(a5)
    80003c3e:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003c40:	0001c717          	auipc	a4,0x1c
    80003c44:	20070713          	addi	a4,a4,512 # 8001fe40 <bcache+0x8268>
    80003c48:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003c4a:	2b87b703          	ld	a4,696(a5)
    80003c4e:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003c50:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003c54:	00014517          	auipc	a0,0x14
    80003c58:	f8450513          	addi	a0,a0,-124 # 80017bd8 <bcache>
    80003c5c:	ffffd097          	auipc	ra,0xffffd
    80003c60:	03c080e7          	jalr	60(ra) # 80000c98 <release>
}
    80003c64:	60e2                	ld	ra,24(sp)
    80003c66:	6442                	ld	s0,16(sp)
    80003c68:	64a2                	ld	s1,8(sp)
    80003c6a:	6902                	ld	s2,0(sp)
    80003c6c:	6105                	addi	sp,sp,32
    80003c6e:	8082                	ret
    panic("brelse");
    80003c70:	00005517          	auipc	a0,0x5
    80003c74:	95850513          	addi	a0,a0,-1704 # 800085c8 <syscalls+0xf8>
    80003c78:	ffffd097          	auipc	ra,0xffffd
    80003c7c:	8c6080e7          	jalr	-1850(ra) # 8000053e <panic>

0000000080003c80 <bpin>:

void
bpin(struct buf *b) {
    80003c80:	1101                	addi	sp,sp,-32
    80003c82:	ec06                	sd	ra,24(sp)
    80003c84:	e822                	sd	s0,16(sp)
    80003c86:	e426                	sd	s1,8(sp)
    80003c88:	1000                	addi	s0,sp,32
    80003c8a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003c8c:	00014517          	auipc	a0,0x14
    80003c90:	f4c50513          	addi	a0,a0,-180 # 80017bd8 <bcache>
    80003c94:	ffffd097          	auipc	ra,0xffffd
    80003c98:	f50080e7          	jalr	-176(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003c9c:	40bc                	lw	a5,64(s1)
    80003c9e:	2785                	addiw	a5,a5,1
    80003ca0:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003ca2:	00014517          	auipc	a0,0x14
    80003ca6:	f3650513          	addi	a0,a0,-202 # 80017bd8 <bcache>
    80003caa:	ffffd097          	auipc	ra,0xffffd
    80003cae:	fee080e7          	jalr	-18(ra) # 80000c98 <release>
}
    80003cb2:	60e2                	ld	ra,24(sp)
    80003cb4:	6442                	ld	s0,16(sp)
    80003cb6:	64a2                	ld	s1,8(sp)
    80003cb8:	6105                	addi	sp,sp,32
    80003cba:	8082                	ret

0000000080003cbc <bunpin>:

void
bunpin(struct buf *b) {
    80003cbc:	1101                	addi	sp,sp,-32
    80003cbe:	ec06                	sd	ra,24(sp)
    80003cc0:	e822                	sd	s0,16(sp)
    80003cc2:	e426                	sd	s1,8(sp)
    80003cc4:	1000                	addi	s0,sp,32
    80003cc6:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003cc8:	00014517          	auipc	a0,0x14
    80003ccc:	f1050513          	addi	a0,a0,-240 # 80017bd8 <bcache>
    80003cd0:	ffffd097          	auipc	ra,0xffffd
    80003cd4:	f14080e7          	jalr	-236(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003cd8:	40bc                	lw	a5,64(s1)
    80003cda:	37fd                	addiw	a5,a5,-1
    80003cdc:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003cde:	00014517          	auipc	a0,0x14
    80003ce2:	efa50513          	addi	a0,a0,-262 # 80017bd8 <bcache>
    80003ce6:	ffffd097          	auipc	ra,0xffffd
    80003cea:	fb2080e7          	jalr	-78(ra) # 80000c98 <release>
}
    80003cee:	60e2                	ld	ra,24(sp)
    80003cf0:	6442                	ld	s0,16(sp)
    80003cf2:	64a2                	ld	s1,8(sp)
    80003cf4:	6105                	addi	sp,sp,32
    80003cf6:	8082                	ret

0000000080003cf8 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003cf8:	1101                	addi	sp,sp,-32
    80003cfa:	ec06                	sd	ra,24(sp)
    80003cfc:	e822                	sd	s0,16(sp)
    80003cfe:	e426                	sd	s1,8(sp)
    80003d00:	e04a                	sd	s2,0(sp)
    80003d02:	1000                	addi	s0,sp,32
    80003d04:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003d06:	00d5d59b          	srliw	a1,a1,0xd
    80003d0a:	0001c797          	auipc	a5,0x1c
    80003d0e:	5aa7a783          	lw	a5,1450(a5) # 800202b4 <sb+0x1c>
    80003d12:	9dbd                	addw	a1,a1,a5
    80003d14:	00000097          	auipc	ra,0x0
    80003d18:	d9e080e7          	jalr	-610(ra) # 80003ab2 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003d1c:	0074f713          	andi	a4,s1,7
    80003d20:	4785                	li	a5,1
    80003d22:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003d26:	14ce                	slli	s1,s1,0x33
    80003d28:	90d9                	srli	s1,s1,0x36
    80003d2a:	00950733          	add	a4,a0,s1
    80003d2e:	05874703          	lbu	a4,88(a4)
    80003d32:	00e7f6b3          	and	a3,a5,a4
    80003d36:	c69d                	beqz	a3,80003d64 <bfree+0x6c>
    80003d38:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003d3a:	94aa                	add	s1,s1,a0
    80003d3c:	fff7c793          	not	a5,a5
    80003d40:	8ff9                	and	a5,a5,a4
    80003d42:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003d46:	00001097          	auipc	ra,0x1
    80003d4a:	118080e7          	jalr	280(ra) # 80004e5e <log_write>
  brelse(bp);
    80003d4e:	854a                	mv	a0,s2
    80003d50:	00000097          	auipc	ra,0x0
    80003d54:	e92080e7          	jalr	-366(ra) # 80003be2 <brelse>
}
    80003d58:	60e2                	ld	ra,24(sp)
    80003d5a:	6442                	ld	s0,16(sp)
    80003d5c:	64a2                	ld	s1,8(sp)
    80003d5e:	6902                	ld	s2,0(sp)
    80003d60:	6105                	addi	sp,sp,32
    80003d62:	8082                	ret
    panic("freeing free block");
    80003d64:	00005517          	auipc	a0,0x5
    80003d68:	86c50513          	addi	a0,a0,-1940 # 800085d0 <syscalls+0x100>
    80003d6c:	ffffc097          	auipc	ra,0xffffc
    80003d70:	7d2080e7          	jalr	2002(ra) # 8000053e <panic>

0000000080003d74 <balloc>:
{
    80003d74:	711d                	addi	sp,sp,-96
    80003d76:	ec86                	sd	ra,88(sp)
    80003d78:	e8a2                	sd	s0,80(sp)
    80003d7a:	e4a6                	sd	s1,72(sp)
    80003d7c:	e0ca                	sd	s2,64(sp)
    80003d7e:	fc4e                	sd	s3,56(sp)
    80003d80:	f852                	sd	s4,48(sp)
    80003d82:	f456                	sd	s5,40(sp)
    80003d84:	f05a                	sd	s6,32(sp)
    80003d86:	ec5e                	sd	s7,24(sp)
    80003d88:	e862                	sd	s8,16(sp)
    80003d8a:	e466                	sd	s9,8(sp)
    80003d8c:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003d8e:	0001c797          	auipc	a5,0x1c
    80003d92:	50e7a783          	lw	a5,1294(a5) # 8002029c <sb+0x4>
    80003d96:	cbd1                	beqz	a5,80003e2a <balloc+0xb6>
    80003d98:	8baa                	mv	s7,a0
    80003d9a:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003d9c:	0001cb17          	auipc	s6,0x1c
    80003da0:	4fcb0b13          	addi	s6,s6,1276 # 80020298 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003da4:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003da6:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003da8:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003daa:	6c89                	lui	s9,0x2
    80003dac:	a831                	j	80003dc8 <balloc+0x54>
    brelse(bp);
    80003dae:	854a                	mv	a0,s2
    80003db0:	00000097          	auipc	ra,0x0
    80003db4:	e32080e7          	jalr	-462(ra) # 80003be2 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003db8:	015c87bb          	addw	a5,s9,s5
    80003dbc:	00078a9b          	sext.w	s5,a5
    80003dc0:	004b2703          	lw	a4,4(s6)
    80003dc4:	06eaf363          	bgeu	s5,a4,80003e2a <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003dc8:	41fad79b          	sraiw	a5,s5,0x1f
    80003dcc:	0137d79b          	srliw	a5,a5,0x13
    80003dd0:	015787bb          	addw	a5,a5,s5
    80003dd4:	40d7d79b          	sraiw	a5,a5,0xd
    80003dd8:	01cb2583          	lw	a1,28(s6)
    80003ddc:	9dbd                	addw	a1,a1,a5
    80003dde:	855e                	mv	a0,s7
    80003de0:	00000097          	auipc	ra,0x0
    80003de4:	cd2080e7          	jalr	-814(ra) # 80003ab2 <bread>
    80003de8:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003dea:	004b2503          	lw	a0,4(s6)
    80003dee:	000a849b          	sext.w	s1,s5
    80003df2:	8662                	mv	a2,s8
    80003df4:	faa4fde3          	bgeu	s1,a0,80003dae <balloc+0x3a>
      m = 1 << (bi % 8);
    80003df8:	41f6579b          	sraiw	a5,a2,0x1f
    80003dfc:	01d7d69b          	srliw	a3,a5,0x1d
    80003e00:	00c6873b          	addw	a4,a3,a2
    80003e04:	00777793          	andi	a5,a4,7
    80003e08:	9f95                	subw	a5,a5,a3
    80003e0a:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003e0e:	4037571b          	sraiw	a4,a4,0x3
    80003e12:	00e906b3          	add	a3,s2,a4
    80003e16:	0586c683          	lbu	a3,88(a3)
    80003e1a:	00d7f5b3          	and	a1,a5,a3
    80003e1e:	cd91                	beqz	a1,80003e3a <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003e20:	2605                	addiw	a2,a2,1
    80003e22:	2485                	addiw	s1,s1,1
    80003e24:	fd4618e3          	bne	a2,s4,80003df4 <balloc+0x80>
    80003e28:	b759                	j	80003dae <balloc+0x3a>
  panic("balloc: out of blocks");
    80003e2a:	00004517          	auipc	a0,0x4
    80003e2e:	7be50513          	addi	a0,a0,1982 # 800085e8 <syscalls+0x118>
    80003e32:	ffffc097          	auipc	ra,0xffffc
    80003e36:	70c080e7          	jalr	1804(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003e3a:	974a                	add	a4,a4,s2
    80003e3c:	8fd5                	or	a5,a5,a3
    80003e3e:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003e42:	854a                	mv	a0,s2
    80003e44:	00001097          	auipc	ra,0x1
    80003e48:	01a080e7          	jalr	26(ra) # 80004e5e <log_write>
        brelse(bp);
    80003e4c:	854a                	mv	a0,s2
    80003e4e:	00000097          	auipc	ra,0x0
    80003e52:	d94080e7          	jalr	-620(ra) # 80003be2 <brelse>
  bp = bread(dev, bno);
    80003e56:	85a6                	mv	a1,s1
    80003e58:	855e                	mv	a0,s7
    80003e5a:	00000097          	auipc	ra,0x0
    80003e5e:	c58080e7          	jalr	-936(ra) # 80003ab2 <bread>
    80003e62:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003e64:	40000613          	li	a2,1024
    80003e68:	4581                	li	a1,0
    80003e6a:	05850513          	addi	a0,a0,88
    80003e6e:	ffffd097          	auipc	ra,0xffffd
    80003e72:	e72080e7          	jalr	-398(ra) # 80000ce0 <memset>
  log_write(bp);
    80003e76:	854a                	mv	a0,s2
    80003e78:	00001097          	auipc	ra,0x1
    80003e7c:	fe6080e7          	jalr	-26(ra) # 80004e5e <log_write>
  brelse(bp);
    80003e80:	854a                	mv	a0,s2
    80003e82:	00000097          	auipc	ra,0x0
    80003e86:	d60080e7          	jalr	-672(ra) # 80003be2 <brelse>
}
    80003e8a:	8526                	mv	a0,s1
    80003e8c:	60e6                	ld	ra,88(sp)
    80003e8e:	6446                	ld	s0,80(sp)
    80003e90:	64a6                	ld	s1,72(sp)
    80003e92:	6906                	ld	s2,64(sp)
    80003e94:	79e2                	ld	s3,56(sp)
    80003e96:	7a42                	ld	s4,48(sp)
    80003e98:	7aa2                	ld	s5,40(sp)
    80003e9a:	7b02                	ld	s6,32(sp)
    80003e9c:	6be2                	ld	s7,24(sp)
    80003e9e:	6c42                	ld	s8,16(sp)
    80003ea0:	6ca2                	ld	s9,8(sp)
    80003ea2:	6125                	addi	sp,sp,96
    80003ea4:	8082                	ret

0000000080003ea6 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003ea6:	7179                	addi	sp,sp,-48
    80003ea8:	f406                	sd	ra,40(sp)
    80003eaa:	f022                	sd	s0,32(sp)
    80003eac:	ec26                	sd	s1,24(sp)
    80003eae:	e84a                	sd	s2,16(sp)
    80003eb0:	e44e                	sd	s3,8(sp)
    80003eb2:	e052                	sd	s4,0(sp)
    80003eb4:	1800                	addi	s0,sp,48
    80003eb6:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003eb8:	47ad                	li	a5,11
    80003eba:	04b7fe63          	bgeu	a5,a1,80003f16 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003ebe:	ff45849b          	addiw	s1,a1,-12
    80003ec2:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003ec6:	0ff00793          	li	a5,255
    80003eca:	0ae7e363          	bltu	a5,a4,80003f70 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003ece:	08052583          	lw	a1,128(a0)
    80003ed2:	c5ad                	beqz	a1,80003f3c <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003ed4:	00092503          	lw	a0,0(s2)
    80003ed8:	00000097          	auipc	ra,0x0
    80003edc:	bda080e7          	jalr	-1062(ra) # 80003ab2 <bread>
    80003ee0:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003ee2:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003ee6:	02049593          	slli	a1,s1,0x20
    80003eea:	9181                	srli	a1,a1,0x20
    80003eec:	058a                	slli	a1,a1,0x2
    80003eee:	00b784b3          	add	s1,a5,a1
    80003ef2:	0004a983          	lw	s3,0(s1)
    80003ef6:	04098d63          	beqz	s3,80003f50 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003efa:	8552                	mv	a0,s4
    80003efc:	00000097          	auipc	ra,0x0
    80003f00:	ce6080e7          	jalr	-794(ra) # 80003be2 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003f04:	854e                	mv	a0,s3
    80003f06:	70a2                	ld	ra,40(sp)
    80003f08:	7402                	ld	s0,32(sp)
    80003f0a:	64e2                	ld	s1,24(sp)
    80003f0c:	6942                	ld	s2,16(sp)
    80003f0e:	69a2                	ld	s3,8(sp)
    80003f10:	6a02                	ld	s4,0(sp)
    80003f12:	6145                	addi	sp,sp,48
    80003f14:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003f16:	02059493          	slli	s1,a1,0x20
    80003f1a:	9081                	srli	s1,s1,0x20
    80003f1c:	048a                	slli	s1,s1,0x2
    80003f1e:	94aa                	add	s1,s1,a0
    80003f20:	0504a983          	lw	s3,80(s1)
    80003f24:	fe0990e3          	bnez	s3,80003f04 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003f28:	4108                	lw	a0,0(a0)
    80003f2a:	00000097          	auipc	ra,0x0
    80003f2e:	e4a080e7          	jalr	-438(ra) # 80003d74 <balloc>
    80003f32:	0005099b          	sext.w	s3,a0
    80003f36:	0534a823          	sw	s3,80(s1)
    80003f3a:	b7e9                	j	80003f04 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003f3c:	4108                	lw	a0,0(a0)
    80003f3e:	00000097          	auipc	ra,0x0
    80003f42:	e36080e7          	jalr	-458(ra) # 80003d74 <balloc>
    80003f46:	0005059b          	sext.w	a1,a0
    80003f4a:	08b92023          	sw	a1,128(s2)
    80003f4e:	b759                	j	80003ed4 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003f50:	00092503          	lw	a0,0(s2)
    80003f54:	00000097          	auipc	ra,0x0
    80003f58:	e20080e7          	jalr	-480(ra) # 80003d74 <balloc>
    80003f5c:	0005099b          	sext.w	s3,a0
    80003f60:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003f64:	8552                	mv	a0,s4
    80003f66:	00001097          	auipc	ra,0x1
    80003f6a:	ef8080e7          	jalr	-264(ra) # 80004e5e <log_write>
    80003f6e:	b771                	j	80003efa <bmap+0x54>
  panic("bmap: out of range");
    80003f70:	00004517          	auipc	a0,0x4
    80003f74:	69050513          	addi	a0,a0,1680 # 80008600 <syscalls+0x130>
    80003f78:	ffffc097          	auipc	ra,0xffffc
    80003f7c:	5c6080e7          	jalr	1478(ra) # 8000053e <panic>

0000000080003f80 <iget>:
{
    80003f80:	7179                	addi	sp,sp,-48
    80003f82:	f406                	sd	ra,40(sp)
    80003f84:	f022                	sd	s0,32(sp)
    80003f86:	ec26                	sd	s1,24(sp)
    80003f88:	e84a                	sd	s2,16(sp)
    80003f8a:	e44e                	sd	s3,8(sp)
    80003f8c:	e052                	sd	s4,0(sp)
    80003f8e:	1800                	addi	s0,sp,48
    80003f90:	89aa                	mv	s3,a0
    80003f92:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003f94:	0001c517          	auipc	a0,0x1c
    80003f98:	32450513          	addi	a0,a0,804 # 800202b8 <itable>
    80003f9c:	ffffd097          	auipc	ra,0xffffd
    80003fa0:	c48080e7          	jalr	-952(ra) # 80000be4 <acquire>
  empty = 0;
    80003fa4:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003fa6:	0001c497          	auipc	s1,0x1c
    80003faa:	32a48493          	addi	s1,s1,810 # 800202d0 <itable+0x18>
    80003fae:	0001e697          	auipc	a3,0x1e
    80003fb2:	db268693          	addi	a3,a3,-590 # 80021d60 <log>
    80003fb6:	a039                	j	80003fc4 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003fb8:	02090b63          	beqz	s2,80003fee <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003fbc:	08848493          	addi	s1,s1,136
    80003fc0:	02d48a63          	beq	s1,a3,80003ff4 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003fc4:	449c                	lw	a5,8(s1)
    80003fc6:	fef059e3          	blez	a5,80003fb8 <iget+0x38>
    80003fca:	4098                	lw	a4,0(s1)
    80003fcc:	ff3716e3          	bne	a4,s3,80003fb8 <iget+0x38>
    80003fd0:	40d8                	lw	a4,4(s1)
    80003fd2:	ff4713e3          	bne	a4,s4,80003fb8 <iget+0x38>
      ip->ref++;
    80003fd6:	2785                	addiw	a5,a5,1
    80003fd8:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003fda:	0001c517          	auipc	a0,0x1c
    80003fde:	2de50513          	addi	a0,a0,734 # 800202b8 <itable>
    80003fe2:	ffffd097          	auipc	ra,0xffffd
    80003fe6:	cb6080e7          	jalr	-842(ra) # 80000c98 <release>
      return ip;
    80003fea:	8926                	mv	s2,s1
    80003fec:	a03d                	j	8000401a <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003fee:	f7f9                	bnez	a5,80003fbc <iget+0x3c>
    80003ff0:	8926                	mv	s2,s1
    80003ff2:	b7e9                	j	80003fbc <iget+0x3c>
  if(empty == 0)
    80003ff4:	02090c63          	beqz	s2,8000402c <iget+0xac>
  ip->dev = dev;
    80003ff8:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003ffc:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80004000:	4785                	li	a5,1
    80004002:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80004006:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000400a:	0001c517          	auipc	a0,0x1c
    8000400e:	2ae50513          	addi	a0,a0,686 # 800202b8 <itable>
    80004012:	ffffd097          	auipc	ra,0xffffd
    80004016:	c86080e7          	jalr	-890(ra) # 80000c98 <release>
}
    8000401a:	854a                	mv	a0,s2
    8000401c:	70a2                	ld	ra,40(sp)
    8000401e:	7402                	ld	s0,32(sp)
    80004020:	64e2                	ld	s1,24(sp)
    80004022:	6942                	ld	s2,16(sp)
    80004024:	69a2                	ld	s3,8(sp)
    80004026:	6a02                	ld	s4,0(sp)
    80004028:	6145                	addi	sp,sp,48
    8000402a:	8082                	ret
    panic("iget: no inodes");
    8000402c:	00004517          	auipc	a0,0x4
    80004030:	5ec50513          	addi	a0,a0,1516 # 80008618 <syscalls+0x148>
    80004034:	ffffc097          	auipc	ra,0xffffc
    80004038:	50a080e7          	jalr	1290(ra) # 8000053e <panic>

000000008000403c <fsinit>:
fsinit(int dev) {
    8000403c:	7179                	addi	sp,sp,-48
    8000403e:	f406                	sd	ra,40(sp)
    80004040:	f022                	sd	s0,32(sp)
    80004042:	ec26                	sd	s1,24(sp)
    80004044:	e84a                	sd	s2,16(sp)
    80004046:	e44e                	sd	s3,8(sp)
    80004048:	1800                	addi	s0,sp,48
    8000404a:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000404c:	4585                	li	a1,1
    8000404e:	00000097          	auipc	ra,0x0
    80004052:	a64080e7          	jalr	-1436(ra) # 80003ab2 <bread>
    80004056:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80004058:	0001c997          	auipc	s3,0x1c
    8000405c:	24098993          	addi	s3,s3,576 # 80020298 <sb>
    80004060:	02000613          	li	a2,32
    80004064:	05850593          	addi	a1,a0,88
    80004068:	854e                	mv	a0,s3
    8000406a:	ffffd097          	auipc	ra,0xffffd
    8000406e:	cd6080e7          	jalr	-810(ra) # 80000d40 <memmove>
  brelse(bp);
    80004072:	8526                	mv	a0,s1
    80004074:	00000097          	auipc	ra,0x0
    80004078:	b6e080e7          	jalr	-1170(ra) # 80003be2 <brelse>
  if(sb.magic != FSMAGIC)
    8000407c:	0009a703          	lw	a4,0(s3)
    80004080:	102037b7          	lui	a5,0x10203
    80004084:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80004088:	02f71263          	bne	a4,a5,800040ac <fsinit+0x70>
  initlog(dev, &sb);
    8000408c:	0001c597          	auipc	a1,0x1c
    80004090:	20c58593          	addi	a1,a1,524 # 80020298 <sb>
    80004094:	854a                	mv	a0,s2
    80004096:	00001097          	auipc	ra,0x1
    8000409a:	b4c080e7          	jalr	-1204(ra) # 80004be2 <initlog>
}
    8000409e:	70a2                	ld	ra,40(sp)
    800040a0:	7402                	ld	s0,32(sp)
    800040a2:	64e2                	ld	s1,24(sp)
    800040a4:	6942                	ld	s2,16(sp)
    800040a6:	69a2                	ld	s3,8(sp)
    800040a8:	6145                	addi	sp,sp,48
    800040aa:	8082                	ret
    panic("invalid file system");
    800040ac:	00004517          	auipc	a0,0x4
    800040b0:	57c50513          	addi	a0,a0,1404 # 80008628 <syscalls+0x158>
    800040b4:	ffffc097          	auipc	ra,0xffffc
    800040b8:	48a080e7          	jalr	1162(ra) # 8000053e <panic>

00000000800040bc <iinit>:
{
    800040bc:	7179                	addi	sp,sp,-48
    800040be:	f406                	sd	ra,40(sp)
    800040c0:	f022                	sd	s0,32(sp)
    800040c2:	ec26                	sd	s1,24(sp)
    800040c4:	e84a                	sd	s2,16(sp)
    800040c6:	e44e                	sd	s3,8(sp)
    800040c8:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800040ca:	00004597          	auipc	a1,0x4
    800040ce:	57658593          	addi	a1,a1,1398 # 80008640 <syscalls+0x170>
    800040d2:	0001c517          	auipc	a0,0x1c
    800040d6:	1e650513          	addi	a0,a0,486 # 800202b8 <itable>
    800040da:	ffffd097          	auipc	ra,0xffffd
    800040de:	a7a080e7          	jalr	-1414(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    800040e2:	0001c497          	auipc	s1,0x1c
    800040e6:	1fe48493          	addi	s1,s1,510 # 800202e0 <itable+0x28>
    800040ea:	0001e997          	auipc	s3,0x1e
    800040ee:	c8698993          	addi	s3,s3,-890 # 80021d70 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800040f2:	00004917          	auipc	s2,0x4
    800040f6:	55690913          	addi	s2,s2,1366 # 80008648 <syscalls+0x178>
    800040fa:	85ca                	mv	a1,s2
    800040fc:	8526                	mv	a0,s1
    800040fe:	00001097          	auipc	ra,0x1
    80004102:	e46080e7          	jalr	-442(ra) # 80004f44 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80004106:	08848493          	addi	s1,s1,136
    8000410a:	ff3498e3          	bne	s1,s3,800040fa <iinit+0x3e>
}
    8000410e:	70a2                	ld	ra,40(sp)
    80004110:	7402                	ld	s0,32(sp)
    80004112:	64e2                	ld	s1,24(sp)
    80004114:	6942                	ld	s2,16(sp)
    80004116:	69a2                	ld	s3,8(sp)
    80004118:	6145                	addi	sp,sp,48
    8000411a:	8082                	ret

000000008000411c <ialloc>:
{
    8000411c:	715d                	addi	sp,sp,-80
    8000411e:	e486                	sd	ra,72(sp)
    80004120:	e0a2                	sd	s0,64(sp)
    80004122:	fc26                	sd	s1,56(sp)
    80004124:	f84a                	sd	s2,48(sp)
    80004126:	f44e                	sd	s3,40(sp)
    80004128:	f052                	sd	s4,32(sp)
    8000412a:	ec56                	sd	s5,24(sp)
    8000412c:	e85a                	sd	s6,16(sp)
    8000412e:	e45e                	sd	s7,8(sp)
    80004130:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80004132:	0001c717          	auipc	a4,0x1c
    80004136:	17272703          	lw	a4,370(a4) # 800202a4 <sb+0xc>
    8000413a:	4785                	li	a5,1
    8000413c:	04e7fa63          	bgeu	a5,a4,80004190 <ialloc+0x74>
    80004140:	8aaa                	mv	s5,a0
    80004142:	8bae                	mv	s7,a1
    80004144:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80004146:	0001ca17          	auipc	s4,0x1c
    8000414a:	152a0a13          	addi	s4,s4,338 # 80020298 <sb>
    8000414e:	00048b1b          	sext.w	s6,s1
    80004152:	0044d593          	srli	a1,s1,0x4
    80004156:	018a2783          	lw	a5,24(s4)
    8000415a:	9dbd                	addw	a1,a1,a5
    8000415c:	8556                	mv	a0,s5
    8000415e:	00000097          	auipc	ra,0x0
    80004162:	954080e7          	jalr	-1708(ra) # 80003ab2 <bread>
    80004166:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80004168:	05850993          	addi	s3,a0,88
    8000416c:	00f4f793          	andi	a5,s1,15
    80004170:	079a                	slli	a5,a5,0x6
    80004172:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80004174:	00099783          	lh	a5,0(s3)
    80004178:	c785                	beqz	a5,800041a0 <ialloc+0x84>
    brelse(bp);
    8000417a:	00000097          	auipc	ra,0x0
    8000417e:	a68080e7          	jalr	-1432(ra) # 80003be2 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80004182:	0485                	addi	s1,s1,1
    80004184:	00ca2703          	lw	a4,12(s4)
    80004188:	0004879b          	sext.w	a5,s1
    8000418c:	fce7e1e3          	bltu	a5,a4,8000414e <ialloc+0x32>
  panic("ialloc: no inodes");
    80004190:	00004517          	auipc	a0,0x4
    80004194:	4c050513          	addi	a0,a0,1216 # 80008650 <syscalls+0x180>
    80004198:	ffffc097          	auipc	ra,0xffffc
    8000419c:	3a6080e7          	jalr	934(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    800041a0:	04000613          	li	a2,64
    800041a4:	4581                	li	a1,0
    800041a6:	854e                	mv	a0,s3
    800041a8:	ffffd097          	auipc	ra,0xffffd
    800041ac:	b38080e7          	jalr	-1224(ra) # 80000ce0 <memset>
      dip->type = type;
    800041b0:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800041b4:	854a                	mv	a0,s2
    800041b6:	00001097          	auipc	ra,0x1
    800041ba:	ca8080e7          	jalr	-856(ra) # 80004e5e <log_write>
      brelse(bp);
    800041be:	854a                	mv	a0,s2
    800041c0:	00000097          	auipc	ra,0x0
    800041c4:	a22080e7          	jalr	-1502(ra) # 80003be2 <brelse>
      return iget(dev, inum);
    800041c8:	85da                	mv	a1,s6
    800041ca:	8556                	mv	a0,s5
    800041cc:	00000097          	auipc	ra,0x0
    800041d0:	db4080e7          	jalr	-588(ra) # 80003f80 <iget>
}
    800041d4:	60a6                	ld	ra,72(sp)
    800041d6:	6406                	ld	s0,64(sp)
    800041d8:	74e2                	ld	s1,56(sp)
    800041da:	7942                	ld	s2,48(sp)
    800041dc:	79a2                	ld	s3,40(sp)
    800041de:	7a02                	ld	s4,32(sp)
    800041e0:	6ae2                	ld	s5,24(sp)
    800041e2:	6b42                	ld	s6,16(sp)
    800041e4:	6ba2                	ld	s7,8(sp)
    800041e6:	6161                	addi	sp,sp,80
    800041e8:	8082                	ret

00000000800041ea <iupdate>:
{
    800041ea:	1101                	addi	sp,sp,-32
    800041ec:	ec06                	sd	ra,24(sp)
    800041ee:	e822                	sd	s0,16(sp)
    800041f0:	e426                	sd	s1,8(sp)
    800041f2:	e04a                	sd	s2,0(sp)
    800041f4:	1000                	addi	s0,sp,32
    800041f6:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800041f8:	415c                	lw	a5,4(a0)
    800041fa:	0047d79b          	srliw	a5,a5,0x4
    800041fe:	0001c597          	auipc	a1,0x1c
    80004202:	0b25a583          	lw	a1,178(a1) # 800202b0 <sb+0x18>
    80004206:	9dbd                	addw	a1,a1,a5
    80004208:	4108                	lw	a0,0(a0)
    8000420a:	00000097          	auipc	ra,0x0
    8000420e:	8a8080e7          	jalr	-1880(ra) # 80003ab2 <bread>
    80004212:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80004214:	05850793          	addi	a5,a0,88
    80004218:	40c8                	lw	a0,4(s1)
    8000421a:	893d                	andi	a0,a0,15
    8000421c:	051a                	slli	a0,a0,0x6
    8000421e:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80004220:	04449703          	lh	a4,68(s1)
    80004224:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80004228:	04649703          	lh	a4,70(s1)
    8000422c:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80004230:	04849703          	lh	a4,72(s1)
    80004234:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80004238:	04a49703          	lh	a4,74(s1)
    8000423c:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80004240:	44f8                	lw	a4,76(s1)
    80004242:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80004244:	03400613          	li	a2,52
    80004248:	05048593          	addi	a1,s1,80
    8000424c:	0531                	addi	a0,a0,12
    8000424e:	ffffd097          	auipc	ra,0xffffd
    80004252:	af2080e7          	jalr	-1294(ra) # 80000d40 <memmove>
  log_write(bp);
    80004256:	854a                	mv	a0,s2
    80004258:	00001097          	auipc	ra,0x1
    8000425c:	c06080e7          	jalr	-1018(ra) # 80004e5e <log_write>
  brelse(bp);
    80004260:	854a                	mv	a0,s2
    80004262:	00000097          	auipc	ra,0x0
    80004266:	980080e7          	jalr	-1664(ra) # 80003be2 <brelse>
}
    8000426a:	60e2                	ld	ra,24(sp)
    8000426c:	6442                	ld	s0,16(sp)
    8000426e:	64a2                	ld	s1,8(sp)
    80004270:	6902                	ld	s2,0(sp)
    80004272:	6105                	addi	sp,sp,32
    80004274:	8082                	ret

0000000080004276 <idup>:
{
    80004276:	1101                	addi	sp,sp,-32
    80004278:	ec06                	sd	ra,24(sp)
    8000427a:	e822                	sd	s0,16(sp)
    8000427c:	e426                	sd	s1,8(sp)
    8000427e:	1000                	addi	s0,sp,32
    80004280:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004282:	0001c517          	auipc	a0,0x1c
    80004286:	03650513          	addi	a0,a0,54 # 800202b8 <itable>
    8000428a:	ffffd097          	auipc	ra,0xffffd
    8000428e:	95a080e7          	jalr	-1702(ra) # 80000be4 <acquire>
  ip->ref++;
    80004292:	449c                	lw	a5,8(s1)
    80004294:	2785                	addiw	a5,a5,1
    80004296:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004298:	0001c517          	auipc	a0,0x1c
    8000429c:	02050513          	addi	a0,a0,32 # 800202b8 <itable>
    800042a0:	ffffd097          	auipc	ra,0xffffd
    800042a4:	9f8080e7          	jalr	-1544(ra) # 80000c98 <release>
}
    800042a8:	8526                	mv	a0,s1
    800042aa:	60e2                	ld	ra,24(sp)
    800042ac:	6442                	ld	s0,16(sp)
    800042ae:	64a2                	ld	s1,8(sp)
    800042b0:	6105                	addi	sp,sp,32
    800042b2:	8082                	ret

00000000800042b4 <ilock>:
{
    800042b4:	1101                	addi	sp,sp,-32
    800042b6:	ec06                	sd	ra,24(sp)
    800042b8:	e822                	sd	s0,16(sp)
    800042ba:	e426                	sd	s1,8(sp)
    800042bc:	e04a                	sd	s2,0(sp)
    800042be:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800042c0:	c115                	beqz	a0,800042e4 <ilock+0x30>
    800042c2:	84aa                	mv	s1,a0
    800042c4:	451c                	lw	a5,8(a0)
    800042c6:	00f05f63          	blez	a5,800042e4 <ilock+0x30>
  acquiresleep(&ip->lock);
    800042ca:	0541                	addi	a0,a0,16
    800042cc:	00001097          	auipc	ra,0x1
    800042d0:	cb2080e7          	jalr	-846(ra) # 80004f7e <acquiresleep>
  if(ip->valid == 0){
    800042d4:	40bc                	lw	a5,64(s1)
    800042d6:	cf99                	beqz	a5,800042f4 <ilock+0x40>
}
    800042d8:	60e2                	ld	ra,24(sp)
    800042da:	6442                	ld	s0,16(sp)
    800042dc:	64a2                	ld	s1,8(sp)
    800042de:	6902                	ld	s2,0(sp)
    800042e0:	6105                	addi	sp,sp,32
    800042e2:	8082                	ret
    panic("ilock");
    800042e4:	00004517          	auipc	a0,0x4
    800042e8:	38450513          	addi	a0,a0,900 # 80008668 <syscalls+0x198>
    800042ec:	ffffc097          	auipc	ra,0xffffc
    800042f0:	252080e7          	jalr	594(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800042f4:	40dc                	lw	a5,4(s1)
    800042f6:	0047d79b          	srliw	a5,a5,0x4
    800042fa:	0001c597          	auipc	a1,0x1c
    800042fe:	fb65a583          	lw	a1,-74(a1) # 800202b0 <sb+0x18>
    80004302:	9dbd                	addw	a1,a1,a5
    80004304:	4088                	lw	a0,0(s1)
    80004306:	fffff097          	auipc	ra,0xfffff
    8000430a:	7ac080e7          	jalr	1964(ra) # 80003ab2 <bread>
    8000430e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80004310:	05850593          	addi	a1,a0,88
    80004314:	40dc                	lw	a5,4(s1)
    80004316:	8bbd                	andi	a5,a5,15
    80004318:	079a                	slli	a5,a5,0x6
    8000431a:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000431c:	00059783          	lh	a5,0(a1)
    80004320:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80004324:	00259783          	lh	a5,2(a1)
    80004328:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000432c:	00459783          	lh	a5,4(a1)
    80004330:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80004334:	00659783          	lh	a5,6(a1)
    80004338:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000433c:	459c                	lw	a5,8(a1)
    8000433e:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80004340:	03400613          	li	a2,52
    80004344:	05b1                	addi	a1,a1,12
    80004346:	05048513          	addi	a0,s1,80
    8000434a:	ffffd097          	auipc	ra,0xffffd
    8000434e:	9f6080e7          	jalr	-1546(ra) # 80000d40 <memmove>
    brelse(bp);
    80004352:	854a                	mv	a0,s2
    80004354:	00000097          	auipc	ra,0x0
    80004358:	88e080e7          	jalr	-1906(ra) # 80003be2 <brelse>
    ip->valid = 1;
    8000435c:	4785                	li	a5,1
    8000435e:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80004360:	04449783          	lh	a5,68(s1)
    80004364:	fbb5                	bnez	a5,800042d8 <ilock+0x24>
      panic("ilock: no type");
    80004366:	00004517          	auipc	a0,0x4
    8000436a:	30a50513          	addi	a0,a0,778 # 80008670 <syscalls+0x1a0>
    8000436e:	ffffc097          	auipc	ra,0xffffc
    80004372:	1d0080e7          	jalr	464(ra) # 8000053e <panic>

0000000080004376 <iunlock>:
{
    80004376:	1101                	addi	sp,sp,-32
    80004378:	ec06                	sd	ra,24(sp)
    8000437a:	e822                	sd	s0,16(sp)
    8000437c:	e426                	sd	s1,8(sp)
    8000437e:	e04a                	sd	s2,0(sp)
    80004380:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80004382:	c905                	beqz	a0,800043b2 <iunlock+0x3c>
    80004384:	84aa                	mv	s1,a0
    80004386:	01050913          	addi	s2,a0,16
    8000438a:	854a                	mv	a0,s2
    8000438c:	00001097          	auipc	ra,0x1
    80004390:	c8c080e7          	jalr	-884(ra) # 80005018 <holdingsleep>
    80004394:	cd19                	beqz	a0,800043b2 <iunlock+0x3c>
    80004396:	449c                	lw	a5,8(s1)
    80004398:	00f05d63          	blez	a5,800043b2 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000439c:	854a                	mv	a0,s2
    8000439e:	00001097          	auipc	ra,0x1
    800043a2:	c36080e7          	jalr	-970(ra) # 80004fd4 <releasesleep>
}
    800043a6:	60e2                	ld	ra,24(sp)
    800043a8:	6442                	ld	s0,16(sp)
    800043aa:	64a2                	ld	s1,8(sp)
    800043ac:	6902                	ld	s2,0(sp)
    800043ae:	6105                	addi	sp,sp,32
    800043b0:	8082                	ret
    panic("iunlock");
    800043b2:	00004517          	auipc	a0,0x4
    800043b6:	2ce50513          	addi	a0,a0,718 # 80008680 <syscalls+0x1b0>
    800043ba:	ffffc097          	auipc	ra,0xffffc
    800043be:	184080e7          	jalr	388(ra) # 8000053e <panic>

00000000800043c2 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800043c2:	7179                	addi	sp,sp,-48
    800043c4:	f406                	sd	ra,40(sp)
    800043c6:	f022                	sd	s0,32(sp)
    800043c8:	ec26                	sd	s1,24(sp)
    800043ca:	e84a                	sd	s2,16(sp)
    800043cc:	e44e                	sd	s3,8(sp)
    800043ce:	e052                	sd	s4,0(sp)
    800043d0:	1800                	addi	s0,sp,48
    800043d2:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800043d4:	05050493          	addi	s1,a0,80
    800043d8:	08050913          	addi	s2,a0,128
    800043dc:	a021                	j	800043e4 <itrunc+0x22>
    800043de:	0491                	addi	s1,s1,4
    800043e0:	01248d63          	beq	s1,s2,800043fa <itrunc+0x38>
    if(ip->addrs[i]){
    800043e4:	408c                	lw	a1,0(s1)
    800043e6:	dde5                	beqz	a1,800043de <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800043e8:	0009a503          	lw	a0,0(s3)
    800043ec:	00000097          	auipc	ra,0x0
    800043f0:	90c080e7          	jalr	-1780(ra) # 80003cf8 <bfree>
      ip->addrs[i] = 0;
    800043f4:	0004a023          	sw	zero,0(s1)
    800043f8:	b7dd                	j	800043de <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800043fa:	0809a583          	lw	a1,128(s3)
    800043fe:	e185                	bnez	a1,8000441e <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80004400:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80004404:	854e                	mv	a0,s3
    80004406:	00000097          	auipc	ra,0x0
    8000440a:	de4080e7          	jalr	-540(ra) # 800041ea <iupdate>
}
    8000440e:	70a2                	ld	ra,40(sp)
    80004410:	7402                	ld	s0,32(sp)
    80004412:	64e2                	ld	s1,24(sp)
    80004414:	6942                	ld	s2,16(sp)
    80004416:	69a2                	ld	s3,8(sp)
    80004418:	6a02                	ld	s4,0(sp)
    8000441a:	6145                	addi	sp,sp,48
    8000441c:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000441e:	0009a503          	lw	a0,0(s3)
    80004422:	fffff097          	auipc	ra,0xfffff
    80004426:	690080e7          	jalr	1680(ra) # 80003ab2 <bread>
    8000442a:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    8000442c:	05850493          	addi	s1,a0,88
    80004430:	45850913          	addi	s2,a0,1112
    80004434:	a811                	j	80004448 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80004436:	0009a503          	lw	a0,0(s3)
    8000443a:	00000097          	auipc	ra,0x0
    8000443e:	8be080e7          	jalr	-1858(ra) # 80003cf8 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80004442:	0491                	addi	s1,s1,4
    80004444:	01248563          	beq	s1,s2,8000444e <itrunc+0x8c>
      if(a[j])
    80004448:	408c                	lw	a1,0(s1)
    8000444a:	dde5                	beqz	a1,80004442 <itrunc+0x80>
    8000444c:	b7ed                	j	80004436 <itrunc+0x74>
    brelse(bp);
    8000444e:	8552                	mv	a0,s4
    80004450:	fffff097          	auipc	ra,0xfffff
    80004454:	792080e7          	jalr	1938(ra) # 80003be2 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80004458:	0809a583          	lw	a1,128(s3)
    8000445c:	0009a503          	lw	a0,0(s3)
    80004460:	00000097          	auipc	ra,0x0
    80004464:	898080e7          	jalr	-1896(ra) # 80003cf8 <bfree>
    ip->addrs[NDIRECT] = 0;
    80004468:	0809a023          	sw	zero,128(s3)
    8000446c:	bf51                	j	80004400 <itrunc+0x3e>

000000008000446e <iput>:
{
    8000446e:	1101                	addi	sp,sp,-32
    80004470:	ec06                	sd	ra,24(sp)
    80004472:	e822                	sd	s0,16(sp)
    80004474:	e426                	sd	s1,8(sp)
    80004476:	e04a                	sd	s2,0(sp)
    80004478:	1000                	addi	s0,sp,32
    8000447a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000447c:	0001c517          	auipc	a0,0x1c
    80004480:	e3c50513          	addi	a0,a0,-452 # 800202b8 <itable>
    80004484:	ffffc097          	auipc	ra,0xffffc
    80004488:	760080e7          	jalr	1888(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000448c:	4498                	lw	a4,8(s1)
    8000448e:	4785                	li	a5,1
    80004490:	02f70363          	beq	a4,a5,800044b6 <iput+0x48>
  ip->ref--;
    80004494:	449c                	lw	a5,8(s1)
    80004496:	37fd                	addiw	a5,a5,-1
    80004498:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000449a:	0001c517          	auipc	a0,0x1c
    8000449e:	e1e50513          	addi	a0,a0,-482 # 800202b8 <itable>
    800044a2:	ffffc097          	auipc	ra,0xffffc
    800044a6:	7f6080e7          	jalr	2038(ra) # 80000c98 <release>
}
    800044aa:	60e2                	ld	ra,24(sp)
    800044ac:	6442                	ld	s0,16(sp)
    800044ae:	64a2                	ld	s1,8(sp)
    800044b0:	6902                	ld	s2,0(sp)
    800044b2:	6105                	addi	sp,sp,32
    800044b4:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800044b6:	40bc                	lw	a5,64(s1)
    800044b8:	dff1                	beqz	a5,80004494 <iput+0x26>
    800044ba:	04a49783          	lh	a5,74(s1)
    800044be:	fbf9                	bnez	a5,80004494 <iput+0x26>
    acquiresleep(&ip->lock);
    800044c0:	01048913          	addi	s2,s1,16
    800044c4:	854a                	mv	a0,s2
    800044c6:	00001097          	auipc	ra,0x1
    800044ca:	ab8080e7          	jalr	-1352(ra) # 80004f7e <acquiresleep>
    release(&itable.lock);
    800044ce:	0001c517          	auipc	a0,0x1c
    800044d2:	dea50513          	addi	a0,a0,-534 # 800202b8 <itable>
    800044d6:	ffffc097          	auipc	ra,0xffffc
    800044da:	7c2080e7          	jalr	1986(ra) # 80000c98 <release>
    itrunc(ip);
    800044de:	8526                	mv	a0,s1
    800044e0:	00000097          	auipc	ra,0x0
    800044e4:	ee2080e7          	jalr	-286(ra) # 800043c2 <itrunc>
    ip->type = 0;
    800044e8:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800044ec:	8526                	mv	a0,s1
    800044ee:	00000097          	auipc	ra,0x0
    800044f2:	cfc080e7          	jalr	-772(ra) # 800041ea <iupdate>
    ip->valid = 0;
    800044f6:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800044fa:	854a                	mv	a0,s2
    800044fc:	00001097          	auipc	ra,0x1
    80004500:	ad8080e7          	jalr	-1320(ra) # 80004fd4 <releasesleep>
    acquire(&itable.lock);
    80004504:	0001c517          	auipc	a0,0x1c
    80004508:	db450513          	addi	a0,a0,-588 # 800202b8 <itable>
    8000450c:	ffffc097          	auipc	ra,0xffffc
    80004510:	6d8080e7          	jalr	1752(ra) # 80000be4 <acquire>
    80004514:	b741                	j	80004494 <iput+0x26>

0000000080004516 <iunlockput>:
{
    80004516:	1101                	addi	sp,sp,-32
    80004518:	ec06                	sd	ra,24(sp)
    8000451a:	e822                	sd	s0,16(sp)
    8000451c:	e426                	sd	s1,8(sp)
    8000451e:	1000                	addi	s0,sp,32
    80004520:	84aa                	mv	s1,a0
  iunlock(ip);
    80004522:	00000097          	auipc	ra,0x0
    80004526:	e54080e7          	jalr	-428(ra) # 80004376 <iunlock>
  iput(ip);
    8000452a:	8526                	mv	a0,s1
    8000452c:	00000097          	auipc	ra,0x0
    80004530:	f42080e7          	jalr	-190(ra) # 8000446e <iput>
}
    80004534:	60e2                	ld	ra,24(sp)
    80004536:	6442                	ld	s0,16(sp)
    80004538:	64a2                	ld	s1,8(sp)
    8000453a:	6105                	addi	sp,sp,32
    8000453c:	8082                	ret

000000008000453e <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    8000453e:	1141                	addi	sp,sp,-16
    80004540:	e422                	sd	s0,8(sp)
    80004542:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80004544:	411c                	lw	a5,0(a0)
    80004546:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80004548:	415c                	lw	a5,4(a0)
    8000454a:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    8000454c:	04451783          	lh	a5,68(a0)
    80004550:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80004554:	04a51783          	lh	a5,74(a0)
    80004558:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    8000455c:	04c56783          	lwu	a5,76(a0)
    80004560:	e99c                	sd	a5,16(a1)
}
    80004562:	6422                	ld	s0,8(sp)
    80004564:	0141                	addi	sp,sp,16
    80004566:	8082                	ret

0000000080004568 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004568:	457c                	lw	a5,76(a0)
    8000456a:	0ed7e963          	bltu	a5,a3,8000465c <readi+0xf4>
{
    8000456e:	7159                	addi	sp,sp,-112
    80004570:	f486                	sd	ra,104(sp)
    80004572:	f0a2                	sd	s0,96(sp)
    80004574:	eca6                	sd	s1,88(sp)
    80004576:	e8ca                	sd	s2,80(sp)
    80004578:	e4ce                	sd	s3,72(sp)
    8000457a:	e0d2                	sd	s4,64(sp)
    8000457c:	fc56                	sd	s5,56(sp)
    8000457e:	f85a                	sd	s6,48(sp)
    80004580:	f45e                	sd	s7,40(sp)
    80004582:	f062                	sd	s8,32(sp)
    80004584:	ec66                	sd	s9,24(sp)
    80004586:	e86a                	sd	s10,16(sp)
    80004588:	e46e                	sd	s11,8(sp)
    8000458a:	1880                	addi	s0,sp,112
    8000458c:	8baa                	mv	s7,a0
    8000458e:	8c2e                	mv	s8,a1
    80004590:	8ab2                	mv	s5,a2
    80004592:	84b6                	mv	s1,a3
    80004594:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004596:	9f35                	addw	a4,a4,a3
    return 0;
    80004598:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    8000459a:	0ad76063          	bltu	a4,a3,8000463a <readi+0xd2>
  if(off + n > ip->size)
    8000459e:	00e7f463          	bgeu	a5,a4,800045a6 <readi+0x3e>
    n = ip->size - off;
    800045a2:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800045a6:	0a0b0963          	beqz	s6,80004658 <readi+0xf0>
    800045aa:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800045ac:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800045b0:	5cfd                	li	s9,-1
    800045b2:	a82d                	j	800045ec <readi+0x84>
    800045b4:	020a1d93          	slli	s11,s4,0x20
    800045b8:	020ddd93          	srli	s11,s11,0x20
    800045bc:	05890613          	addi	a2,s2,88
    800045c0:	86ee                	mv	a3,s11
    800045c2:	963a                	add	a2,a2,a4
    800045c4:	85d6                	mv	a1,s5
    800045c6:	8562                	mv	a0,s8
    800045c8:	ffffe097          	auipc	ra,0xffffe
    800045cc:	7be080e7          	jalr	1982(ra) # 80002d86 <either_copyout>
    800045d0:	05950d63          	beq	a0,s9,8000462a <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800045d4:	854a                	mv	a0,s2
    800045d6:	fffff097          	auipc	ra,0xfffff
    800045da:	60c080e7          	jalr	1548(ra) # 80003be2 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800045de:	013a09bb          	addw	s3,s4,s3
    800045e2:	009a04bb          	addw	s1,s4,s1
    800045e6:	9aee                	add	s5,s5,s11
    800045e8:	0569f763          	bgeu	s3,s6,80004636 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800045ec:	000ba903          	lw	s2,0(s7)
    800045f0:	00a4d59b          	srliw	a1,s1,0xa
    800045f4:	855e                	mv	a0,s7
    800045f6:	00000097          	auipc	ra,0x0
    800045fa:	8b0080e7          	jalr	-1872(ra) # 80003ea6 <bmap>
    800045fe:	0005059b          	sext.w	a1,a0
    80004602:	854a                	mv	a0,s2
    80004604:	fffff097          	auipc	ra,0xfffff
    80004608:	4ae080e7          	jalr	1198(ra) # 80003ab2 <bread>
    8000460c:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000460e:	3ff4f713          	andi	a4,s1,1023
    80004612:	40ed07bb          	subw	a5,s10,a4
    80004616:	413b06bb          	subw	a3,s6,s3
    8000461a:	8a3e                	mv	s4,a5
    8000461c:	2781                	sext.w	a5,a5
    8000461e:	0006861b          	sext.w	a2,a3
    80004622:	f8f679e3          	bgeu	a2,a5,800045b4 <readi+0x4c>
    80004626:	8a36                	mv	s4,a3
    80004628:	b771                	j	800045b4 <readi+0x4c>
      brelse(bp);
    8000462a:	854a                	mv	a0,s2
    8000462c:	fffff097          	auipc	ra,0xfffff
    80004630:	5b6080e7          	jalr	1462(ra) # 80003be2 <brelse>
      tot = -1;
    80004634:	59fd                	li	s3,-1
  }
  return tot;
    80004636:	0009851b          	sext.w	a0,s3
}
    8000463a:	70a6                	ld	ra,104(sp)
    8000463c:	7406                	ld	s0,96(sp)
    8000463e:	64e6                	ld	s1,88(sp)
    80004640:	6946                	ld	s2,80(sp)
    80004642:	69a6                	ld	s3,72(sp)
    80004644:	6a06                	ld	s4,64(sp)
    80004646:	7ae2                	ld	s5,56(sp)
    80004648:	7b42                	ld	s6,48(sp)
    8000464a:	7ba2                	ld	s7,40(sp)
    8000464c:	7c02                	ld	s8,32(sp)
    8000464e:	6ce2                	ld	s9,24(sp)
    80004650:	6d42                	ld	s10,16(sp)
    80004652:	6da2                	ld	s11,8(sp)
    80004654:	6165                	addi	sp,sp,112
    80004656:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004658:	89da                	mv	s3,s6
    8000465a:	bff1                	j	80004636 <readi+0xce>
    return 0;
    8000465c:	4501                	li	a0,0
}
    8000465e:	8082                	ret

0000000080004660 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004660:	457c                	lw	a5,76(a0)
    80004662:	10d7e863          	bltu	a5,a3,80004772 <writei+0x112>
{
    80004666:	7159                	addi	sp,sp,-112
    80004668:	f486                	sd	ra,104(sp)
    8000466a:	f0a2                	sd	s0,96(sp)
    8000466c:	eca6                	sd	s1,88(sp)
    8000466e:	e8ca                	sd	s2,80(sp)
    80004670:	e4ce                	sd	s3,72(sp)
    80004672:	e0d2                	sd	s4,64(sp)
    80004674:	fc56                	sd	s5,56(sp)
    80004676:	f85a                	sd	s6,48(sp)
    80004678:	f45e                	sd	s7,40(sp)
    8000467a:	f062                	sd	s8,32(sp)
    8000467c:	ec66                	sd	s9,24(sp)
    8000467e:	e86a                	sd	s10,16(sp)
    80004680:	e46e                	sd	s11,8(sp)
    80004682:	1880                	addi	s0,sp,112
    80004684:	8b2a                	mv	s6,a0
    80004686:	8c2e                	mv	s8,a1
    80004688:	8ab2                	mv	s5,a2
    8000468a:	8936                	mv	s2,a3
    8000468c:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    8000468e:	00e687bb          	addw	a5,a3,a4
    80004692:	0ed7e263          	bltu	a5,a3,80004776 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004696:	00043737          	lui	a4,0x43
    8000469a:	0ef76063          	bltu	a4,a5,8000477a <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000469e:	0c0b8863          	beqz	s7,8000476e <writei+0x10e>
    800046a2:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800046a4:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800046a8:	5cfd                	li	s9,-1
    800046aa:	a091                	j	800046ee <writei+0x8e>
    800046ac:	02099d93          	slli	s11,s3,0x20
    800046b0:	020ddd93          	srli	s11,s11,0x20
    800046b4:	05848513          	addi	a0,s1,88
    800046b8:	86ee                	mv	a3,s11
    800046ba:	8656                	mv	a2,s5
    800046bc:	85e2                	mv	a1,s8
    800046be:	953a                	add	a0,a0,a4
    800046c0:	ffffe097          	auipc	ra,0xffffe
    800046c4:	71c080e7          	jalr	1820(ra) # 80002ddc <either_copyin>
    800046c8:	07950263          	beq	a0,s9,8000472c <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800046cc:	8526                	mv	a0,s1
    800046ce:	00000097          	auipc	ra,0x0
    800046d2:	790080e7          	jalr	1936(ra) # 80004e5e <log_write>
    brelse(bp);
    800046d6:	8526                	mv	a0,s1
    800046d8:	fffff097          	auipc	ra,0xfffff
    800046dc:	50a080e7          	jalr	1290(ra) # 80003be2 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800046e0:	01498a3b          	addw	s4,s3,s4
    800046e4:	0129893b          	addw	s2,s3,s2
    800046e8:	9aee                	add	s5,s5,s11
    800046ea:	057a7663          	bgeu	s4,s7,80004736 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800046ee:	000b2483          	lw	s1,0(s6)
    800046f2:	00a9559b          	srliw	a1,s2,0xa
    800046f6:	855a                	mv	a0,s6
    800046f8:	fffff097          	auipc	ra,0xfffff
    800046fc:	7ae080e7          	jalr	1966(ra) # 80003ea6 <bmap>
    80004700:	0005059b          	sext.w	a1,a0
    80004704:	8526                	mv	a0,s1
    80004706:	fffff097          	auipc	ra,0xfffff
    8000470a:	3ac080e7          	jalr	940(ra) # 80003ab2 <bread>
    8000470e:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004710:	3ff97713          	andi	a4,s2,1023
    80004714:	40ed07bb          	subw	a5,s10,a4
    80004718:	414b86bb          	subw	a3,s7,s4
    8000471c:	89be                	mv	s3,a5
    8000471e:	2781                	sext.w	a5,a5
    80004720:	0006861b          	sext.w	a2,a3
    80004724:	f8f674e3          	bgeu	a2,a5,800046ac <writei+0x4c>
    80004728:	89b6                	mv	s3,a3
    8000472a:	b749                	j	800046ac <writei+0x4c>
      brelse(bp);
    8000472c:	8526                	mv	a0,s1
    8000472e:	fffff097          	auipc	ra,0xfffff
    80004732:	4b4080e7          	jalr	1204(ra) # 80003be2 <brelse>
  }

  if(off > ip->size)
    80004736:	04cb2783          	lw	a5,76(s6)
    8000473a:	0127f463          	bgeu	a5,s2,80004742 <writei+0xe2>
    ip->size = off;
    8000473e:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004742:	855a                	mv	a0,s6
    80004744:	00000097          	auipc	ra,0x0
    80004748:	aa6080e7          	jalr	-1370(ra) # 800041ea <iupdate>

  return tot;
    8000474c:	000a051b          	sext.w	a0,s4
}
    80004750:	70a6                	ld	ra,104(sp)
    80004752:	7406                	ld	s0,96(sp)
    80004754:	64e6                	ld	s1,88(sp)
    80004756:	6946                	ld	s2,80(sp)
    80004758:	69a6                	ld	s3,72(sp)
    8000475a:	6a06                	ld	s4,64(sp)
    8000475c:	7ae2                	ld	s5,56(sp)
    8000475e:	7b42                	ld	s6,48(sp)
    80004760:	7ba2                	ld	s7,40(sp)
    80004762:	7c02                	ld	s8,32(sp)
    80004764:	6ce2                	ld	s9,24(sp)
    80004766:	6d42                	ld	s10,16(sp)
    80004768:	6da2                	ld	s11,8(sp)
    8000476a:	6165                	addi	sp,sp,112
    8000476c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000476e:	8a5e                	mv	s4,s7
    80004770:	bfc9                	j	80004742 <writei+0xe2>
    return -1;
    80004772:	557d                	li	a0,-1
}
    80004774:	8082                	ret
    return -1;
    80004776:	557d                	li	a0,-1
    80004778:	bfe1                	j	80004750 <writei+0xf0>
    return -1;
    8000477a:	557d                	li	a0,-1
    8000477c:	bfd1                	j	80004750 <writei+0xf0>

000000008000477e <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    8000477e:	1141                	addi	sp,sp,-16
    80004780:	e406                	sd	ra,8(sp)
    80004782:	e022                	sd	s0,0(sp)
    80004784:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004786:	4639                	li	a2,14
    80004788:	ffffc097          	auipc	ra,0xffffc
    8000478c:	630080e7          	jalr	1584(ra) # 80000db8 <strncmp>
}
    80004790:	60a2                	ld	ra,8(sp)
    80004792:	6402                	ld	s0,0(sp)
    80004794:	0141                	addi	sp,sp,16
    80004796:	8082                	ret

0000000080004798 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004798:	7139                	addi	sp,sp,-64
    8000479a:	fc06                	sd	ra,56(sp)
    8000479c:	f822                	sd	s0,48(sp)
    8000479e:	f426                	sd	s1,40(sp)
    800047a0:	f04a                	sd	s2,32(sp)
    800047a2:	ec4e                	sd	s3,24(sp)
    800047a4:	e852                	sd	s4,16(sp)
    800047a6:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800047a8:	04451703          	lh	a4,68(a0)
    800047ac:	4785                	li	a5,1
    800047ae:	00f71a63          	bne	a4,a5,800047c2 <dirlookup+0x2a>
    800047b2:	892a                	mv	s2,a0
    800047b4:	89ae                	mv	s3,a1
    800047b6:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800047b8:	457c                	lw	a5,76(a0)
    800047ba:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800047bc:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800047be:	e79d                	bnez	a5,800047ec <dirlookup+0x54>
    800047c0:	a8a5                	j	80004838 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800047c2:	00004517          	auipc	a0,0x4
    800047c6:	ec650513          	addi	a0,a0,-314 # 80008688 <syscalls+0x1b8>
    800047ca:	ffffc097          	auipc	ra,0xffffc
    800047ce:	d74080e7          	jalr	-652(ra) # 8000053e <panic>
      panic("dirlookup read");
    800047d2:	00004517          	auipc	a0,0x4
    800047d6:	ece50513          	addi	a0,a0,-306 # 800086a0 <syscalls+0x1d0>
    800047da:	ffffc097          	auipc	ra,0xffffc
    800047de:	d64080e7          	jalr	-668(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800047e2:	24c1                	addiw	s1,s1,16
    800047e4:	04c92783          	lw	a5,76(s2)
    800047e8:	04f4f763          	bgeu	s1,a5,80004836 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800047ec:	4741                	li	a4,16
    800047ee:	86a6                	mv	a3,s1
    800047f0:	fc040613          	addi	a2,s0,-64
    800047f4:	4581                	li	a1,0
    800047f6:	854a                	mv	a0,s2
    800047f8:	00000097          	auipc	ra,0x0
    800047fc:	d70080e7          	jalr	-656(ra) # 80004568 <readi>
    80004800:	47c1                	li	a5,16
    80004802:	fcf518e3          	bne	a0,a5,800047d2 <dirlookup+0x3a>
    if(de.inum == 0)
    80004806:	fc045783          	lhu	a5,-64(s0)
    8000480a:	dfe1                	beqz	a5,800047e2 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    8000480c:	fc240593          	addi	a1,s0,-62
    80004810:	854e                	mv	a0,s3
    80004812:	00000097          	auipc	ra,0x0
    80004816:	f6c080e7          	jalr	-148(ra) # 8000477e <namecmp>
    8000481a:	f561                	bnez	a0,800047e2 <dirlookup+0x4a>
      if(poff)
    8000481c:	000a0463          	beqz	s4,80004824 <dirlookup+0x8c>
        *poff = off;
    80004820:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004824:	fc045583          	lhu	a1,-64(s0)
    80004828:	00092503          	lw	a0,0(s2)
    8000482c:	fffff097          	auipc	ra,0xfffff
    80004830:	754080e7          	jalr	1876(ra) # 80003f80 <iget>
    80004834:	a011                	j	80004838 <dirlookup+0xa0>
  return 0;
    80004836:	4501                	li	a0,0
}
    80004838:	70e2                	ld	ra,56(sp)
    8000483a:	7442                	ld	s0,48(sp)
    8000483c:	74a2                	ld	s1,40(sp)
    8000483e:	7902                	ld	s2,32(sp)
    80004840:	69e2                	ld	s3,24(sp)
    80004842:	6a42                	ld	s4,16(sp)
    80004844:	6121                	addi	sp,sp,64
    80004846:	8082                	ret

0000000080004848 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004848:	711d                	addi	sp,sp,-96
    8000484a:	ec86                	sd	ra,88(sp)
    8000484c:	e8a2                	sd	s0,80(sp)
    8000484e:	e4a6                	sd	s1,72(sp)
    80004850:	e0ca                	sd	s2,64(sp)
    80004852:	fc4e                	sd	s3,56(sp)
    80004854:	f852                	sd	s4,48(sp)
    80004856:	f456                	sd	s5,40(sp)
    80004858:	f05a                	sd	s6,32(sp)
    8000485a:	ec5e                	sd	s7,24(sp)
    8000485c:	e862                	sd	s8,16(sp)
    8000485e:	e466                	sd	s9,8(sp)
    80004860:	1080                	addi	s0,sp,96
    80004862:	84aa                	mv	s1,a0
    80004864:	8b2e                	mv	s6,a1
    80004866:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004868:	00054703          	lbu	a4,0(a0)
    8000486c:	02f00793          	li	a5,47
    80004870:	02f70363          	beq	a4,a5,80004896 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004874:	ffffd097          	auipc	ra,0xffffd
    80004878:	72c080e7          	jalr	1836(ra) # 80001fa0 <myproc>
    8000487c:	16853503          	ld	a0,360(a0)
    80004880:	00000097          	auipc	ra,0x0
    80004884:	9f6080e7          	jalr	-1546(ra) # 80004276 <idup>
    80004888:	89aa                	mv	s3,a0
  while(*path == '/')
    8000488a:	02f00913          	li	s2,47
  len = path - s;
    8000488e:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80004890:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004892:	4c05                	li	s8,1
    80004894:	a865                	j	8000494c <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004896:	4585                	li	a1,1
    80004898:	4505                	li	a0,1
    8000489a:	fffff097          	auipc	ra,0xfffff
    8000489e:	6e6080e7          	jalr	1766(ra) # 80003f80 <iget>
    800048a2:	89aa                	mv	s3,a0
    800048a4:	b7dd                	j	8000488a <namex+0x42>
      iunlockput(ip);
    800048a6:	854e                	mv	a0,s3
    800048a8:	00000097          	auipc	ra,0x0
    800048ac:	c6e080e7          	jalr	-914(ra) # 80004516 <iunlockput>
      return 0;
    800048b0:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800048b2:	854e                	mv	a0,s3
    800048b4:	60e6                	ld	ra,88(sp)
    800048b6:	6446                	ld	s0,80(sp)
    800048b8:	64a6                	ld	s1,72(sp)
    800048ba:	6906                	ld	s2,64(sp)
    800048bc:	79e2                	ld	s3,56(sp)
    800048be:	7a42                	ld	s4,48(sp)
    800048c0:	7aa2                	ld	s5,40(sp)
    800048c2:	7b02                	ld	s6,32(sp)
    800048c4:	6be2                	ld	s7,24(sp)
    800048c6:	6c42                	ld	s8,16(sp)
    800048c8:	6ca2                	ld	s9,8(sp)
    800048ca:	6125                	addi	sp,sp,96
    800048cc:	8082                	ret
      iunlock(ip);
    800048ce:	854e                	mv	a0,s3
    800048d0:	00000097          	auipc	ra,0x0
    800048d4:	aa6080e7          	jalr	-1370(ra) # 80004376 <iunlock>
      return ip;
    800048d8:	bfe9                	j	800048b2 <namex+0x6a>
      iunlockput(ip);
    800048da:	854e                	mv	a0,s3
    800048dc:	00000097          	auipc	ra,0x0
    800048e0:	c3a080e7          	jalr	-966(ra) # 80004516 <iunlockput>
      return 0;
    800048e4:	89d2                	mv	s3,s4
    800048e6:	b7f1                	j	800048b2 <namex+0x6a>
  len = path - s;
    800048e8:	40b48633          	sub	a2,s1,a1
    800048ec:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    800048f0:	094cd463          	bge	s9,s4,80004978 <namex+0x130>
    memmove(name, s, DIRSIZ);
    800048f4:	4639                	li	a2,14
    800048f6:	8556                	mv	a0,s5
    800048f8:	ffffc097          	auipc	ra,0xffffc
    800048fc:	448080e7          	jalr	1096(ra) # 80000d40 <memmove>
  while(*path == '/')
    80004900:	0004c783          	lbu	a5,0(s1)
    80004904:	01279763          	bne	a5,s2,80004912 <namex+0xca>
    path++;
    80004908:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000490a:	0004c783          	lbu	a5,0(s1)
    8000490e:	ff278de3          	beq	a5,s2,80004908 <namex+0xc0>
    ilock(ip);
    80004912:	854e                	mv	a0,s3
    80004914:	00000097          	auipc	ra,0x0
    80004918:	9a0080e7          	jalr	-1632(ra) # 800042b4 <ilock>
    if(ip->type != T_DIR){
    8000491c:	04499783          	lh	a5,68(s3)
    80004920:	f98793e3          	bne	a5,s8,800048a6 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004924:	000b0563          	beqz	s6,8000492e <namex+0xe6>
    80004928:	0004c783          	lbu	a5,0(s1)
    8000492c:	d3cd                	beqz	a5,800048ce <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000492e:	865e                	mv	a2,s7
    80004930:	85d6                	mv	a1,s5
    80004932:	854e                	mv	a0,s3
    80004934:	00000097          	auipc	ra,0x0
    80004938:	e64080e7          	jalr	-412(ra) # 80004798 <dirlookup>
    8000493c:	8a2a                	mv	s4,a0
    8000493e:	dd51                	beqz	a0,800048da <namex+0x92>
    iunlockput(ip);
    80004940:	854e                	mv	a0,s3
    80004942:	00000097          	auipc	ra,0x0
    80004946:	bd4080e7          	jalr	-1068(ra) # 80004516 <iunlockput>
    ip = next;
    8000494a:	89d2                	mv	s3,s4
  while(*path == '/')
    8000494c:	0004c783          	lbu	a5,0(s1)
    80004950:	05279763          	bne	a5,s2,8000499e <namex+0x156>
    path++;
    80004954:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004956:	0004c783          	lbu	a5,0(s1)
    8000495a:	ff278de3          	beq	a5,s2,80004954 <namex+0x10c>
  if(*path == 0)
    8000495e:	c79d                	beqz	a5,8000498c <namex+0x144>
    path++;
    80004960:	85a6                	mv	a1,s1
  len = path - s;
    80004962:	8a5e                	mv	s4,s7
    80004964:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004966:	01278963          	beq	a5,s2,80004978 <namex+0x130>
    8000496a:	dfbd                	beqz	a5,800048e8 <namex+0xa0>
    path++;
    8000496c:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    8000496e:	0004c783          	lbu	a5,0(s1)
    80004972:	ff279ce3          	bne	a5,s2,8000496a <namex+0x122>
    80004976:	bf8d                	j	800048e8 <namex+0xa0>
    memmove(name, s, len);
    80004978:	2601                	sext.w	a2,a2
    8000497a:	8556                	mv	a0,s5
    8000497c:	ffffc097          	auipc	ra,0xffffc
    80004980:	3c4080e7          	jalr	964(ra) # 80000d40 <memmove>
    name[len] = 0;
    80004984:	9a56                	add	s4,s4,s5
    80004986:	000a0023          	sb	zero,0(s4)
    8000498a:	bf9d                	j	80004900 <namex+0xb8>
  if(nameiparent){
    8000498c:	f20b03e3          	beqz	s6,800048b2 <namex+0x6a>
    iput(ip);
    80004990:	854e                	mv	a0,s3
    80004992:	00000097          	auipc	ra,0x0
    80004996:	adc080e7          	jalr	-1316(ra) # 8000446e <iput>
    return 0;
    8000499a:	4981                	li	s3,0
    8000499c:	bf19                	j	800048b2 <namex+0x6a>
  if(*path == 0)
    8000499e:	d7fd                	beqz	a5,8000498c <namex+0x144>
  while(*path != '/' && *path != 0)
    800049a0:	0004c783          	lbu	a5,0(s1)
    800049a4:	85a6                	mv	a1,s1
    800049a6:	b7d1                	j	8000496a <namex+0x122>

00000000800049a8 <dirlink>:
{
    800049a8:	7139                	addi	sp,sp,-64
    800049aa:	fc06                	sd	ra,56(sp)
    800049ac:	f822                	sd	s0,48(sp)
    800049ae:	f426                	sd	s1,40(sp)
    800049b0:	f04a                	sd	s2,32(sp)
    800049b2:	ec4e                	sd	s3,24(sp)
    800049b4:	e852                	sd	s4,16(sp)
    800049b6:	0080                	addi	s0,sp,64
    800049b8:	892a                	mv	s2,a0
    800049ba:	8a2e                	mv	s4,a1
    800049bc:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800049be:	4601                	li	a2,0
    800049c0:	00000097          	auipc	ra,0x0
    800049c4:	dd8080e7          	jalr	-552(ra) # 80004798 <dirlookup>
    800049c8:	e93d                	bnez	a0,80004a3e <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800049ca:	04c92483          	lw	s1,76(s2)
    800049ce:	c49d                	beqz	s1,800049fc <dirlink+0x54>
    800049d0:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800049d2:	4741                	li	a4,16
    800049d4:	86a6                	mv	a3,s1
    800049d6:	fc040613          	addi	a2,s0,-64
    800049da:	4581                	li	a1,0
    800049dc:	854a                	mv	a0,s2
    800049de:	00000097          	auipc	ra,0x0
    800049e2:	b8a080e7          	jalr	-1142(ra) # 80004568 <readi>
    800049e6:	47c1                	li	a5,16
    800049e8:	06f51163          	bne	a0,a5,80004a4a <dirlink+0xa2>
    if(de.inum == 0)
    800049ec:	fc045783          	lhu	a5,-64(s0)
    800049f0:	c791                	beqz	a5,800049fc <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800049f2:	24c1                	addiw	s1,s1,16
    800049f4:	04c92783          	lw	a5,76(s2)
    800049f8:	fcf4ede3          	bltu	s1,a5,800049d2 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800049fc:	4639                	li	a2,14
    800049fe:	85d2                	mv	a1,s4
    80004a00:	fc240513          	addi	a0,s0,-62
    80004a04:	ffffc097          	auipc	ra,0xffffc
    80004a08:	3f0080e7          	jalr	1008(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80004a0c:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004a10:	4741                	li	a4,16
    80004a12:	86a6                	mv	a3,s1
    80004a14:	fc040613          	addi	a2,s0,-64
    80004a18:	4581                	li	a1,0
    80004a1a:	854a                	mv	a0,s2
    80004a1c:	00000097          	auipc	ra,0x0
    80004a20:	c44080e7          	jalr	-956(ra) # 80004660 <writei>
    80004a24:	872a                	mv	a4,a0
    80004a26:	47c1                	li	a5,16
  return 0;
    80004a28:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004a2a:	02f71863          	bne	a4,a5,80004a5a <dirlink+0xb2>
}
    80004a2e:	70e2                	ld	ra,56(sp)
    80004a30:	7442                	ld	s0,48(sp)
    80004a32:	74a2                	ld	s1,40(sp)
    80004a34:	7902                	ld	s2,32(sp)
    80004a36:	69e2                	ld	s3,24(sp)
    80004a38:	6a42                	ld	s4,16(sp)
    80004a3a:	6121                	addi	sp,sp,64
    80004a3c:	8082                	ret
    iput(ip);
    80004a3e:	00000097          	auipc	ra,0x0
    80004a42:	a30080e7          	jalr	-1488(ra) # 8000446e <iput>
    return -1;
    80004a46:	557d                	li	a0,-1
    80004a48:	b7dd                	j	80004a2e <dirlink+0x86>
      panic("dirlink read");
    80004a4a:	00004517          	auipc	a0,0x4
    80004a4e:	c6650513          	addi	a0,a0,-922 # 800086b0 <syscalls+0x1e0>
    80004a52:	ffffc097          	auipc	ra,0xffffc
    80004a56:	aec080e7          	jalr	-1300(ra) # 8000053e <panic>
    panic("dirlink");
    80004a5a:	00004517          	auipc	a0,0x4
    80004a5e:	d6650513          	addi	a0,a0,-666 # 800087c0 <syscalls+0x2f0>
    80004a62:	ffffc097          	auipc	ra,0xffffc
    80004a66:	adc080e7          	jalr	-1316(ra) # 8000053e <panic>

0000000080004a6a <namei>:

struct inode*
namei(char *path)
{
    80004a6a:	1101                	addi	sp,sp,-32
    80004a6c:	ec06                	sd	ra,24(sp)
    80004a6e:	e822                	sd	s0,16(sp)
    80004a70:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004a72:	fe040613          	addi	a2,s0,-32
    80004a76:	4581                	li	a1,0
    80004a78:	00000097          	auipc	ra,0x0
    80004a7c:	dd0080e7          	jalr	-560(ra) # 80004848 <namex>
}
    80004a80:	60e2                	ld	ra,24(sp)
    80004a82:	6442                	ld	s0,16(sp)
    80004a84:	6105                	addi	sp,sp,32
    80004a86:	8082                	ret

0000000080004a88 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004a88:	1141                	addi	sp,sp,-16
    80004a8a:	e406                	sd	ra,8(sp)
    80004a8c:	e022                	sd	s0,0(sp)
    80004a8e:	0800                	addi	s0,sp,16
    80004a90:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004a92:	4585                	li	a1,1
    80004a94:	00000097          	auipc	ra,0x0
    80004a98:	db4080e7          	jalr	-588(ra) # 80004848 <namex>
}
    80004a9c:	60a2                	ld	ra,8(sp)
    80004a9e:	6402                	ld	s0,0(sp)
    80004aa0:	0141                	addi	sp,sp,16
    80004aa2:	8082                	ret

0000000080004aa4 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004aa4:	1101                	addi	sp,sp,-32
    80004aa6:	ec06                	sd	ra,24(sp)
    80004aa8:	e822                	sd	s0,16(sp)
    80004aaa:	e426                	sd	s1,8(sp)
    80004aac:	e04a                	sd	s2,0(sp)
    80004aae:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004ab0:	0001d917          	auipc	s2,0x1d
    80004ab4:	2b090913          	addi	s2,s2,688 # 80021d60 <log>
    80004ab8:	01892583          	lw	a1,24(s2)
    80004abc:	02892503          	lw	a0,40(s2)
    80004ac0:	fffff097          	auipc	ra,0xfffff
    80004ac4:	ff2080e7          	jalr	-14(ra) # 80003ab2 <bread>
    80004ac8:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004aca:	02c92683          	lw	a3,44(s2)
    80004ace:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004ad0:	02d05763          	blez	a3,80004afe <write_head+0x5a>
    80004ad4:	0001d797          	auipc	a5,0x1d
    80004ad8:	2bc78793          	addi	a5,a5,700 # 80021d90 <log+0x30>
    80004adc:	05c50713          	addi	a4,a0,92
    80004ae0:	36fd                	addiw	a3,a3,-1
    80004ae2:	1682                	slli	a3,a3,0x20
    80004ae4:	9281                	srli	a3,a3,0x20
    80004ae6:	068a                	slli	a3,a3,0x2
    80004ae8:	0001d617          	auipc	a2,0x1d
    80004aec:	2ac60613          	addi	a2,a2,684 # 80021d94 <log+0x34>
    80004af0:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004af2:	4390                	lw	a2,0(a5)
    80004af4:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004af6:	0791                	addi	a5,a5,4
    80004af8:	0711                	addi	a4,a4,4
    80004afa:	fed79ce3          	bne	a5,a3,80004af2 <write_head+0x4e>
  }
  bwrite(buf);
    80004afe:	8526                	mv	a0,s1
    80004b00:	fffff097          	auipc	ra,0xfffff
    80004b04:	0a4080e7          	jalr	164(ra) # 80003ba4 <bwrite>
  brelse(buf);
    80004b08:	8526                	mv	a0,s1
    80004b0a:	fffff097          	auipc	ra,0xfffff
    80004b0e:	0d8080e7          	jalr	216(ra) # 80003be2 <brelse>
}
    80004b12:	60e2                	ld	ra,24(sp)
    80004b14:	6442                	ld	s0,16(sp)
    80004b16:	64a2                	ld	s1,8(sp)
    80004b18:	6902                	ld	s2,0(sp)
    80004b1a:	6105                	addi	sp,sp,32
    80004b1c:	8082                	ret

0000000080004b1e <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004b1e:	0001d797          	auipc	a5,0x1d
    80004b22:	26e7a783          	lw	a5,622(a5) # 80021d8c <log+0x2c>
    80004b26:	0af05d63          	blez	a5,80004be0 <install_trans+0xc2>
{
    80004b2a:	7139                	addi	sp,sp,-64
    80004b2c:	fc06                	sd	ra,56(sp)
    80004b2e:	f822                	sd	s0,48(sp)
    80004b30:	f426                	sd	s1,40(sp)
    80004b32:	f04a                	sd	s2,32(sp)
    80004b34:	ec4e                	sd	s3,24(sp)
    80004b36:	e852                	sd	s4,16(sp)
    80004b38:	e456                	sd	s5,8(sp)
    80004b3a:	e05a                	sd	s6,0(sp)
    80004b3c:	0080                	addi	s0,sp,64
    80004b3e:	8b2a                	mv	s6,a0
    80004b40:	0001da97          	auipc	s5,0x1d
    80004b44:	250a8a93          	addi	s5,s5,592 # 80021d90 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004b48:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004b4a:	0001d997          	auipc	s3,0x1d
    80004b4e:	21698993          	addi	s3,s3,534 # 80021d60 <log>
    80004b52:	a035                	j	80004b7e <install_trans+0x60>
      bunpin(dbuf);
    80004b54:	8526                	mv	a0,s1
    80004b56:	fffff097          	auipc	ra,0xfffff
    80004b5a:	166080e7          	jalr	358(ra) # 80003cbc <bunpin>
    brelse(lbuf);
    80004b5e:	854a                	mv	a0,s2
    80004b60:	fffff097          	auipc	ra,0xfffff
    80004b64:	082080e7          	jalr	130(ra) # 80003be2 <brelse>
    brelse(dbuf);
    80004b68:	8526                	mv	a0,s1
    80004b6a:	fffff097          	auipc	ra,0xfffff
    80004b6e:	078080e7          	jalr	120(ra) # 80003be2 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004b72:	2a05                	addiw	s4,s4,1
    80004b74:	0a91                	addi	s5,s5,4
    80004b76:	02c9a783          	lw	a5,44(s3)
    80004b7a:	04fa5963          	bge	s4,a5,80004bcc <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004b7e:	0189a583          	lw	a1,24(s3)
    80004b82:	014585bb          	addw	a1,a1,s4
    80004b86:	2585                	addiw	a1,a1,1
    80004b88:	0289a503          	lw	a0,40(s3)
    80004b8c:	fffff097          	auipc	ra,0xfffff
    80004b90:	f26080e7          	jalr	-218(ra) # 80003ab2 <bread>
    80004b94:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004b96:	000aa583          	lw	a1,0(s5)
    80004b9a:	0289a503          	lw	a0,40(s3)
    80004b9e:	fffff097          	auipc	ra,0xfffff
    80004ba2:	f14080e7          	jalr	-236(ra) # 80003ab2 <bread>
    80004ba6:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004ba8:	40000613          	li	a2,1024
    80004bac:	05890593          	addi	a1,s2,88
    80004bb0:	05850513          	addi	a0,a0,88
    80004bb4:	ffffc097          	auipc	ra,0xffffc
    80004bb8:	18c080e7          	jalr	396(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004bbc:	8526                	mv	a0,s1
    80004bbe:	fffff097          	auipc	ra,0xfffff
    80004bc2:	fe6080e7          	jalr	-26(ra) # 80003ba4 <bwrite>
    if(recovering == 0)
    80004bc6:	f80b1ce3          	bnez	s6,80004b5e <install_trans+0x40>
    80004bca:	b769                	j	80004b54 <install_trans+0x36>
}
    80004bcc:	70e2                	ld	ra,56(sp)
    80004bce:	7442                	ld	s0,48(sp)
    80004bd0:	74a2                	ld	s1,40(sp)
    80004bd2:	7902                	ld	s2,32(sp)
    80004bd4:	69e2                	ld	s3,24(sp)
    80004bd6:	6a42                	ld	s4,16(sp)
    80004bd8:	6aa2                	ld	s5,8(sp)
    80004bda:	6b02                	ld	s6,0(sp)
    80004bdc:	6121                	addi	sp,sp,64
    80004bde:	8082                	ret
    80004be0:	8082                	ret

0000000080004be2 <initlog>:
{
    80004be2:	7179                	addi	sp,sp,-48
    80004be4:	f406                	sd	ra,40(sp)
    80004be6:	f022                	sd	s0,32(sp)
    80004be8:	ec26                	sd	s1,24(sp)
    80004bea:	e84a                	sd	s2,16(sp)
    80004bec:	e44e                	sd	s3,8(sp)
    80004bee:	1800                	addi	s0,sp,48
    80004bf0:	892a                	mv	s2,a0
    80004bf2:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004bf4:	0001d497          	auipc	s1,0x1d
    80004bf8:	16c48493          	addi	s1,s1,364 # 80021d60 <log>
    80004bfc:	00004597          	auipc	a1,0x4
    80004c00:	ac458593          	addi	a1,a1,-1340 # 800086c0 <syscalls+0x1f0>
    80004c04:	8526                	mv	a0,s1
    80004c06:	ffffc097          	auipc	ra,0xffffc
    80004c0a:	f4e080e7          	jalr	-178(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80004c0e:	0149a583          	lw	a1,20(s3)
    80004c12:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004c14:	0109a783          	lw	a5,16(s3)
    80004c18:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004c1a:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004c1e:	854a                	mv	a0,s2
    80004c20:	fffff097          	auipc	ra,0xfffff
    80004c24:	e92080e7          	jalr	-366(ra) # 80003ab2 <bread>
  log.lh.n = lh->n;
    80004c28:	4d3c                	lw	a5,88(a0)
    80004c2a:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004c2c:	02f05563          	blez	a5,80004c56 <initlog+0x74>
    80004c30:	05c50713          	addi	a4,a0,92
    80004c34:	0001d697          	auipc	a3,0x1d
    80004c38:	15c68693          	addi	a3,a3,348 # 80021d90 <log+0x30>
    80004c3c:	37fd                	addiw	a5,a5,-1
    80004c3e:	1782                	slli	a5,a5,0x20
    80004c40:	9381                	srli	a5,a5,0x20
    80004c42:	078a                	slli	a5,a5,0x2
    80004c44:	06050613          	addi	a2,a0,96
    80004c48:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004c4a:	4310                	lw	a2,0(a4)
    80004c4c:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004c4e:	0711                	addi	a4,a4,4
    80004c50:	0691                	addi	a3,a3,4
    80004c52:	fef71ce3          	bne	a4,a5,80004c4a <initlog+0x68>
  brelse(buf);
    80004c56:	fffff097          	auipc	ra,0xfffff
    80004c5a:	f8c080e7          	jalr	-116(ra) # 80003be2 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004c5e:	4505                	li	a0,1
    80004c60:	00000097          	auipc	ra,0x0
    80004c64:	ebe080e7          	jalr	-322(ra) # 80004b1e <install_trans>
  log.lh.n = 0;
    80004c68:	0001d797          	auipc	a5,0x1d
    80004c6c:	1207a223          	sw	zero,292(a5) # 80021d8c <log+0x2c>
  write_head(); // clear the log
    80004c70:	00000097          	auipc	ra,0x0
    80004c74:	e34080e7          	jalr	-460(ra) # 80004aa4 <write_head>
}
    80004c78:	70a2                	ld	ra,40(sp)
    80004c7a:	7402                	ld	s0,32(sp)
    80004c7c:	64e2                	ld	s1,24(sp)
    80004c7e:	6942                	ld	s2,16(sp)
    80004c80:	69a2                	ld	s3,8(sp)
    80004c82:	6145                	addi	sp,sp,48
    80004c84:	8082                	ret

0000000080004c86 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004c86:	1101                	addi	sp,sp,-32
    80004c88:	ec06                	sd	ra,24(sp)
    80004c8a:	e822                	sd	s0,16(sp)
    80004c8c:	e426                	sd	s1,8(sp)
    80004c8e:	e04a                	sd	s2,0(sp)
    80004c90:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004c92:	0001d517          	auipc	a0,0x1d
    80004c96:	0ce50513          	addi	a0,a0,206 # 80021d60 <log>
    80004c9a:	ffffc097          	auipc	ra,0xffffc
    80004c9e:	f4a080e7          	jalr	-182(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80004ca2:	0001d497          	auipc	s1,0x1d
    80004ca6:	0be48493          	addi	s1,s1,190 # 80021d60 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004caa:	4979                	li	s2,30
    80004cac:	a039                	j	80004cba <begin_op+0x34>
      sleep(&log, &log.lock);
    80004cae:	85a6                	mv	a1,s1
    80004cb0:	8526                	mv	a0,s1
    80004cb2:	ffffe097          	auipc	ra,0xffffe
    80004cb6:	b6e080e7          	jalr	-1170(ra) # 80002820 <sleep>
    if(log.committing){
    80004cba:	50dc                	lw	a5,36(s1)
    80004cbc:	fbed                	bnez	a5,80004cae <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004cbe:	509c                	lw	a5,32(s1)
    80004cc0:	0017871b          	addiw	a4,a5,1
    80004cc4:	0007069b          	sext.w	a3,a4
    80004cc8:	0027179b          	slliw	a5,a4,0x2
    80004ccc:	9fb9                	addw	a5,a5,a4
    80004cce:	0017979b          	slliw	a5,a5,0x1
    80004cd2:	54d8                	lw	a4,44(s1)
    80004cd4:	9fb9                	addw	a5,a5,a4
    80004cd6:	00f95963          	bge	s2,a5,80004ce8 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004cda:	85a6                	mv	a1,s1
    80004cdc:	8526                	mv	a0,s1
    80004cde:	ffffe097          	auipc	ra,0xffffe
    80004ce2:	b42080e7          	jalr	-1214(ra) # 80002820 <sleep>
    80004ce6:	bfd1                	j	80004cba <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004ce8:	0001d517          	auipc	a0,0x1d
    80004cec:	07850513          	addi	a0,a0,120 # 80021d60 <log>
    80004cf0:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004cf2:	ffffc097          	auipc	ra,0xffffc
    80004cf6:	fa6080e7          	jalr	-90(ra) # 80000c98 <release>
      break;
    }
  }
}
    80004cfa:	60e2                	ld	ra,24(sp)
    80004cfc:	6442                	ld	s0,16(sp)
    80004cfe:	64a2                	ld	s1,8(sp)
    80004d00:	6902                	ld	s2,0(sp)
    80004d02:	6105                	addi	sp,sp,32
    80004d04:	8082                	ret

0000000080004d06 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004d06:	7139                	addi	sp,sp,-64
    80004d08:	fc06                	sd	ra,56(sp)
    80004d0a:	f822                	sd	s0,48(sp)
    80004d0c:	f426                	sd	s1,40(sp)
    80004d0e:	f04a                	sd	s2,32(sp)
    80004d10:	ec4e                	sd	s3,24(sp)
    80004d12:	e852                	sd	s4,16(sp)
    80004d14:	e456                	sd	s5,8(sp)
    80004d16:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004d18:	0001d497          	auipc	s1,0x1d
    80004d1c:	04848493          	addi	s1,s1,72 # 80021d60 <log>
    80004d20:	8526                	mv	a0,s1
    80004d22:	ffffc097          	auipc	ra,0xffffc
    80004d26:	ec2080e7          	jalr	-318(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    80004d2a:	509c                	lw	a5,32(s1)
    80004d2c:	37fd                	addiw	a5,a5,-1
    80004d2e:	0007891b          	sext.w	s2,a5
    80004d32:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004d34:	50dc                	lw	a5,36(s1)
    80004d36:	efb9                	bnez	a5,80004d94 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004d38:	06091663          	bnez	s2,80004da4 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004d3c:	0001d497          	auipc	s1,0x1d
    80004d40:	02448493          	addi	s1,s1,36 # 80021d60 <log>
    80004d44:	4785                	li	a5,1
    80004d46:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004d48:	8526                	mv	a0,s1
    80004d4a:	ffffc097          	auipc	ra,0xffffc
    80004d4e:	f4e080e7          	jalr	-178(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004d52:	54dc                	lw	a5,44(s1)
    80004d54:	06f04763          	bgtz	a5,80004dc2 <end_op+0xbc>
    acquire(&log.lock);
    80004d58:	0001d497          	auipc	s1,0x1d
    80004d5c:	00848493          	addi	s1,s1,8 # 80021d60 <log>
    80004d60:	8526                	mv	a0,s1
    80004d62:	ffffc097          	auipc	ra,0xffffc
    80004d66:	e82080e7          	jalr	-382(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004d6a:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004d6e:	8526                	mv	a0,s1
    80004d70:	ffffe097          	auipc	ra,0xffffe
    80004d74:	c52080e7          	jalr	-942(ra) # 800029c2 <wakeup>
    release(&log.lock);
    80004d78:	8526                	mv	a0,s1
    80004d7a:	ffffc097          	auipc	ra,0xffffc
    80004d7e:	f1e080e7          	jalr	-226(ra) # 80000c98 <release>
}
    80004d82:	70e2                	ld	ra,56(sp)
    80004d84:	7442                	ld	s0,48(sp)
    80004d86:	74a2                	ld	s1,40(sp)
    80004d88:	7902                	ld	s2,32(sp)
    80004d8a:	69e2                	ld	s3,24(sp)
    80004d8c:	6a42                	ld	s4,16(sp)
    80004d8e:	6aa2                	ld	s5,8(sp)
    80004d90:	6121                	addi	sp,sp,64
    80004d92:	8082                	ret
    panic("log.committing");
    80004d94:	00004517          	auipc	a0,0x4
    80004d98:	93450513          	addi	a0,a0,-1740 # 800086c8 <syscalls+0x1f8>
    80004d9c:	ffffb097          	auipc	ra,0xffffb
    80004da0:	7a2080e7          	jalr	1954(ra) # 8000053e <panic>
    wakeup(&log);
    80004da4:	0001d497          	auipc	s1,0x1d
    80004da8:	fbc48493          	addi	s1,s1,-68 # 80021d60 <log>
    80004dac:	8526                	mv	a0,s1
    80004dae:	ffffe097          	auipc	ra,0xffffe
    80004db2:	c14080e7          	jalr	-1004(ra) # 800029c2 <wakeup>
  release(&log.lock);
    80004db6:	8526                	mv	a0,s1
    80004db8:	ffffc097          	auipc	ra,0xffffc
    80004dbc:	ee0080e7          	jalr	-288(ra) # 80000c98 <release>
  if(do_commit){
    80004dc0:	b7c9                	j	80004d82 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004dc2:	0001da97          	auipc	s5,0x1d
    80004dc6:	fcea8a93          	addi	s5,s5,-50 # 80021d90 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004dca:	0001da17          	auipc	s4,0x1d
    80004dce:	f96a0a13          	addi	s4,s4,-106 # 80021d60 <log>
    80004dd2:	018a2583          	lw	a1,24(s4)
    80004dd6:	012585bb          	addw	a1,a1,s2
    80004dda:	2585                	addiw	a1,a1,1
    80004ddc:	028a2503          	lw	a0,40(s4)
    80004de0:	fffff097          	auipc	ra,0xfffff
    80004de4:	cd2080e7          	jalr	-814(ra) # 80003ab2 <bread>
    80004de8:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004dea:	000aa583          	lw	a1,0(s5)
    80004dee:	028a2503          	lw	a0,40(s4)
    80004df2:	fffff097          	auipc	ra,0xfffff
    80004df6:	cc0080e7          	jalr	-832(ra) # 80003ab2 <bread>
    80004dfa:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004dfc:	40000613          	li	a2,1024
    80004e00:	05850593          	addi	a1,a0,88
    80004e04:	05848513          	addi	a0,s1,88
    80004e08:	ffffc097          	auipc	ra,0xffffc
    80004e0c:	f38080e7          	jalr	-200(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    80004e10:	8526                	mv	a0,s1
    80004e12:	fffff097          	auipc	ra,0xfffff
    80004e16:	d92080e7          	jalr	-622(ra) # 80003ba4 <bwrite>
    brelse(from);
    80004e1a:	854e                	mv	a0,s3
    80004e1c:	fffff097          	auipc	ra,0xfffff
    80004e20:	dc6080e7          	jalr	-570(ra) # 80003be2 <brelse>
    brelse(to);
    80004e24:	8526                	mv	a0,s1
    80004e26:	fffff097          	auipc	ra,0xfffff
    80004e2a:	dbc080e7          	jalr	-580(ra) # 80003be2 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004e2e:	2905                	addiw	s2,s2,1
    80004e30:	0a91                	addi	s5,s5,4
    80004e32:	02ca2783          	lw	a5,44(s4)
    80004e36:	f8f94ee3          	blt	s2,a5,80004dd2 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004e3a:	00000097          	auipc	ra,0x0
    80004e3e:	c6a080e7          	jalr	-918(ra) # 80004aa4 <write_head>
    install_trans(0); // Now install writes to home locations
    80004e42:	4501                	li	a0,0
    80004e44:	00000097          	auipc	ra,0x0
    80004e48:	cda080e7          	jalr	-806(ra) # 80004b1e <install_trans>
    log.lh.n = 0;
    80004e4c:	0001d797          	auipc	a5,0x1d
    80004e50:	f407a023          	sw	zero,-192(a5) # 80021d8c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004e54:	00000097          	auipc	ra,0x0
    80004e58:	c50080e7          	jalr	-944(ra) # 80004aa4 <write_head>
    80004e5c:	bdf5                	j	80004d58 <end_op+0x52>

0000000080004e5e <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004e5e:	1101                	addi	sp,sp,-32
    80004e60:	ec06                	sd	ra,24(sp)
    80004e62:	e822                	sd	s0,16(sp)
    80004e64:	e426                	sd	s1,8(sp)
    80004e66:	e04a                	sd	s2,0(sp)
    80004e68:	1000                	addi	s0,sp,32
    80004e6a:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004e6c:	0001d917          	auipc	s2,0x1d
    80004e70:	ef490913          	addi	s2,s2,-268 # 80021d60 <log>
    80004e74:	854a                	mv	a0,s2
    80004e76:	ffffc097          	auipc	ra,0xffffc
    80004e7a:	d6e080e7          	jalr	-658(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004e7e:	02c92603          	lw	a2,44(s2)
    80004e82:	47f5                	li	a5,29
    80004e84:	06c7c563          	blt	a5,a2,80004eee <log_write+0x90>
    80004e88:	0001d797          	auipc	a5,0x1d
    80004e8c:	ef47a783          	lw	a5,-268(a5) # 80021d7c <log+0x1c>
    80004e90:	37fd                	addiw	a5,a5,-1
    80004e92:	04f65e63          	bge	a2,a5,80004eee <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004e96:	0001d797          	auipc	a5,0x1d
    80004e9a:	eea7a783          	lw	a5,-278(a5) # 80021d80 <log+0x20>
    80004e9e:	06f05063          	blez	a5,80004efe <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004ea2:	4781                	li	a5,0
    80004ea4:	06c05563          	blez	a2,80004f0e <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004ea8:	44cc                	lw	a1,12(s1)
    80004eaa:	0001d717          	auipc	a4,0x1d
    80004eae:	ee670713          	addi	a4,a4,-282 # 80021d90 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004eb2:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004eb4:	4314                	lw	a3,0(a4)
    80004eb6:	04b68c63          	beq	a3,a1,80004f0e <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004eba:	2785                	addiw	a5,a5,1
    80004ebc:	0711                	addi	a4,a4,4
    80004ebe:	fef61be3          	bne	a2,a5,80004eb4 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004ec2:	0621                	addi	a2,a2,8
    80004ec4:	060a                	slli	a2,a2,0x2
    80004ec6:	0001d797          	auipc	a5,0x1d
    80004eca:	e9a78793          	addi	a5,a5,-358 # 80021d60 <log>
    80004ece:	963e                	add	a2,a2,a5
    80004ed0:	44dc                	lw	a5,12(s1)
    80004ed2:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004ed4:	8526                	mv	a0,s1
    80004ed6:	fffff097          	auipc	ra,0xfffff
    80004eda:	daa080e7          	jalr	-598(ra) # 80003c80 <bpin>
    log.lh.n++;
    80004ede:	0001d717          	auipc	a4,0x1d
    80004ee2:	e8270713          	addi	a4,a4,-382 # 80021d60 <log>
    80004ee6:	575c                	lw	a5,44(a4)
    80004ee8:	2785                	addiw	a5,a5,1
    80004eea:	d75c                	sw	a5,44(a4)
    80004eec:	a835                	j	80004f28 <log_write+0xca>
    panic("too big a transaction");
    80004eee:	00003517          	auipc	a0,0x3
    80004ef2:	7ea50513          	addi	a0,a0,2026 # 800086d8 <syscalls+0x208>
    80004ef6:	ffffb097          	auipc	ra,0xffffb
    80004efa:	648080e7          	jalr	1608(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004efe:	00003517          	auipc	a0,0x3
    80004f02:	7f250513          	addi	a0,a0,2034 # 800086f0 <syscalls+0x220>
    80004f06:	ffffb097          	auipc	ra,0xffffb
    80004f0a:	638080e7          	jalr	1592(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004f0e:	00878713          	addi	a4,a5,8
    80004f12:	00271693          	slli	a3,a4,0x2
    80004f16:	0001d717          	auipc	a4,0x1d
    80004f1a:	e4a70713          	addi	a4,a4,-438 # 80021d60 <log>
    80004f1e:	9736                	add	a4,a4,a3
    80004f20:	44d4                	lw	a3,12(s1)
    80004f22:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004f24:	faf608e3          	beq	a2,a5,80004ed4 <log_write+0x76>
  }
  release(&log.lock);
    80004f28:	0001d517          	auipc	a0,0x1d
    80004f2c:	e3850513          	addi	a0,a0,-456 # 80021d60 <log>
    80004f30:	ffffc097          	auipc	ra,0xffffc
    80004f34:	d68080e7          	jalr	-664(ra) # 80000c98 <release>
}
    80004f38:	60e2                	ld	ra,24(sp)
    80004f3a:	6442                	ld	s0,16(sp)
    80004f3c:	64a2                	ld	s1,8(sp)
    80004f3e:	6902                	ld	s2,0(sp)
    80004f40:	6105                	addi	sp,sp,32
    80004f42:	8082                	ret

0000000080004f44 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004f44:	1101                	addi	sp,sp,-32
    80004f46:	ec06                	sd	ra,24(sp)
    80004f48:	e822                	sd	s0,16(sp)
    80004f4a:	e426                	sd	s1,8(sp)
    80004f4c:	e04a                	sd	s2,0(sp)
    80004f4e:	1000                	addi	s0,sp,32
    80004f50:	84aa                	mv	s1,a0
    80004f52:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004f54:	00003597          	auipc	a1,0x3
    80004f58:	7bc58593          	addi	a1,a1,1980 # 80008710 <syscalls+0x240>
    80004f5c:	0521                	addi	a0,a0,8
    80004f5e:	ffffc097          	auipc	ra,0xffffc
    80004f62:	bf6080e7          	jalr	-1034(ra) # 80000b54 <initlock>
  lk->name = name;
    80004f66:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004f6a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004f6e:	0204a423          	sw	zero,40(s1)
}
    80004f72:	60e2                	ld	ra,24(sp)
    80004f74:	6442                	ld	s0,16(sp)
    80004f76:	64a2                	ld	s1,8(sp)
    80004f78:	6902                	ld	s2,0(sp)
    80004f7a:	6105                	addi	sp,sp,32
    80004f7c:	8082                	ret

0000000080004f7e <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004f7e:	1101                	addi	sp,sp,-32
    80004f80:	ec06                	sd	ra,24(sp)
    80004f82:	e822                	sd	s0,16(sp)
    80004f84:	e426                	sd	s1,8(sp)
    80004f86:	e04a                	sd	s2,0(sp)
    80004f88:	1000                	addi	s0,sp,32
    80004f8a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004f8c:	00850913          	addi	s2,a0,8
    80004f90:	854a                	mv	a0,s2
    80004f92:	ffffc097          	auipc	ra,0xffffc
    80004f96:	c52080e7          	jalr	-942(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004f9a:	409c                	lw	a5,0(s1)
    80004f9c:	cb89                	beqz	a5,80004fae <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004f9e:	85ca                	mv	a1,s2
    80004fa0:	8526                	mv	a0,s1
    80004fa2:	ffffe097          	auipc	ra,0xffffe
    80004fa6:	87e080e7          	jalr	-1922(ra) # 80002820 <sleep>
  while (lk->locked) {
    80004faa:	409c                	lw	a5,0(s1)
    80004fac:	fbed                	bnez	a5,80004f9e <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004fae:	4785                	li	a5,1
    80004fb0:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004fb2:	ffffd097          	auipc	ra,0xffffd
    80004fb6:	fee080e7          	jalr	-18(ra) # 80001fa0 <myproc>
    80004fba:	453c                	lw	a5,72(a0)
    80004fbc:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004fbe:	854a                	mv	a0,s2
    80004fc0:	ffffc097          	auipc	ra,0xffffc
    80004fc4:	cd8080e7          	jalr	-808(ra) # 80000c98 <release>
}
    80004fc8:	60e2                	ld	ra,24(sp)
    80004fca:	6442                	ld	s0,16(sp)
    80004fcc:	64a2                	ld	s1,8(sp)
    80004fce:	6902                	ld	s2,0(sp)
    80004fd0:	6105                	addi	sp,sp,32
    80004fd2:	8082                	ret

0000000080004fd4 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004fd4:	1101                	addi	sp,sp,-32
    80004fd6:	ec06                	sd	ra,24(sp)
    80004fd8:	e822                	sd	s0,16(sp)
    80004fda:	e426                	sd	s1,8(sp)
    80004fdc:	e04a                	sd	s2,0(sp)
    80004fde:	1000                	addi	s0,sp,32
    80004fe0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004fe2:	00850913          	addi	s2,a0,8
    80004fe6:	854a                	mv	a0,s2
    80004fe8:	ffffc097          	auipc	ra,0xffffc
    80004fec:	bfc080e7          	jalr	-1028(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004ff0:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004ff4:	0204a423          	sw	zero,40(s1)
  
  wakeup(lk);
    80004ff8:	8526                	mv	a0,s1
    80004ffa:	ffffe097          	auipc	ra,0xffffe
    80004ffe:	9c8080e7          	jalr	-1592(ra) # 800029c2 <wakeup>
  release(&lk->lk);
    80005002:	854a                	mv	a0,s2
    80005004:	ffffc097          	auipc	ra,0xffffc
    80005008:	c94080e7          	jalr	-876(ra) # 80000c98 <release>
}
    8000500c:	60e2                	ld	ra,24(sp)
    8000500e:	6442                	ld	s0,16(sp)
    80005010:	64a2                	ld	s1,8(sp)
    80005012:	6902                	ld	s2,0(sp)
    80005014:	6105                	addi	sp,sp,32
    80005016:	8082                	ret

0000000080005018 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80005018:	7179                	addi	sp,sp,-48
    8000501a:	f406                	sd	ra,40(sp)
    8000501c:	f022                	sd	s0,32(sp)
    8000501e:	ec26                	sd	s1,24(sp)
    80005020:	e84a                	sd	s2,16(sp)
    80005022:	e44e                	sd	s3,8(sp)
    80005024:	1800                	addi	s0,sp,48
    80005026:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80005028:	00850913          	addi	s2,a0,8
    8000502c:	854a                	mv	a0,s2
    8000502e:	ffffc097          	auipc	ra,0xffffc
    80005032:	bb6080e7          	jalr	-1098(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80005036:	409c                	lw	a5,0(s1)
    80005038:	ef99                	bnez	a5,80005056 <holdingsleep+0x3e>
    8000503a:	4481                	li	s1,0
  release(&lk->lk);
    8000503c:	854a                	mv	a0,s2
    8000503e:	ffffc097          	auipc	ra,0xffffc
    80005042:	c5a080e7          	jalr	-934(ra) # 80000c98 <release>
  return r;
}
    80005046:	8526                	mv	a0,s1
    80005048:	70a2                	ld	ra,40(sp)
    8000504a:	7402                	ld	s0,32(sp)
    8000504c:	64e2                	ld	s1,24(sp)
    8000504e:	6942                	ld	s2,16(sp)
    80005050:	69a2                	ld	s3,8(sp)
    80005052:	6145                	addi	sp,sp,48
    80005054:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80005056:	0284a983          	lw	s3,40(s1)
    8000505a:	ffffd097          	auipc	ra,0xffffd
    8000505e:	f46080e7          	jalr	-186(ra) # 80001fa0 <myproc>
    80005062:	4524                	lw	s1,72(a0)
    80005064:	413484b3          	sub	s1,s1,s3
    80005068:	0014b493          	seqz	s1,s1
    8000506c:	bfc1                	j	8000503c <holdingsleep+0x24>

000000008000506e <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000506e:	1141                	addi	sp,sp,-16
    80005070:	e406                	sd	ra,8(sp)
    80005072:	e022                	sd	s0,0(sp)
    80005074:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80005076:	00003597          	auipc	a1,0x3
    8000507a:	6aa58593          	addi	a1,a1,1706 # 80008720 <syscalls+0x250>
    8000507e:	0001d517          	auipc	a0,0x1d
    80005082:	e2a50513          	addi	a0,a0,-470 # 80021ea8 <ftable>
    80005086:	ffffc097          	auipc	ra,0xffffc
    8000508a:	ace080e7          	jalr	-1330(ra) # 80000b54 <initlock>
}
    8000508e:	60a2                	ld	ra,8(sp)
    80005090:	6402                	ld	s0,0(sp)
    80005092:	0141                	addi	sp,sp,16
    80005094:	8082                	ret

0000000080005096 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80005096:	1101                	addi	sp,sp,-32
    80005098:	ec06                	sd	ra,24(sp)
    8000509a:	e822                	sd	s0,16(sp)
    8000509c:	e426                	sd	s1,8(sp)
    8000509e:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800050a0:	0001d517          	auipc	a0,0x1d
    800050a4:	e0850513          	addi	a0,a0,-504 # 80021ea8 <ftable>
    800050a8:	ffffc097          	auipc	ra,0xffffc
    800050ac:	b3c080e7          	jalr	-1220(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800050b0:	0001d497          	auipc	s1,0x1d
    800050b4:	e1048493          	addi	s1,s1,-496 # 80021ec0 <ftable+0x18>
    800050b8:	0001e717          	auipc	a4,0x1e
    800050bc:	da870713          	addi	a4,a4,-600 # 80022e60 <ftable+0xfb8>
    if(f->ref == 0){
    800050c0:	40dc                	lw	a5,4(s1)
    800050c2:	cf99                	beqz	a5,800050e0 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800050c4:	02848493          	addi	s1,s1,40
    800050c8:	fee49ce3          	bne	s1,a4,800050c0 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800050cc:	0001d517          	auipc	a0,0x1d
    800050d0:	ddc50513          	addi	a0,a0,-548 # 80021ea8 <ftable>
    800050d4:	ffffc097          	auipc	ra,0xffffc
    800050d8:	bc4080e7          	jalr	-1084(ra) # 80000c98 <release>
  return 0;
    800050dc:	4481                	li	s1,0
    800050de:	a819                	j	800050f4 <filealloc+0x5e>
      f->ref = 1;
    800050e0:	4785                	li	a5,1
    800050e2:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800050e4:	0001d517          	auipc	a0,0x1d
    800050e8:	dc450513          	addi	a0,a0,-572 # 80021ea8 <ftable>
    800050ec:	ffffc097          	auipc	ra,0xffffc
    800050f0:	bac080e7          	jalr	-1108(ra) # 80000c98 <release>
}
    800050f4:	8526                	mv	a0,s1
    800050f6:	60e2                	ld	ra,24(sp)
    800050f8:	6442                	ld	s0,16(sp)
    800050fa:	64a2                	ld	s1,8(sp)
    800050fc:	6105                	addi	sp,sp,32
    800050fe:	8082                	ret

0000000080005100 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80005100:	1101                	addi	sp,sp,-32
    80005102:	ec06                	sd	ra,24(sp)
    80005104:	e822                	sd	s0,16(sp)
    80005106:	e426                	sd	s1,8(sp)
    80005108:	1000                	addi	s0,sp,32
    8000510a:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000510c:	0001d517          	auipc	a0,0x1d
    80005110:	d9c50513          	addi	a0,a0,-612 # 80021ea8 <ftable>
    80005114:	ffffc097          	auipc	ra,0xffffc
    80005118:	ad0080e7          	jalr	-1328(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    8000511c:	40dc                	lw	a5,4(s1)
    8000511e:	02f05263          	blez	a5,80005142 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80005122:	2785                	addiw	a5,a5,1
    80005124:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80005126:	0001d517          	auipc	a0,0x1d
    8000512a:	d8250513          	addi	a0,a0,-638 # 80021ea8 <ftable>
    8000512e:	ffffc097          	auipc	ra,0xffffc
    80005132:	b6a080e7          	jalr	-1174(ra) # 80000c98 <release>
  return f;
}
    80005136:	8526                	mv	a0,s1
    80005138:	60e2                	ld	ra,24(sp)
    8000513a:	6442                	ld	s0,16(sp)
    8000513c:	64a2                	ld	s1,8(sp)
    8000513e:	6105                	addi	sp,sp,32
    80005140:	8082                	ret
    panic("filedup");
    80005142:	00003517          	auipc	a0,0x3
    80005146:	5e650513          	addi	a0,a0,1510 # 80008728 <syscalls+0x258>
    8000514a:	ffffb097          	auipc	ra,0xffffb
    8000514e:	3f4080e7          	jalr	1012(ra) # 8000053e <panic>

0000000080005152 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80005152:	7139                	addi	sp,sp,-64
    80005154:	fc06                	sd	ra,56(sp)
    80005156:	f822                	sd	s0,48(sp)
    80005158:	f426                	sd	s1,40(sp)
    8000515a:	f04a                	sd	s2,32(sp)
    8000515c:	ec4e                	sd	s3,24(sp)
    8000515e:	e852                	sd	s4,16(sp)
    80005160:	e456                	sd	s5,8(sp)
    80005162:	0080                	addi	s0,sp,64
    80005164:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80005166:	0001d517          	auipc	a0,0x1d
    8000516a:	d4250513          	addi	a0,a0,-702 # 80021ea8 <ftable>
    8000516e:	ffffc097          	auipc	ra,0xffffc
    80005172:	a76080e7          	jalr	-1418(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80005176:	40dc                	lw	a5,4(s1)
    80005178:	06f05163          	blez	a5,800051da <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000517c:	37fd                	addiw	a5,a5,-1
    8000517e:	0007871b          	sext.w	a4,a5
    80005182:	c0dc                	sw	a5,4(s1)
    80005184:	06e04363          	bgtz	a4,800051ea <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80005188:	0004a903          	lw	s2,0(s1)
    8000518c:	0094ca83          	lbu	s5,9(s1)
    80005190:	0104ba03          	ld	s4,16(s1)
    80005194:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80005198:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000519c:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800051a0:	0001d517          	auipc	a0,0x1d
    800051a4:	d0850513          	addi	a0,a0,-760 # 80021ea8 <ftable>
    800051a8:	ffffc097          	auipc	ra,0xffffc
    800051ac:	af0080e7          	jalr	-1296(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    800051b0:	4785                	li	a5,1
    800051b2:	04f90d63          	beq	s2,a5,8000520c <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800051b6:	3979                	addiw	s2,s2,-2
    800051b8:	4785                	li	a5,1
    800051ba:	0527e063          	bltu	a5,s2,800051fa <fileclose+0xa8>
    begin_op();
    800051be:	00000097          	auipc	ra,0x0
    800051c2:	ac8080e7          	jalr	-1336(ra) # 80004c86 <begin_op>
    iput(ff.ip);
    800051c6:	854e                	mv	a0,s3
    800051c8:	fffff097          	auipc	ra,0xfffff
    800051cc:	2a6080e7          	jalr	678(ra) # 8000446e <iput>
    end_op();
    800051d0:	00000097          	auipc	ra,0x0
    800051d4:	b36080e7          	jalr	-1226(ra) # 80004d06 <end_op>
    800051d8:	a00d                	j	800051fa <fileclose+0xa8>
    panic("fileclose");
    800051da:	00003517          	auipc	a0,0x3
    800051de:	55650513          	addi	a0,a0,1366 # 80008730 <syscalls+0x260>
    800051e2:	ffffb097          	auipc	ra,0xffffb
    800051e6:	35c080e7          	jalr	860(ra) # 8000053e <panic>
    release(&ftable.lock);
    800051ea:	0001d517          	auipc	a0,0x1d
    800051ee:	cbe50513          	addi	a0,a0,-834 # 80021ea8 <ftable>
    800051f2:	ffffc097          	auipc	ra,0xffffc
    800051f6:	aa6080e7          	jalr	-1370(ra) # 80000c98 <release>
  }
}
    800051fa:	70e2                	ld	ra,56(sp)
    800051fc:	7442                	ld	s0,48(sp)
    800051fe:	74a2                	ld	s1,40(sp)
    80005200:	7902                	ld	s2,32(sp)
    80005202:	69e2                	ld	s3,24(sp)
    80005204:	6a42                	ld	s4,16(sp)
    80005206:	6aa2                	ld	s5,8(sp)
    80005208:	6121                	addi	sp,sp,64
    8000520a:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000520c:	85d6                	mv	a1,s5
    8000520e:	8552                	mv	a0,s4
    80005210:	00000097          	auipc	ra,0x0
    80005214:	34c080e7          	jalr	844(ra) # 8000555c <pipeclose>
    80005218:	b7cd                	j	800051fa <fileclose+0xa8>

000000008000521a <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000521a:	715d                	addi	sp,sp,-80
    8000521c:	e486                	sd	ra,72(sp)
    8000521e:	e0a2                	sd	s0,64(sp)
    80005220:	fc26                	sd	s1,56(sp)
    80005222:	f84a                	sd	s2,48(sp)
    80005224:	f44e                	sd	s3,40(sp)
    80005226:	0880                	addi	s0,sp,80
    80005228:	84aa                	mv	s1,a0
    8000522a:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000522c:	ffffd097          	auipc	ra,0xffffd
    80005230:	d74080e7          	jalr	-652(ra) # 80001fa0 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80005234:	409c                	lw	a5,0(s1)
    80005236:	37f9                	addiw	a5,a5,-2
    80005238:	4705                	li	a4,1
    8000523a:	04f76763          	bltu	a4,a5,80005288 <filestat+0x6e>
    8000523e:	892a                	mv	s2,a0
    ilock(f->ip);
    80005240:	6c88                	ld	a0,24(s1)
    80005242:	fffff097          	auipc	ra,0xfffff
    80005246:	072080e7          	jalr	114(ra) # 800042b4 <ilock>
    stati(f->ip, &st);
    8000524a:	fb840593          	addi	a1,s0,-72
    8000524e:	6c88                	ld	a0,24(s1)
    80005250:	fffff097          	auipc	ra,0xfffff
    80005254:	2ee080e7          	jalr	750(ra) # 8000453e <stati>
    iunlock(f->ip);
    80005258:	6c88                	ld	a0,24(s1)
    8000525a:	fffff097          	auipc	ra,0xfffff
    8000525e:	11c080e7          	jalr	284(ra) # 80004376 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80005262:	46e1                	li	a3,24
    80005264:	fb840613          	addi	a2,s0,-72
    80005268:	85ce                	mv	a1,s3
    8000526a:	06893503          	ld	a0,104(s2)
    8000526e:	ffffc097          	auipc	ra,0xffffc
    80005272:	404080e7          	jalr	1028(ra) # 80001672 <copyout>
    80005276:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000527a:	60a6                	ld	ra,72(sp)
    8000527c:	6406                	ld	s0,64(sp)
    8000527e:	74e2                	ld	s1,56(sp)
    80005280:	7942                	ld	s2,48(sp)
    80005282:	79a2                	ld	s3,40(sp)
    80005284:	6161                	addi	sp,sp,80
    80005286:	8082                	ret
  return -1;
    80005288:	557d                	li	a0,-1
    8000528a:	bfc5                	j	8000527a <filestat+0x60>

000000008000528c <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000528c:	7179                	addi	sp,sp,-48
    8000528e:	f406                	sd	ra,40(sp)
    80005290:	f022                	sd	s0,32(sp)
    80005292:	ec26                	sd	s1,24(sp)
    80005294:	e84a                	sd	s2,16(sp)
    80005296:	e44e                	sd	s3,8(sp)
    80005298:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000529a:	00854783          	lbu	a5,8(a0)
    8000529e:	c3d5                	beqz	a5,80005342 <fileread+0xb6>
    800052a0:	84aa                	mv	s1,a0
    800052a2:	89ae                	mv	s3,a1
    800052a4:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800052a6:	411c                	lw	a5,0(a0)
    800052a8:	4705                	li	a4,1
    800052aa:	04e78963          	beq	a5,a4,800052fc <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800052ae:	470d                	li	a4,3
    800052b0:	04e78d63          	beq	a5,a4,8000530a <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800052b4:	4709                	li	a4,2
    800052b6:	06e79e63          	bne	a5,a4,80005332 <fileread+0xa6>
    ilock(f->ip);
    800052ba:	6d08                	ld	a0,24(a0)
    800052bc:	fffff097          	auipc	ra,0xfffff
    800052c0:	ff8080e7          	jalr	-8(ra) # 800042b4 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800052c4:	874a                	mv	a4,s2
    800052c6:	5094                	lw	a3,32(s1)
    800052c8:	864e                	mv	a2,s3
    800052ca:	4585                	li	a1,1
    800052cc:	6c88                	ld	a0,24(s1)
    800052ce:	fffff097          	auipc	ra,0xfffff
    800052d2:	29a080e7          	jalr	666(ra) # 80004568 <readi>
    800052d6:	892a                	mv	s2,a0
    800052d8:	00a05563          	blez	a0,800052e2 <fileread+0x56>
      f->off += r;
    800052dc:	509c                	lw	a5,32(s1)
    800052de:	9fa9                	addw	a5,a5,a0
    800052e0:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800052e2:	6c88                	ld	a0,24(s1)
    800052e4:	fffff097          	auipc	ra,0xfffff
    800052e8:	092080e7          	jalr	146(ra) # 80004376 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800052ec:	854a                	mv	a0,s2
    800052ee:	70a2                	ld	ra,40(sp)
    800052f0:	7402                	ld	s0,32(sp)
    800052f2:	64e2                	ld	s1,24(sp)
    800052f4:	6942                	ld	s2,16(sp)
    800052f6:	69a2                	ld	s3,8(sp)
    800052f8:	6145                	addi	sp,sp,48
    800052fa:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800052fc:	6908                	ld	a0,16(a0)
    800052fe:	00000097          	auipc	ra,0x0
    80005302:	3c8080e7          	jalr	968(ra) # 800056c6 <piperead>
    80005306:	892a                	mv	s2,a0
    80005308:	b7d5                	j	800052ec <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000530a:	02451783          	lh	a5,36(a0)
    8000530e:	03079693          	slli	a3,a5,0x30
    80005312:	92c1                	srli	a3,a3,0x30
    80005314:	4725                	li	a4,9
    80005316:	02d76863          	bltu	a4,a3,80005346 <fileread+0xba>
    8000531a:	0792                	slli	a5,a5,0x4
    8000531c:	0001d717          	auipc	a4,0x1d
    80005320:	aec70713          	addi	a4,a4,-1300 # 80021e08 <devsw>
    80005324:	97ba                	add	a5,a5,a4
    80005326:	639c                	ld	a5,0(a5)
    80005328:	c38d                	beqz	a5,8000534a <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000532a:	4505                	li	a0,1
    8000532c:	9782                	jalr	a5
    8000532e:	892a                	mv	s2,a0
    80005330:	bf75                	j	800052ec <fileread+0x60>
    panic("fileread");
    80005332:	00003517          	auipc	a0,0x3
    80005336:	40e50513          	addi	a0,a0,1038 # 80008740 <syscalls+0x270>
    8000533a:	ffffb097          	auipc	ra,0xffffb
    8000533e:	204080e7          	jalr	516(ra) # 8000053e <panic>
    return -1;
    80005342:	597d                	li	s2,-1
    80005344:	b765                	j	800052ec <fileread+0x60>
      return -1;
    80005346:	597d                	li	s2,-1
    80005348:	b755                	j	800052ec <fileread+0x60>
    8000534a:	597d                	li	s2,-1
    8000534c:	b745                	j	800052ec <fileread+0x60>

000000008000534e <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    8000534e:	715d                	addi	sp,sp,-80
    80005350:	e486                	sd	ra,72(sp)
    80005352:	e0a2                	sd	s0,64(sp)
    80005354:	fc26                	sd	s1,56(sp)
    80005356:	f84a                	sd	s2,48(sp)
    80005358:	f44e                	sd	s3,40(sp)
    8000535a:	f052                	sd	s4,32(sp)
    8000535c:	ec56                	sd	s5,24(sp)
    8000535e:	e85a                	sd	s6,16(sp)
    80005360:	e45e                	sd	s7,8(sp)
    80005362:	e062                	sd	s8,0(sp)
    80005364:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80005366:	00954783          	lbu	a5,9(a0)
    8000536a:	10078663          	beqz	a5,80005476 <filewrite+0x128>
    8000536e:	892a                	mv	s2,a0
    80005370:	8aae                	mv	s5,a1
    80005372:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80005374:	411c                	lw	a5,0(a0)
    80005376:	4705                	li	a4,1
    80005378:	02e78263          	beq	a5,a4,8000539c <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000537c:	470d                	li	a4,3
    8000537e:	02e78663          	beq	a5,a4,800053aa <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80005382:	4709                	li	a4,2
    80005384:	0ee79163          	bne	a5,a4,80005466 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80005388:	0ac05d63          	blez	a2,80005442 <filewrite+0xf4>
    int i = 0;
    8000538c:	4981                	li	s3,0
    8000538e:	6b05                	lui	s6,0x1
    80005390:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80005394:	6b85                	lui	s7,0x1
    80005396:	c00b8b9b          	addiw	s7,s7,-1024
    8000539a:	a861                	j	80005432 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    8000539c:	6908                	ld	a0,16(a0)
    8000539e:	00000097          	auipc	ra,0x0
    800053a2:	22e080e7          	jalr	558(ra) # 800055cc <pipewrite>
    800053a6:	8a2a                	mv	s4,a0
    800053a8:	a045                	j	80005448 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800053aa:	02451783          	lh	a5,36(a0)
    800053ae:	03079693          	slli	a3,a5,0x30
    800053b2:	92c1                	srli	a3,a3,0x30
    800053b4:	4725                	li	a4,9
    800053b6:	0cd76263          	bltu	a4,a3,8000547a <filewrite+0x12c>
    800053ba:	0792                	slli	a5,a5,0x4
    800053bc:	0001d717          	auipc	a4,0x1d
    800053c0:	a4c70713          	addi	a4,a4,-1460 # 80021e08 <devsw>
    800053c4:	97ba                	add	a5,a5,a4
    800053c6:	679c                	ld	a5,8(a5)
    800053c8:	cbdd                	beqz	a5,8000547e <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800053ca:	4505                	li	a0,1
    800053cc:	9782                	jalr	a5
    800053ce:	8a2a                	mv	s4,a0
    800053d0:	a8a5                	j	80005448 <filewrite+0xfa>
    800053d2:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800053d6:	00000097          	auipc	ra,0x0
    800053da:	8b0080e7          	jalr	-1872(ra) # 80004c86 <begin_op>
      ilock(f->ip);
    800053de:	01893503          	ld	a0,24(s2)
    800053e2:	fffff097          	auipc	ra,0xfffff
    800053e6:	ed2080e7          	jalr	-302(ra) # 800042b4 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800053ea:	8762                	mv	a4,s8
    800053ec:	02092683          	lw	a3,32(s2)
    800053f0:	01598633          	add	a2,s3,s5
    800053f4:	4585                	li	a1,1
    800053f6:	01893503          	ld	a0,24(s2)
    800053fa:	fffff097          	auipc	ra,0xfffff
    800053fe:	266080e7          	jalr	614(ra) # 80004660 <writei>
    80005402:	84aa                	mv	s1,a0
    80005404:	00a05763          	blez	a0,80005412 <filewrite+0xc4>
        f->off += r;
    80005408:	02092783          	lw	a5,32(s2)
    8000540c:	9fa9                	addw	a5,a5,a0
    8000540e:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80005412:	01893503          	ld	a0,24(s2)
    80005416:	fffff097          	auipc	ra,0xfffff
    8000541a:	f60080e7          	jalr	-160(ra) # 80004376 <iunlock>
      end_op();
    8000541e:	00000097          	auipc	ra,0x0
    80005422:	8e8080e7          	jalr	-1816(ra) # 80004d06 <end_op>

      if(r != n1){
    80005426:	009c1f63          	bne	s8,s1,80005444 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    8000542a:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000542e:	0149db63          	bge	s3,s4,80005444 <filewrite+0xf6>
      int n1 = n - i;
    80005432:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80005436:	84be                	mv	s1,a5
    80005438:	2781                	sext.w	a5,a5
    8000543a:	f8fb5ce3          	bge	s6,a5,800053d2 <filewrite+0x84>
    8000543e:	84de                	mv	s1,s7
    80005440:	bf49                	j	800053d2 <filewrite+0x84>
    int i = 0;
    80005442:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80005444:	013a1f63          	bne	s4,s3,80005462 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80005448:	8552                	mv	a0,s4
    8000544a:	60a6                	ld	ra,72(sp)
    8000544c:	6406                	ld	s0,64(sp)
    8000544e:	74e2                	ld	s1,56(sp)
    80005450:	7942                	ld	s2,48(sp)
    80005452:	79a2                	ld	s3,40(sp)
    80005454:	7a02                	ld	s4,32(sp)
    80005456:	6ae2                	ld	s5,24(sp)
    80005458:	6b42                	ld	s6,16(sp)
    8000545a:	6ba2                	ld	s7,8(sp)
    8000545c:	6c02                	ld	s8,0(sp)
    8000545e:	6161                	addi	sp,sp,80
    80005460:	8082                	ret
    ret = (i == n ? n : -1);
    80005462:	5a7d                	li	s4,-1
    80005464:	b7d5                	j	80005448 <filewrite+0xfa>
    panic("filewrite");
    80005466:	00003517          	auipc	a0,0x3
    8000546a:	2ea50513          	addi	a0,a0,746 # 80008750 <syscalls+0x280>
    8000546e:	ffffb097          	auipc	ra,0xffffb
    80005472:	0d0080e7          	jalr	208(ra) # 8000053e <panic>
    return -1;
    80005476:	5a7d                	li	s4,-1
    80005478:	bfc1                	j	80005448 <filewrite+0xfa>
      return -1;
    8000547a:	5a7d                	li	s4,-1
    8000547c:	b7f1                	j	80005448 <filewrite+0xfa>
    8000547e:	5a7d                	li	s4,-1
    80005480:	b7e1                	j	80005448 <filewrite+0xfa>

0000000080005482 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80005482:	7179                	addi	sp,sp,-48
    80005484:	f406                	sd	ra,40(sp)
    80005486:	f022                	sd	s0,32(sp)
    80005488:	ec26                	sd	s1,24(sp)
    8000548a:	e84a                	sd	s2,16(sp)
    8000548c:	e44e                	sd	s3,8(sp)
    8000548e:	e052                	sd	s4,0(sp)
    80005490:	1800                	addi	s0,sp,48
    80005492:	84aa                	mv	s1,a0
    80005494:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80005496:	0005b023          	sd	zero,0(a1)
    8000549a:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    8000549e:	00000097          	auipc	ra,0x0
    800054a2:	bf8080e7          	jalr	-1032(ra) # 80005096 <filealloc>
    800054a6:	e088                	sd	a0,0(s1)
    800054a8:	c551                	beqz	a0,80005534 <pipealloc+0xb2>
    800054aa:	00000097          	auipc	ra,0x0
    800054ae:	bec080e7          	jalr	-1044(ra) # 80005096 <filealloc>
    800054b2:	00aa3023          	sd	a0,0(s4)
    800054b6:	c92d                	beqz	a0,80005528 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800054b8:	ffffb097          	auipc	ra,0xffffb
    800054bc:	63c080e7          	jalr	1596(ra) # 80000af4 <kalloc>
    800054c0:	892a                	mv	s2,a0
    800054c2:	c125                	beqz	a0,80005522 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800054c4:	4985                	li	s3,1
    800054c6:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800054ca:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800054ce:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800054d2:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800054d6:	00003597          	auipc	a1,0x3
    800054da:	28a58593          	addi	a1,a1,650 # 80008760 <syscalls+0x290>
    800054de:	ffffb097          	auipc	ra,0xffffb
    800054e2:	676080e7          	jalr	1654(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    800054e6:	609c                	ld	a5,0(s1)
    800054e8:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800054ec:	609c                	ld	a5,0(s1)
    800054ee:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800054f2:	609c                	ld	a5,0(s1)
    800054f4:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800054f8:	609c                	ld	a5,0(s1)
    800054fa:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800054fe:	000a3783          	ld	a5,0(s4)
    80005502:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005506:	000a3783          	ld	a5,0(s4)
    8000550a:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000550e:	000a3783          	ld	a5,0(s4)
    80005512:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005516:	000a3783          	ld	a5,0(s4)
    8000551a:	0127b823          	sd	s2,16(a5)
  return 0;
    8000551e:	4501                	li	a0,0
    80005520:	a025                	j	80005548 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80005522:	6088                	ld	a0,0(s1)
    80005524:	e501                	bnez	a0,8000552c <pipealloc+0xaa>
    80005526:	a039                	j	80005534 <pipealloc+0xb2>
    80005528:	6088                	ld	a0,0(s1)
    8000552a:	c51d                	beqz	a0,80005558 <pipealloc+0xd6>
    fileclose(*f0);
    8000552c:	00000097          	auipc	ra,0x0
    80005530:	c26080e7          	jalr	-986(ra) # 80005152 <fileclose>
  if(*f1)
    80005534:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80005538:	557d                	li	a0,-1
  if(*f1)
    8000553a:	c799                	beqz	a5,80005548 <pipealloc+0xc6>
    fileclose(*f1);
    8000553c:	853e                	mv	a0,a5
    8000553e:	00000097          	auipc	ra,0x0
    80005542:	c14080e7          	jalr	-1004(ra) # 80005152 <fileclose>
  return -1;
    80005546:	557d                	li	a0,-1
}
    80005548:	70a2                	ld	ra,40(sp)
    8000554a:	7402                	ld	s0,32(sp)
    8000554c:	64e2                	ld	s1,24(sp)
    8000554e:	6942                	ld	s2,16(sp)
    80005550:	69a2                	ld	s3,8(sp)
    80005552:	6a02                	ld	s4,0(sp)
    80005554:	6145                	addi	sp,sp,48
    80005556:	8082                	ret
  return -1;
    80005558:	557d                	li	a0,-1
    8000555a:	b7fd                	j	80005548 <pipealloc+0xc6>

000000008000555c <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    8000555c:	1101                	addi	sp,sp,-32
    8000555e:	ec06                	sd	ra,24(sp)
    80005560:	e822                	sd	s0,16(sp)
    80005562:	e426                	sd	s1,8(sp)
    80005564:	e04a                	sd	s2,0(sp)
    80005566:	1000                	addi	s0,sp,32
    80005568:	84aa                	mv	s1,a0
    8000556a:	892e                	mv	s2,a1
  acquire(&pi->lock);
    8000556c:	ffffb097          	auipc	ra,0xffffb
    80005570:	678080e7          	jalr	1656(ra) # 80000be4 <acquire>
  if(writable){
    80005574:	02090d63          	beqz	s2,800055ae <pipeclose+0x52>
    pi->writeopen = 0;
    80005578:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    8000557c:	21848513          	addi	a0,s1,536
    80005580:	ffffd097          	auipc	ra,0xffffd
    80005584:	442080e7          	jalr	1090(ra) # 800029c2 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005588:	2204b783          	ld	a5,544(s1)
    8000558c:	eb95                	bnez	a5,800055c0 <pipeclose+0x64>
    release(&pi->lock);
    8000558e:	8526                	mv	a0,s1
    80005590:	ffffb097          	auipc	ra,0xffffb
    80005594:	708080e7          	jalr	1800(ra) # 80000c98 <release>
    kfree((char*)pi);
    80005598:	8526                	mv	a0,s1
    8000559a:	ffffb097          	auipc	ra,0xffffb
    8000559e:	45e080e7          	jalr	1118(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    800055a2:	60e2                	ld	ra,24(sp)
    800055a4:	6442                	ld	s0,16(sp)
    800055a6:	64a2                	ld	s1,8(sp)
    800055a8:	6902                	ld	s2,0(sp)
    800055aa:	6105                	addi	sp,sp,32
    800055ac:	8082                	ret
    pi->readopen = 0;
    800055ae:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800055b2:	21c48513          	addi	a0,s1,540
    800055b6:	ffffd097          	auipc	ra,0xffffd
    800055ba:	40c080e7          	jalr	1036(ra) # 800029c2 <wakeup>
    800055be:	b7e9                	j	80005588 <pipeclose+0x2c>
    release(&pi->lock);
    800055c0:	8526                	mv	a0,s1
    800055c2:	ffffb097          	auipc	ra,0xffffb
    800055c6:	6d6080e7          	jalr	1750(ra) # 80000c98 <release>
}
    800055ca:	bfe1                	j	800055a2 <pipeclose+0x46>

00000000800055cc <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800055cc:	7159                	addi	sp,sp,-112
    800055ce:	f486                	sd	ra,104(sp)
    800055d0:	f0a2                	sd	s0,96(sp)
    800055d2:	eca6                	sd	s1,88(sp)
    800055d4:	e8ca                	sd	s2,80(sp)
    800055d6:	e4ce                	sd	s3,72(sp)
    800055d8:	e0d2                	sd	s4,64(sp)
    800055da:	fc56                	sd	s5,56(sp)
    800055dc:	f85a                	sd	s6,48(sp)
    800055de:	f45e                	sd	s7,40(sp)
    800055e0:	f062                	sd	s8,32(sp)
    800055e2:	ec66                	sd	s9,24(sp)
    800055e4:	1880                	addi	s0,sp,112
    800055e6:	84aa                	mv	s1,a0
    800055e8:	8aae                	mv	s5,a1
    800055ea:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800055ec:	ffffd097          	auipc	ra,0xffffd
    800055f0:	9b4080e7          	jalr	-1612(ra) # 80001fa0 <myproc>
    800055f4:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800055f6:	8526                	mv	a0,s1
    800055f8:	ffffb097          	auipc	ra,0xffffb
    800055fc:	5ec080e7          	jalr	1516(ra) # 80000be4 <acquire>
  while(i < n){
    80005600:	0d405163          	blez	s4,800056c2 <pipewrite+0xf6>
    80005604:	8ba6                	mv	s7,s1
  int i = 0;
    80005606:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005608:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    8000560a:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    8000560e:	21c48c13          	addi	s8,s1,540
    80005612:	a08d                	j	80005674 <pipewrite+0xa8>
      release(&pi->lock);
    80005614:	8526                	mv	a0,s1
    80005616:	ffffb097          	auipc	ra,0xffffb
    8000561a:	682080e7          	jalr	1666(ra) # 80000c98 <release>
      return -1;
    8000561e:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005620:	854a                	mv	a0,s2
    80005622:	70a6                	ld	ra,104(sp)
    80005624:	7406                	ld	s0,96(sp)
    80005626:	64e6                	ld	s1,88(sp)
    80005628:	6946                	ld	s2,80(sp)
    8000562a:	69a6                	ld	s3,72(sp)
    8000562c:	6a06                	ld	s4,64(sp)
    8000562e:	7ae2                	ld	s5,56(sp)
    80005630:	7b42                	ld	s6,48(sp)
    80005632:	7ba2                	ld	s7,40(sp)
    80005634:	7c02                	ld	s8,32(sp)
    80005636:	6ce2                	ld	s9,24(sp)
    80005638:	6165                	addi	sp,sp,112
    8000563a:	8082                	ret
      wakeup(&pi->nread);
    8000563c:	8566                	mv	a0,s9
    8000563e:	ffffd097          	auipc	ra,0xffffd
    80005642:	384080e7          	jalr	900(ra) # 800029c2 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005646:	85de                	mv	a1,s7
    80005648:	8562                	mv	a0,s8
    8000564a:	ffffd097          	auipc	ra,0xffffd
    8000564e:	1d6080e7          	jalr	470(ra) # 80002820 <sleep>
    80005652:	a839                	j	80005670 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005654:	21c4a783          	lw	a5,540(s1)
    80005658:	0017871b          	addiw	a4,a5,1
    8000565c:	20e4ae23          	sw	a4,540(s1)
    80005660:	1ff7f793          	andi	a5,a5,511
    80005664:	97a6                	add	a5,a5,s1
    80005666:	f9f44703          	lbu	a4,-97(s0)
    8000566a:	00e78c23          	sb	a4,24(a5)
      i++;
    8000566e:	2905                	addiw	s2,s2,1
  while(i < n){
    80005670:	03495d63          	bge	s2,s4,800056aa <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80005674:	2204a783          	lw	a5,544(s1)
    80005678:	dfd1                	beqz	a5,80005614 <pipewrite+0x48>
    8000567a:	0409a783          	lw	a5,64(s3)
    8000567e:	fbd9                	bnez	a5,80005614 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005680:	2184a783          	lw	a5,536(s1)
    80005684:	21c4a703          	lw	a4,540(s1)
    80005688:	2007879b          	addiw	a5,a5,512
    8000568c:	faf708e3          	beq	a4,a5,8000563c <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005690:	4685                	li	a3,1
    80005692:	01590633          	add	a2,s2,s5
    80005696:	f9f40593          	addi	a1,s0,-97
    8000569a:	0689b503          	ld	a0,104(s3)
    8000569e:	ffffc097          	auipc	ra,0xffffc
    800056a2:	060080e7          	jalr	96(ra) # 800016fe <copyin>
    800056a6:	fb6517e3          	bne	a0,s6,80005654 <pipewrite+0x88>
  wakeup(&pi->nread);
    800056aa:	21848513          	addi	a0,s1,536
    800056ae:	ffffd097          	auipc	ra,0xffffd
    800056b2:	314080e7          	jalr	788(ra) # 800029c2 <wakeup>
  release(&pi->lock);
    800056b6:	8526                	mv	a0,s1
    800056b8:	ffffb097          	auipc	ra,0xffffb
    800056bc:	5e0080e7          	jalr	1504(ra) # 80000c98 <release>
  return i;
    800056c0:	b785                	j	80005620 <pipewrite+0x54>
  int i = 0;
    800056c2:	4901                	li	s2,0
    800056c4:	b7dd                	j	800056aa <pipewrite+0xde>

00000000800056c6 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800056c6:	715d                	addi	sp,sp,-80
    800056c8:	e486                	sd	ra,72(sp)
    800056ca:	e0a2                	sd	s0,64(sp)
    800056cc:	fc26                	sd	s1,56(sp)
    800056ce:	f84a                	sd	s2,48(sp)
    800056d0:	f44e                	sd	s3,40(sp)
    800056d2:	f052                	sd	s4,32(sp)
    800056d4:	ec56                	sd	s5,24(sp)
    800056d6:	e85a                	sd	s6,16(sp)
    800056d8:	0880                	addi	s0,sp,80
    800056da:	84aa                	mv	s1,a0
    800056dc:	892e                	mv	s2,a1
    800056de:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800056e0:	ffffd097          	auipc	ra,0xffffd
    800056e4:	8c0080e7          	jalr	-1856(ra) # 80001fa0 <myproc>
    800056e8:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800056ea:	8b26                	mv	s6,s1
    800056ec:	8526                	mv	a0,s1
    800056ee:	ffffb097          	auipc	ra,0xffffb
    800056f2:	4f6080e7          	jalr	1270(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800056f6:	2184a703          	lw	a4,536(s1)
    800056fa:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800056fe:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005702:	02f71463          	bne	a4,a5,8000572a <piperead+0x64>
    80005706:	2244a783          	lw	a5,548(s1)
    8000570a:	c385                	beqz	a5,8000572a <piperead+0x64>
    if(pr->killed){
    8000570c:	040a2783          	lw	a5,64(s4)
    80005710:	ebc1                	bnez	a5,800057a0 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005712:	85da                	mv	a1,s6
    80005714:	854e                	mv	a0,s3
    80005716:	ffffd097          	auipc	ra,0xffffd
    8000571a:	10a080e7          	jalr	266(ra) # 80002820 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000571e:	2184a703          	lw	a4,536(s1)
    80005722:	21c4a783          	lw	a5,540(s1)
    80005726:	fef700e3          	beq	a4,a5,80005706 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000572a:	09505263          	blez	s5,800057ae <piperead+0xe8>
    8000572e:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005730:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80005732:	2184a783          	lw	a5,536(s1)
    80005736:	21c4a703          	lw	a4,540(s1)
    8000573a:	02f70d63          	beq	a4,a5,80005774 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    8000573e:	0017871b          	addiw	a4,a5,1
    80005742:	20e4ac23          	sw	a4,536(s1)
    80005746:	1ff7f793          	andi	a5,a5,511
    8000574a:	97a6                	add	a5,a5,s1
    8000574c:	0187c783          	lbu	a5,24(a5)
    80005750:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005754:	4685                	li	a3,1
    80005756:	fbf40613          	addi	a2,s0,-65
    8000575a:	85ca                	mv	a1,s2
    8000575c:	068a3503          	ld	a0,104(s4)
    80005760:	ffffc097          	auipc	ra,0xffffc
    80005764:	f12080e7          	jalr	-238(ra) # 80001672 <copyout>
    80005768:	01650663          	beq	a0,s6,80005774 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000576c:	2985                	addiw	s3,s3,1
    8000576e:	0905                	addi	s2,s2,1
    80005770:	fd3a91e3          	bne	s5,s3,80005732 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005774:	21c48513          	addi	a0,s1,540
    80005778:	ffffd097          	auipc	ra,0xffffd
    8000577c:	24a080e7          	jalr	586(ra) # 800029c2 <wakeup>
  release(&pi->lock);
    80005780:	8526                	mv	a0,s1
    80005782:	ffffb097          	auipc	ra,0xffffb
    80005786:	516080e7          	jalr	1302(ra) # 80000c98 <release>
  return i;
}
    8000578a:	854e                	mv	a0,s3
    8000578c:	60a6                	ld	ra,72(sp)
    8000578e:	6406                	ld	s0,64(sp)
    80005790:	74e2                	ld	s1,56(sp)
    80005792:	7942                	ld	s2,48(sp)
    80005794:	79a2                	ld	s3,40(sp)
    80005796:	7a02                	ld	s4,32(sp)
    80005798:	6ae2                	ld	s5,24(sp)
    8000579a:	6b42                	ld	s6,16(sp)
    8000579c:	6161                	addi	sp,sp,80
    8000579e:	8082                	ret
      release(&pi->lock);
    800057a0:	8526                	mv	a0,s1
    800057a2:	ffffb097          	auipc	ra,0xffffb
    800057a6:	4f6080e7          	jalr	1270(ra) # 80000c98 <release>
      return -1;
    800057aa:	59fd                	li	s3,-1
    800057ac:	bff9                	j	8000578a <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800057ae:	4981                	li	s3,0
    800057b0:	b7d1                	j	80005774 <piperead+0xae>

00000000800057b2 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    800057b2:	df010113          	addi	sp,sp,-528
    800057b6:	20113423          	sd	ra,520(sp)
    800057ba:	20813023          	sd	s0,512(sp)
    800057be:	ffa6                	sd	s1,504(sp)
    800057c0:	fbca                	sd	s2,496(sp)
    800057c2:	f7ce                	sd	s3,488(sp)
    800057c4:	f3d2                	sd	s4,480(sp)
    800057c6:	efd6                	sd	s5,472(sp)
    800057c8:	ebda                	sd	s6,464(sp)
    800057ca:	e7de                	sd	s7,456(sp)
    800057cc:	e3e2                	sd	s8,448(sp)
    800057ce:	ff66                	sd	s9,440(sp)
    800057d0:	fb6a                	sd	s10,432(sp)
    800057d2:	f76e                	sd	s11,424(sp)
    800057d4:	0c00                	addi	s0,sp,528
    800057d6:	84aa                	mv	s1,a0
    800057d8:	dea43c23          	sd	a0,-520(s0)
    800057dc:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800057e0:	ffffc097          	auipc	ra,0xffffc
    800057e4:	7c0080e7          	jalr	1984(ra) # 80001fa0 <myproc>
    800057e8:	892a                	mv	s2,a0

  begin_op();
    800057ea:	fffff097          	auipc	ra,0xfffff
    800057ee:	49c080e7          	jalr	1180(ra) # 80004c86 <begin_op>

  if((ip = namei(path)) == 0){
    800057f2:	8526                	mv	a0,s1
    800057f4:	fffff097          	auipc	ra,0xfffff
    800057f8:	276080e7          	jalr	630(ra) # 80004a6a <namei>
    800057fc:	c92d                	beqz	a0,8000586e <exec+0xbc>
    800057fe:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005800:	fffff097          	auipc	ra,0xfffff
    80005804:	ab4080e7          	jalr	-1356(ra) # 800042b4 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005808:	04000713          	li	a4,64
    8000580c:	4681                	li	a3,0
    8000580e:	e5040613          	addi	a2,s0,-432
    80005812:	4581                	li	a1,0
    80005814:	8526                	mv	a0,s1
    80005816:	fffff097          	auipc	ra,0xfffff
    8000581a:	d52080e7          	jalr	-686(ra) # 80004568 <readi>
    8000581e:	04000793          	li	a5,64
    80005822:	00f51a63          	bne	a0,a5,80005836 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005826:	e5042703          	lw	a4,-432(s0)
    8000582a:	464c47b7          	lui	a5,0x464c4
    8000582e:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005832:	04f70463          	beq	a4,a5,8000587a <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005836:	8526                	mv	a0,s1
    80005838:	fffff097          	auipc	ra,0xfffff
    8000583c:	cde080e7          	jalr	-802(ra) # 80004516 <iunlockput>
    end_op();
    80005840:	fffff097          	auipc	ra,0xfffff
    80005844:	4c6080e7          	jalr	1222(ra) # 80004d06 <end_op>
  }
  return -1;
    80005848:	557d                	li	a0,-1
}
    8000584a:	20813083          	ld	ra,520(sp)
    8000584e:	20013403          	ld	s0,512(sp)
    80005852:	74fe                	ld	s1,504(sp)
    80005854:	795e                	ld	s2,496(sp)
    80005856:	79be                	ld	s3,488(sp)
    80005858:	7a1e                	ld	s4,480(sp)
    8000585a:	6afe                	ld	s5,472(sp)
    8000585c:	6b5e                	ld	s6,464(sp)
    8000585e:	6bbe                	ld	s7,456(sp)
    80005860:	6c1e                	ld	s8,448(sp)
    80005862:	7cfa                	ld	s9,440(sp)
    80005864:	7d5a                	ld	s10,432(sp)
    80005866:	7dba                	ld	s11,424(sp)
    80005868:	21010113          	addi	sp,sp,528
    8000586c:	8082                	ret
    end_op();
    8000586e:	fffff097          	auipc	ra,0xfffff
    80005872:	498080e7          	jalr	1176(ra) # 80004d06 <end_op>
    return -1;
    80005876:	557d                	li	a0,-1
    80005878:	bfc9                	j	8000584a <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    8000587a:	854a                	mv	a0,s2
    8000587c:	ffffc097          	auipc	ra,0xffffc
    80005880:	7dc080e7          	jalr	2012(ra) # 80002058 <proc_pagetable>
    80005884:	8baa                	mv	s7,a0
    80005886:	d945                	beqz	a0,80005836 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005888:	e7042983          	lw	s3,-400(s0)
    8000588c:	e8845783          	lhu	a5,-376(s0)
    80005890:	c7ad                	beqz	a5,800058fa <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005892:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005894:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80005896:	6c85                	lui	s9,0x1
    80005898:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    8000589c:	def43823          	sd	a5,-528(s0)
    800058a0:	a42d                	j	80005aca <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800058a2:	00003517          	auipc	a0,0x3
    800058a6:	ec650513          	addi	a0,a0,-314 # 80008768 <syscalls+0x298>
    800058aa:	ffffb097          	auipc	ra,0xffffb
    800058ae:	c94080e7          	jalr	-876(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800058b2:	8756                	mv	a4,s5
    800058b4:	012d86bb          	addw	a3,s11,s2
    800058b8:	4581                	li	a1,0
    800058ba:	8526                	mv	a0,s1
    800058bc:	fffff097          	auipc	ra,0xfffff
    800058c0:	cac080e7          	jalr	-852(ra) # 80004568 <readi>
    800058c4:	2501                	sext.w	a0,a0
    800058c6:	1aaa9963          	bne	s5,a0,80005a78 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    800058ca:	6785                	lui	a5,0x1
    800058cc:	0127893b          	addw	s2,a5,s2
    800058d0:	77fd                	lui	a5,0xfffff
    800058d2:	01478a3b          	addw	s4,a5,s4
    800058d6:	1f897163          	bgeu	s2,s8,80005ab8 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    800058da:	02091593          	slli	a1,s2,0x20
    800058de:	9181                	srli	a1,a1,0x20
    800058e0:	95ea                	add	a1,a1,s10
    800058e2:	855e                	mv	a0,s7
    800058e4:	ffffb097          	auipc	ra,0xffffb
    800058e8:	78a080e7          	jalr	1930(ra) # 8000106e <walkaddr>
    800058ec:	862a                	mv	a2,a0
    if(pa == 0)
    800058ee:	d955                	beqz	a0,800058a2 <exec+0xf0>
      n = PGSIZE;
    800058f0:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    800058f2:	fd9a70e3          	bgeu	s4,s9,800058b2 <exec+0x100>
      n = sz - i;
    800058f6:	8ad2                	mv	s5,s4
    800058f8:	bf6d                	j	800058b2 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800058fa:	4901                	li	s2,0
  iunlockput(ip);
    800058fc:	8526                	mv	a0,s1
    800058fe:	fffff097          	auipc	ra,0xfffff
    80005902:	c18080e7          	jalr	-1000(ra) # 80004516 <iunlockput>
  end_op();
    80005906:	fffff097          	auipc	ra,0xfffff
    8000590a:	400080e7          	jalr	1024(ra) # 80004d06 <end_op>
  p = myproc();
    8000590e:	ffffc097          	auipc	ra,0xffffc
    80005912:	692080e7          	jalr	1682(ra) # 80001fa0 <myproc>
    80005916:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005918:	06053d03          	ld	s10,96(a0)
  sz = PGROUNDUP(sz);
    8000591c:	6785                	lui	a5,0x1
    8000591e:	17fd                	addi	a5,a5,-1
    80005920:	993e                	add	s2,s2,a5
    80005922:	757d                	lui	a0,0xfffff
    80005924:	00a977b3          	and	a5,s2,a0
    80005928:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000592c:	6609                	lui	a2,0x2
    8000592e:	963e                	add	a2,a2,a5
    80005930:	85be                	mv	a1,a5
    80005932:	855e                	mv	a0,s7
    80005934:	ffffc097          	auipc	ra,0xffffc
    80005938:	aee080e7          	jalr	-1298(ra) # 80001422 <uvmalloc>
    8000593c:	8b2a                	mv	s6,a0
  ip = 0;
    8000593e:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005940:	12050c63          	beqz	a0,80005a78 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005944:	75f9                	lui	a1,0xffffe
    80005946:	95aa                	add	a1,a1,a0
    80005948:	855e                	mv	a0,s7
    8000594a:	ffffc097          	auipc	ra,0xffffc
    8000594e:	cf6080e7          	jalr	-778(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    80005952:	7c7d                	lui	s8,0xfffff
    80005954:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80005956:	e0043783          	ld	a5,-512(s0)
    8000595a:	6388                	ld	a0,0(a5)
    8000595c:	c535                	beqz	a0,800059c8 <exec+0x216>
    8000595e:	e9040993          	addi	s3,s0,-368
    80005962:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005966:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005968:	ffffb097          	auipc	ra,0xffffb
    8000596c:	4fc080e7          	jalr	1276(ra) # 80000e64 <strlen>
    80005970:	2505                	addiw	a0,a0,1
    80005972:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005976:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    8000597a:	13896363          	bltu	s2,s8,80005aa0 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000597e:	e0043d83          	ld	s11,-512(s0)
    80005982:	000dba03          	ld	s4,0(s11)
    80005986:	8552                	mv	a0,s4
    80005988:	ffffb097          	auipc	ra,0xffffb
    8000598c:	4dc080e7          	jalr	1244(ra) # 80000e64 <strlen>
    80005990:	0015069b          	addiw	a3,a0,1
    80005994:	8652                	mv	a2,s4
    80005996:	85ca                	mv	a1,s2
    80005998:	855e                	mv	a0,s7
    8000599a:	ffffc097          	auipc	ra,0xffffc
    8000599e:	cd8080e7          	jalr	-808(ra) # 80001672 <copyout>
    800059a2:	10054363          	bltz	a0,80005aa8 <exec+0x2f6>
    ustack[argc] = sp;
    800059a6:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800059aa:	0485                	addi	s1,s1,1
    800059ac:	008d8793          	addi	a5,s11,8
    800059b0:	e0f43023          	sd	a5,-512(s0)
    800059b4:	008db503          	ld	a0,8(s11)
    800059b8:	c911                	beqz	a0,800059cc <exec+0x21a>
    if(argc >= MAXARG)
    800059ba:	09a1                	addi	s3,s3,8
    800059bc:	fb3c96e3          	bne	s9,s3,80005968 <exec+0x1b6>
  sz = sz1;
    800059c0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800059c4:	4481                	li	s1,0
    800059c6:	a84d                	j	80005a78 <exec+0x2c6>
  sp = sz;
    800059c8:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    800059ca:	4481                	li	s1,0
  ustack[argc] = 0;
    800059cc:	00349793          	slli	a5,s1,0x3
    800059d0:	f9040713          	addi	a4,s0,-112
    800059d4:	97ba                	add	a5,a5,a4
    800059d6:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    800059da:	00148693          	addi	a3,s1,1
    800059de:	068e                	slli	a3,a3,0x3
    800059e0:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800059e4:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800059e8:	01897663          	bgeu	s2,s8,800059f4 <exec+0x242>
  sz = sz1;
    800059ec:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800059f0:	4481                	li	s1,0
    800059f2:	a059                	j	80005a78 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800059f4:	e9040613          	addi	a2,s0,-368
    800059f8:	85ca                	mv	a1,s2
    800059fa:	855e                	mv	a0,s7
    800059fc:	ffffc097          	auipc	ra,0xffffc
    80005a00:	c76080e7          	jalr	-906(ra) # 80001672 <copyout>
    80005a04:	0a054663          	bltz	a0,80005ab0 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80005a08:	070ab783          	ld	a5,112(s5)
    80005a0c:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005a10:	df843783          	ld	a5,-520(s0)
    80005a14:	0007c703          	lbu	a4,0(a5)
    80005a18:	cf11                	beqz	a4,80005a34 <exec+0x282>
    80005a1a:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005a1c:	02f00693          	li	a3,47
    80005a20:	a039                	j	80005a2e <exec+0x27c>
      last = s+1;
    80005a22:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005a26:	0785                	addi	a5,a5,1
    80005a28:	fff7c703          	lbu	a4,-1(a5)
    80005a2c:	c701                	beqz	a4,80005a34 <exec+0x282>
    if(*s == '/')
    80005a2e:	fed71ce3          	bne	a4,a3,80005a26 <exec+0x274>
    80005a32:	bfc5                	j	80005a22 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005a34:	4641                	li	a2,16
    80005a36:	df843583          	ld	a1,-520(s0)
    80005a3a:	170a8513          	addi	a0,s5,368
    80005a3e:	ffffb097          	auipc	ra,0xffffb
    80005a42:	3f4080e7          	jalr	1012(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80005a46:	068ab503          	ld	a0,104(s5)
  p->pagetable = pagetable;
    80005a4a:	077ab423          	sd	s7,104(s5)
  p->sz = sz;
    80005a4e:	076ab023          	sd	s6,96(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005a52:	070ab783          	ld	a5,112(s5)
    80005a56:	e6843703          	ld	a4,-408(s0)
    80005a5a:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005a5c:	070ab783          	ld	a5,112(s5)
    80005a60:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005a64:	85ea                	mv	a1,s10
    80005a66:	ffffc097          	auipc	ra,0xffffc
    80005a6a:	68e080e7          	jalr	1678(ra) # 800020f4 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005a6e:	0004851b          	sext.w	a0,s1
    80005a72:	bbe1                	j	8000584a <exec+0x98>
    80005a74:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005a78:	e0843583          	ld	a1,-504(s0)
    80005a7c:	855e                	mv	a0,s7
    80005a7e:	ffffc097          	auipc	ra,0xffffc
    80005a82:	676080e7          	jalr	1654(ra) # 800020f4 <proc_freepagetable>
  if(ip){
    80005a86:	da0498e3          	bnez	s1,80005836 <exec+0x84>
  return -1;
    80005a8a:	557d                	li	a0,-1
    80005a8c:	bb7d                	j	8000584a <exec+0x98>
    80005a8e:	e1243423          	sd	s2,-504(s0)
    80005a92:	b7dd                	j	80005a78 <exec+0x2c6>
    80005a94:	e1243423          	sd	s2,-504(s0)
    80005a98:	b7c5                	j	80005a78 <exec+0x2c6>
    80005a9a:	e1243423          	sd	s2,-504(s0)
    80005a9e:	bfe9                	j	80005a78 <exec+0x2c6>
  sz = sz1;
    80005aa0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005aa4:	4481                	li	s1,0
    80005aa6:	bfc9                	j	80005a78 <exec+0x2c6>
  sz = sz1;
    80005aa8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005aac:	4481                	li	s1,0
    80005aae:	b7e9                	j	80005a78 <exec+0x2c6>
  sz = sz1;
    80005ab0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005ab4:	4481                	li	s1,0
    80005ab6:	b7c9                	j	80005a78 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005ab8:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005abc:	2b05                	addiw	s6,s6,1
    80005abe:	0389899b          	addiw	s3,s3,56
    80005ac2:	e8845783          	lhu	a5,-376(s0)
    80005ac6:	e2fb5be3          	bge	s6,a5,800058fc <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005aca:	2981                	sext.w	s3,s3
    80005acc:	03800713          	li	a4,56
    80005ad0:	86ce                	mv	a3,s3
    80005ad2:	e1840613          	addi	a2,s0,-488
    80005ad6:	4581                	li	a1,0
    80005ad8:	8526                	mv	a0,s1
    80005ada:	fffff097          	auipc	ra,0xfffff
    80005ade:	a8e080e7          	jalr	-1394(ra) # 80004568 <readi>
    80005ae2:	03800793          	li	a5,56
    80005ae6:	f8f517e3          	bne	a0,a5,80005a74 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005aea:	e1842783          	lw	a5,-488(s0)
    80005aee:	4705                	li	a4,1
    80005af0:	fce796e3          	bne	a5,a4,80005abc <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005af4:	e4043603          	ld	a2,-448(s0)
    80005af8:	e3843783          	ld	a5,-456(s0)
    80005afc:	f8f669e3          	bltu	a2,a5,80005a8e <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005b00:	e2843783          	ld	a5,-472(s0)
    80005b04:	963e                	add	a2,a2,a5
    80005b06:	f8f667e3          	bltu	a2,a5,80005a94 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005b0a:	85ca                	mv	a1,s2
    80005b0c:	855e                	mv	a0,s7
    80005b0e:	ffffc097          	auipc	ra,0xffffc
    80005b12:	914080e7          	jalr	-1772(ra) # 80001422 <uvmalloc>
    80005b16:	e0a43423          	sd	a0,-504(s0)
    80005b1a:	d141                	beqz	a0,80005a9a <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80005b1c:	e2843d03          	ld	s10,-472(s0)
    80005b20:	df043783          	ld	a5,-528(s0)
    80005b24:	00fd77b3          	and	a5,s10,a5
    80005b28:	fba1                	bnez	a5,80005a78 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005b2a:	e2042d83          	lw	s11,-480(s0)
    80005b2e:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005b32:	f80c03e3          	beqz	s8,80005ab8 <exec+0x306>
    80005b36:	8a62                	mv	s4,s8
    80005b38:	4901                	li	s2,0
    80005b3a:	b345                	j	800058da <exec+0x128>

0000000080005b3c <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005b3c:	7179                	addi	sp,sp,-48
    80005b3e:	f406                	sd	ra,40(sp)
    80005b40:	f022                	sd	s0,32(sp)
    80005b42:	ec26                	sd	s1,24(sp)
    80005b44:	e84a                	sd	s2,16(sp)
    80005b46:	1800                	addi	s0,sp,48
    80005b48:	892e                	mv	s2,a1
    80005b4a:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005b4c:	fdc40593          	addi	a1,s0,-36
    80005b50:	ffffe097          	auipc	ra,0xffffe
    80005b54:	b76080e7          	jalr	-1162(ra) # 800036c6 <argint>
    80005b58:	04054063          	bltz	a0,80005b98 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005b5c:	fdc42703          	lw	a4,-36(s0)
    80005b60:	47bd                	li	a5,15
    80005b62:	02e7ed63          	bltu	a5,a4,80005b9c <argfd+0x60>
    80005b66:	ffffc097          	auipc	ra,0xffffc
    80005b6a:	43a080e7          	jalr	1082(ra) # 80001fa0 <myproc>
    80005b6e:	fdc42703          	lw	a4,-36(s0)
    80005b72:	01c70793          	addi	a5,a4,28
    80005b76:	078e                	slli	a5,a5,0x3
    80005b78:	953e                	add	a0,a0,a5
    80005b7a:	651c                	ld	a5,8(a0)
    80005b7c:	c395                	beqz	a5,80005ba0 <argfd+0x64>
    return -1;
  if(pfd)
    80005b7e:	00090463          	beqz	s2,80005b86 <argfd+0x4a>
    *pfd = fd;
    80005b82:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005b86:	4501                	li	a0,0
  if(pf)
    80005b88:	c091                	beqz	s1,80005b8c <argfd+0x50>
    *pf = f;
    80005b8a:	e09c                	sd	a5,0(s1)
}
    80005b8c:	70a2                	ld	ra,40(sp)
    80005b8e:	7402                	ld	s0,32(sp)
    80005b90:	64e2                	ld	s1,24(sp)
    80005b92:	6942                	ld	s2,16(sp)
    80005b94:	6145                	addi	sp,sp,48
    80005b96:	8082                	ret
    return -1;
    80005b98:	557d                	li	a0,-1
    80005b9a:	bfcd                	j	80005b8c <argfd+0x50>
    return -1;
    80005b9c:	557d                	li	a0,-1
    80005b9e:	b7fd                	j	80005b8c <argfd+0x50>
    80005ba0:	557d                	li	a0,-1
    80005ba2:	b7ed                	j	80005b8c <argfd+0x50>

0000000080005ba4 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005ba4:	1101                	addi	sp,sp,-32
    80005ba6:	ec06                	sd	ra,24(sp)
    80005ba8:	e822                	sd	s0,16(sp)
    80005baa:	e426                	sd	s1,8(sp)
    80005bac:	1000                	addi	s0,sp,32
    80005bae:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005bb0:	ffffc097          	auipc	ra,0xffffc
    80005bb4:	3f0080e7          	jalr	1008(ra) # 80001fa0 <myproc>
    80005bb8:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005bba:	0e850793          	addi	a5,a0,232 # fffffffffffff0e8 <end+0xffffffff7ffd90e8>
    80005bbe:	4501                	li	a0,0
    80005bc0:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005bc2:	6398                	ld	a4,0(a5)
    80005bc4:	cb19                	beqz	a4,80005bda <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005bc6:	2505                	addiw	a0,a0,1
    80005bc8:	07a1                	addi	a5,a5,8
    80005bca:	fed51ce3          	bne	a0,a3,80005bc2 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005bce:	557d                	li	a0,-1
}
    80005bd0:	60e2                	ld	ra,24(sp)
    80005bd2:	6442                	ld	s0,16(sp)
    80005bd4:	64a2                	ld	s1,8(sp)
    80005bd6:	6105                	addi	sp,sp,32
    80005bd8:	8082                	ret
      p->ofile[fd] = f;
    80005bda:	01c50793          	addi	a5,a0,28
    80005bde:	078e                	slli	a5,a5,0x3
    80005be0:	963e                	add	a2,a2,a5
    80005be2:	e604                	sd	s1,8(a2)
      return fd;
    80005be4:	b7f5                	j	80005bd0 <fdalloc+0x2c>

0000000080005be6 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005be6:	715d                	addi	sp,sp,-80
    80005be8:	e486                	sd	ra,72(sp)
    80005bea:	e0a2                	sd	s0,64(sp)
    80005bec:	fc26                	sd	s1,56(sp)
    80005bee:	f84a                	sd	s2,48(sp)
    80005bf0:	f44e                	sd	s3,40(sp)
    80005bf2:	f052                	sd	s4,32(sp)
    80005bf4:	ec56                	sd	s5,24(sp)
    80005bf6:	0880                	addi	s0,sp,80
    80005bf8:	89ae                	mv	s3,a1
    80005bfa:	8ab2                	mv	s5,a2
    80005bfc:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005bfe:	fb040593          	addi	a1,s0,-80
    80005c02:	fffff097          	auipc	ra,0xfffff
    80005c06:	e86080e7          	jalr	-378(ra) # 80004a88 <nameiparent>
    80005c0a:	892a                	mv	s2,a0
    80005c0c:	12050f63          	beqz	a0,80005d4a <create+0x164>
    return 0;

  ilock(dp);
    80005c10:	ffffe097          	auipc	ra,0xffffe
    80005c14:	6a4080e7          	jalr	1700(ra) # 800042b4 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005c18:	4601                	li	a2,0
    80005c1a:	fb040593          	addi	a1,s0,-80
    80005c1e:	854a                	mv	a0,s2
    80005c20:	fffff097          	auipc	ra,0xfffff
    80005c24:	b78080e7          	jalr	-1160(ra) # 80004798 <dirlookup>
    80005c28:	84aa                	mv	s1,a0
    80005c2a:	c921                	beqz	a0,80005c7a <create+0x94>
    iunlockput(dp);
    80005c2c:	854a                	mv	a0,s2
    80005c2e:	fffff097          	auipc	ra,0xfffff
    80005c32:	8e8080e7          	jalr	-1816(ra) # 80004516 <iunlockput>
    ilock(ip);
    80005c36:	8526                	mv	a0,s1
    80005c38:	ffffe097          	auipc	ra,0xffffe
    80005c3c:	67c080e7          	jalr	1660(ra) # 800042b4 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005c40:	2981                	sext.w	s3,s3
    80005c42:	4789                	li	a5,2
    80005c44:	02f99463          	bne	s3,a5,80005c6c <create+0x86>
    80005c48:	0444d783          	lhu	a5,68(s1)
    80005c4c:	37f9                	addiw	a5,a5,-2
    80005c4e:	17c2                	slli	a5,a5,0x30
    80005c50:	93c1                	srli	a5,a5,0x30
    80005c52:	4705                	li	a4,1
    80005c54:	00f76c63          	bltu	a4,a5,80005c6c <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005c58:	8526                	mv	a0,s1
    80005c5a:	60a6                	ld	ra,72(sp)
    80005c5c:	6406                	ld	s0,64(sp)
    80005c5e:	74e2                	ld	s1,56(sp)
    80005c60:	7942                	ld	s2,48(sp)
    80005c62:	79a2                	ld	s3,40(sp)
    80005c64:	7a02                	ld	s4,32(sp)
    80005c66:	6ae2                	ld	s5,24(sp)
    80005c68:	6161                	addi	sp,sp,80
    80005c6a:	8082                	ret
    iunlockput(ip);
    80005c6c:	8526                	mv	a0,s1
    80005c6e:	fffff097          	auipc	ra,0xfffff
    80005c72:	8a8080e7          	jalr	-1880(ra) # 80004516 <iunlockput>
    return 0;
    80005c76:	4481                	li	s1,0
    80005c78:	b7c5                	j	80005c58 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005c7a:	85ce                	mv	a1,s3
    80005c7c:	00092503          	lw	a0,0(s2)
    80005c80:	ffffe097          	auipc	ra,0xffffe
    80005c84:	49c080e7          	jalr	1180(ra) # 8000411c <ialloc>
    80005c88:	84aa                	mv	s1,a0
    80005c8a:	c529                	beqz	a0,80005cd4 <create+0xee>
  ilock(ip);
    80005c8c:	ffffe097          	auipc	ra,0xffffe
    80005c90:	628080e7          	jalr	1576(ra) # 800042b4 <ilock>
  ip->major = major;
    80005c94:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005c98:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005c9c:	4785                	li	a5,1
    80005c9e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005ca2:	8526                	mv	a0,s1
    80005ca4:	ffffe097          	auipc	ra,0xffffe
    80005ca8:	546080e7          	jalr	1350(ra) # 800041ea <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005cac:	2981                	sext.w	s3,s3
    80005cae:	4785                	li	a5,1
    80005cb0:	02f98a63          	beq	s3,a5,80005ce4 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005cb4:	40d0                	lw	a2,4(s1)
    80005cb6:	fb040593          	addi	a1,s0,-80
    80005cba:	854a                	mv	a0,s2
    80005cbc:	fffff097          	auipc	ra,0xfffff
    80005cc0:	cec080e7          	jalr	-788(ra) # 800049a8 <dirlink>
    80005cc4:	06054b63          	bltz	a0,80005d3a <create+0x154>
  iunlockput(dp);
    80005cc8:	854a                	mv	a0,s2
    80005cca:	fffff097          	auipc	ra,0xfffff
    80005cce:	84c080e7          	jalr	-1972(ra) # 80004516 <iunlockput>
  return ip;
    80005cd2:	b759                	j	80005c58 <create+0x72>
    panic("create: ialloc");
    80005cd4:	00003517          	auipc	a0,0x3
    80005cd8:	ab450513          	addi	a0,a0,-1356 # 80008788 <syscalls+0x2b8>
    80005cdc:	ffffb097          	auipc	ra,0xffffb
    80005ce0:	862080e7          	jalr	-1950(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005ce4:	04a95783          	lhu	a5,74(s2)
    80005ce8:	2785                	addiw	a5,a5,1
    80005cea:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005cee:	854a                	mv	a0,s2
    80005cf0:	ffffe097          	auipc	ra,0xffffe
    80005cf4:	4fa080e7          	jalr	1274(ra) # 800041ea <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005cf8:	40d0                	lw	a2,4(s1)
    80005cfa:	00003597          	auipc	a1,0x3
    80005cfe:	a9e58593          	addi	a1,a1,-1378 # 80008798 <syscalls+0x2c8>
    80005d02:	8526                	mv	a0,s1
    80005d04:	fffff097          	auipc	ra,0xfffff
    80005d08:	ca4080e7          	jalr	-860(ra) # 800049a8 <dirlink>
    80005d0c:	00054f63          	bltz	a0,80005d2a <create+0x144>
    80005d10:	00492603          	lw	a2,4(s2)
    80005d14:	00003597          	auipc	a1,0x3
    80005d18:	a8c58593          	addi	a1,a1,-1396 # 800087a0 <syscalls+0x2d0>
    80005d1c:	8526                	mv	a0,s1
    80005d1e:	fffff097          	auipc	ra,0xfffff
    80005d22:	c8a080e7          	jalr	-886(ra) # 800049a8 <dirlink>
    80005d26:	f80557e3          	bgez	a0,80005cb4 <create+0xce>
      panic("create dots");
    80005d2a:	00003517          	auipc	a0,0x3
    80005d2e:	a7e50513          	addi	a0,a0,-1410 # 800087a8 <syscalls+0x2d8>
    80005d32:	ffffb097          	auipc	ra,0xffffb
    80005d36:	80c080e7          	jalr	-2036(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005d3a:	00003517          	auipc	a0,0x3
    80005d3e:	a7e50513          	addi	a0,a0,-1410 # 800087b8 <syscalls+0x2e8>
    80005d42:	ffffa097          	auipc	ra,0xffffa
    80005d46:	7fc080e7          	jalr	2044(ra) # 8000053e <panic>
    return 0;
    80005d4a:	84aa                	mv	s1,a0
    80005d4c:	b731                	j	80005c58 <create+0x72>

0000000080005d4e <sys_dup>:
{
    80005d4e:	7179                	addi	sp,sp,-48
    80005d50:	f406                	sd	ra,40(sp)
    80005d52:	f022                	sd	s0,32(sp)
    80005d54:	ec26                	sd	s1,24(sp)
    80005d56:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005d58:	fd840613          	addi	a2,s0,-40
    80005d5c:	4581                	li	a1,0
    80005d5e:	4501                	li	a0,0
    80005d60:	00000097          	auipc	ra,0x0
    80005d64:	ddc080e7          	jalr	-548(ra) # 80005b3c <argfd>
    return -1;
    80005d68:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005d6a:	02054363          	bltz	a0,80005d90 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005d6e:	fd843503          	ld	a0,-40(s0)
    80005d72:	00000097          	auipc	ra,0x0
    80005d76:	e32080e7          	jalr	-462(ra) # 80005ba4 <fdalloc>
    80005d7a:	84aa                	mv	s1,a0
    return -1;
    80005d7c:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005d7e:	00054963          	bltz	a0,80005d90 <sys_dup+0x42>
  filedup(f);
    80005d82:	fd843503          	ld	a0,-40(s0)
    80005d86:	fffff097          	auipc	ra,0xfffff
    80005d8a:	37a080e7          	jalr	890(ra) # 80005100 <filedup>
  return fd;
    80005d8e:	87a6                	mv	a5,s1
}
    80005d90:	853e                	mv	a0,a5
    80005d92:	70a2                	ld	ra,40(sp)
    80005d94:	7402                	ld	s0,32(sp)
    80005d96:	64e2                	ld	s1,24(sp)
    80005d98:	6145                	addi	sp,sp,48
    80005d9a:	8082                	ret

0000000080005d9c <sys_read>:
{
    80005d9c:	7179                	addi	sp,sp,-48
    80005d9e:	f406                	sd	ra,40(sp)
    80005da0:	f022                	sd	s0,32(sp)
    80005da2:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005da4:	fe840613          	addi	a2,s0,-24
    80005da8:	4581                	li	a1,0
    80005daa:	4501                	li	a0,0
    80005dac:	00000097          	auipc	ra,0x0
    80005db0:	d90080e7          	jalr	-624(ra) # 80005b3c <argfd>
    return -1;
    80005db4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005db6:	04054163          	bltz	a0,80005df8 <sys_read+0x5c>
    80005dba:	fe440593          	addi	a1,s0,-28
    80005dbe:	4509                	li	a0,2
    80005dc0:	ffffe097          	auipc	ra,0xffffe
    80005dc4:	906080e7          	jalr	-1786(ra) # 800036c6 <argint>
    return -1;
    80005dc8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005dca:	02054763          	bltz	a0,80005df8 <sys_read+0x5c>
    80005dce:	fd840593          	addi	a1,s0,-40
    80005dd2:	4505                	li	a0,1
    80005dd4:	ffffe097          	auipc	ra,0xffffe
    80005dd8:	914080e7          	jalr	-1772(ra) # 800036e8 <argaddr>
    return -1;
    80005ddc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005dde:	00054d63          	bltz	a0,80005df8 <sys_read+0x5c>
  return fileread(f, p, n);
    80005de2:	fe442603          	lw	a2,-28(s0)
    80005de6:	fd843583          	ld	a1,-40(s0)
    80005dea:	fe843503          	ld	a0,-24(s0)
    80005dee:	fffff097          	auipc	ra,0xfffff
    80005df2:	49e080e7          	jalr	1182(ra) # 8000528c <fileread>
    80005df6:	87aa                	mv	a5,a0
}
    80005df8:	853e                	mv	a0,a5
    80005dfa:	70a2                	ld	ra,40(sp)
    80005dfc:	7402                	ld	s0,32(sp)
    80005dfe:	6145                	addi	sp,sp,48
    80005e00:	8082                	ret

0000000080005e02 <sys_write>:
{
    80005e02:	7179                	addi	sp,sp,-48
    80005e04:	f406                	sd	ra,40(sp)
    80005e06:	f022                	sd	s0,32(sp)
    80005e08:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005e0a:	fe840613          	addi	a2,s0,-24
    80005e0e:	4581                	li	a1,0
    80005e10:	4501                	li	a0,0
    80005e12:	00000097          	auipc	ra,0x0
    80005e16:	d2a080e7          	jalr	-726(ra) # 80005b3c <argfd>
    return -1;
    80005e1a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005e1c:	04054163          	bltz	a0,80005e5e <sys_write+0x5c>
    80005e20:	fe440593          	addi	a1,s0,-28
    80005e24:	4509                	li	a0,2
    80005e26:	ffffe097          	auipc	ra,0xffffe
    80005e2a:	8a0080e7          	jalr	-1888(ra) # 800036c6 <argint>
    return -1;
    80005e2e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005e30:	02054763          	bltz	a0,80005e5e <sys_write+0x5c>
    80005e34:	fd840593          	addi	a1,s0,-40
    80005e38:	4505                	li	a0,1
    80005e3a:	ffffe097          	auipc	ra,0xffffe
    80005e3e:	8ae080e7          	jalr	-1874(ra) # 800036e8 <argaddr>
    return -1;
    80005e42:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005e44:	00054d63          	bltz	a0,80005e5e <sys_write+0x5c>
  return filewrite(f, p, n);
    80005e48:	fe442603          	lw	a2,-28(s0)
    80005e4c:	fd843583          	ld	a1,-40(s0)
    80005e50:	fe843503          	ld	a0,-24(s0)
    80005e54:	fffff097          	auipc	ra,0xfffff
    80005e58:	4fa080e7          	jalr	1274(ra) # 8000534e <filewrite>
    80005e5c:	87aa                	mv	a5,a0
}
    80005e5e:	853e                	mv	a0,a5
    80005e60:	70a2                	ld	ra,40(sp)
    80005e62:	7402                	ld	s0,32(sp)
    80005e64:	6145                	addi	sp,sp,48
    80005e66:	8082                	ret

0000000080005e68 <sys_close>:
{
    80005e68:	1101                	addi	sp,sp,-32
    80005e6a:	ec06                	sd	ra,24(sp)
    80005e6c:	e822                	sd	s0,16(sp)
    80005e6e:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005e70:	fe040613          	addi	a2,s0,-32
    80005e74:	fec40593          	addi	a1,s0,-20
    80005e78:	4501                	li	a0,0
    80005e7a:	00000097          	auipc	ra,0x0
    80005e7e:	cc2080e7          	jalr	-830(ra) # 80005b3c <argfd>
    return -1;
    80005e82:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005e84:	02054463          	bltz	a0,80005eac <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005e88:	ffffc097          	auipc	ra,0xffffc
    80005e8c:	118080e7          	jalr	280(ra) # 80001fa0 <myproc>
    80005e90:	fec42783          	lw	a5,-20(s0)
    80005e94:	07f1                	addi	a5,a5,28
    80005e96:	078e                	slli	a5,a5,0x3
    80005e98:	97aa                	add	a5,a5,a0
    80005e9a:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    80005e9e:	fe043503          	ld	a0,-32(s0)
    80005ea2:	fffff097          	auipc	ra,0xfffff
    80005ea6:	2b0080e7          	jalr	688(ra) # 80005152 <fileclose>
  return 0;
    80005eaa:	4781                	li	a5,0
}
    80005eac:	853e                	mv	a0,a5
    80005eae:	60e2                	ld	ra,24(sp)
    80005eb0:	6442                	ld	s0,16(sp)
    80005eb2:	6105                	addi	sp,sp,32
    80005eb4:	8082                	ret

0000000080005eb6 <sys_fstat>:
{
    80005eb6:	1101                	addi	sp,sp,-32
    80005eb8:	ec06                	sd	ra,24(sp)
    80005eba:	e822                	sd	s0,16(sp)
    80005ebc:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005ebe:	fe840613          	addi	a2,s0,-24
    80005ec2:	4581                	li	a1,0
    80005ec4:	4501                	li	a0,0
    80005ec6:	00000097          	auipc	ra,0x0
    80005eca:	c76080e7          	jalr	-906(ra) # 80005b3c <argfd>
    return -1;
    80005ece:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005ed0:	02054563          	bltz	a0,80005efa <sys_fstat+0x44>
    80005ed4:	fe040593          	addi	a1,s0,-32
    80005ed8:	4505                	li	a0,1
    80005eda:	ffffe097          	auipc	ra,0xffffe
    80005ede:	80e080e7          	jalr	-2034(ra) # 800036e8 <argaddr>
    return -1;
    80005ee2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005ee4:	00054b63          	bltz	a0,80005efa <sys_fstat+0x44>
  return filestat(f, st);
    80005ee8:	fe043583          	ld	a1,-32(s0)
    80005eec:	fe843503          	ld	a0,-24(s0)
    80005ef0:	fffff097          	auipc	ra,0xfffff
    80005ef4:	32a080e7          	jalr	810(ra) # 8000521a <filestat>
    80005ef8:	87aa                	mv	a5,a0
}
    80005efa:	853e                	mv	a0,a5
    80005efc:	60e2                	ld	ra,24(sp)
    80005efe:	6442                	ld	s0,16(sp)
    80005f00:	6105                	addi	sp,sp,32
    80005f02:	8082                	ret

0000000080005f04 <sys_link>:
{
    80005f04:	7169                	addi	sp,sp,-304
    80005f06:	f606                	sd	ra,296(sp)
    80005f08:	f222                	sd	s0,288(sp)
    80005f0a:	ee26                	sd	s1,280(sp)
    80005f0c:	ea4a                	sd	s2,272(sp)
    80005f0e:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005f10:	08000613          	li	a2,128
    80005f14:	ed040593          	addi	a1,s0,-304
    80005f18:	4501                	li	a0,0
    80005f1a:	ffffd097          	auipc	ra,0xffffd
    80005f1e:	7f0080e7          	jalr	2032(ra) # 8000370a <argstr>
    return -1;
    80005f22:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005f24:	10054e63          	bltz	a0,80006040 <sys_link+0x13c>
    80005f28:	08000613          	li	a2,128
    80005f2c:	f5040593          	addi	a1,s0,-176
    80005f30:	4505                	li	a0,1
    80005f32:	ffffd097          	auipc	ra,0xffffd
    80005f36:	7d8080e7          	jalr	2008(ra) # 8000370a <argstr>
    return -1;
    80005f3a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005f3c:	10054263          	bltz	a0,80006040 <sys_link+0x13c>
  begin_op();
    80005f40:	fffff097          	auipc	ra,0xfffff
    80005f44:	d46080e7          	jalr	-698(ra) # 80004c86 <begin_op>
  if((ip = namei(old)) == 0){
    80005f48:	ed040513          	addi	a0,s0,-304
    80005f4c:	fffff097          	auipc	ra,0xfffff
    80005f50:	b1e080e7          	jalr	-1250(ra) # 80004a6a <namei>
    80005f54:	84aa                	mv	s1,a0
    80005f56:	c551                	beqz	a0,80005fe2 <sys_link+0xde>
  ilock(ip);
    80005f58:	ffffe097          	auipc	ra,0xffffe
    80005f5c:	35c080e7          	jalr	860(ra) # 800042b4 <ilock>
  if(ip->type == T_DIR){
    80005f60:	04449703          	lh	a4,68(s1)
    80005f64:	4785                	li	a5,1
    80005f66:	08f70463          	beq	a4,a5,80005fee <sys_link+0xea>
  ip->nlink++;
    80005f6a:	04a4d783          	lhu	a5,74(s1)
    80005f6e:	2785                	addiw	a5,a5,1
    80005f70:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005f74:	8526                	mv	a0,s1
    80005f76:	ffffe097          	auipc	ra,0xffffe
    80005f7a:	274080e7          	jalr	628(ra) # 800041ea <iupdate>
  iunlock(ip);
    80005f7e:	8526                	mv	a0,s1
    80005f80:	ffffe097          	auipc	ra,0xffffe
    80005f84:	3f6080e7          	jalr	1014(ra) # 80004376 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005f88:	fd040593          	addi	a1,s0,-48
    80005f8c:	f5040513          	addi	a0,s0,-176
    80005f90:	fffff097          	auipc	ra,0xfffff
    80005f94:	af8080e7          	jalr	-1288(ra) # 80004a88 <nameiparent>
    80005f98:	892a                	mv	s2,a0
    80005f9a:	c935                	beqz	a0,8000600e <sys_link+0x10a>
  ilock(dp);
    80005f9c:	ffffe097          	auipc	ra,0xffffe
    80005fa0:	318080e7          	jalr	792(ra) # 800042b4 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005fa4:	00092703          	lw	a4,0(s2)
    80005fa8:	409c                	lw	a5,0(s1)
    80005faa:	04f71d63          	bne	a4,a5,80006004 <sys_link+0x100>
    80005fae:	40d0                	lw	a2,4(s1)
    80005fb0:	fd040593          	addi	a1,s0,-48
    80005fb4:	854a                	mv	a0,s2
    80005fb6:	fffff097          	auipc	ra,0xfffff
    80005fba:	9f2080e7          	jalr	-1550(ra) # 800049a8 <dirlink>
    80005fbe:	04054363          	bltz	a0,80006004 <sys_link+0x100>
  iunlockput(dp);
    80005fc2:	854a                	mv	a0,s2
    80005fc4:	ffffe097          	auipc	ra,0xffffe
    80005fc8:	552080e7          	jalr	1362(ra) # 80004516 <iunlockput>
  iput(ip);
    80005fcc:	8526                	mv	a0,s1
    80005fce:	ffffe097          	auipc	ra,0xffffe
    80005fd2:	4a0080e7          	jalr	1184(ra) # 8000446e <iput>
  end_op();
    80005fd6:	fffff097          	auipc	ra,0xfffff
    80005fda:	d30080e7          	jalr	-720(ra) # 80004d06 <end_op>
  return 0;
    80005fde:	4781                	li	a5,0
    80005fe0:	a085                	j	80006040 <sys_link+0x13c>
    end_op();
    80005fe2:	fffff097          	auipc	ra,0xfffff
    80005fe6:	d24080e7          	jalr	-732(ra) # 80004d06 <end_op>
    return -1;
    80005fea:	57fd                	li	a5,-1
    80005fec:	a891                	j	80006040 <sys_link+0x13c>
    iunlockput(ip);
    80005fee:	8526                	mv	a0,s1
    80005ff0:	ffffe097          	auipc	ra,0xffffe
    80005ff4:	526080e7          	jalr	1318(ra) # 80004516 <iunlockput>
    end_op();
    80005ff8:	fffff097          	auipc	ra,0xfffff
    80005ffc:	d0e080e7          	jalr	-754(ra) # 80004d06 <end_op>
    return -1;
    80006000:	57fd                	li	a5,-1
    80006002:	a83d                	j	80006040 <sys_link+0x13c>
    iunlockput(dp);
    80006004:	854a                	mv	a0,s2
    80006006:	ffffe097          	auipc	ra,0xffffe
    8000600a:	510080e7          	jalr	1296(ra) # 80004516 <iunlockput>
  ilock(ip);
    8000600e:	8526                	mv	a0,s1
    80006010:	ffffe097          	auipc	ra,0xffffe
    80006014:	2a4080e7          	jalr	676(ra) # 800042b4 <ilock>
  ip->nlink--;
    80006018:	04a4d783          	lhu	a5,74(s1)
    8000601c:	37fd                	addiw	a5,a5,-1
    8000601e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80006022:	8526                	mv	a0,s1
    80006024:	ffffe097          	auipc	ra,0xffffe
    80006028:	1c6080e7          	jalr	454(ra) # 800041ea <iupdate>
  iunlockput(ip);
    8000602c:	8526                	mv	a0,s1
    8000602e:	ffffe097          	auipc	ra,0xffffe
    80006032:	4e8080e7          	jalr	1256(ra) # 80004516 <iunlockput>
  end_op();
    80006036:	fffff097          	auipc	ra,0xfffff
    8000603a:	cd0080e7          	jalr	-816(ra) # 80004d06 <end_op>
  return -1;
    8000603e:	57fd                	li	a5,-1
}
    80006040:	853e                	mv	a0,a5
    80006042:	70b2                	ld	ra,296(sp)
    80006044:	7412                	ld	s0,288(sp)
    80006046:	64f2                	ld	s1,280(sp)
    80006048:	6952                	ld	s2,272(sp)
    8000604a:	6155                	addi	sp,sp,304
    8000604c:	8082                	ret

000000008000604e <sys_unlink>:
{
    8000604e:	7151                	addi	sp,sp,-240
    80006050:	f586                	sd	ra,232(sp)
    80006052:	f1a2                	sd	s0,224(sp)
    80006054:	eda6                	sd	s1,216(sp)
    80006056:	e9ca                	sd	s2,208(sp)
    80006058:	e5ce                	sd	s3,200(sp)
    8000605a:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000605c:	08000613          	li	a2,128
    80006060:	f3040593          	addi	a1,s0,-208
    80006064:	4501                	li	a0,0
    80006066:	ffffd097          	auipc	ra,0xffffd
    8000606a:	6a4080e7          	jalr	1700(ra) # 8000370a <argstr>
    8000606e:	18054163          	bltz	a0,800061f0 <sys_unlink+0x1a2>
  begin_op();
    80006072:	fffff097          	auipc	ra,0xfffff
    80006076:	c14080e7          	jalr	-1004(ra) # 80004c86 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000607a:	fb040593          	addi	a1,s0,-80
    8000607e:	f3040513          	addi	a0,s0,-208
    80006082:	fffff097          	auipc	ra,0xfffff
    80006086:	a06080e7          	jalr	-1530(ra) # 80004a88 <nameiparent>
    8000608a:	84aa                	mv	s1,a0
    8000608c:	c979                	beqz	a0,80006162 <sys_unlink+0x114>
  ilock(dp);
    8000608e:	ffffe097          	auipc	ra,0xffffe
    80006092:	226080e7          	jalr	550(ra) # 800042b4 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80006096:	00002597          	auipc	a1,0x2
    8000609a:	70258593          	addi	a1,a1,1794 # 80008798 <syscalls+0x2c8>
    8000609e:	fb040513          	addi	a0,s0,-80
    800060a2:	ffffe097          	auipc	ra,0xffffe
    800060a6:	6dc080e7          	jalr	1756(ra) # 8000477e <namecmp>
    800060aa:	14050a63          	beqz	a0,800061fe <sys_unlink+0x1b0>
    800060ae:	00002597          	auipc	a1,0x2
    800060b2:	6f258593          	addi	a1,a1,1778 # 800087a0 <syscalls+0x2d0>
    800060b6:	fb040513          	addi	a0,s0,-80
    800060ba:	ffffe097          	auipc	ra,0xffffe
    800060be:	6c4080e7          	jalr	1732(ra) # 8000477e <namecmp>
    800060c2:	12050e63          	beqz	a0,800061fe <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800060c6:	f2c40613          	addi	a2,s0,-212
    800060ca:	fb040593          	addi	a1,s0,-80
    800060ce:	8526                	mv	a0,s1
    800060d0:	ffffe097          	auipc	ra,0xffffe
    800060d4:	6c8080e7          	jalr	1736(ra) # 80004798 <dirlookup>
    800060d8:	892a                	mv	s2,a0
    800060da:	12050263          	beqz	a0,800061fe <sys_unlink+0x1b0>
  ilock(ip);
    800060de:	ffffe097          	auipc	ra,0xffffe
    800060e2:	1d6080e7          	jalr	470(ra) # 800042b4 <ilock>
  if(ip->nlink < 1)
    800060e6:	04a91783          	lh	a5,74(s2)
    800060ea:	08f05263          	blez	a5,8000616e <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800060ee:	04491703          	lh	a4,68(s2)
    800060f2:	4785                	li	a5,1
    800060f4:	08f70563          	beq	a4,a5,8000617e <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800060f8:	4641                	li	a2,16
    800060fa:	4581                	li	a1,0
    800060fc:	fc040513          	addi	a0,s0,-64
    80006100:	ffffb097          	auipc	ra,0xffffb
    80006104:	be0080e7          	jalr	-1056(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80006108:	4741                	li	a4,16
    8000610a:	f2c42683          	lw	a3,-212(s0)
    8000610e:	fc040613          	addi	a2,s0,-64
    80006112:	4581                	li	a1,0
    80006114:	8526                	mv	a0,s1
    80006116:	ffffe097          	auipc	ra,0xffffe
    8000611a:	54a080e7          	jalr	1354(ra) # 80004660 <writei>
    8000611e:	47c1                	li	a5,16
    80006120:	0af51563          	bne	a0,a5,800061ca <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80006124:	04491703          	lh	a4,68(s2)
    80006128:	4785                	li	a5,1
    8000612a:	0af70863          	beq	a4,a5,800061da <sys_unlink+0x18c>
  iunlockput(dp);
    8000612e:	8526                	mv	a0,s1
    80006130:	ffffe097          	auipc	ra,0xffffe
    80006134:	3e6080e7          	jalr	998(ra) # 80004516 <iunlockput>
  ip->nlink--;
    80006138:	04a95783          	lhu	a5,74(s2)
    8000613c:	37fd                	addiw	a5,a5,-1
    8000613e:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80006142:	854a                	mv	a0,s2
    80006144:	ffffe097          	auipc	ra,0xffffe
    80006148:	0a6080e7          	jalr	166(ra) # 800041ea <iupdate>
  iunlockput(ip);
    8000614c:	854a                	mv	a0,s2
    8000614e:	ffffe097          	auipc	ra,0xffffe
    80006152:	3c8080e7          	jalr	968(ra) # 80004516 <iunlockput>
  end_op();
    80006156:	fffff097          	auipc	ra,0xfffff
    8000615a:	bb0080e7          	jalr	-1104(ra) # 80004d06 <end_op>
  return 0;
    8000615e:	4501                	li	a0,0
    80006160:	a84d                	j	80006212 <sys_unlink+0x1c4>
    end_op();
    80006162:	fffff097          	auipc	ra,0xfffff
    80006166:	ba4080e7          	jalr	-1116(ra) # 80004d06 <end_op>
    return -1;
    8000616a:	557d                	li	a0,-1
    8000616c:	a05d                	j	80006212 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000616e:	00002517          	auipc	a0,0x2
    80006172:	65a50513          	addi	a0,a0,1626 # 800087c8 <syscalls+0x2f8>
    80006176:	ffffa097          	auipc	ra,0xffffa
    8000617a:	3c8080e7          	jalr	968(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000617e:	04c92703          	lw	a4,76(s2)
    80006182:	02000793          	li	a5,32
    80006186:	f6e7f9e3          	bgeu	a5,a4,800060f8 <sys_unlink+0xaa>
    8000618a:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000618e:	4741                	li	a4,16
    80006190:	86ce                	mv	a3,s3
    80006192:	f1840613          	addi	a2,s0,-232
    80006196:	4581                	li	a1,0
    80006198:	854a                	mv	a0,s2
    8000619a:	ffffe097          	auipc	ra,0xffffe
    8000619e:	3ce080e7          	jalr	974(ra) # 80004568 <readi>
    800061a2:	47c1                	li	a5,16
    800061a4:	00f51b63          	bne	a0,a5,800061ba <sys_unlink+0x16c>
    if(de.inum != 0)
    800061a8:	f1845783          	lhu	a5,-232(s0)
    800061ac:	e7a1                	bnez	a5,800061f4 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800061ae:	29c1                	addiw	s3,s3,16
    800061b0:	04c92783          	lw	a5,76(s2)
    800061b4:	fcf9ede3          	bltu	s3,a5,8000618e <sys_unlink+0x140>
    800061b8:	b781                	j	800060f8 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800061ba:	00002517          	auipc	a0,0x2
    800061be:	62650513          	addi	a0,a0,1574 # 800087e0 <syscalls+0x310>
    800061c2:	ffffa097          	auipc	ra,0xffffa
    800061c6:	37c080e7          	jalr	892(ra) # 8000053e <panic>
    panic("unlink: writei");
    800061ca:	00002517          	auipc	a0,0x2
    800061ce:	62e50513          	addi	a0,a0,1582 # 800087f8 <syscalls+0x328>
    800061d2:	ffffa097          	auipc	ra,0xffffa
    800061d6:	36c080e7          	jalr	876(ra) # 8000053e <panic>
    dp->nlink--;
    800061da:	04a4d783          	lhu	a5,74(s1)
    800061de:	37fd                	addiw	a5,a5,-1
    800061e0:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800061e4:	8526                	mv	a0,s1
    800061e6:	ffffe097          	auipc	ra,0xffffe
    800061ea:	004080e7          	jalr	4(ra) # 800041ea <iupdate>
    800061ee:	b781                	j	8000612e <sys_unlink+0xe0>
    return -1;
    800061f0:	557d                	li	a0,-1
    800061f2:	a005                	j	80006212 <sys_unlink+0x1c4>
    iunlockput(ip);
    800061f4:	854a                	mv	a0,s2
    800061f6:	ffffe097          	auipc	ra,0xffffe
    800061fa:	320080e7          	jalr	800(ra) # 80004516 <iunlockput>
  iunlockput(dp);
    800061fe:	8526                	mv	a0,s1
    80006200:	ffffe097          	auipc	ra,0xffffe
    80006204:	316080e7          	jalr	790(ra) # 80004516 <iunlockput>
  end_op();
    80006208:	fffff097          	auipc	ra,0xfffff
    8000620c:	afe080e7          	jalr	-1282(ra) # 80004d06 <end_op>
  return -1;
    80006210:	557d                	li	a0,-1
}
    80006212:	70ae                	ld	ra,232(sp)
    80006214:	740e                	ld	s0,224(sp)
    80006216:	64ee                	ld	s1,216(sp)
    80006218:	694e                	ld	s2,208(sp)
    8000621a:	69ae                	ld	s3,200(sp)
    8000621c:	616d                	addi	sp,sp,240
    8000621e:	8082                	ret

0000000080006220 <sys_open>:

uint64
sys_open(void)
{
    80006220:	7131                	addi	sp,sp,-192
    80006222:	fd06                	sd	ra,184(sp)
    80006224:	f922                	sd	s0,176(sp)
    80006226:	f526                	sd	s1,168(sp)
    80006228:	f14a                	sd	s2,160(sp)
    8000622a:	ed4e                	sd	s3,152(sp)
    8000622c:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000622e:	08000613          	li	a2,128
    80006232:	f5040593          	addi	a1,s0,-176
    80006236:	4501                	li	a0,0
    80006238:	ffffd097          	auipc	ra,0xffffd
    8000623c:	4d2080e7          	jalr	1234(ra) # 8000370a <argstr>
    return -1;
    80006240:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80006242:	0c054163          	bltz	a0,80006304 <sys_open+0xe4>
    80006246:	f4c40593          	addi	a1,s0,-180
    8000624a:	4505                	li	a0,1
    8000624c:	ffffd097          	auipc	ra,0xffffd
    80006250:	47a080e7          	jalr	1146(ra) # 800036c6 <argint>
    80006254:	0a054863          	bltz	a0,80006304 <sys_open+0xe4>

  begin_op();
    80006258:	fffff097          	auipc	ra,0xfffff
    8000625c:	a2e080e7          	jalr	-1490(ra) # 80004c86 <begin_op>

  if(omode & O_CREATE){
    80006260:	f4c42783          	lw	a5,-180(s0)
    80006264:	2007f793          	andi	a5,a5,512
    80006268:	cbdd                	beqz	a5,8000631e <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000626a:	4681                	li	a3,0
    8000626c:	4601                	li	a2,0
    8000626e:	4589                	li	a1,2
    80006270:	f5040513          	addi	a0,s0,-176
    80006274:	00000097          	auipc	ra,0x0
    80006278:	972080e7          	jalr	-1678(ra) # 80005be6 <create>
    8000627c:	892a                	mv	s2,a0
    if(ip == 0){
    8000627e:	c959                	beqz	a0,80006314 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80006280:	04491703          	lh	a4,68(s2)
    80006284:	478d                	li	a5,3
    80006286:	00f71763          	bne	a4,a5,80006294 <sys_open+0x74>
    8000628a:	04695703          	lhu	a4,70(s2)
    8000628e:	47a5                	li	a5,9
    80006290:	0ce7ec63          	bltu	a5,a4,80006368 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80006294:	fffff097          	auipc	ra,0xfffff
    80006298:	e02080e7          	jalr	-510(ra) # 80005096 <filealloc>
    8000629c:	89aa                	mv	s3,a0
    8000629e:	10050263          	beqz	a0,800063a2 <sys_open+0x182>
    800062a2:	00000097          	auipc	ra,0x0
    800062a6:	902080e7          	jalr	-1790(ra) # 80005ba4 <fdalloc>
    800062aa:	84aa                	mv	s1,a0
    800062ac:	0e054663          	bltz	a0,80006398 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800062b0:	04491703          	lh	a4,68(s2)
    800062b4:	478d                	li	a5,3
    800062b6:	0cf70463          	beq	a4,a5,8000637e <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800062ba:	4789                	li	a5,2
    800062bc:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800062c0:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800062c4:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800062c8:	f4c42783          	lw	a5,-180(s0)
    800062cc:	0017c713          	xori	a4,a5,1
    800062d0:	8b05                	andi	a4,a4,1
    800062d2:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800062d6:	0037f713          	andi	a4,a5,3
    800062da:	00e03733          	snez	a4,a4
    800062de:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800062e2:	4007f793          	andi	a5,a5,1024
    800062e6:	c791                	beqz	a5,800062f2 <sys_open+0xd2>
    800062e8:	04491703          	lh	a4,68(s2)
    800062ec:	4789                	li	a5,2
    800062ee:	08f70f63          	beq	a4,a5,8000638c <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800062f2:	854a                	mv	a0,s2
    800062f4:	ffffe097          	auipc	ra,0xffffe
    800062f8:	082080e7          	jalr	130(ra) # 80004376 <iunlock>
  end_op();
    800062fc:	fffff097          	auipc	ra,0xfffff
    80006300:	a0a080e7          	jalr	-1526(ra) # 80004d06 <end_op>

  return fd;
}
    80006304:	8526                	mv	a0,s1
    80006306:	70ea                	ld	ra,184(sp)
    80006308:	744a                	ld	s0,176(sp)
    8000630a:	74aa                	ld	s1,168(sp)
    8000630c:	790a                	ld	s2,160(sp)
    8000630e:	69ea                	ld	s3,152(sp)
    80006310:	6129                	addi	sp,sp,192
    80006312:	8082                	ret
      end_op();
    80006314:	fffff097          	auipc	ra,0xfffff
    80006318:	9f2080e7          	jalr	-1550(ra) # 80004d06 <end_op>
      return -1;
    8000631c:	b7e5                	j	80006304 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000631e:	f5040513          	addi	a0,s0,-176
    80006322:	ffffe097          	auipc	ra,0xffffe
    80006326:	748080e7          	jalr	1864(ra) # 80004a6a <namei>
    8000632a:	892a                	mv	s2,a0
    8000632c:	c905                	beqz	a0,8000635c <sys_open+0x13c>
    ilock(ip);
    8000632e:	ffffe097          	auipc	ra,0xffffe
    80006332:	f86080e7          	jalr	-122(ra) # 800042b4 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80006336:	04491703          	lh	a4,68(s2)
    8000633a:	4785                	li	a5,1
    8000633c:	f4f712e3          	bne	a4,a5,80006280 <sys_open+0x60>
    80006340:	f4c42783          	lw	a5,-180(s0)
    80006344:	dba1                	beqz	a5,80006294 <sys_open+0x74>
      iunlockput(ip);
    80006346:	854a                	mv	a0,s2
    80006348:	ffffe097          	auipc	ra,0xffffe
    8000634c:	1ce080e7          	jalr	462(ra) # 80004516 <iunlockput>
      end_op();
    80006350:	fffff097          	auipc	ra,0xfffff
    80006354:	9b6080e7          	jalr	-1610(ra) # 80004d06 <end_op>
      return -1;
    80006358:	54fd                	li	s1,-1
    8000635a:	b76d                	j	80006304 <sys_open+0xe4>
      end_op();
    8000635c:	fffff097          	auipc	ra,0xfffff
    80006360:	9aa080e7          	jalr	-1622(ra) # 80004d06 <end_op>
      return -1;
    80006364:	54fd                	li	s1,-1
    80006366:	bf79                	j	80006304 <sys_open+0xe4>
    iunlockput(ip);
    80006368:	854a                	mv	a0,s2
    8000636a:	ffffe097          	auipc	ra,0xffffe
    8000636e:	1ac080e7          	jalr	428(ra) # 80004516 <iunlockput>
    end_op();
    80006372:	fffff097          	auipc	ra,0xfffff
    80006376:	994080e7          	jalr	-1644(ra) # 80004d06 <end_op>
    return -1;
    8000637a:	54fd                	li	s1,-1
    8000637c:	b761                	j	80006304 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000637e:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80006382:	04691783          	lh	a5,70(s2)
    80006386:	02f99223          	sh	a5,36(s3)
    8000638a:	bf2d                	j	800062c4 <sys_open+0xa4>
    itrunc(ip);
    8000638c:	854a                	mv	a0,s2
    8000638e:	ffffe097          	auipc	ra,0xffffe
    80006392:	034080e7          	jalr	52(ra) # 800043c2 <itrunc>
    80006396:	bfb1                	j	800062f2 <sys_open+0xd2>
      fileclose(f);
    80006398:	854e                	mv	a0,s3
    8000639a:	fffff097          	auipc	ra,0xfffff
    8000639e:	db8080e7          	jalr	-584(ra) # 80005152 <fileclose>
    iunlockput(ip);
    800063a2:	854a                	mv	a0,s2
    800063a4:	ffffe097          	auipc	ra,0xffffe
    800063a8:	172080e7          	jalr	370(ra) # 80004516 <iunlockput>
    end_op();
    800063ac:	fffff097          	auipc	ra,0xfffff
    800063b0:	95a080e7          	jalr	-1702(ra) # 80004d06 <end_op>
    return -1;
    800063b4:	54fd                	li	s1,-1
    800063b6:	b7b9                	j	80006304 <sys_open+0xe4>

00000000800063b8 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800063b8:	7175                	addi	sp,sp,-144
    800063ba:	e506                	sd	ra,136(sp)
    800063bc:	e122                	sd	s0,128(sp)
    800063be:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800063c0:	fffff097          	auipc	ra,0xfffff
    800063c4:	8c6080e7          	jalr	-1850(ra) # 80004c86 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800063c8:	08000613          	li	a2,128
    800063cc:	f7040593          	addi	a1,s0,-144
    800063d0:	4501                	li	a0,0
    800063d2:	ffffd097          	auipc	ra,0xffffd
    800063d6:	338080e7          	jalr	824(ra) # 8000370a <argstr>
    800063da:	02054963          	bltz	a0,8000640c <sys_mkdir+0x54>
    800063de:	4681                	li	a3,0
    800063e0:	4601                	li	a2,0
    800063e2:	4585                	li	a1,1
    800063e4:	f7040513          	addi	a0,s0,-144
    800063e8:	fffff097          	auipc	ra,0xfffff
    800063ec:	7fe080e7          	jalr	2046(ra) # 80005be6 <create>
    800063f0:	cd11                	beqz	a0,8000640c <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800063f2:	ffffe097          	auipc	ra,0xffffe
    800063f6:	124080e7          	jalr	292(ra) # 80004516 <iunlockput>
  end_op();
    800063fa:	fffff097          	auipc	ra,0xfffff
    800063fe:	90c080e7          	jalr	-1780(ra) # 80004d06 <end_op>
  return 0;
    80006402:	4501                	li	a0,0
}
    80006404:	60aa                	ld	ra,136(sp)
    80006406:	640a                	ld	s0,128(sp)
    80006408:	6149                	addi	sp,sp,144
    8000640a:	8082                	ret
    end_op();
    8000640c:	fffff097          	auipc	ra,0xfffff
    80006410:	8fa080e7          	jalr	-1798(ra) # 80004d06 <end_op>
    return -1;
    80006414:	557d                	li	a0,-1
    80006416:	b7fd                	j	80006404 <sys_mkdir+0x4c>

0000000080006418 <sys_mknod>:

uint64
sys_mknod(void)
{
    80006418:	7135                	addi	sp,sp,-160
    8000641a:	ed06                	sd	ra,152(sp)
    8000641c:	e922                	sd	s0,144(sp)
    8000641e:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80006420:	fffff097          	auipc	ra,0xfffff
    80006424:	866080e7          	jalr	-1946(ra) # 80004c86 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006428:	08000613          	li	a2,128
    8000642c:	f7040593          	addi	a1,s0,-144
    80006430:	4501                	li	a0,0
    80006432:	ffffd097          	auipc	ra,0xffffd
    80006436:	2d8080e7          	jalr	728(ra) # 8000370a <argstr>
    8000643a:	04054a63          	bltz	a0,8000648e <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    8000643e:	f6c40593          	addi	a1,s0,-148
    80006442:	4505                	li	a0,1
    80006444:	ffffd097          	auipc	ra,0xffffd
    80006448:	282080e7          	jalr	642(ra) # 800036c6 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000644c:	04054163          	bltz	a0,8000648e <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80006450:	f6840593          	addi	a1,s0,-152
    80006454:	4509                	li	a0,2
    80006456:	ffffd097          	auipc	ra,0xffffd
    8000645a:	270080e7          	jalr	624(ra) # 800036c6 <argint>
     argint(1, &major) < 0 ||
    8000645e:	02054863          	bltz	a0,8000648e <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80006462:	f6841683          	lh	a3,-152(s0)
    80006466:	f6c41603          	lh	a2,-148(s0)
    8000646a:	458d                	li	a1,3
    8000646c:	f7040513          	addi	a0,s0,-144
    80006470:	fffff097          	auipc	ra,0xfffff
    80006474:	776080e7          	jalr	1910(ra) # 80005be6 <create>
     argint(2, &minor) < 0 ||
    80006478:	c919                	beqz	a0,8000648e <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000647a:	ffffe097          	auipc	ra,0xffffe
    8000647e:	09c080e7          	jalr	156(ra) # 80004516 <iunlockput>
  end_op();
    80006482:	fffff097          	auipc	ra,0xfffff
    80006486:	884080e7          	jalr	-1916(ra) # 80004d06 <end_op>
  return 0;
    8000648a:	4501                	li	a0,0
    8000648c:	a031                	j	80006498 <sys_mknod+0x80>
    end_op();
    8000648e:	fffff097          	auipc	ra,0xfffff
    80006492:	878080e7          	jalr	-1928(ra) # 80004d06 <end_op>
    return -1;
    80006496:	557d                	li	a0,-1
}
    80006498:	60ea                	ld	ra,152(sp)
    8000649a:	644a                	ld	s0,144(sp)
    8000649c:	610d                	addi	sp,sp,160
    8000649e:	8082                	ret

00000000800064a0 <sys_chdir>:

uint64
sys_chdir(void)
{
    800064a0:	7135                	addi	sp,sp,-160
    800064a2:	ed06                	sd	ra,152(sp)
    800064a4:	e922                	sd	s0,144(sp)
    800064a6:	e526                	sd	s1,136(sp)
    800064a8:	e14a                	sd	s2,128(sp)
    800064aa:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800064ac:	ffffc097          	auipc	ra,0xffffc
    800064b0:	af4080e7          	jalr	-1292(ra) # 80001fa0 <myproc>
    800064b4:	892a                	mv	s2,a0
  
  begin_op();
    800064b6:	ffffe097          	auipc	ra,0xffffe
    800064ba:	7d0080e7          	jalr	2000(ra) # 80004c86 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800064be:	08000613          	li	a2,128
    800064c2:	f6040593          	addi	a1,s0,-160
    800064c6:	4501                	li	a0,0
    800064c8:	ffffd097          	auipc	ra,0xffffd
    800064cc:	242080e7          	jalr	578(ra) # 8000370a <argstr>
    800064d0:	04054b63          	bltz	a0,80006526 <sys_chdir+0x86>
    800064d4:	f6040513          	addi	a0,s0,-160
    800064d8:	ffffe097          	auipc	ra,0xffffe
    800064dc:	592080e7          	jalr	1426(ra) # 80004a6a <namei>
    800064e0:	84aa                	mv	s1,a0
    800064e2:	c131                	beqz	a0,80006526 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800064e4:	ffffe097          	auipc	ra,0xffffe
    800064e8:	dd0080e7          	jalr	-560(ra) # 800042b4 <ilock>
  if(ip->type != T_DIR){
    800064ec:	04449703          	lh	a4,68(s1)
    800064f0:	4785                	li	a5,1
    800064f2:	04f71063          	bne	a4,a5,80006532 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800064f6:	8526                	mv	a0,s1
    800064f8:	ffffe097          	auipc	ra,0xffffe
    800064fc:	e7e080e7          	jalr	-386(ra) # 80004376 <iunlock>
  iput(p->cwd);
    80006500:	16893503          	ld	a0,360(s2)
    80006504:	ffffe097          	auipc	ra,0xffffe
    80006508:	f6a080e7          	jalr	-150(ra) # 8000446e <iput>
  end_op();
    8000650c:	ffffe097          	auipc	ra,0xffffe
    80006510:	7fa080e7          	jalr	2042(ra) # 80004d06 <end_op>
  p->cwd = ip;
    80006514:	16993423          	sd	s1,360(s2)
  return 0;
    80006518:	4501                	li	a0,0
}
    8000651a:	60ea                	ld	ra,152(sp)
    8000651c:	644a                	ld	s0,144(sp)
    8000651e:	64aa                	ld	s1,136(sp)
    80006520:	690a                	ld	s2,128(sp)
    80006522:	610d                	addi	sp,sp,160
    80006524:	8082                	ret
    end_op();
    80006526:	ffffe097          	auipc	ra,0xffffe
    8000652a:	7e0080e7          	jalr	2016(ra) # 80004d06 <end_op>
    return -1;
    8000652e:	557d                	li	a0,-1
    80006530:	b7ed                	j	8000651a <sys_chdir+0x7a>
    iunlockput(ip);
    80006532:	8526                	mv	a0,s1
    80006534:	ffffe097          	auipc	ra,0xffffe
    80006538:	fe2080e7          	jalr	-30(ra) # 80004516 <iunlockput>
    end_op();
    8000653c:	ffffe097          	auipc	ra,0xffffe
    80006540:	7ca080e7          	jalr	1994(ra) # 80004d06 <end_op>
    return -1;
    80006544:	557d                	li	a0,-1
    80006546:	bfd1                	j	8000651a <sys_chdir+0x7a>

0000000080006548 <sys_exec>:

uint64
sys_exec(void)
{
    80006548:	7145                	addi	sp,sp,-464
    8000654a:	e786                	sd	ra,456(sp)
    8000654c:	e3a2                	sd	s0,448(sp)
    8000654e:	ff26                	sd	s1,440(sp)
    80006550:	fb4a                	sd	s2,432(sp)
    80006552:	f74e                	sd	s3,424(sp)
    80006554:	f352                	sd	s4,416(sp)
    80006556:	ef56                	sd	s5,408(sp)
    80006558:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    8000655a:	08000613          	li	a2,128
    8000655e:	f4040593          	addi	a1,s0,-192
    80006562:	4501                	li	a0,0
    80006564:	ffffd097          	auipc	ra,0xffffd
    80006568:	1a6080e7          	jalr	422(ra) # 8000370a <argstr>
    return -1;
    8000656c:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    8000656e:	0c054a63          	bltz	a0,80006642 <sys_exec+0xfa>
    80006572:	e3840593          	addi	a1,s0,-456
    80006576:	4505                	li	a0,1
    80006578:	ffffd097          	auipc	ra,0xffffd
    8000657c:	170080e7          	jalr	368(ra) # 800036e8 <argaddr>
    80006580:	0c054163          	bltz	a0,80006642 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80006584:	10000613          	li	a2,256
    80006588:	4581                	li	a1,0
    8000658a:	e4040513          	addi	a0,s0,-448
    8000658e:	ffffa097          	auipc	ra,0xffffa
    80006592:	752080e7          	jalr	1874(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006596:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    8000659a:	89a6                	mv	s3,s1
    8000659c:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    8000659e:	02000a13          	li	s4,32
    800065a2:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800065a6:	00391513          	slli	a0,s2,0x3
    800065aa:	e3040593          	addi	a1,s0,-464
    800065ae:	e3843783          	ld	a5,-456(s0)
    800065b2:	953e                	add	a0,a0,a5
    800065b4:	ffffd097          	auipc	ra,0xffffd
    800065b8:	078080e7          	jalr	120(ra) # 8000362c <fetchaddr>
    800065bc:	02054a63          	bltz	a0,800065f0 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    800065c0:	e3043783          	ld	a5,-464(s0)
    800065c4:	c3b9                	beqz	a5,8000660a <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800065c6:	ffffa097          	auipc	ra,0xffffa
    800065ca:	52e080e7          	jalr	1326(ra) # 80000af4 <kalloc>
    800065ce:	85aa                	mv	a1,a0
    800065d0:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800065d4:	cd11                	beqz	a0,800065f0 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800065d6:	6605                	lui	a2,0x1
    800065d8:	e3043503          	ld	a0,-464(s0)
    800065dc:	ffffd097          	auipc	ra,0xffffd
    800065e0:	0a2080e7          	jalr	162(ra) # 8000367e <fetchstr>
    800065e4:	00054663          	bltz	a0,800065f0 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    800065e8:	0905                	addi	s2,s2,1
    800065ea:	09a1                	addi	s3,s3,8
    800065ec:	fb491be3          	bne	s2,s4,800065a2 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800065f0:	10048913          	addi	s2,s1,256
    800065f4:	6088                	ld	a0,0(s1)
    800065f6:	c529                	beqz	a0,80006640 <sys_exec+0xf8>
    kfree(argv[i]);
    800065f8:	ffffa097          	auipc	ra,0xffffa
    800065fc:	400080e7          	jalr	1024(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006600:	04a1                	addi	s1,s1,8
    80006602:	ff2499e3          	bne	s1,s2,800065f4 <sys_exec+0xac>
  return -1;
    80006606:	597d                	li	s2,-1
    80006608:	a82d                	j	80006642 <sys_exec+0xfa>
      argv[i] = 0;
    8000660a:	0a8e                	slli	s5,s5,0x3
    8000660c:	fc040793          	addi	a5,s0,-64
    80006610:	9abe                	add	s5,s5,a5
    80006612:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80006616:	e4040593          	addi	a1,s0,-448
    8000661a:	f4040513          	addi	a0,s0,-192
    8000661e:	fffff097          	auipc	ra,0xfffff
    80006622:	194080e7          	jalr	404(ra) # 800057b2 <exec>
    80006626:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006628:	10048993          	addi	s3,s1,256
    8000662c:	6088                	ld	a0,0(s1)
    8000662e:	c911                	beqz	a0,80006642 <sys_exec+0xfa>
    kfree(argv[i]);
    80006630:	ffffa097          	auipc	ra,0xffffa
    80006634:	3c8080e7          	jalr	968(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006638:	04a1                	addi	s1,s1,8
    8000663a:	ff3499e3          	bne	s1,s3,8000662c <sys_exec+0xe4>
    8000663e:	a011                	j	80006642 <sys_exec+0xfa>
  return -1;
    80006640:	597d                	li	s2,-1
}
    80006642:	854a                	mv	a0,s2
    80006644:	60be                	ld	ra,456(sp)
    80006646:	641e                	ld	s0,448(sp)
    80006648:	74fa                	ld	s1,440(sp)
    8000664a:	795a                	ld	s2,432(sp)
    8000664c:	79ba                	ld	s3,424(sp)
    8000664e:	7a1a                	ld	s4,416(sp)
    80006650:	6afa                	ld	s5,408(sp)
    80006652:	6179                	addi	sp,sp,464
    80006654:	8082                	ret

0000000080006656 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006656:	7139                	addi	sp,sp,-64
    80006658:	fc06                	sd	ra,56(sp)
    8000665a:	f822                	sd	s0,48(sp)
    8000665c:	f426                	sd	s1,40(sp)
    8000665e:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006660:	ffffc097          	auipc	ra,0xffffc
    80006664:	940080e7          	jalr	-1728(ra) # 80001fa0 <myproc>
    80006668:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    8000666a:	fd840593          	addi	a1,s0,-40
    8000666e:	4501                	li	a0,0
    80006670:	ffffd097          	auipc	ra,0xffffd
    80006674:	078080e7          	jalr	120(ra) # 800036e8 <argaddr>
    return -1;
    80006678:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    8000667a:	0e054063          	bltz	a0,8000675a <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    8000667e:	fc840593          	addi	a1,s0,-56
    80006682:	fd040513          	addi	a0,s0,-48
    80006686:	fffff097          	auipc	ra,0xfffff
    8000668a:	dfc080e7          	jalr	-516(ra) # 80005482 <pipealloc>
    return -1;
    8000668e:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006690:	0c054563          	bltz	a0,8000675a <sys_pipe+0x104>
  fd0 = -1;
    80006694:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006698:	fd043503          	ld	a0,-48(s0)
    8000669c:	fffff097          	auipc	ra,0xfffff
    800066a0:	508080e7          	jalr	1288(ra) # 80005ba4 <fdalloc>
    800066a4:	fca42223          	sw	a0,-60(s0)
    800066a8:	08054c63          	bltz	a0,80006740 <sys_pipe+0xea>
    800066ac:	fc843503          	ld	a0,-56(s0)
    800066b0:	fffff097          	auipc	ra,0xfffff
    800066b4:	4f4080e7          	jalr	1268(ra) # 80005ba4 <fdalloc>
    800066b8:	fca42023          	sw	a0,-64(s0)
    800066bc:	06054863          	bltz	a0,8000672c <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800066c0:	4691                	li	a3,4
    800066c2:	fc440613          	addi	a2,s0,-60
    800066c6:	fd843583          	ld	a1,-40(s0)
    800066ca:	74a8                	ld	a0,104(s1)
    800066cc:	ffffb097          	auipc	ra,0xffffb
    800066d0:	fa6080e7          	jalr	-90(ra) # 80001672 <copyout>
    800066d4:	02054063          	bltz	a0,800066f4 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800066d8:	4691                	li	a3,4
    800066da:	fc040613          	addi	a2,s0,-64
    800066de:	fd843583          	ld	a1,-40(s0)
    800066e2:	0591                	addi	a1,a1,4
    800066e4:	74a8                	ld	a0,104(s1)
    800066e6:	ffffb097          	auipc	ra,0xffffb
    800066ea:	f8c080e7          	jalr	-116(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800066ee:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800066f0:	06055563          	bgez	a0,8000675a <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    800066f4:	fc442783          	lw	a5,-60(s0)
    800066f8:	07f1                	addi	a5,a5,28
    800066fa:	078e                	slli	a5,a5,0x3
    800066fc:	97a6                	add	a5,a5,s1
    800066fe:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80006702:	fc042503          	lw	a0,-64(s0)
    80006706:	0571                	addi	a0,a0,28
    80006708:	050e                	slli	a0,a0,0x3
    8000670a:	9526                	add	a0,a0,s1
    8000670c:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80006710:	fd043503          	ld	a0,-48(s0)
    80006714:	fffff097          	auipc	ra,0xfffff
    80006718:	a3e080e7          	jalr	-1474(ra) # 80005152 <fileclose>
    fileclose(wf);
    8000671c:	fc843503          	ld	a0,-56(s0)
    80006720:	fffff097          	auipc	ra,0xfffff
    80006724:	a32080e7          	jalr	-1486(ra) # 80005152 <fileclose>
    return -1;
    80006728:	57fd                	li	a5,-1
    8000672a:	a805                	j	8000675a <sys_pipe+0x104>
    if(fd0 >= 0)
    8000672c:	fc442783          	lw	a5,-60(s0)
    80006730:	0007c863          	bltz	a5,80006740 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80006734:	01c78513          	addi	a0,a5,28
    80006738:	050e                	slli	a0,a0,0x3
    8000673a:	9526                	add	a0,a0,s1
    8000673c:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80006740:	fd043503          	ld	a0,-48(s0)
    80006744:	fffff097          	auipc	ra,0xfffff
    80006748:	a0e080e7          	jalr	-1522(ra) # 80005152 <fileclose>
    fileclose(wf);
    8000674c:	fc843503          	ld	a0,-56(s0)
    80006750:	fffff097          	auipc	ra,0xfffff
    80006754:	a02080e7          	jalr	-1534(ra) # 80005152 <fileclose>
    return -1;
    80006758:	57fd                	li	a5,-1
}
    8000675a:	853e                	mv	a0,a5
    8000675c:	70e2                	ld	ra,56(sp)
    8000675e:	7442                	ld	s0,48(sp)
    80006760:	74a2                	ld	s1,40(sp)
    80006762:	6121                	addi	sp,sp,64
    80006764:	8082                	ret
	...

0000000080006770 <kernelvec>:
    80006770:	7111                	addi	sp,sp,-256
    80006772:	e006                	sd	ra,0(sp)
    80006774:	e40a                	sd	sp,8(sp)
    80006776:	e80e                	sd	gp,16(sp)
    80006778:	ec12                	sd	tp,24(sp)
    8000677a:	f016                	sd	t0,32(sp)
    8000677c:	f41a                	sd	t1,40(sp)
    8000677e:	f81e                	sd	t2,48(sp)
    80006780:	fc22                	sd	s0,56(sp)
    80006782:	e0a6                	sd	s1,64(sp)
    80006784:	e4aa                	sd	a0,72(sp)
    80006786:	e8ae                	sd	a1,80(sp)
    80006788:	ecb2                	sd	a2,88(sp)
    8000678a:	f0b6                	sd	a3,96(sp)
    8000678c:	f4ba                	sd	a4,104(sp)
    8000678e:	f8be                	sd	a5,112(sp)
    80006790:	fcc2                	sd	a6,120(sp)
    80006792:	e146                	sd	a7,128(sp)
    80006794:	e54a                	sd	s2,136(sp)
    80006796:	e94e                	sd	s3,144(sp)
    80006798:	ed52                	sd	s4,152(sp)
    8000679a:	f156                	sd	s5,160(sp)
    8000679c:	f55a                	sd	s6,168(sp)
    8000679e:	f95e                	sd	s7,176(sp)
    800067a0:	fd62                	sd	s8,184(sp)
    800067a2:	e1e6                	sd	s9,192(sp)
    800067a4:	e5ea                	sd	s10,200(sp)
    800067a6:	e9ee                	sd	s11,208(sp)
    800067a8:	edf2                	sd	t3,216(sp)
    800067aa:	f1f6                	sd	t4,224(sp)
    800067ac:	f5fa                	sd	t5,232(sp)
    800067ae:	f9fe                	sd	t6,240(sp)
    800067b0:	d49fc0ef          	jal	ra,800034f8 <kerneltrap>
    800067b4:	6082                	ld	ra,0(sp)
    800067b6:	6122                	ld	sp,8(sp)
    800067b8:	61c2                	ld	gp,16(sp)
    800067ba:	7282                	ld	t0,32(sp)
    800067bc:	7322                	ld	t1,40(sp)
    800067be:	73c2                	ld	t2,48(sp)
    800067c0:	7462                	ld	s0,56(sp)
    800067c2:	6486                	ld	s1,64(sp)
    800067c4:	6526                	ld	a0,72(sp)
    800067c6:	65c6                	ld	a1,80(sp)
    800067c8:	6666                	ld	a2,88(sp)
    800067ca:	7686                	ld	a3,96(sp)
    800067cc:	7726                	ld	a4,104(sp)
    800067ce:	77c6                	ld	a5,112(sp)
    800067d0:	7866                	ld	a6,120(sp)
    800067d2:	688a                	ld	a7,128(sp)
    800067d4:	692a                	ld	s2,136(sp)
    800067d6:	69ca                	ld	s3,144(sp)
    800067d8:	6a6a                	ld	s4,152(sp)
    800067da:	7a8a                	ld	s5,160(sp)
    800067dc:	7b2a                	ld	s6,168(sp)
    800067de:	7bca                	ld	s7,176(sp)
    800067e0:	7c6a                	ld	s8,184(sp)
    800067e2:	6c8e                	ld	s9,192(sp)
    800067e4:	6d2e                	ld	s10,200(sp)
    800067e6:	6dce                	ld	s11,208(sp)
    800067e8:	6e6e                	ld	t3,216(sp)
    800067ea:	7e8e                	ld	t4,224(sp)
    800067ec:	7f2e                	ld	t5,232(sp)
    800067ee:	7fce                	ld	t6,240(sp)
    800067f0:	6111                	addi	sp,sp,256
    800067f2:	10200073          	sret
    800067f6:	00000013          	nop
    800067fa:	00000013          	nop
    800067fe:	0001                	nop

0000000080006800 <timervec>:
    80006800:	34051573          	csrrw	a0,mscratch,a0
    80006804:	e10c                	sd	a1,0(a0)
    80006806:	e510                	sd	a2,8(a0)
    80006808:	e914                	sd	a3,16(a0)
    8000680a:	6d0c                	ld	a1,24(a0)
    8000680c:	7110                	ld	a2,32(a0)
    8000680e:	6194                	ld	a3,0(a1)
    80006810:	96b2                	add	a3,a3,a2
    80006812:	e194                	sd	a3,0(a1)
    80006814:	4589                	li	a1,2
    80006816:	14459073          	csrw	sip,a1
    8000681a:	6914                	ld	a3,16(a0)
    8000681c:	6510                	ld	a2,8(a0)
    8000681e:	610c                	ld	a1,0(a0)
    80006820:	34051573          	csrrw	a0,mscratch,a0
    80006824:	30200073          	mret
	...

000000008000682a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000682a:	1141                	addi	sp,sp,-16
    8000682c:	e422                	sd	s0,8(sp)
    8000682e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006830:	0c0007b7          	lui	a5,0xc000
    80006834:	4705                	li	a4,1
    80006836:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006838:	c3d8                	sw	a4,4(a5)
}
    8000683a:	6422                	ld	s0,8(sp)
    8000683c:	0141                	addi	sp,sp,16
    8000683e:	8082                	ret

0000000080006840 <plicinithart>:

void
plicinithart(void)
{
    80006840:	1141                	addi	sp,sp,-16
    80006842:	e406                	sd	ra,8(sp)
    80006844:	e022                	sd	s0,0(sp)
    80006846:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006848:	ffffb097          	auipc	ra,0xffffb
    8000684c:	72c080e7          	jalr	1836(ra) # 80001f74 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006850:	0085171b          	slliw	a4,a0,0x8
    80006854:	0c0027b7          	lui	a5,0xc002
    80006858:	97ba                	add	a5,a5,a4
    8000685a:	40200713          	li	a4,1026
    8000685e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006862:	00d5151b          	slliw	a0,a0,0xd
    80006866:	0c2017b7          	lui	a5,0xc201
    8000686a:	953e                	add	a0,a0,a5
    8000686c:	00052023          	sw	zero,0(a0)
}
    80006870:	60a2                	ld	ra,8(sp)
    80006872:	6402                	ld	s0,0(sp)
    80006874:	0141                	addi	sp,sp,16
    80006876:	8082                	ret

0000000080006878 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006878:	1141                	addi	sp,sp,-16
    8000687a:	e406                	sd	ra,8(sp)
    8000687c:	e022                	sd	s0,0(sp)
    8000687e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006880:	ffffb097          	auipc	ra,0xffffb
    80006884:	6f4080e7          	jalr	1780(ra) # 80001f74 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006888:	00d5179b          	slliw	a5,a0,0xd
    8000688c:	0c201537          	lui	a0,0xc201
    80006890:	953e                	add	a0,a0,a5
  return irq;
}
    80006892:	4148                	lw	a0,4(a0)
    80006894:	60a2                	ld	ra,8(sp)
    80006896:	6402                	ld	s0,0(sp)
    80006898:	0141                	addi	sp,sp,16
    8000689a:	8082                	ret

000000008000689c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000689c:	1101                	addi	sp,sp,-32
    8000689e:	ec06                	sd	ra,24(sp)
    800068a0:	e822                	sd	s0,16(sp)
    800068a2:	e426                	sd	s1,8(sp)
    800068a4:	1000                	addi	s0,sp,32
    800068a6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800068a8:	ffffb097          	auipc	ra,0xffffb
    800068ac:	6cc080e7          	jalr	1740(ra) # 80001f74 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800068b0:	00d5151b          	slliw	a0,a0,0xd
    800068b4:	0c2017b7          	lui	a5,0xc201
    800068b8:	97aa                	add	a5,a5,a0
    800068ba:	c3c4                	sw	s1,4(a5)
}
    800068bc:	60e2                	ld	ra,24(sp)
    800068be:	6442                	ld	s0,16(sp)
    800068c0:	64a2                	ld	s1,8(sp)
    800068c2:	6105                	addi	sp,sp,32
    800068c4:	8082                	ret

00000000800068c6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800068c6:	1141                	addi	sp,sp,-16
    800068c8:	e406                	sd	ra,8(sp)
    800068ca:	e022                	sd	s0,0(sp)
    800068cc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800068ce:	479d                	li	a5,7
    800068d0:	06a7c963          	blt	a5,a0,80006942 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    800068d4:	0001c797          	auipc	a5,0x1c
    800068d8:	72c78793          	addi	a5,a5,1836 # 80023000 <disk>
    800068dc:	00a78733          	add	a4,a5,a0
    800068e0:	6789                	lui	a5,0x2
    800068e2:	97ba                	add	a5,a5,a4
    800068e4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    800068e8:	e7ad                	bnez	a5,80006952 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800068ea:	00451793          	slli	a5,a0,0x4
    800068ee:	0001e717          	auipc	a4,0x1e
    800068f2:	71270713          	addi	a4,a4,1810 # 80025000 <disk+0x2000>
    800068f6:	6314                	ld	a3,0(a4)
    800068f8:	96be                	add	a3,a3,a5
    800068fa:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    800068fe:	6314                	ld	a3,0(a4)
    80006900:	96be                	add	a3,a3,a5
    80006902:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006906:	6314                	ld	a3,0(a4)
    80006908:	96be                	add	a3,a3,a5
    8000690a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000690e:	6318                	ld	a4,0(a4)
    80006910:	97ba                	add	a5,a5,a4
    80006912:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006916:	0001c797          	auipc	a5,0x1c
    8000691a:	6ea78793          	addi	a5,a5,1770 # 80023000 <disk>
    8000691e:	97aa                	add	a5,a5,a0
    80006920:	6509                	lui	a0,0x2
    80006922:	953e                	add	a0,a0,a5
    80006924:	4785                	li	a5,1
    80006926:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000692a:	0001e517          	auipc	a0,0x1e
    8000692e:	6ee50513          	addi	a0,a0,1774 # 80025018 <disk+0x2018>
    80006932:	ffffc097          	auipc	ra,0xffffc
    80006936:	090080e7          	jalr	144(ra) # 800029c2 <wakeup>
}
    8000693a:	60a2                	ld	ra,8(sp)
    8000693c:	6402                	ld	s0,0(sp)
    8000693e:	0141                	addi	sp,sp,16
    80006940:	8082                	ret
    panic("free_desc 1");
    80006942:	00002517          	auipc	a0,0x2
    80006946:	ec650513          	addi	a0,a0,-314 # 80008808 <syscalls+0x338>
    8000694a:	ffffa097          	auipc	ra,0xffffa
    8000694e:	bf4080e7          	jalr	-1036(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006952:	00002517          	auipc	a0,0x2
    80006956:	ec650513          	addi	a0,a0,-314 # 80008818 <syscalls+0x348>
    8000695a:	ffffa097          	auipc	ra,0xffffa
    8000695e:	be4080e7          	jalr	-1052(ra) # 8000053e <panic>

0000000080006962 <virtio_disk_init>:
{
    80006962:	1101                	addi	sp,sp,-32
    80006964:	ec06                	sd	ra,24(sp)
    80006966:	e822                	sd	s0,16(sp)
    80006968:	e426                	sd	s1,8(sp)
    8000696a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000696c:	00002597          	auipc	a1,0x2
    80006970:	ebc58593          	addi	a1,a1,-324 # 80008828 <syscalls+0x358>
    80006974:	0001e517          	auipc	a0,0x1e
    80006978:	7b450513          	addi	a0,a0,1972 # 80025128 <disk+0x2128>
    8000697c:	ffffa097          	auipc	ra,0xffffa
    80006980:	1d8080e7          	jalr	472(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006984:	100017b7          	lui	a5,0x10001
    80006988:	4398                	lw	a4,0(a5)
    8000698a:	2701                	sext.w	a4,a4
    8000698c:	747277b7          	lui	a5,0x74727
    80006990:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006994:	0ef71163          	bne	a4,a5,80006a76 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006998:	100017b7          	lui	a5,0x10001
    8000699c:	43dc                	lw	a5,4(a5)
    8000699e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800069a0:	4705                	li	a4,1
    800069a2:	0ce79a63          	bne	a5,a4,80006a76 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800069a6:	100017b7          	lui	a5,0x10001
    800069aa:	479c                	lw	a5,8(a5)
    800069ac:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800069ae:	4709                	li	a4,2
    800069b0:	0ce79363          	bne	a5,a4,80006a76 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800069b4:	100017b7          	lui	a5,0x10001
    800069b8:	47d8                	lw	a4,12(a5)
    800069ba:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800069bc:	554d47b7          	lui	a5,0x554d4
    800069c0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800069c4:	0af71963          	bne	a4,a5,80006a76 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800069c8:	100017b7          	lui	a5,0x10001
    800069cc:	4705                	li	a4,1
    800069ce:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800069d0:	470d                	li	a4,3
    800069d2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800069d4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800069d6:	c7ffe737          	lui	a4,0xc7ffe
    800069da:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    800069de:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800069e0:	2701                	sext.w	a4,a4
    800069e2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800069e4:	472d                	li	a4,11
    800069e6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800069e8:	473d                	li	a4,15
    800069ea:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    800069ec:	6705                	lui	a4,0x1
    800069ee:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800069f0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800069f4:	5bdc                	lw	a5,52(a5)
    800069f6:	2781                	sext.w	a5,a5
  if(max == 0)
    800069f8:	c7d9                	beqz	a5,80006a86 <virtio_disk_init+0x124>
  if(max < NUM)
    800069fa:	471d                	li	a4,7
    800069fc:	08f77d63          	bgeu	a4,a5,80006a96 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006a00:	100014b7          	lui	s1,0x10001
    80006a04:	47a1                	li	a5,8
    80006a06:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006a08:	6609                	lui	a2,0x2
    80006a0a:	4581                	li	a1,0
    80006a0c:	0001c517          	auipc	a0,0x1c
    80006a10:	5f450513          	addi	a0,a0,1524 # 80023000 <disk>
    80006a14:	ffffa097          	auipc	ra,0xffffa
    80006a18:	2cc080e7          	jalr	716(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80006a1c:	0001c717          	auipc	a4,0x1c
    80006a20:	5e470713          	addi	a4,a4,1508 # 80023000 <disk>
    80006a24:	00c75793          	srli	a5,a4,0xc
    80006a28:	2781                	sext.w	a5,a5
    80006a2a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80006a2c:	0001e797          	auipc	a5,0x1e
    80006a30:	5d478793          	addi	a5,a5,1492 # 80025000 <disk+0x2000>
    80006a34:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006a36:	0001c717          	auipc	a4,0x1c
    80006a3a:	64a70713          	addi	a4,a4,1610 # 80023080 <disk+0x80>
    80006a3e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006a40:	0001d717          	auipc	a4,0x1d
    80006a44:	5c070713          	addi	a4,a4,1472 # 80024000 <disk+0x1000>
    80006a48:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80006a4a:	4705                	li	a4,1
    80006a4c:	00e78c23          	sb	a4,24(a5)
    80006a50:	00e78ca3          	sb	a4,25(a5)
    80006a54:	00e78d23          	sb	a4,26(a5)
    80006a58:	00e78da3          	sb	a4,27(a5)
    80006a5c:	00e78e23          	sb	a4,28(a5)
    80006a60:	00e78ea3          	sb	a4,29(a5)
    80006a64:	00e78f23          	sb	a4,30(a5)
    80006a68:	00e78fa3          	sb	a4,31(a5)
}
    80006a6c:	60e2                	ld	ra,24(sp)
    80006a6e:	6442                	ld	s0,16(sp)
    80006a70:	64a2                	ld	s1,8(sp)
    80006a72:	6105                	addi	sp,sp,32
    80006a74:	8082                	ret
    panic("could not find virtio disk");
    80006a76:	00002517          	auipc	a0,0x2
    80006a7a:	dc250513          	addi	a0,a0,-574 # 80008838 <syscalls+0x368>
    80006a7e:	ffffa097          	auipc	ra,0xffffa
    80006a82:	ac0080e7          	jalr	-1344(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006a86:	00002517          	auipc	a0,0x2
    80006a8a:	dd250513          	addi	a0,a0,-558 # 80008858 <syscalls+0x388>
    80006a8e:	ffffa097          	auipc	ra,0xffffa
    80006a92:	ab0080e7          	jalr	-1360(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006a96:	00002517          	auipc	a0,0x2
    80006a9a:	de250513          	addi	a0,a0,-542 # 80008878 <syscalls+0x3a8>
    80006a9e:	ffffa097          	auipc	ra,0xffffa
    80006aa2:	aa0080e7          	jalr	-1376(ra) # 8000053e <panic>

0000000080006aa6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006aa6:	7159                	addi	sp,sp,-112
    80006aa8:	f486                	sd	ra,104(sp)
    80006aaa:	f0a2                	sd	s0,96(sp)
    80006aac:	eca6                	sd	s1,88(sp)
    80006aae:	e8ca                	sd	s2,80(sp)
    80006ab0:	e4ce                	sd	s3,72(sp)
    80006ab2:	e0d2                	sd	s4,64(sp)
    80006ab4:	fc56                	sd	s5,56(sp)
    80006ab6:	f85a                	sd	s6,48(sp)
    80006ab8:	f45e                	sd	s7,40(sp)
    80006aba:	f062                	sd	s8,32(sp)
    80006abc:	ec66                	sd	s9,24(sp)
    80006abe:	e86a                	sd	s10,16(sp)
    80006ac0:	1880                	addi	s0,sp,112
    80006ac2:	892a                	mv	s2,a0
    80006ac4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006ac6:	00c52c83          	lw	s9,12(a0)
    80006aca:	001c9c9b          	slliw	s9,s9,0x1
    80006ace:	1c82                	slli	s9,s9,0x20
    80006ad0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006ad4:	0001e517          	auipc	a0,0x1e
    80006ad8:	65450513          	addi	a0,a0,1620 # 80025128 <disk+0x2128>
    80006adc:	ffffa097          	auipc	ra,0xffffa
    80006ae0:	108080e7          	jalr	264(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006ae4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006ae6:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006ae8:	0001cb97          	auipc	s7,0x1c
    80006aec:	518b8b93          	addi	s7,s7,1304 # 80023000 <disk>
    80006af0:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006af2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006af4:	8a4e                	mv	s4,s3
    80006af6:	a051                	j	80006b7a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006af8:	00fb86b3          	add	a3,s7,a5
    80006afc:	96da                	add	a3,a3,s6
    80006afe:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006b02:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006b04:	0207c563          	bltz	a5,80006b2e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006b08:	2485                	addiw	s1,s1,1
    80006b0a:	0711                	addi	a4,a4,4
    80006b0c:	25548063          	beq	s1,s5,80006d4c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006b10:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006b12:	0001e697          	auipc	a3,0x1e
    80006b16:	50668693          	addi	a3,a3,1286 # 80025018 <disk+0x2018>
    80006b1a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80006b1c:	0006c583          	lbu	a1,0(a3)
    80006b20:	fde1                	bnez	a1,80006af8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006b22:	2785                	addiw	a5,a5,1
    80006b24:	0685                	addi	a3,a3,1
    80006b26:	ff879be3          	bne	a5,s8,80006b1c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006b2a:	57fd                	li	a5,-1
    80006b2c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80006b2e:	02905a63          	blez	s1,80006b62 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006b32:	f9042503          	lw	a0,-112(s0)
    80006b36:	00000097          	auipc	ra,0x0
    80006b3a:	d90080e7          	jalr	-624(ra) # 800068c6 <free_desc>
      for(int j = 0; j < i; j++)
    80006b3e:	4785                	li	a5,1
    80006b40:	0297d163          	bge	a5,s1,80006b62 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006b44:	f9442503          	lw	a0,-108(s0)
    80006b48:	00000097          	auipc	ra,0x0
    80006b4c:	d7e080e7          	jalr	-642(ra) # 800068c6 <free_desc>
      for(int j = 0; j < i; j++)
    80006b50:	4789                	li	a5,2
    80006b52:	0097d863          	bge	a5,s1,80006b62 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006b56:	f9842503          	lw	a0,-104(s0)
    80006b5a:	00000097          	auipc	ra,0x0
    80006b5e:	d6c080e7          	jalr	-660(ra) # 800068c6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006b62:	0001e597          	auipc	a1,0x1e
    80006b66:	5c658593          	addi	a1,a1,1478 # 80025128 <disk+0x2128>
    80006b6a:	0001e517          	auipc	a0,0x1e
    80006b6e:	4ae50513          	addi	a0,a0,1198 # 80025018 <disk+0x2018>
    80006b72:	ffffc097          	auipc	ra,0xffffc
    80006b76:	cae080e7          	jalr	-850(ra) # 80002820 <sleep>
  for(int i = 0; i < 3; i++){
    80006b7a:	f9040713          	addi	a4,s0,-112
    80006b7e:	84ce                	mv	s1,s3
    80006b80:	bf41                	j	80006b10 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006b82:	20058713          	addi	a4,a1,512
    80006b86:	00471693          	slli	a3,a4,0x4
    80006b8a:	0001c717          	auipc	a4,0x1c
    80006b8e:	47670713          	addi	a4,a4,1142 # 80023000 <disk>
    80006b92:	9736                	add	a4,a4,a3
    80006b94:	4685                	li	a3,1
    80006b96:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006b9a:	20058713          	addi	a4,a1,512
    80006b9e:	00471693          	slli	a3,a4,0x4
    80006ba2:	0001c717          	auipc	a4,0x1c
    80006ba6:	45e70713          	addi	a4,a4,1118 # 80023000 <disk>
    80006baa:	9736                	add	a4,a4,a3
    80006bac:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006bb0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006bb4:	7679                	lui	a2,0xffffe
    80006bb6:	963e                	add	a2,a2,a5
    80006bb8:	0001e697          	auipc	a3,0x1e
    80006bbc:	44868693          	addi	a3,a3,1096 # 80025000 <disk+0x2000>
    80006bc0:	6298                	ld	a4,0(a3)
    80006bc2:	9732                	add	a4,a4,a2
    80006bc4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006bc6:	6298                	ld	a4,0(a3)
    80006bc8:	9732                	add	a4,a4,a2
    80006bca:	4541                	li	a0,16
    80006bcc:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006bce:	6298                	ld	a4,0(a3)
    80006bd0:	9732                	add	a4,a4,a2
    80006bd2:	4505                	li	a0,1
    80006bd4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006bd8:	f9442703          	lw	a4,-108(s0)
    80006bdc:	6288                	ld	a0,0(a3)
    80006bde:	962a                	add	a2,a2,a0
    80006be0:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006be4:	0712                	slli	a4,a4,0x4
    80006be6:	6290                	ld	a2,0(a3)
    80006be8:	963a                	add	a2,a2,a4
    80006bea:	05890513          	addi	a0,s2,88
    80006bee:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006bf0:	6294                	ld	a3,0(a3)
    80006bf2:	96ba                	add	a3,a3,a4
    80006bf4:	40000613          	li	a2,1024
    80006bf8:	c690                	sw	a2,8(a3)
  if(write)
    80006bfa:	140d0063          	beqz	s10,80006d3a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006bfe:	0001e697          	auipc	a3,0x1e
    80006c02:	4026b683          	ld	a3,1026(a3) # 80025000 <disk+0x2000>
    80006c06:	96ba                	add	a3,a3,a4
    80006c08:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006c0c:	0001c817          	auipc	a6,0x1c
    80006c10:	3f480813          	addi	a6,a6,1012 # 80023000 <disk>
    80006c14:	0001e517          	auipc	a0,0x1e
    80006c18:	3ec50513          	addi	a0,a0,1004 # 80025000 <disk+0x2000>
    80006c1c:	6114                	ld	a3,0(a0)
    80006c1e:	96ba                	add	a3,a3,a4
    80006c20:	00c6d603          	lhu	a2,12(a3)
    80006c24:	00166613          	ori	a2,a2,1
    80006c28:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006c2c:	f9842683          	lw	a3,-104(s0)
    80006c30:	6110                	ld	a2,0(a0)
    80006c32:	9732                	add	a4,a4,a2
    80006c34:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006c38:	20058613          	addi	a2,a1,512
    80006c3c:	0612                	slli	a2,a2,0x4
    80006c3e:	9642                	add	a2,a2,a6
    80006c40:	577d                	li	a4,-1
    80006c42:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006c46:	00469713          	slli	a4,a3,0x4
    80006c4a:	6114                	ld	a3,0(a0)
    80006c4c:	96ba                	add	a3,a3,a4
    80006c4e:	03078793          	addi	a5,a5,48
    80006c52:	97c2                	add	a5,a5,a6
    80006c54:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006c56:	611c                	ld	a5,0(a0)
    80006c58:	97ba                	add	a5,a5,a4
    80006c5a:	4685                	li	a3,1
    80006c5c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006c5e:	611c                	ld	a5,0(a0)
    80006c60:	97ba                	add	a5,a5,a4
    80006c62:	4809                	li	a6,2
    80006c64:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006c68:	611c                	ld	a5,0(a0)
    80006c6a:	973e                	add	a4,a4,a5
    80006c6c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006c70:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006c74:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006c78:	6518                	ld	a4,8(a0)
    80006c7a:	00275783          	lhu	a5,2(a4)
    80006c7e:	8b9d                	andi	a5,a5,7
    80006c80:	0786                	slli	a5,a5,0x1
    80006c82:	97ba                	add	a5,a5,a4
    80006c84:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006c88:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006c8c:	6518                	ld	a4,8(a0)
    80006c8e:	00275783          	lhu	a5,2(a4)
    80006c92:	2785                	addiw	a5,a5,1
    80006c94:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006c98:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006c9c:	100017b7          	lui	a5,0x10001
    80006ca0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006ca4:	00492703          	lw	a4,4(s2)
    80006ca8:	4785                	li	a5,1
    80006caa:	02f71163          	bne	a4,a5,80006ccc <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    80006cae:	0001e997          	auipc	s3,0x1e
    80006cb2:	47a98993          	addi	s3,s3,1146 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006cb6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006cb8:	85ce                	mv	a1,s3
    80006cba:	854a                	mv	a0,s2
    80006cbc:	ffffc097          	auipc	ra,0xffffc
    80006cc0:	b64080e7          	jalr	-1180(ra) # 80002820 <sleep>
  while(b->disk == 1) {
    80006cc4:	00492783          	lw	a5,4(s2)
    80006cc8:	fe9788e3          	beq	a5,s1,80006cb8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    80006ccc:	f9042903          	lw	s2,-112(s0)
    80006cd0:	20090793          	addi	a5,s2,512
    80006cd4:	00479713          	slli	a4,a5,0x4
    80006cd8:	0001c797          	auipc	a5,0x1c
    80006cdc:	32878793          	addi	a5,a5,808 # 80023000 <disk>
    80006ce0:	97ba                	add	a5,a5,a4
    80006ce2:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006ce6:	0001e997          	auipc	s3,0x1e
    80006cea:	31a98993          	addi	s3,s3,794 # 80025000 <disk+0x2000>
    80006cee:	00491713          	slli	a4,s2,0x4
    80006cf2:	0009b783          	ld	a5,0(s3)
    80006cf6:	97ba                	add	a5,a5,a4
    80006cf8:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006cfc:	854a                	mv	a0,s2
    80006cfe:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006d02:	00000097          	auipc	ra,0x0
    80006d06:	bc4080e7          	jalr	-1084(ra) # 800068c6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006d0a:	8885                	andi	s1,s1,1
    80006d0c:	f0ed                	bnez	s1,80006cee <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006d0e:	0001e517          	auipc	a0,0x1e
    80006d12:	41a50513          	addi	a0,a0,1050 # 80025128 <disk+0x2128>
    80006d16:	ffffa097          	auipc	ra,0xffffa
    80006d1a:	f82080e7          	jalr	-126(ra) # 80000c98 <release>
}
    80006d1e:	70a6                	ld	ra,104(sp)
    80006d20:	7406                	ld	s0,96(sp)
    80006d22:	64e6                	ld	s1,88(sp)
    80006d24:	6946                	ld	s2,80(sp)
    80006d26:	69a6                	ld	s3,72(sp)
    80006d28:	6a06                	ld	s4,64(sp)
    80006d2a:	7ae2                	ld	s5,56(sp)
    80006d2c:	7b42                	ld	s6,48(sp)
    80006d2e:	7ba2                	ld	s7,40(sp)
    80006d30:	7c02                	ld	s8,32(sp)
    80006d32:	6ce2                	ld	s9,24(sp)
    80006d34:	6d42                	ld	s10,16(sp)
    80006d36:	6165                	addi	sp,sp,112
    80006d38:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006d3a:	0001e697          	auipc	a3,0x1e
    80006d3e:	2c66b683          	ld	a3,710(a3) # 80025000 <disk+0x2000>
    80006d42:	96ba                	add	a3,a3,a4
    80006d44:	4609                	li	a2,2
    80006d46:	00c69623          	sh	a2,12(a3)
    80006d4a:	b5c9                	j	80006c0c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006d4c:	f9042583          	lw	a1,-112(s0)
    80006d50:	20058793          	addi	a5,a1,512
    80006d54:	0792                	slli	a5,a5,0x4
    80006d56:	0001c517          	auipc	a0,0x1c
    80006d5a:	35250513          	addi	a0,a0,850 # 800230a8 <disk+0xa8>
    80006d5e:	953e                	add	a0,a0,a5
  if(write)
    80006d60:	e20d11e3          	bnez	s10,80006b82 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006d64:	20058713          	addi	a4,a1,512
    80006d68:	00471693          	slli	a3,a4,0x4
    80006d6c:	0001c717          	auipc	a4,0x1c
    80006d70:	29470713          	addi	a4,a4,660 # 80023000 <disk>
    80006d74:	9736                	add	a4,a4,a3
    80006d76:	0a072423          	sw	zero,168(a4)
    80006d7a:	b505                	j	80006b9a <virtio_disk_rw+0xf4>

0000000080006d7c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006d7c:	1101                	addi	sp,sp,-32
    80006d7e:	ec06                	sd	ra,24(sp)
    80006d80:	e822                	sd	s0,16(sp)
    80006d82:	e426                	sd	s1,8(sp)
    80006d84:	e04a                	sd	s2,0(sp)
    80006d86:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006d88:	0001e517          	auipc	a0,0x1e
    80006d8c:	3a050513          	addi	a0,a0,928 # 80025128 <disk+0x2128>
    80006d90:	ffffa097          	auipc	ra,0xffffa
    80006d94:	e54080e7          	jalr	-428(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006d98:	10001737          	lui	a4,0x10001
    80006d9c:	533c                	lw	a5,96(a4)
    80006d9e:	8b8d                	andi	a5,a5,3
    80006da0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006da2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006da6:	0001e797          	auipc	a5,0x1e
    80006daa:	25a78793          	addi	a5,a5,602 # 80025000 <disk+0x2000>
    80006dae:	6b94                	ld	a3,16(a5)
    80006db0:	0207d703          	lhu	a4,32(a5)
    80006db4:	0026d783          	lhu	a5,2(a3)
    80006db8:	06f70163          	beq	a4,a5,80006e1a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006dbc:	0001c917          	auipc	s2,0x1c
    80006dc0:	24490913          	addi	s2,s2,580 # 80023000 <disk>
    80006dc4:	0001e497          	auipc	s1,0x1e
    80006dc8:	23c48493          	addi	s1,s1,572 # 80025000 <disk+0x2000>
    __sync_synchronize();
    80006dcc:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006dd0:	6898                	ld	a4,16(s1)
    80006dd2:	0204d783          	lhu	a5,32(s1)
    80006dd6:	8b9d                	andi	a5,a5,7
    80006dd8:	078e                	slli	a5,a5,0x3
    80006dda:	97ba                	add	a5,a5,a4
    80006ddc:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006dde:	20078713          	addi	a4,a5,512
    80006de2:	0712                	slli	a4,a4,0x4
    80006de4:	974a                	add	a4,a4,s2
    80006de6:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    80006dea:	e731                	bnez	a4,80006e36 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006dec:	20078793          	addi	a5,a5,512
    80006df0:	0792                	slli	a5,a5,0x4
    80006df2:	97ca                	add	a5,a5,s2
    80006df4:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006df6:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006dfa:	ffffc097          	auipc	ra,0xffffc
    80006dfe:	bc8080e7          	jalr	-1080(ra) # 800029c2 <wakeup>

    disk.used_idx += 1;
    80006e02:	0204d783          	lhu	a5,32(s1)
    80006e06:	2785                	addiw	a5,a5,1
    80006e08:	17c2                	slli	a5,a5,0x30
    80006e0a:	93c1                	srli	a5,a5,0x30
    80006e0c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006e10:	6898                	ld	a4,16(s1)
    80006e12:	00275703          	lhu	a4,2(a4)
    80006e16:	faf71be3          	bne	a4,a5,80006dcc <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    80006e1a:	0001e517          	auipc	a0,0x1e
    80006e1e:	30e50513          	addi	a0,a0,782 # 80025128 <disk+0x2128>
    80006e22:	ffffa097          	auipc	ra,0xffffa
    80006e26:	e76080e7          	jalr	-394(ra) # 80000c98 <release>
}
    80006e2a:	60e2                	ld	ra,24(sp)
    80006e2c:	6442                	ld	s0,16(sp)
    80006e2e:	64a2                	ld	s1,8(sp)
    80006e30:	6902                	ld	s2,0(sp)
    80006e32:	6105                	addi	sp,sp,32
    80006e34:	8082                	ret
      panic("virtio_disk_intr status");
    80006e36:	00002517          	auipc	a0,0x2
    80006e3a:	a6250513          	addi	a0,a0,-1438 # 80008898 <syscalls+0x3c8>
    80006e3e:	ffff9097          	auipc	ra,0xffff9
    80006e42:	700080e7          	jalr	1792(ra) # 8000053e <panic>

0000000080006e46 <cas>:
    80006e46:	100522af          	lr.w	t0,(a0)
    80006e4a:	00b29563          	bne	t0,a1,80006e54 <fail>
    80006e4e:	18c5252f          	sc.w	a0,a2,(a0)
    80006e52:	8082                	ret

0000000080006e54 <fail>:
    80006e54:	4505                	li	a0,1
    80006e56:	8082                	ret
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
