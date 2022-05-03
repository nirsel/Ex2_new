
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	86013103          	ld	sp,-1952(sp) # 80008860 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000068:	b0c78793          	addi	a5,a5,-1268 # 80005b70 <timervec>
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
    80000130:	398080e7          	jalr	920(ra) # 800024c4 <either_copyin>
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
    800001c8:	858080e7          	jalr	-1960(ra) # 80001a1c <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	ef6080e7          	jalr	-266(ra) # 800020ca <sleep>
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
    80000214:	25e080e7          	jalr	606(ra) # 8000246e <either_copyout>
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
    800002f6:	228080e7          	jalr	552(ra) # 8000251a <procdump>
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
    8000044a:	e10080e7          	jalr	-496(ra) # 80002256 <wakeup>
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
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	0a078793          	addi	a5,a5,160 # 80021518 <devsw>
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
    80000570:	b5c50513          	addi	a0,a0,-1188 # 800080c8 <digits+0x88>
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
    800008a4:	9b6080e7          	jalr	-1610(ra) # 80002256 <wakeup>
    
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
    8000092c:	00001097          	auipc	ra,0x1
    80000930:	79e080e7          	jalr	1950(ra) # 800020ca <sleep>
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
    80000b82:	e82080e7          	jalr	-382(ra) # 80001a00 <mycpu>
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
    80000bb4:	e50080e7          	jalr	-432(ra) # 80001a00 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	e44080e7          	jalr	-444(ra) # 80001a00 <mycpu>
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
    80000bd8:	e2c080e7          	jalr	-468(ra) # 80001a00 <mycpu>
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
    80000c18:	dec080e7          	jalr	-532(ra) # 80001a00 <mycpu>
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
    80000c44:	dc0080e7          	jalr	-576(ra) # 80001a00 <mycpu>
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
    80000e9a:	b5a080e7          	jalr	-1190(ra) # 800019f0 <cpuid>
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
    80000eb6:	b3e080e7          	jalr	-1218(ra) # 800019f0 <cpuid>
    80000eba:	85aa                	mv	a1,a0
    80000ebc:	00007517          	auipc	a0,0x7
    80000ec0:	1fc50513          	addi	a0,a0,508 # 800080b8 <digits+0x78>
    80000ec4:	fffff097          	auipc	ra,0xfffff
    80000ec8:	6c4080e7          	jalr	1732(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ecc:	00000097          	auipc	ra,0x0
    80000ed0:	0d8080e7          	jalr	216(ra) # 80000fa4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ed4:	00001097          	auipc	ra,0x1
    80000ed8:	786080e7          	jalr	1926(ra) # 8000265a <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	cd4080e7          	jalr	-812(ra) # 80005bb0 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	034080e7          	jalr	52(ra) # 80001f18 <scheduler>
    consoleinit();
    80000eec:	fffff097          	auipc	ra,0xfffff
    80000ef0:	564080e7          	jalr	1380(ra) # 80000450 <consoleinit>
    printfinit();
    80000ef4:	00000097          	auipc	ra,0x0
    80000ef8:	87a080e7          	jalr	-1926(ra) # 8000076e <printfinit>
    printf("\n");
    80000efc:	00007517          	auipc	a0,0x7
    80000f00:	1cc50513          	addi	a0,a0,460 # 800080c8 <digits+0x88>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	684080e7          	jalr	1668(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	19450513          	addi	a0,a0,404 # 800080a0 <digits+0x60>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	1ac50513          	addi	a0,a0,428 # 800080c8 <digits+0x88>
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
    80000f48:	9fc080e7          	jalr	-1540(ra) # 80001940 <procinit>
    trapinit();      // trap vectors
    80000f4c:	00001097          	auipc	ra,0x1
    80000f50:	6e6080e7          	jalr	1766(ra) # 80002632 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00001097          	auipc	ra,0x1
    80000f58:	706080e7          	jalr	1798(ra) # 8000265a <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	c3e080e7          	jalr	-962(ra) # 80005b9a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	c4c080e7          	jalr	-948(ra) # 80005bb0 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	e30080e7          	jalr	-464(ra) # 80002d9c <binit>
    iinit();         // inode table
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	4c0080e7          	jalr	1216(ra) # 80003434 <iinit>
    fileinit();      // file table
    80000f7c:	00003097          	auipc	ra,0x3
    80000f80:	46a080e7          	jalr	1130(ra) # 800043e6 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	d4e080e7          	jalr	-690(ra) # 80005cd2 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	d5a080e7          	jalr	-678(ra) # 80001ce6 <userinit>
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
    80001240:	00000097          	auipc	ra,0x0
    80001244:	66a080e7          	jalr	1642(ra) # 800018aa <proc_mapstacks>
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

000000008000183e <add_link>:

extern char trampoline[]; // trampoline.S

extern uint64 cas(volatile void* addr, int expected, int newval);

void add_link(struct processList list, int index){
    8000183e:	1101                	addi	sp,sp,-32
    80001840:	ec22                	sd	s0,24(sp)
    80001842:	1000                	addi	s0,sp,32
    80001844:	fea43423          	sd	a0,-24(s0)
  if (list.head == -1){
    80001848:	2501                	sext.w	a0,a0
    8000184a:	57fd                	li	a5,-1
    8000184c:	02f50a63          	beq	a0,a5,80001880 <add_link+0x42>
    80001850:	fec42683          	lw	a3,-20(s0)
    p->prev_proc_index = -1;
    p->next_proc_index = -1;
    return;
  }
  struct proc* last_proc = &proc[list.last];
  last_proc->next_proc_index = index;
    80001854:	00010797          	auipc	a5,0x10
    80001858:	e7c78793          	addi	a5,a5,-388 # 800116d0 <proc>
    8000185c:	17000613          	li	a2,368
    80001860:	02c68733          	mul	a4,a3,a2
    80001864:	973e                	add	a4,a4,a5
    80001866:	16b72423          	sw	a1,360(a4)
  struct proc* new_last = &proc[index];
  new_last -> prev_proc_index = list.last;
    8000186a:	02c585b3          	mul	a1,a1,a2
    8000186e:	95be                	add	a1,a1,a5
    80001870:	16d5a623          	sw	a3,364(a1) # 400016c <_entry-0x7bfffe94>
  new_last -> next_proc_index = -1;
    80001874:	57fd                	li	a5,-1
    80001876:	16f5a423          	sw	a5,360(a1)
  list.last = index;

  

}
    8000187a:	6462                	ld	s0,24(sp)
    8000187c:	6105                	addi	sp,sp,32
    8000187e:	8082                	ret
    p->prev_proc_index = -1;
    80001880:	17000793          	li	a5,368
    80001884:	02f585b3          	mul	a1,a1,a5
    80001888:	00010797          	auipc	a5,0x10
    8000188c:	e4878793          	addi	a5,a5,-440 # 800116d0 <proc>
    80001890:	95be                	add	a1,a1,a5
    80001892:	57fd                	li	a5,-1
    80001894:	16f5a623          	sw	a5,364(a1)
    p->next_proc_index = -1;
    80001898:	16f5a423          	sw	a5,360(a1)
    return;
    8000189c:	bff9                	j	8000187a <add_link+0x3c>

000000008000189e <remove_link>:

void remove_link(struct processList list, int index){
    8000189e:	1101                	addi	sp,sp,-32
    800018a0:	ec22                	sd	s0,24(sp)
    800018a2:	1000                	addi	s0,sp,32

}
    800018a4:	6462                	ld	s0,24(sp)
    800018a6:	6105                	addi	sp,sp,32
    800018a8:	8082                	ret

00000000800018aa <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    800018aa:	7139                	addi	sp,sp,-64
    800018ac:	fc06                	sd	ra,56(sp)
    800018ae:	f822                	sd	s0,48(sp)
    800018b0:	f426                	sd	s1,40(sp)
    800018b2:	f04a                	sd	s2,32(sp)
    800018b4:	ec4e                	sd	s3,24(sp)
    800018b6:	e852                	sd	s4,16(sp)
    800018b8:	e456                	sd	s5,8(sp)
    800018ba:	e05a                	sd	s6,0(sp)
    800018bc:	0080                	addi	s0,sp,64
    800018be:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    800018c0:	00010497          	auipc	s1,0x10
    800018c4:	e1048493          	addi	s1,s1,-496 # 800116d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    800018c8:	8b26                	mv	s6,s1
    800018ca:	00006a97          	auipc	s5,0x6
    800018ce:	736a8a93          	addi	s5,s5,1846 # 80008000 <etext>
    800018d2:	04000937          	lui	s2,0x4000
    800018d6:	197d                	addi	s2,s2,-1
    800018d8:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800018da:	00016a17          	auipc	s4,0x16
    800018de:	9f6a0a13          	addi	s4,s4,-1546 # 800172d0 <tickslock>
    char *pa = kalloc();
    800018e2:	fffff097          	auipc	ra,0xfffff
    800018e6:	212080e7          	jalr	530(ra) # 80000af4 <kalloc>
    800018ea:	862a                	mv	a2,a0
    if(pa == 0)
    800018ec:	c131                	beqz	a0,80001930 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    800018ee:	416485b3          	sub	a1,s1,s6
    800018f2:	8591                	srai	a1,a1,0x4
    800018f4:	000ab783          	ld	a5,0(s5)
    800018f8:	02f585b3          	mul	a1,a1,a5
    800018fc:	2585                	addiw	a1,a1,1
    800018fe:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001902:	4719                	li	a4,6
    80001904:	6685                	lui	a3,0x1
    80001906:	40b905b3          	sub	a1,s2,a1
    8000190a:	854e                	mv	a0,s3
    8000190c:	00000097          	auipc	ra,0x0
    80001910:	844080e7          	jalr	-1980(ra) # 80001150 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001914:	17048493          	addi	s1,s1,368
    80001918:	fd4495e3          	bne	s1,s4,800018e2 <proc_mapstacks+0x38>
  }
}
    8000191c:	70e2                	ld	ra,56(sp)
    8000191e:	7442                	ld	s0,48(sp)
    80001920:	74a2                	ld	s1,40(sp)
    80001922:	7902                	ld	s2,32(sp)
    80001924:	69e2                	ld	s3,24(sp)
    80001926:	6a42                	ld	s4,16(sp)
    80001928:	6aa2                	ld	s5,8(sp)
    8000192a:	6b02                	ld	s6,0(sp)
    8000192c:	6121                	addi	sp,sp,64
    8000192e:	8082                	ret
      panic("kalloc");
    80001930:	00007517          	auipc	a0,0x7
    80001934:	8a850513          	addi	a0,a0,-1880 # 800081d8 <digits+0x198>
    80001938:	fffff097          	auipc	ra,0xfffff
    8000193c:	c06080e7          	jalr	-1018(ra) # 8000053e <panic>

0000000080001940 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    80001940:	7139                	addi	sp,sp,-64
    80001942:	fc06                	sd	ra,56(sp)
    80001944:	f822                	sd	s0,48(sp)
    80001946:	f426                	sd	s1,40(sp)
    80001948:	f04a                	sd	s2,32(sp)
    8000194a:	ec4e                	sd	s3,24(sp)
    8000194c:	e852                	sd	s4,16(sp)
    8000194e:	e456                	sd	s5,8(sp)
    80001950:	e05a                	sd	s6,0(sp)
    80001952:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001954:	00007597          	auipc	a1,0x7
    80001958:	88c58593          	addi	a1,a1,-1908 # 800081e0 <digits+0x1a0>
    8000195c:	00010517          	auipc	a0,0x10
    80001960:	94450513          	addi	a0,a0,-1724 # 800112a0 <pid_lock>
    80001964:	fffff097          	auipc	ra,0xfffff
    80001968:	1f0080e7          	jalr	496(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    8000196c:	00007597          	auipc	a1,0x7
    80001970:	87c58593          	addi	a1,a1,-1924 # 800081e8 <digits+0x1a8>
    80001974:	00010517          	auipc	a0,0x10
    80001978:	94450513          	addi	a0,a0,-1724 # 800112b8 <wait_lock>
    8000197c:	fffff097          	auipc	ra,0xfffff
    80001980:	1d8080e7          	jalr	472(ra) # 80000b54 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001984:	00010497          	auipc	s1,0x10
    80001988:	d4c48493          	addi	s1,s1,-692 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    8000198c:	00007b17          	auipc	s6,0x7
    80001990:	86cb0b13          	addi	s6,s6,-1940 # 800081f8 <digits+0x1b8>
      p->kstack = KSTACK((int) (p - proc));
    80001994:	8aa6                	mv	s5,s1
    80001996:	00006a17          	auipc	s4,0x6
    8000199a:	66aa0a13          	addi	s4,s4,1642 # 80008000 <etext>
    8000199e:	04000937          	lui	s2,0x4000
    800019a2:	197d                	addi	s2,s2,-1
    800019a4:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800019a6:	00016997          	auipc	s3,0x16
    800019aa:	92a98993          	addi	s3,s3,-1750 # 800172d0 <tickslock>
      initlock(&p->lock, "proc");
    800019ae:	85da                	mv	a1,s6
    800019b0:	8526                	mv	a0,s1
    800019b2:	fffff097          	auipc	ra,0xfffff
    800019b6:	1a2080e7          	jalr	418(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    800019ba:	415487b3          	sub	a5,s1,s5
    800019be:	8791                	srai	a5,a5,0x4
    800019c0:	000a3703          	ld	a4,0(s4)
    800019c4:	02e787b3          	mul	a5,a5,a4
    800019c8:	2785                	addiw	a5,a5,1
    800019ca:	00d7979b          	slliw	a5,a5,0xd
    800019ce:	40f907b3          	sub	a5,s2,a5
    800019d2:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    800019d4:	17048493          	addi	s1,s1,368
    800019d8:	fd349be3          	bne	s1,s3,800019ae <procinit+0x6e>
  }
}
    800019dc:	70e2                	ld	ra,56(sp)
    800019de:	7442                	ld	s0,48(sp)
    800019e0:	74a2                	ld	s1,40(sp)
    800019e2:	7902                	ld	s2,32(sp)
    800019e4:	69e2                	ld	s3,24(sp)
    800019e6:	6a42                	ld	s4,16(sp)
    800019e8:	6aa2                	ld	s5,8(sp)
    800019ea:	6b02                	ld	s6,0(sp)
    800019ec:	6121                	addi	sp,sp,64
    800019ee:	8082                	ret

00000000800019f0 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800019f0:	1141                	addi	sp,sp,-16
    800019f2:	e422                	sd	s0,8(sp)
    800019f4:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019f6:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800019f8:	2501                	sext.w	a0,a0
    800019fa:	6422                	ld	s0,8(sp)
    800019fc:	0141                	addi	sp,sp,16
    800019fe:	8082                	ret

0000000080001a00 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001a00:	1141                	addi	sp,sp,-16
    80001a02:	e422                	sd	s0,8(sp)
    80001a04:	0800                	addi	s0,sp,16
    80001a06:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001a08:	2781                	sext.w	a5,a5
    80001a0a:	079e                	slli	a5,a5,0x7
  return c;
}
    80001a0c:	00010517          	auipc	a0,0x10
    80001a10:	8c450513          	addi	a0,a0,-1852 # 800112d0 <cpus>
    80001a14:	953e                	add	a0,a0,a5
    80001a16:	6422                	ld	s0,8(sp)
    80001a18:	0141                	addi	sp,sp,16
    80001a1a:	8082                	ret

0000000080001a1c <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001a1c:	1101                	addi	sp,sp,-32
    80001a1e:	ec06                	sd	ra,24(sp)
    80001a20:	e822                	sd	s0,16(sp)
    80001a22:	e426                	sd	s1,8(sp)
    80001a24:	1000                	addi	s0,sp,32
  push_off();
    80001a26:	fffff097          	auipc	ra,0xfffff
    80001a2a:	172080e7          	jalr	370(ra) # 80000b98 <push_off>
    80001a2e:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001a30:	2781                	sext.w	a5,a5
    80001a32:	079e                	slli	a5,a5,0x7
    80001a34:	00010717          	auipc	a4,0x10
    80001a38:	86c70713          	addi	a4,a4,-1940 # 800112a0 <pid_lock>
    80001a3c:	97ba                	add	a5,a5,a4
    80001a3e:	7b84                	ld	s1,48(a5)
  pop_off();
    80001a40:	fffff097          	auipc	ra,0xfffff
    80001a44:	1f8080e7          	jalr	504(ra) # 80000c38 <pop_off>
  return p;
}
    80001a48:	8526                	mv	a0,s1
    80001a4a:	60e2                	ld	ra,24(sp)
    80001a4c:	6442                	ld	s0,16(sp)
    80001a4e:	64a2                	ld	s1,8(sp)
    80001a50:	6105                	addi	sp,sp,32
    80001a52:	8082                	ret

0000000080001a54 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001a54:	1141                	addi	sp,sp,-16
    80001a56:	e406                	sd	ra,8(sp)
    80001a58:	e022                	sd	s0,0(sp)
    80001a5a:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a5c:	00000097          	auipc	ra,0x0
    80001a60:	fc0080e7          	jalr	-64(ra) # 80001a1c <myproc>
    80001a64:	fffff097          	auipc	ra,0xfffff
    80001a68:	234080e7          	jalr	564(ra) # 80000c98 <release>

  if (first) {
    80001a6c:	00007797          	auipc	a5,0x7
    80001a70:	da47a783          	lw	a5,-604(a5) # 80008810 <first.1694>
    80001a74:	eb89                	bnez	a5,80001a86 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a76:	00001097          	auipc	ra,0x1
    80001a7a:	bfc080e7          	jalr	-1028(ra) # 80002672 <usertrapret>
}
    80001a7e:	60a2                	ld	ra,8(sp)
    80001a80:	6402                	ld	s0,0(sp)
    80001a82:	0141                	addi	sp,sp,16
    80001a84:	8082                	ret
    first = 0;
    80001a86:	00007797          	auipc	a5,0x7
    80001a8a:	d807a523          	sw	zero,-630(a5) # 80008810 <first.1694>
    fsinit(ROOTDEV);
    80001a8e:	4505                	li	a0,1
    80001a90:	00002097          	auipc	ra,0x2
    80001a94:	924080e7          	jalr	-1756(ra) # 800033b4 <fsinit>
    80001a98:	bff9                	j	80001a76 <forkret+0x22>

0000000080001a9a <allocpid>:
allocpid() {
    80001a9a:	1101                	addi	sp,sp,-32
    80001a9c:	ec06                	sd	ra,24(sp)
    80001a9e:	e822                	sd	s0,16(sp)
    80001aa0:	e426                	sd	s1,8(sp)
    80001aa2:	e04a                	sd	s2,0(sp)
    80001aa4:	1000                	addi	s0,sp,32
    pid = nextpid;
    80001aa6:	00007917          	auipc	s2,0x7
    80001aaa:	d6e90913          	addi	s2,s2,-658 # 80008814 <nextpid>
    80001aae:	00092583          	lw	a1,0(s2)
  } while (cas(&nextpid, pid, pid+1));
    80001ab2:	0015849b          	addiw	s1,a1,1
    80001ab6:	8626                	mv	a2,s1
    80001ab8:	854a                	mv	a0,s2
    80001aba:	00004097          	auipc	ra,0x4
    80001abe:	6fc080e7          	jalr	1788(ra) # 800061b6 <cas>
    80001ac2:	f575                	bnez	a0,80001aae <allocpid+0x14>
}
    80001ac4:	8526                	mv	a0,s1
    80001ac6:	60e2                	ld	ra,24(sp)
    80001ac8:	6442                	ld	s0,16(sp)
    80001aca:	64a2                	ld	s1,8(sp)
    80001acc:	6902                	ld	s2,0(sp)
    80001ace:	6105                	addi	sp,sp,32
    80001ad0:	8082                	ret

0000000080001ad2 <proc_pagetable>:
{
    80001ad2:	1101                	addi	sp,sp,-32
    80001ad4:	ec06                	sd	ra,24(sp)
    80001ad6:	e822                	sd	s0,16(sp)
    80001ad8:	e426                	sd	s1,8(sp)
    80001ada:	e04a                	sd	s2,0(sp)
    80001adc:	1000                	addi	s0,sp,32
    80001ade:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001ae0:	00000097          	auipc	ra,0x0
    80001ae4:	85a080e7          	jalr	-1958(ra) # 8000133a <uvmcreate>
    80001ae8:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001aea:	c121                	beqz	a0,80001b2a <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001aec:	4729                	li	a4,10
    80001aee:	00005697          	auipc	a3,0x5
    80001af2:	51268693          	addi	a3,a3,1298 # 80007000 <_trampoline>
    80001af6:	6605                	lui	a2,0x1
    80001af8:	040005b7          	lui	a1,0x4000
    80001afc:	15fd                	addi	a1,a1,-1
    80001afe:	05b2                	slli	a1,a1,0xc
    80001b00:	fffff097          	auipc	ra,0xfffff
    80001b04:	5b0080e7          	jalr	1456(ra) # 800010b0 <mappages>
    80001b08:	02054863          	bltz	a0,80001b38 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b0c:	4719                	li	a4,6
    80001b0e:	05893683          	ld	a3,88(s2)
    80001b12:	6605                	lui	a2,0x1
    80001b14:	020005b7          	lui	a1,0x2000
    80001b18:	15fd                	addi	a1,a1,-1
    80001b1a:	05b6                	slli	a1,a1,0xd
    80001b1c:	8526                	mv	a0,s1
    80001b1e:	fffff097          	auipc	ra,0xfffff
    80001b22:	592080e7          	jalr	1426(ra) # 800010b0 <mappages>
    80001b26:	02054163          	bltz	a0,80001b48 <proc_pagetable+0x76>
}
    80001b2a:	8526                	mv	a0,s1
    80001b2c:	60e2                	ld	ra,24(sp)
    80001b2e:	6442                	ld	s0,16(sp)
    80001b30:	64a2                	ld	s1,8(sp)
    80001b32:	6902                	ld	s2,0(sp)
    80001b34:	6105                	addi	sp,sp,32
    80001b36:	8082                	ret
    uvmfree(pagetable, 0);
    80001b38:	4581                	li	a1,0
    80001b3a:	8526                	mv	a0,s1
    80001b3c:	00000097          	auipc	ra,0x0
    80001b40:	9fa080e7          	jalr	-1542(ra) # 80001536 <uvmfree>
    return 0;
    80001b44:	4481                	li	s1,0
    80001b46:	b7d5                	j	80001b2a <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b48:	4681                	li	a3,0
    80001b4a:	4605                	li	a2,1
    80001b4c:	040005b7          	lui	a1,0x4000
    80001b50:	15fd                	addi	a1,a1,-1
    80001b52:	05b2                	slli	a1,a1,0xc
    80001b54:	8526                	mv	a0,s1
    80001b56:	fffff097          	auipc	ra,0xfffff
    80001b5a:	720080e7          	jalr	1824(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b5e:	4581                	li	a1,0
    80001b60:	8526                	mv	a0,s1
    80001b62:	00000097          	auipc	ra,0x0
    80001b66:	9d4080e7          	jalr	-1580(ra) # 80001536 <uvmfree>
    return 0;
    80001b6a:	4481                	li	s1,0
    80001b6c:	bf7d                	j	80001b2a <proc_pagetable+0x58>

0000000080001b6e <proc_freepagetable>:
{
    80001b6e:	1101                	addi	sp,sp,-32
    80001b70:	ec06                	sd	ra,24(sp)
    80001b72:	e822                	sd	s0,16(sp)
    80001b74:	e426                	sd	s1,8(sp)
    80001b76:	e04a                	sd	s2,0(sp)
    80001b78:	1000                	addi	s0,sp,32
    80001b7a:	84aa                	mv	s1,a0
    80001b7c:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b7e:	4681                	li	a3,0
    80001b80:	4605                	li	a2,1
    80001b82:	040005b7          	lui	a1,0x4000
    80001b86:	15fd                	addi	a1,a1,-1
    80001b88:	05b2                	slli	a1,a1,0xc
    80001b8a:	fffff097          	auipc	ra,0xfffff
    80001b8e:	6ec080e7          	jalr	1772(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b92:	4681                	li	a3,0
    80001b94:	4605                	li	a2,1
    80001b96:	020005b7          	lui	a1,0x2000
    80001b9a:	15fd                	addi	a1,a1,-1
    80001b9c:	05b6                	slli	a1,a1,0xd
    80001b9e:	8526                	mv	a0,s1
    80001ba0:	fffff097          	auipc	ra,0xfffff
    80001ba4:	6d6080e7          	jalr	1750(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80001ba8:	85ca                	mv	a1,s2
    80001baa:	8526                	mv	a0,s1
    80001bac:	00000097          	auipc	ra,0x0
    80001bb0:	98a080e7          	jalr	-1654(ra) # 80001536 <uvmfree>
}
    80001bb4:	60e2                	ld	ra,24(sp)
    80001bb6:	6442                	ld	s0,16(sp)
    80001bb8:	64a2                	ld	s1,8(sp)
    80001bba:	6902                	ld	s2,0(sp)
    80001bbc:	6105                	addi	sp,sp,32
    80001bbe:	8082                	ret

0000000080001bc0 <freeproc>:
{
    80001bc0:	1101                	addi	sp,sp,-32
    80001bc2:	ec06                	sd	ra,24(sp)
    80001bc4:	e822                	sd	s0,16(sp)
    80001bc6:	e426                	sd	s1,8(sp)
    80001bc8:	1000                	addi	s0,sp,32
    80001bca:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001bcc:	6d28                	ld	a0,88(a0)
    80001bce:	c509                	beqz	a0,80001bd8 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001bd0:	fffff097          	auipc	ra,0xfffff
    80001bd4:	e28080e7          	jalr	-472(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001bd8:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001bdc:	68a8                	ld	a0,80(s1)
    80001bde:	c511                	beqz	a0,80001bea <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001be0:	64ac                	ld	a1,72(s1)
    80001be2:	00000097          	auipc	ra,0x0
    80001be6:	f8c080e7          	jalr	-116(ra) # 80001b6e <proc_freepagetable>
  p->pagetable = 0;
    80001bea:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001bee:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001bf2:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001bf6:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001bfa:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001bfe:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001c02:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001c06:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001c0a:	0004ac23          	sw	zero,24(s1)
}
    80001c0e:	60e2                	ld	ra,24(sp)
    80001c10:	6442                	ld	s0,16(sp)
    80001c12:	64a2                	ld	s1,8(sp)
    80001c14:	6105                	addi	sp,sp,32
    80001c16:	8082                	ret

0000000080001c18 <allocproc>:
{
    80001c18:	1101                	addi	sp,sp,-32
    80001c1a:	ec06                	sd	ra,24(sp)
    80001c1c:	e822                	sd	s0,16(sp)
    80001c1e:	e426                	sd	s1,8(sp)
    80001c20:	e04a                	sd	s2,0(sp)
    80001c22:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c24:	00010497          	auipc	s1,0x10
    80001c28:	aac48493          	addi	s1,s1,-1364 # 800116d0 <proc>
    80001c2c:	00015917          	auipc	s2,0x15
    80001c30:	6a490913          	addi	s2,s2,1700 # 800172d0 <tickslock>
    acquire(&p->lock);
    80001c34:	8526                	mv	a0,s1
    80001c36:	fffff097          	auipc	ra,0xfffff
    80001c3a:	fae080e7          	jalr	-82(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001c3e:	4c9c                	lw	a5,24(s1)
    80001c40:	cf81                	beqz	a5,80001c58 <allocproc+0x40>
      release(&p->lock);
    80001c42:	8526                	mv	a0,s1
    80001c44:	fffff097          	auipc	ra,0xfffff
    80001c48:	054080e7          	jalr	84(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c4c:	17048493          	addi	s1,s1,368
    80001c50:	ff2492e3          	bne	s1,s2,80001c34 <allocproc+0x1c>
  return 0;
    80001c54:	4481                	li	s1,0
    80001c56:	a889                	j	80001ca8 <allocproc+0x90>
  p->pid = allocpid();
    80001c58:	00000097          	auipc	ra,0x0
    80001c5c:	e42080e7          	jalr	-446(ra) # 80001a9a <allocpid>
    80001c60:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c62:	4785                	li	a5,1
    80001c64:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c66:	fffff097          	auipc	ra,0xfffff
    80001c6a:	e8e080e7          	jalr	-370(ra) # 80000af4 <kalloc>
    80001c6e:	892a                	mv	s2,a0
    80001c70:	eca8                	sd	a0,88(s1)
    80001c72:	c131                	beqz	a0,80001cb6 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c74:	8526                	mv	a0,s1
    80001c76:	00000097          	auipc	ra,0x0
    80001c7a:	e5c080e7          	jalr	-420(ra) # 80001ad2 <proc_pagetable>
    80001c7e:	892a                	mv	s2,a0
    80001c80:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c82:	c531                	beqz	a0,80001cce <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c84:	07000613          	li	a2,112
    80001c88:	4581                	li	a1,0
    80001c8a:	06048513          	addi	a0,s1,96
    80001c8e:	fffff097          	auipc	ra,0xfffff
    80001c92:	052080e7          	jalr	82(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001c96:	00000797          	auipc	a5,0x0
    80001c9a:	dbe78793          	addi	a5,a5,-578 # 80001a54 <forkret>
    80001c9e:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001ca0:	60bc                	ld	a5,64(s1)
    80001ca2:	6705                	lui	a4,0x1
    80001ca4:	97ba                	add	a5,a5,a4
    80001ca6:	f4bc                	sd	a5,104(s1)
}
    80001ca8:	8526                	mv	a0,s1
    80001caa:	60e2                	ld	ra,24(sp)
    80001cac:	6442                	ld	s0,16(sp)
    80001cae:	64a2                	ld	s1,8(sp)
    80001cb0:	6902                	ld	s2,0(sp)
    80001cb2:	6105                	addi	sp,sp,32
    80001cb4:	8082                	ret
    freeproc(p);
    80001cb6:	8526                	mv	a0,s1
    80001cb8:	00000097          	auipc	ra,0x0
    80001cbc:	f08080e7          	jalr	-248(ra) # 80001bc0 <freeproc>
    release(&p->lock);
    80001cc0:	8526                	mv	a0,s1
    80001cc2:	fffff097          	auipc	ra,0xfffff
    80001cc6:	fd6080e7          	jalr	-42(ra) # 80000c98 <release>
    return 0;
    80001cca:	84ca                	mv	s1,s2
    80001ccc:	bff1                	j	80001ca8 <allocproc+0x90>
    freeproc(p);
    80001cce:	8526                	mv	a0,s1
    80001cd0:	00000097          	auipc	ra,0x0
    80001cd4:	ef0080e7          	jalr	-272(ra) # 80001bc0 <freeproc>
    release(&p->lock);
    80001cd8:	8526                	mv	a0,s1
    80001cda:	fffff097          	auipc	ra,0xfffff
    80001cde:	fbe080e7          	jalr	-66(ra) # 80000c98 <release>
    return 0;
    80001ce2:	84ca                	mv	s1,s2
    80001ce4:	b7d1                	j	80001ca8 <allocproc+0x90>

0000000080001ce6 <userinit>:
{
    80001ce6:	1101                	addi	sp,sp,-32
    80001ce8:	ec06                	sd	ra,24(sp)
    80001cea:	e822                	sd	s0,16(sp)
    80001cec:	e426                	sd	s1,8(sp)
    80001cee:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cf0:	00000097          	auipc	ra,0x0
    80001cf4:	f28080e7          	jalr	-216(ra) # 80001c18 <allocproc>
    80001cf8:	84aa                	mv	s1,a0
  initproc = p;
    80001cfa:	00007797          	auipc	a5,0x7
    80001cfe:	32a7b723          	sd	a0,814(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001d02:	03400613          	li	a2,52
    80001d06:	00007597          	auipc	a1,0x7
    80001d0a:	b1a58593          	addi	a1,a1,-1254 # 80008820 <initcode>
    80001d0e:	6928                	ld	a0,80(a0)
    80001d10:	fffff097          	auipc	ra,0xfffff
    80001d14:	658080e7          	jalr	1624(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    80001d18:	6785                	lui	a5,0x1
    80001d1a:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d1c:	6cb8                	ld	a4,88(s1)
    80001d1e:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d22:	6cb8                	ld	a4,88(s1)
    80001d24:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d26:	4641                	li	a2,16
    80001d28:	00006597          	auipc	a1,0x6
    80001d2c:	4d858593          	addi	a1,a1,1240 # 80008200 <digits+0x1c0>
    80001d30:	15848513          	addi	a0,s1,344
    80001d34:	fffff097          	auipc	ra,0xfffff
    80001d38:	0fe080e7          	jalr	254(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001d3c:	00006517          	auipc	a0,0x6
    80001d40:	4d450513          	addi	a0,a0,1236 # 80008210 <digits+0x1d0>
    80001d44:	00002097          	auipc	ra,0x2
    80001d48:	09e080e7          	jalr	158(ra) # 80003de2 <namei>
    80001d4c:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d50:	478d                	li	a5,3
    80001d52:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d54:	8526                	mv	a0,s1
    80001d56:	fffff097          	auipc	ra,0xfffff
    80001d5a:	f42080e7          	jalr	-190(ra) # 80000c98 <release>
}
    80001d5e:	60e2                	ld	ra,24(sp)
    80001d60:	6442                	ld	s0,16(sp)
    80001d62:	64a2                	ld	s1,8(sp)
    80001d64:	6105                	addi	sp,sp,32
    80001d66:	8082                	ret

0000000080001d68 <growproc>:
{
    80001d68:	1101                	addi	sp,sp,-32
    80001d6a:	ec06                	sd	ra,24(sp)
    80001d6c:	e822                	sd	s0,16(sp)
    80001d6e:	e426                	sd	s1,8(sp)
    80001d70:	e04a                	sd	s2,0(sp)
    80001d72:	1000                	addi	s0,sp,32
    80001d74:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d76:	00000097          	auipc	ra,0x0
    80001d7a:	ca6080e7          	jalr	-858(ra) # 80001a1c <myproc>
    80001d7e:	892a                	mv	s2,a0
  sz = p->sz;
    80001d80:	652c                	ld	a1,72(a0)
    80001d82:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d86:	00904f63          	bgtz	s1,80001da4 <growproc+0x3c>
  } else if(n < 0){
    80001d8a:	0204cc63          	bltz	s1,80001dc2 <growproc+0x5a>
  p->sz = sz;
    80001d8e:	1602                	slli	a2,a2,0x20
    80001d90:	9201                	srli	a2,a2,0x20
    80001d92:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d96:	4501                	li	a0,0
}
    80001d98:	60e2                	ld	ra,24(sp)
    80001d9a:	6442                	ld	s0,16(sp)
    80001d9c:	64a2                	ld	s1,8(sp)
    80001d9e:	6902                	ld	s2,0(sp)
    80001da0:	6105                	addi	sp,sp,32
    80001da2:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001da4:	9e25                	addw	a2,a2,s1
    80001da6:	1602                	slli	a2,a2,0x20
    80001da8:	9201                	srli	a2,a2,0x20
    80001daa:	1582                	slli	a1,a1,0x20
    80001dac:	9181                	srli	a1,a1,0x20
    80001dae:	6928                	ld	a0,80(a0)
    80001db0:	fffff097          	auipc	ra,0xfffff
    80001db4:	672080e7          	jalr	1650(ra) # 80001422 <uvmalloc>
    80001db8:	0005061b          	sext.w	a2,a0
    80001dbc:	fa69                	bnez	a2,80001d8e <growproc+0x26>
      return -1;
    80001dbe:	557d                	li	a0,-1
    80001dc0:	bfe1                	j	80001d98 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001dc2:	9e25                	addw	a2,a2,s1
    80001dc4:	1602                	slli	a2,a2,0x20
    80001dc6:	9201                	srli	a2,a2,0x20
    80001dc8:	1582                	slli	a1,a1,0x20
    80001dca:	9181                	srli	a1,a1,0x20
    80001dcc:	6928                	ld	a0,80(a0)
    80001dce:	fffff097          	auipc	ra,0xfffff
    80001dd2:	60c080e7          	jalr	1548(ra) # 800013da <uvmdealloc>
    80001dd6:	0005061b          	sext.w	a2,a0
    80001dda:	bf55                	j	80001d8e <growproc+0x26>

0000000080001ddc <fork>:
{
    80001ddc:	7179                	addi	sp,sp,-48
    80001dde:	f406                	sd	ra,40(sp)
    80001de0:	f022                	sd	s0,32(sp)
    80001de2:	ec26                	sd	s1,24(sp)
    80001de4:	e84a                	sd	s2,16(sp)
    80001de6:	e44e                	sd	s3,8(sp)
    80001de8:	e052                	sd	s4,0(sp)
    80001dea:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001dec:	00000097          	auipc	ra,0x0
    80001df0:	c30080e7          	jalr	-976(ra) # 80001a1c <myproc>
    80001df4:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001df6:	00000097          	auipc	ra,0x0
    80001dfa:	e22080e7          	jalr	-478(ra) # 80001c18 <allocproc>
    80001dfe:	10050b63          	beqz	a0,80001f14 <fork+0x138>
    80001e02:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e04:	04893603          	ld	a2,72(s2)
    80001e08:	692c                	ld	a1,80(a0)
    80001e0a:	05093503          	ld	a0,80(s2)
    80001e0e:	fffff097          	auipc	ra,0xfffff
    80001e12:	760080e7          	jalr	1888(ra) # 8000156e <uvmcopy>
    80001e16:	04054663          	bltz	a0,80001e62 <fork+0x86>
  np->sz = p->sz;
    80001e1a:	04893783          	ld	a5,72(s2)
    80001e1e:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001e22:	05893683          	ld	a3,88(s2)
    80001e26:	87b6                	mv	a5,a3
    80001e28:	0589b703          	ld	a4,88(s3)
    80001e2c:	12068693          	addi	a3,a3,288
    80001e30:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e34:	6788                	ld	a0,8(a5)
    80001e36:	6b8c                	ld	a1,16(a5)
    80001e38:	6f90                	ld	a2,24(a5)
    80001e3a:	01073023          	sd	a6,0(a4)
    80001e3e:	e708                	sd	a0,8(a4)
    80001e40:	eb0c                	sd	a1,16(a4)
    80001e42:	ef10                	sd	a2,24(a4)
    80001e44:	02078793          	addi	a5,a5,32
    80001e48:	02070713          	addi	a4,a4,32
    80001e4c:	fed792e3          	bne	a5,a3,80001e30 <fork+0x54>
  np->trapframe->a0 = 0;
    80001e50:	0589b783          	ld	a5,88(s3)
    80001e54:	0607b823          	sd	zero,112(a5)
    80001e58:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001e5c:	15000a13          	li	s4,336
    80001e60:	a03d                	j	80001e8e <fork+0xb2>
    freeproc(np);
    80001e62:	854e                	mv	a0,s3
    80001e64:	00000097          	auipc	ra,0x0
    80001e68:	d5c080e7          	jalr	-676(ra) # 80001bc0 <freeproc>
    release(&np->lock);
    80001e6c:	854e                	mv	a0,s3
    80001e6e:	fffff097          	auipc	ra,0xfffff
    80001e72:	e2a080e7          	jalr	-470(ra) # 80000c98 <release>
    return -1;
    80001e76:	5a7d                	li	s4,-1
    80001e78:	a069                	j	80001f02 <fork+0x126>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e7a:	00002097          	auipc	ra,0x2
    80001e7e:	5fe080e7          	jalr	1534(ra) # 80004478 <filedup>
    80001e82:	009987b3          	add	a5,s3,s1
    80001e86:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e88:	04a1                	addi	s1,s1,8
    80001e8a:	01448763          	beq	s1,s4,80001e98 <fork+0xbc>
    if(p->ofile[i])
    80001e8e:	009907b3          	add	a5,s2,s1
    80001e92:	6388                	ld	a0,0(a5)
    80001e94:	f17d                	bnez	a0,80001e7a <fork+0x9e>
    80001e96:	bfcd                	j	80001e88 <fork+0xac>
  np->cwd = idup(p->cwd);
    80001e98:	15093503          	ld	a0,336(s2)
    80001e9c:	00001097          	auipc	ra,0x1
    80001ea0:	752080e7          	jalr	1874(ra) # 800035ee <idup>
    80001ea4:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001ea8:	4641                	li	a2,16
    80001eaa:	15890593          	addi	a1,s2,344
    80001eae:	15898513          	addi	a0,s3,344
    80001eb2:	fffff097          	auipc	ra,0xfffff
    80001eb6:	f80080e7          	jalr	-128(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001eba:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001ebe:	854e                	mv	a0,s3
    80001ec0:	fffff097          	auipc	ra,0xfffff
    80001ec4:	dd8080e7          	jalr	-552(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001ec8:	0000f497          	auipc	s1,0xf
    80001ecc:	3f048493          	addi	s1,s1,1008 # 800112b8 <wait_lock>
    80001ed0:	8526                	mv	a0,s1
    80001ed2:	fffff097          	auipc	ra,0xfffff
    80001ed6:	d12080e7          	jalr	-750(ra) # 80000be4 <acquire>
  np->parent = p;
    80001eda:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001ede:	8526                	mv	a0,s1
    80001ee0:	fffff097          	auipc	ra,0xfffff
    80001ee4:	db8080e7          	jalr	-584(ra) # 80000c98 <release>
  acquire(&np->lock);
    80001ee8:	854e                	mv	a0,s3
    80001eea:	fffff097          	auipc	ra,0xfffff
    80001eee:	cfa080e7          	jalr	-774(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80001ef2:	478d                	li	a5,3
    80001ef4:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001ef8:	854e                	mv	a0,s3
    80001efa:	fffff097          	auipc	ra,0xfffff
    80001efe:	d9e080e7          	jalr	-610(ra) # 80000c98 <release>
}
    80001f02:	8552                	mv	a0,s4
    80001f04:	70a2                	ld	ra,40(sp)
    80001f06:	7402                	ld	s0,32(sp)
    80001f08:	64e2                	ld	s1,24(sp)
    80001f0a:	6942                	ld	s2,16(sp)
    80001f0c:	69a2                	ld	s3,8(sp)
    80001f0e:	6a02                	ld	s4,0(sp)
    80001f10:	6145                	addi	sp,sp,48
    80001f12:	8082                	ret
    return -1;
    80001f14:	5a7d                	li	s4,-1
    80001f16:	b7f5                	j	80001f02 <fork+0x126>

0000000080001f18 <scheduler>:
{
    80001f18:	7139                	addi	sp,sp,-64
    80001f1a:	fc06                	sd	ra,56(sp)
    80001f1c:	f822                	sd	s0,48(sp)
    80001f1e:	f426                	sd	s1,40(sp)
    80001f20:	f04a                	sd	s2,32(sp)
    80001f22:	ec4e                	sd	s3,24(sp)
    80001f24:	e852                	sd	s4,16(sp)
    80001f26:	e456                	sd	s5,8(sp)
    80001f28:	e05a                	sd	s6,0(sp)
    80001f2a:	0080                	addi	s0,sp,64
    80001f2c:	8792                	mv	a5,tp
  int id = r_tp();
    80001f2e:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f30:	00779a93          	slli	s5,a5,0x7
    80001f34:	0000f717          	auipc	a4,0xf
    80001f38:	36c70713          	addi	a4,a4,876 # 800112a0 <pid_lock>
    80001f3c:	9756                	add	a4,a4,s5
    80001f3e:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001f42:	0000f717          	auipc	a4,0xf
    80001f46:	39670713          	addi	a4,a4,918 # 800112d8 <cpus+0x8>
    80001f4a:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001f4c:	498d                	li	s3,3
        p->state = RUNNING;
    80001f4e:	4b11                	li	s6,4
        c->proc = p;
    80001f50:	079e                	slli	a5,a5,0x7
    80001f52:	0000fa17          	auipc	s4,0xf
    80001f56:	34ea0a13          	addi	s4,s4,846 # 800112a0 <pid_lock>
    80001f5a:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f5c:	00015917          	auipc	s2,0x15
    80001f60:	37490913          	addi	s2,s2,884 # 800172d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f64:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f68:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f6c:	10079073          	csrw	sstatus,a5
    80001f70:	0000f497          	auipc	s1,0xf
    80001f74:	76048493          	addi	s1,s1,1888 # 800116d0 <proc>
    80001f78:	a03d                	j	80001fa6 <scheduler+0x8e>
        p->state = RUNNING;
    80001f7a:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f7e:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f82:	06048593          	addi	a1,s1,96
    80001f86:	8556                	mv	a0,s5
    80001f88:	00000097          	auipc	ra,0x0
    80001f8c:	640080e7          	jalr	1600(ra) # 800025c8 <swtch>
        c->proc = 0;
    80001f90:	020a3823          	sd	zero,48(s4)
      release(&p->lock);
    80001f94:	8526                	mv	a0,s1
    80001f96:	fffff097          	auipc	ra,0xfffff
    80001f9a:	d02080e7          	jalr	-766(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f9e:	17048493          	addi	s1,s1,368
    80001fa2:	fd2481e3          	beq	s1,s2,80001f64 <scheduler+0x4c>
      acquire(&p->lock);
    80001fa6:	8526                	mv	a0,s1
    80001fa8:	fffff097          	auipc	ra,0xfffff
    80001fac:	c3c080e7          	jalr	-964(ra) # 80000be4 <acquire>
      if(p->state == RUNNABLE) {
    80001fb0:	4c9c                	lw	a5,24(s1)
    80001fb2:	ff3791e3          	bne	a5,s3,80001f94 <scheduler+0x7c>
    80001fb6:	b7d1                	j	80001f7a <scheduler+0x62>

0000000080001fb8 <sched>:
{
    80001fb8:	7179                	addi	sp,sp,-48
    80001fba:	f406                	sd	ra,40(sp)
    80001fbc:	f022                	sd	s0,32(sp)
    80001fbe:	ec26                	sd	s1,24(sp)
    80001fc0:	e84a                	sd	s2,16(sp)
    80001fc2:	e44e                	sd	s3,8(sp)
    80001fc4:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001fc6:	00000097          	auipc	ra,0x0
    80001fca:	a56080e7          	jalr	-1450(ra) # 80001a1c <myproc>
    80001fce:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001fd0:	fffff097          	auipc	ra,0xfffff
    80001fd4:	b9a080e7          	jalr	-1126(ra) # 80000b6a <holding>
    80001fd8:	c93d                	beqz	a0,8000204e <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fda:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001fdc:	2781                	sext.w	a5,a5
    80001fde:	079e                	slli	a5,a5,0x7
    80001fe0:	0000f717          	auipc	a4,0xf
    80001fe4:	2c070713          	addi	a4,a4,704 # 800112a0 <pid_lock>
    80001fe8:	97ba                	add	a5,a5,a4
    80001fea:	0a87a703          	lw	a4,168(a5)
    80001fee:	4785                	li	a5,1
    80001ff0:	06f71763          	bne	a4,a5,8000205e <sched+0xa6>
  if(p->state == RUNNING)
    80001ff4:	4c98                	lw	a4,24(s1)
    80001ff6:	4791                	li	a5,4
    80001ff8:	06f70b63          	beq	a4,a5,8000206e <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001ffc:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002000:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002002:	efb5                	bnez	a5,8000207e <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002004:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002006:	0000f917          	auipc	s2,0xf
    8000200a:	29a90913          	addi	s2,s2,666 # 800112a0 <pid_lock>
    8000200e:	2781                	sext.w	a5,a5
    80002010:	079e                	slli	a5,a5,0x7
    80002012:	97ca                	add	a5,a5,s2
    80002014:	0ac7a983          	lw	s3,172(a5)
    80002018:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000201a:	2781                	sext.w	a5,a5
    8000201c:	079e                	slli	a5,a5,0x7
    8000201e:	0000f597          	auipc	a1,0xf
    80002022:	2ba58593          	addi	a1,a1,698 # 800112d8 <cpus+0x8>
    80002026:	95be                	add	a1,a1,a5
    80002028:	06048513          	addi	a0,s1,96
    8000202c:	00000097          	auipc	ra,0x0
    80002030:	59c080e7          	jalr	1436(ra) # 800025c8 <swtch>
    80002034:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002036:	2781                	sext.w	a5,a5
    80002038:	079e                	slli	a5,a5,0x7
    8000203a:	97ca                	add	a5,a5,s2
    8000203c:	0b37a623          	sw	s3,172(a5)
}
    80002040:	70a2                	ld	ra,40(sp)
    80002042:	7402                	ld	s0,32(sp)
    80002044:	64e2                	ld	s1,24(sp)
    80002046:	6942                	ld	s2,16(sp)
    80002048:	69a2                	ld	s3,8(sp)
    8000204a:	6145                	addi	sp,sp,48
    8000204c:	8082                	ret
    panic("sched p->lock");
    8000204e:	00006517          	auipc	a0,0x6
    80002052:	1ca50513          	addi	a0,a0,458 # 80008218 <digits+0x1d8>
    80002056:	ffffe097          	auipc	ra,0xffffe
    8000205a:	4e8080e7          	jalr	1256(ra) # 8000053e <panic>
    panic("sched locks");
    8000205e:	00006517          	auipc	a0,0x6
    80002062:	1ca50513          	addi	a0,a0,458 # 80008228 <digits+0x1e8>
    80002066:	ffffe097          	auipc	ra,0xffffe
    8000206a:	4d8080e7          	jalr	1240(ra) # 8000053e <panic>
    panic("sched running");
    8000206e:	00006517          	auipc	a0,0x6
    80002072:	1ca50513          	addi	a0,a0,458 # 80008238 <digits+0x1f8>
    80002076:	ffffe097          	auipc	ra,0xffffe
    8000207a:	4c8080e7          	jalr	1224(ra) # 8000053e <panic>
    panic("sched interruptible");
    8000207e:	00006517          	auipc	a0,0x6
    80002082:	1ca50513          	addi	a0,a0,458 # 80008248 <digits+0x208>
    80002086:	ffffe097          	auipc	ra,0xffffe
    8000208a:	4b8080e7          	jalr	1208(ra) # 8000053e <panic>

000000008000208e <yield>:
{
    8000208e:	1101                	addi	sp,sp,-32
    80002090:	ec06                	sd	ra,24(sp)
    80002092:	e822                	sd	s0,16(sp)
    80002094:	e426                	sd	s1,8(sp)
    80002096:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002098:	00000097          	auipc	ra,0x0
    8000209c:	984080e7          	jalr	-1660(ra) # 80001a1c <myproc>
    800020a0:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800020a2:	fffff097          	auipc	ra,0xfffff
    800020a6:	b42080e7          	jalr	-1214(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    800020aa:	478d                	li	a5,3
    800020ac:	cc9c                	sw	a5,24(s1)
  sched();
    800020ae:	00000097          	auipc	ra,0x0
    800020b2:	f0a080e7          	jalr	-246(ra) # 80001fb8 <sched>
  release(&p->lock);
    800020b6:	8526                	mv	a0,s1
    800020b8:	fffff097          	auipc	ra,0xfffff
    800020bc:	be0080e7          	jalr	-1056(ra) # 80000c98 <release>
}
    800020c0:	60e2                	ld	ra,24(sp)
    800020c2:	6442                	ld	s0,16(sp)
    800020c4:	64a2                	ld	s1,8(sp)
    800020c6:	6105                	addi	sp,sp,32
    800020c8:	8082                	ret

00000000800020ca <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800020ca:	7179                	addi	sp,sp,-48
    800020cc:	f406                	sd	ra,40(sp)
    800020ce:	f022                	sd	s0,32(sp)
    800020d0:	ec26                	sd	s1,24(sp)
    800020d2:	e84a                	sd	s2,16(sp)
    800020d4:	e44e                	sd	s3,8(sp)
    800020d6:	1800                	addi	s0,sp,48
    800020d8:	89aa                	mv	s3,a0
    800020da:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800020dc:	00000097          	auipc	ra,0x0
    800020e0:	940080e7          	jalr	-1728(ra) # 80001a1c <myproc>
    800020e4:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    800020e6:	fffff097          	auipc	ra,0xfffff
    800020ea:	afe080e7          	jalr	-1282(ra) # 80000be4 <acquire>
  release(lk);
    800020ee:	854a                	mv	a0,s2
    800020f0:	fffff097          	auipc	ra,0xfffff
    800020f4:	ba8080e7          	jalr	-1112(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    800020f8:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800020fc:	4789                	li	a5,2
    800020fe:	cc9c                	sw	a5,24(s1)

  sched();
    80002100:	00000097          	auipc	ra,0x0
    80002104:	eb8080e7          	jalr	-328(ra) # 80001fb8 <sched>

  // Tidy up.
  p->chan = 0;
    80002108:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000210c:	8526                	mv	a0,s1
    8000210e:	fffff097          	auipc	ra,0xfffff
    80002112:	b8a080e7          	jalr	-1142(ra) # 80000c98 <release>
  acquire(lk);
    80002116:	854a                	mv	a0,s2
    80002118:	fffff097          	auipc	ra,0xfffff
    8000211c:	acc080e7          	jalr	-1332(ra) # 80000be4 <acquire>
}
    80002120:	70a2                	ld	ra,40(sp)
    80002122:	7402                	ld	s0,32(sp)
    80002124:	64e2                	ld	s1,24(sp)
    80002126:	6942                	ld	s2,16(sp)
    80002128:	69a2                	ld	s3,8(sp)
    8000212a:	6145                	addi	sp,sp,48
    8000212c:	8082                	ret

000000008000212e <wait>:
{
    8000212e:	715d                	addi	sp,sp,-80
    80002130:	e486                	sd	ra,72(sp)
    80002132:	e0a2                	sd	s0,64(sp)
    80002134:	fc26                	sd	s1,56(sp)
    80002136:	f84a                	sd	s2,48(sp)
    80002138:	f44e                	sd	s3,40(sp)
    8000213a:	f052                	sd	s4,32(sp)
    8000213c:	ec56                	sd	s5,24(sp)
    8000213e:	e85a                	sd	s6,16(sp)
    80002140:	e45e                	sd	s7,8(sp)
    80002142:	e062                	sd	s8,0(sp)
    80002144:	0880                	addi	s0,sp,80
    80002146:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002148:	00000097          	auipc	ra,0x0
    8000214c:	8d4080e7          	jalr	-1836(ra) # 80001a1c <myproc>
    80002150:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002152:	0000f517          	auipc	a0,0xf
    80002156:	16650513          	addi	a0,a0,358 # 800112b8 <wait_lock>
    8000215a:	fffff097          	auipc	ra,0xfffff
    8000215e:	a8a080e7          	jalr	-1398(ra) # 80000be4 <acquire>
    havekids = 0;
    80002162:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002164:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    80002166:	00015997          	auipc	s3,0x15
    8000216a:	16a98993          	addi	s3,s3,362 # 800172d0 <tickslock>
        havekids = 1;
    8000216e:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002170:	0000fc17          	auipc	s8,0xf
    80002174:	148c0c13          	addi	s8,s8,328 # 800112b8 <wait_lock>
    havekids = 0;
    80002178:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    8000217a:	0000f497          	auipc	s1,0xf
    8000217e:	55648493          	addi	s1,s1,1366 # 800116d0 <proc>
    80002182:	a0bd                	j	800021f0 <wait+0xc2>
          pid = np->pid;
    80002184:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002188:	000b0e63          	beqz	s6,800021a4 <wait+0x76>
    8000218c:	4691                	li	a3,4
    8000218e:	02c48613          	addi	a2,s1,44
    80002192:	85da                	mv	a1,s6
    80002194:	05093503          	ld	a0,80(s2)
    80002198:	fffff097          	auipc	ra,0xfffff
    8000219c:	4da080e7          	jalr	1242(ra) # 80001672 <copyout>
    800021a0:	02054563          	bltz	a0,800021ca <wait+0x9c>
          freeproc(np);
    800021a4:	8526                	mv	a0,s1
    800021a6:	00000097          	auipc	ra,0x0
    800021aa:	a1a080e7          	jalr	-1510(ra) # 80001bc0 <freeproc>
          release(&np->lock);
    800021ae:	8526                	mv	a0,s1
    800021b0:	fffff097          	auipc	ra,0xfffff
    800021b4:	ae8080e7          	jalr	-1304(ra) # 80000c98 <release>
          release(&wait_lock);
    800021b8:	0000f517          	auipc	a0,0xf
    800021bc:	10050513          	addi	a0,a0,256 # 800112b8 <wait_lock>
    800021c0:	fffff097          	auipc	ra,0xfffff
    800021c4:	ad8080e7          	jalr	-1320(ra) # 80000c98 <release>
          return pid;
    800021c8:	a09d                	j	8000222e <wait+0x100>
            release(&np->lock);
    800021ca:	8526                	mv	a0,s1
    800021cc:	fffff097          	auipc	ra,0xfffff
    800021d0:	acc080e7          	jalr	-1332(ra) # 80000c98 <release>
            release(&wait_lock);
    800021d4:	0000f517          	auipc	a0,0xf
    800021d8:	0e450513          	addi	a0,a0,228 # 800112b8 <wait_lock>
    800021dc:	fffff097          	auipc	ra,0xfffff
    800021e0:	abc080e7          	jalr	-1348(ra) # 80000c98 <release>
            return -1;
    800021e4:	59fd                	li	s3,-1
    800021e6:	a0a1                	j	8000222e <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    800021e8:	17048493          	addi	s1,s1,368
    800021ec:	03348463          	beq	s1,s3,80002214 <wait+0xe6>
      if(np->parent == p){
    800021f0:	7c9c                	ld	a5,56(s1)
    800021f2:	ff279be3          	bne	a5,s2,800021e8 <wait+0xba>
        acquire(&np->lock);
    800021f6:	8526                	mv	a0,s1
    800021f8:	fffff097          	auipc	ra,0xfffff
    800021fc:	9ec080e7          	jalr	-1556(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    80002200:	4c9c                	lw	a5,24(s1)
    80002202:	f94781e3          	beq	a5,s4,80002184 <wait+0x56>
        release(&np->lock);
    80002206:	8526                	mv	a0,s1
    80002208:	fffff097          	auipc	ra,0xfffff
    8000220c:	a90080e7          	jalr	-1392(ra) # 80000c98 <release>
        havekids = 1;
    80002210:	8756                	mv	a4,s5
    80002212:	bfd9                	j	800021e8 <wait+0xba>
    if(!havekids || p->killed){
    80002214:	c701                	beqz	a4,8000221c <wait+0xee>
    80002216:	02892783          	lw	a5,40(s2)
    8000221a:	c79d                	beqz	a5,80002248 <wait+0x11a>
      release(&wait_lock);
    8000221c:	0000f517          	auipc	a0,0xf
    80002220:	09c50513          	addi	a0,a0,156 # 800112b8 <wait_lock>
    80002224:	fffff097          	auipc	ra,0xfffff
    80002228:	a74080e7          	jalr	-1420(ra) # 80000c98 <release>
      return -1;
    8000222c:	59fd                	li	s3,-1
}
    8000222e:	854e                	mv	a0,s3
    80002230:	60a6                	ld	ra,72(sp)
    80002232:	6406                	ld	s0,64(sp)
    80002234:	74e2                	ld	s1,56(sp)
    80002236:	7942                	ld	s2,48(sp)
    80002238:	79a2                	ld	s3,40(sp)
    8000223a:	7a02                	ld	s4,32(sp)
    8000223c:	6ae2                	ld	s5,24(sp)
    8000223e:	6b42                	ld	s6,16(sp)
    80002240:	6ba2                	ld	s7,8(sp)
    80002242:	6c02                	ld	s8,0(sp)
    80002244:	6161                	addi	sp,sp,80
    80002246:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002248:	85e2                	mv	a1,s8
    8000224a:	854a                	mv	a0,s2
    8000224c:	00000097          	auipc	ra,0x0
    80002250:	e7e080e7          	jalr	-386(ra) # 800020ca <sleep>
    havekids = 0;
    80002254:	b715                	j	80002178 <wait+0x4a>

0000000080002256 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002256:	7139                	addi	sp,sp,-64
    80002258:	fc06                	sd	ra,56(sp)
    8000225a:	f822                	sd	s0,48(sp)
    8000225c:	f426                	sd	s1,40(sp)
    8000225e:	f04a                	sd	s2,32(sp)
    80002260:	ec4e                	sd	s3,24(sp)
    80002262:	e852                	sd	s4,16(sp)
    80002264:	e456                	sd	s5,8(sp)
    80002266:	0080                	addi	s0,sp,64
    80002268:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    8000226a:	0000f497          	auipc	s1,0xf
    8000226e:	46648493          	addi	s1,s1,1126 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002272:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002274:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002276:	00015917          	auipc	s2,0x15
    8000227a:	05a90913          	addi	s2,s2,90 # 800172d0 <tickslock>
    8000227e:	a821                	j	80002296 <wakeup+0x40>
        p->state = RUNNABLE;
    80002280:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    80002284:	8526                	mv	a0,s1
    80002286:	fffff097          	auipc	ra,0xfffff
    8000228a:	a12080e7          	jalr	-1518(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000228e:	17048493          	addi	s1,s1,368
    80002292:	03248463          	beq	s1,s2,800022ba <wakeup+0x64>
    if(p != myproc()){
    80002296:	fffff097          	auipc	ra,0xfffff
    8000229a:	786080e7          	jalr	1926(ra) # 80001a1c <myproc>
    8000229e:	fea488e3          	beq	s1,a0,8000228e <wakeup+0x38>
      acquire(&p->lock);
    800022a2:	8526                	mv	a0,s1
    800022a4:	fffff097          	auipc	ra,0xfffff
    800022a8:	940080e7          	jalr	-1728(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800022ac:	4c9c                	lw	a5,24(s1)
    800022ae:	fd379be3          	bne	a5,s3,80002284 <wakeup+0x2e>
    800022b2:	709c                	ld	a5,32(s1)
    800022b4:	fd4798e3          	bne	a5,s4,80002284 <wakeup+0x2e>
    800022b8:	b7e1                	j	80002280 <wakeup+0x2a>
    }
  }
}
    800022ba:	70e2                	ld	ra,56(sp)
    800022bc:	7442                	ld	s0,48(sp)
    800022be:	74a2                	ld	s1,40(sp)
    800022c0:	7902                	ld	s2,32(sp)
    800022c2:	69e2                	ld	s3,24(sp)
    800022c4:	6a42                	ld	s4,16(sp)
    800022c6:	6aa2                	ld	s5,8(sp)
    800022c8:	6121                	addi	sp,sp,64
    800022ca:	8082                	ret

00000000800022cc <reparent>:
{
    800022cc:	7179                	addi	sp,sp,-48
    800022ce:	f406                	sd	ra,40(sp)
    800022d0:	f022                	sd	s0,32(sp)
    800022d2:	ec26                	sd	s1,24(sp)
    800022d4:	e84a                	sd	s2,16(sp)
    800022d6:	e44e                	sd	s3,8(sp)
    800022d8:	e052                	sd	s4,0(sp)
    800022da:	1800                	addi	s0,sp,48
    800022dc:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800022de:	0000f497          	auipc	s1,0xf
    800022e2:	3f248493          	addi	s1,s1,1010 # 800116d0 <proc>
      pp->parent = initproc;
    800022e6:	00007a17          	auipc	s4,0x7
    800022ea:	d42a0a13          	addi	s4,s4,-702 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800022ee:	00015997          	auipc	s3,0x15
    800022f2:	fe298993          	addi	s3,s3,-30 # 800172d0 <tickslock>
    800022f6:	a029                	j	80002300 <reparent+0x34>
    800022f8:	17048493          	addi	s1,s1,368
    800022fc:	01348d63          	beq	s1,s3,80002316 <reparent+0x4a>
    if(pp->parent == p){
    80002300:	7c9c                	ld	a5,56(s1)
    80002302:	ff279be3          	bne	a5,s2,800022f8 <reparent+0x2c>
      pp->parent = initproc;
    80002306:	000a3503          	ld	a0,0(s4)
    8000230a:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000230c:	00000097          	auipc	ra,0x0
    80002310:	f4a080e7          	jalr	-182(ra) # 80002256 <wakeup>
    80002314:	b7d5                	j	800022f8 <reparent+0x2c>
}
    80002316:	70a2                	ld	ra,40(sp)
    80002318:	7402                	ld	s0,32(sp)
    8000231a:	64e2                	ld	s1,24(sp)
    8000231c:	6942                	ld	s2,16(sp)
    8000231e:	69a2                	ld	s3,8(sp)
    80002320:	6a02                	ld	s4,0(sp)
    80002322:	6145                	addi	sp,sp,48
    80002324:	8082                	ret

0000000080002326 <exit>:
{
    80002326:	7179                	addi	sp,sp,-48
    80002328:	f406                	sd	ra,40(sp)
    8000232a:	f022                	sd	s0,32(sp)
    8000232c:	ec26                	sd	s1,24(sp)
    8000232e:	e84a                	sd	s2,16(sp)
    80002330:	e44e                	sd	s3,8(sp)
    80002332:	e052                	sd	s4,0(sp)
    80002334:	1800                	addi	s0,sp,48
    80002336:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002338:	fffff097          	auipc	ra,0xfffff
    8000233c:	6e4080e7          	jalr	1764(ra) # 80001a1c <myproc>
    80002340:	89aa                	mv	s3,a0
  if(p == initproc)
    80002342:	00007797          	auipc	a5,0x7
    80002346:	ce67b783          	ld	a5,-794(a5) # 80009028 <initproc>
    8000234a:	0d050493          	addi	s1,a0,208
    8000234e:	15050913          	addi	s2,a0,336
    80002352:	02a79363          	bne	a5,a0,80002378 <exit+0x52>
    panic("init exiting");
    80002356:	00006517          	auipc	a0,0x6
    8000235a:	f0a50513          	addi	a0,a0,-246 # 80008260 <digits+0x220>
    8000235e:	ffffe097          	auipc	ra,0xffffe
    80002362:	1e0080e7          	jalr	480(ra) # 8000053e <panic>
      fileclose(f);
    80002366:	00002097          	auipc	ra,0x2
    8000236a:	164080e7          	jalr	356(ra) # 800044ca <fileclose>
      p->ofile[fd] = 0;
    8000236e:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002372:	04a1                	addi	s1,s1,8
    80002374:	01248563          	beq	s1,s2,8000237e <exit+0x58>
    if(p->ofile[fd]){
    80002378:	6088                	ld	a0,0(s1)
    8000237a:	f575                	bnez	a0,80002366 <exit+0x40>
    8000237c:	bfdd                	j	80002372 <exit+0x4c>
  begin_op();
    8000237e:	00002097          	auipc	ra,0x2
    80002382:	c80080e7          	jalr	-896(ra) # 80003ffe <begin_op>
  iput(p->cwd);
    80002386:	1509b503          	ld	a0,336(s3)
    8000238a:	00001097          	auipc	ra,0x1
    8000238e:	45c080e7          	jalr	1116(ra) # 800037e6 <iput>
  end_op();
    80002392:	00002097          	auipc	ra,0x2
    80002396:	cec080e7          	jalr	-788(ra) # 8000407e <end_op>
  p->cwd = 0;
    8000239a:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000239e:	0000f497          	auipc	s1,0xf
    800023a2:	f1a48493          	addi	s1,s1,-230 # 800112b8 <wait_lock>
    800023a6:	8526                	mv	a0,s1
    800023a8:	fffff097          	auipc	ra,0xfffff
    800023ac:	83c080e7          	jalr	-1988(ra) # 80000be4 <acquire>
  reparent(p);
    800023b0:	854e                	mv	a0,s3
    800023b2:	00000097          	auipc	ra,0x0
    800023b6:	f1a080e7          	jalr	-230(ra) # 800022cc <reparent>
  wakeup(p->parent);
    800023ba:	0389b503          	ld	a0,56(s3)
    800023be:	00000097          	auipc	ra,0x0
    800023c2:	e98080e7          	jalr	-360(ra) # 80002256 <wakeup>
  acquire(&p->lock);
    800023c6:	854e                	mv	a0,s3
    800023c8:	fffff097          	auipc	ra,0xfffff
    800023cc:	81c080e7          	jalr	-2020(ra) # 80000be4 <acquire>
  p->xstate = status;
    800023d0:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800023d4:	4795                	li	a5,5
    800023d6:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800023da:	8526                	mv	a0,s1
    800023dc:	fffff097          	auipc	ra,0xfffff
    800023e0:	8bc080e7          	jalr	-1860(ra) # 80000c98 <release>
  sched();
    800023e4:	00000097          	auipc	ra,0x0
    800023e8:	bd4080e7          	jalr	-1068(ra) # 80001fb8 <sched>
  panic("zombie exit");
    800023ec:	00006517          	auipc	a0,0x6
    800023f0:	e8450513          	addi	a0,a0,-380 # 80008270 <digits+0x230>
    800023f4:	ffffe097          	auipc	ra,0xffffe
    800023f8:	14a080e7          	jalr	330(ra) # 8000053e <panic>

00000000800023fc <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800023fc:	7179                	addi	sp,sp,-48
    800023fe:	f406                	sd	ra,40(sp)
    80002400:	f022                	sd	s0,32(sp)
    80002402:	ec26                	sd	s1,24(sp)
    80002404:	e84a                	sd	s2,16(sp)
    80002406:	e44e                	sd	s3,8(sp)
    80002408:	1800                	addi	s0,sp,48
    8000240a:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000240c:	0000f497          	auipc	s1,0xf
    80002410:	2c448493          	addi	s1,s1,708 # 800116d0 <proc>
    80002414:	00015997          	auipc	s3,0x15
    80002418:	ebc98993          	addi	s3,s3,-324 # 800172d0 <tickslock>
    acquire(&p->lock);
    8000241c:	8526                	mv	a0,s1
    8000241e:	ffffe097          	auipc	ra,0xffffe
    80002422:	7c6080e7          	jalr	1990(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    80002426:	589c                	lw	a5,48(s1)
    80002428:	01278d63          	beq	a5,s2,80002442 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000242c:	8526                	mv	a0,s1
    8000242e:	fffff097          	auipc	ra,0xfffff
    80002432:	86a080e7          	jalr	-1942(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002436:	17048493          	addi	s1,s1,368
    8000243a:	ff3491e3          	bne	s1,s3,8000241c <kill+0x20>
  }
  return -1;
    8000243e:	557d                	li	a0,-1
    80002440:	a829                	j	8000245a <kill+0x5e>
      p->killed = 1;
    80002442:	4785                	li	a5,1
    80002444:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002446:	4c98                	lw	a4,24(s1)
    80002448:	4789                	li	a5,2
    8000244a:	00f70f63          	beq	a4,a5,80002468 <kill+0x6c>
      release(&p->lock);
    8000244e:	8526                	mv	a0,s1
    80002450:	fffff097          	auipc	ra,0xfffff
    80002454:	848080e7          	jalr	-1976(ra) # 80000c98 <release>
      return 0;
    80002458:	4501                	li	a0,0
}
    8000245a:	70a2                	ld	ra,40(sp)
    8000245c:	7402                	ld	s0,32(sp)
    8000245e:	64e2                	ld	s1,24(sp)
    80002460:	6942                	ld	s2,16(sp)
    80002462:	69a2                	ld	s3,8(sp)
    80002464:	6145                	addi	sp,sp,48
    80002466:	8082                	ret
        p->state = RUNNABLE;
    80002468:	478d                	li	a5,3
    8000246a:	cc9c                	sw	a5,24(s1)
    8000246c:	b7cd                	j	8000244e <kill+0x52>

000000008000246e <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000246e:	7179                	addi	sp,sp,-48
    80002470:	f406                	sd	ra,40(sp)
    80002472:	f022                	sd	s0,32(sp)
    80002474:	ec26                	sd	s1,24(sp)
    80002476:	e84a                	sd	s2,16(sp)
    80002478:	e44e                	sd	s3,8(sp)
    8000247a:	e052                	sd	s4,0(sp)
    8000247c:	1800                	addi	s0,sp,48
    8000247e:	84aa                	mv	s1,a0
    80002480:	892e                	mv	s2,a1
    80002482:	89b2                	mv	s3,a2
    80002484:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002486:	fffff097          	auipc	ra,0xfffff
    8000248a:	596080e7          	jalr	1430(ra) # 80001a1c <myproc>
  if(user_dst){
    8000248e:	c08d                	beqz	s1,800024b0 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002490:	86d2                	mv	a3,s4
    80002492:	864e                	mv	a2,s3
    80002494:	85ca                	mv	a1,s2
    80002496:	6928                	ld	a0,80(a0)
    80002498:	fffff097          	auipc	ra,0xfffff
    8000249c:	1da080e7          	jalr	474(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024a0:	70a2                	ld	ra,40(sp)
    800024a2:	7402                	ld	s0,32(sp)
    800024a4:	64e2                	ld	s1,24(sp)
    800024a6:	6942                	ld	s2,16(sp)
    800024a8:	69a2                	ld	s3,8(sp)
    800024aa:	6a02                	ld	s4,0(sp)
    800024ac:	6145                	addi	sp,sp,48
    800024ae:	8082                	ret
    memmove((char *)dst, src, len);
    800024b0:	000a061b          	sext.w	a2,s4
    800024b4:	85ce                	mv	a1,s3
    800024b6:	854a                	mv	a0,s2
    800024b8:	fffff097          	auipc	ra,0xfffff
    800024bc:	888080e7          	jalr	-1912(ra) # 80000d40 <memmove>
    return 0;
    800024c0:	8526                	mv	a0,s1
    800024c2:	bff9                	j	800024a0 <either_copyout+0x32>

00000000800024c4 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024c4:	7179                	addi	sp,sp,-48
    800024c6:	f406                	sd	ra,40(sp)
    800024c8:	f022                	sd	s0,32(sp)
    800024ca:	ec26                	sd	s1,24(sp)
    800024cc:	e84a                	sd	s2,16(sp)
    800024ce:	e44e                	sd	s3,8(sp)
    800024d0:	e052                	sd	s4,0(sp)
    800024d2:	1800                	addi	s0,sp,48
    800024d4:	892a                	mv	s2,a0
    800024d6:	84ae                	mv	s1,a1
    800024d8:	89b2                	mv	s3,a2
    800024da:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024dc:	fffff097          	auipc	ra,0xfffff
    800024e0:	540080e7          	jalr	1344(ra) # 80001a1c <myproc>
  if(user_src){
    800024e4:	c08d                	beqz	s1,80002506 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800024e6:	86d2                	mv	a3,s4
    800024e8:	864e                	mv	a2,s3
    800024ea:	85ca                	mv	a1,s2
    800024ec:	6928                	ld	a0,80(a0)
    800024ee:	fffff097          	auipc	ra,0xfffff
    800024f2:	210080e7          	jalr	528(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800024f6:	70a2                	ld	ra,40(sp)
    800024f8:	7402                	ld	s0,32(sp)
    800024fa:	64e2                	ld	s1,24(sp)
    800024fc:	6942                	ld	s2,16(sp)
    800024fe:	69a2                	ld	s3,8(sp)
    80002500:	6a02                	ld	s4,0(sp)
    80002502:	6145                	addi	sp,sp,48
    80002504:	8082                	ret
    memmove(dst, (char*)src, len);
    80002506:	000a061b          	sext.w	a2,s4
    8000250a:	85ce                	mv	a1,s3
    8000250c:	854a                	mv	a0,s2
    8000250e:	fffff097          	auipc	ra,0xfffff
    80002512:	832080e7          	jalr	-1998(ra) # 80000d40 <memmove>
    return 0;
    80002516:	8526                	mv	a0,s1
    80002518:	bff9                	j	800024f6 <either_copyin+0x32>

000000008000251a <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000251a:	715d                	addi	sp,sp,-80
    8000251c:	e486                	sd	ra,72(sp)
    8000251e:	e0a2                	sd	s0,64(sp)
    80002520:	fc26                	sd	s1,56(sp)
    80002522:	f84a                	sd	s2,48(sp)
    80002524:	f44e                	sd	s3,40(sp)
    80002526:	f052                	sd	s4,32(sp)
    80002528:	ec56                	sd	s5,24(sp)
    8000252a:	e85a                	sd	s6,16(sp)
    8000252c:	e45e                	sd	s7,8(sp)
    8000252e:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002530:	00006517          	auipc	a0,0x6
    80002534:	b9850513          	addi	a0,a0,-1128 # 800080c8 <digits+0x88>
    80002538:	ffffe097          	auipc	ra,0xffffe
    8000253c:	050080e7          	jalr	80(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002540:	0000f497          	auipc	s1,0xf
    80002544:	2e848493          	addi	s1,s1,744 # 80011828 <proc+0x158>
    80002548:	00015917          	auipc	s2,0x15
    8000254c:	ee090913          	addi	s2,s2,-288 # 80017428 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002550:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002552:	00006997          	auipc	s3,0x6
    80002556:	d2e98993          	addi	s3,s3,-722 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    8000255a:	00006a97          	auipc	s5,0x6
    8000255e:	d2ea8a93          	addi	s5,s5,-722 # 80008288 <digits+0x248>
    printf("\n");
    80002562:	00006a17          	auipc	s4,0x6
    80002566:	b66a0a13          	addi	s4,s4,-1178 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000256a:	00006b97          	auipc	s7,0x6
    8000256e:	d56b8b93          	addi	s7,s7,-682 # 800082c0 <states.1731>
    80002572:	a00d                	j	80002594 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002574:	ed86a583          	lw	a1,-296(a3)
    80002578:	8556                	mv	a0,s5
    8000257a:	ffffe097          	auipc	ra,0xffffe
    8000257e:	00e080e7          	jalr	14(ra) # 80000588 <printf>
    printf("\n");
    80002582:	8552                	mv	a0,s4
    80002584:	ffffe097          	auipc	ra,0xffffe
    80002588:	004080e7          	jalr	4(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000258c:	17048493          	addi	s1,s1,368
    80002590:	03248163          	beq	s1,s2,800025b2 <procdump+0x98>
    if(p->state == UNUSED)
    80002594:	86a6                	mv	a3,s1
    80002596:	ec04a783          	lw	a5,-320(s1)
    8000259a:	dbed                	beqz	a5,8000258c <procdump+0x72>
      state = "???";
    8000259c:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000259e:	fcfb6be3          	bltu	s6,a5,80002574 <procdump+0x5a>
    800025a2:	1782                	slli	a5,a5,0x20
    800025a4:	9381                	srli	a5,a5,0x20
    800025a6:	078e                	slli	a5,a5,0x3
    800025a8:	97de                	add	a5,a5,s7
    800025aa:	6390                	ld	a2,0(a5)
    800025ac:	f661                	bnez	a2,80002574 <procdump+0x5a>
      state = "???";
    800025ae:	864e                	mv	a2,s3
    800025b0:	b7d1                	j	80002574 <procdump+0x5a>
  }
}
    800025b2:	60a6                	ld	ra,72(sp)
    800025b4:	6406                	ld	s0,64(sp)
    800025b6:	74e2                	ld	s1,56(sp)
    800025b8:	7942                	ld	s2,48(sp)
    800025ba:	79a2                	ld	s3,40(sp)
    800025bc:	7a02                	ld	s4,32(sp)
    800025be:	6ae2                	ld	s5,24(sp)
    800025c0:	6b42                	ld	s6,16(sp)
    800025c2:	6ba2                	ld	s7,8(sp)
    800025c4:	6161                	addi	sp,sp,80
    800025c6:	8082                	ret

00000000800025c8 <swtch>:
    800025c8:	00153023          	sd	ra,0(a0)
    800025cc:	00253423          	sd	sp,8(a0)
    800025d0:	e900                	sd	s0,16(a0)
    800025d2:	ed04                	sd	s1,24(a0)
    800025d4:	03253023          	sd	s2,32(a0)
    800025d8:	03353423          	sd	s3,40(a0)
    800025dc:	03453823          	sd	s4,48(a0)
    800025e0:	03553c23          	sd	s5,56(a0)
    800025e4:	05653023          	sd	s6,64(a0)
    800025e8:	05753423          	sd	s7,72(a0)
    800025ec:	05853823          	sd	s8,80(a0)
    800025f0:	05953c23          	sd	s9,88(a0)
    800025f4:	07a53023          	sd	s10,96(a0)
    800025f8:	07b53423          	sd	s11,104(a0)
    800025fc:	0005b083          	ld	ra,0(a1)
    80002600:	0085b103          	ld	sp,8(a1)
    80002604:	6980                	ld	s0,16(a1)
    80002606:	6d84                	ld	s1,24(a1)
    80002608:	0205b903          	ld	s2,32(a1)
    8000260c:	0285b983          	ld	s3,40(a1)
    80002610:	0305ba03          	ld	s4,48(a1)
    80002614:	0385ba83          	ld	s5,56(a1)
    80002618:	0405bb03          	ld	s6,64(a1)
    8000261c:	0485bb83          	ld	s7,72(a1)
    80002620:	0505bc03          	ld	s8,80(a1)
    80002624:	0585bc83          	ld	s9,88(a1)
    80002628:	0605bd03          	ld	s10,96(a1)
    8000262c:	0685bd83          	ld	s11,104(a1)
    80002630:	8082                	ret

0000000080002632 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002632:	1141                	addi	sp,sp,-16
    80002634:	e406                	sd	ra,8(sp)
    80002636:	e022                	sd	s0,0(sp)
    80002638:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000263a:	00006597          	auipc	a1,0x6
    8000263e:	cb658593          	addi	a1,a1,-842 # 800082f0 <states.1731+0x30>
    80002642:	00015517          	auipc	a0,0x15
    80002646:	c8e50513          	addi	a0,a0,-882 # 800172d0 <tickslock>
    8000264a:	ffffe097          	auipc	ra,0xffffe
    8000264e:	50a080e7          	jalr	1290(ra) # 80000b54 <initlock>
}
    80002652:	60a2                	ld	ra,8(sp)
    80002654:	6402                	ld	s0,0(sp)
    80002656:	0141                	addi	sp,sp,16
    80002658:	8082                	ret

000000008000265a <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000265a:	1141                	addi	sp,sp,-16
    8000265c:	e422                	sd	s0,8(sp)
    8000265e:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002660:	00003797          	auipc	a5,0x3
    80002664:	48078793          	addi	a5,a5,1152 # 80005ae0 <kernelvec>
    80002668:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000266c:	6422                	ld	s0,8(sp)
    8000266e:	0141                	addi	sp,sp,16
    80002670:	8082                	ret

0000000080002672 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002672:	1141                	addi	sp,sp,-16
    80002674:	e406                	sd	ra,8(sp)
    80002676:	e022                	sd	s0,0(sp)
    80002678:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000267a:	fffff097          	auipc	ra,0xfffff
    8000267e:	3a2080e7          	jalr	930(ra) # 80001a1c <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002682:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002686:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002688:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000268c:	00005617          	auipc	a2,0x5
    80002690:	97460613          	addi	a2,a2,-1676 # 80007000 <_trampoline>
    80002694:	00005697          	auipc	a3,0x5
    80002698:	96c68693          	addi	a3,a3,-1684 # 80007000 <_trampoline>
    8000269c:	8e91                	sub	a3,a3,a2
    8000269e:	040007b7          	lui	a5,0x4000
    800026a2:	17fd                	addi	a5,a5,-1
    800026a4:	07b2                	slli	a5,a5,0xc
    800026a6:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026a8:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800026ac:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800026ae:	180026f3          	csrr	a3,satp
    800026b2:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800026b4:	6d38                	ld	a4,88(a0)
    800026b6:	6134                	ld	a3,64(a0)
    800026b8:	6585                	lui	a1,0x1
    800026ba:	96ae                	add	a3,a3,a1
    800026bc:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800026be:	6d38                	ld	a4,88(a0)
    800026c0:	00000697          	auipc	a3,0x0
    800026c4:	13868693          	addi	a3,a3,312 # 800027f8 <usertrap>
    800026c8:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800026ca:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800026cc:	8692                	mv	a3,tp
    800026ce:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026d0:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800026d4:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800026d8:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026dc:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800026e0:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800026e2:	6f18                	ld	a4,24(a4)
    800026e4:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800026e8:	692c                	ld	a1,80(a0)
    800026ea:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800026ec:	00005717          	auipc	a4,0x5
    800026f0:	9a470713          	addi	a4,a4,-1628 # 80007090 <userret>
    800026f4:	8f11                	sub	a4,a4,a2
    800026f6:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800026f8:	577d                	li	a4,-1
    800026fa:	177e                	slli	a4,a4,0x3f
    800026fc:	8dd9                	or	a1,a1,a4
    800026fe:	02000537          	lui	a0,0x2000
    80002702:	157d                	addi	a0,a0,-1
    80002704:	0536                	slli	a0,a0,0xd
    80002706:	9782                	jalr	a5
}
    80002708:	60a2                	ld	ra,8(sp)
    8000270a:	6402                	ld	s0,0(sp)
    8000270c:	0141                	addi	sp,sp,16
    8000270e:	8082                	ret

0000000080002710 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002710:	1101                	addi	sp,sp,-32
    80002712:	ec06                	sd	ra,24(sp)
    80002714:	e822                	sd	s0,16(sp)
    80002716:	e426                	sd	s1,8(sp)
    80002718:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    8000271a:	00015497          	auipc	s1,0x15
    8000271e:	bb648493          	addi	s1,s1,-1098 # 800172d0 <tickslock>
    80002722:	8526                	mv	a0,s1
    80002724:	ffffe097          	auipc	ra,0xffffe
    80002728:	4c0080e7          	jalr	1216(ra) # 80000be4 <acquire>
  ticks++;
    8000272c:	00007517          	auipc	a0,0x7
    80002730:	90450513          	addi	a0,a0,-1788 # 80009030 <ticks>
    80002734:	411c                	lw	a5,0(a0)
    80002736:	2785                	addiw	a5,a5,1
    80002738:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    8000273a:	00000097          	auipc	ra,0x0
    8000273e:	b1c080e7          	jalr	-1252(ra) # 80002256 <wakeup>
  release(&tickslock);
    80002742:	8526                	mv	a0,s1
    80002744:	ffffe097          	auipc	ra,0xffffe
    80002748:	554080e7          	jalr	1364(ra) # 80000c98 <release>
}
    8000274c:	60e2                	ld	ra,24(sp)
    8000274e:	6442                	ld	s0,16(sp)
    80002750:	64a2                	ld	s1,8(sp)
    80002752:	6105                	addi	sp,sp,32
    80002754:	8082                	ret

0000000080002756 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002756:	1101                	addi	sp,sp,-32
    80002758:	ec06                	sd	ra,24(sp)
    8000275a:	e822                	sd	s0,16(sp)
    8000275c:	e426                	sd	s1,8(sp)
    8000275e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002760:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002764:	00074d63          	bltz	a4,8000277e <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002768:	57fd                	li	a5,-1
    8000276a:	17fe                	slli	a5,a5,0x3f
    8000276c:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000276e:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002770:	06f70363          	beq	a4,a5,800027d6 <devintr+0x80>
  }
}
    80002774:	60e2                	ld	ra,24(sp)
    80002776:	6442                	ld	s0,16(sp)
    80002778:	64a2                	ld	s1,8(sp)
    8000277a:	6105                	addi	sp,sp,32
    8000277c:	8082                	ret
     (scause & 0xff) == 9){
    8000277e:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002782:	46a5                	li	a3,9
    80002784:	fed792e3          	bne	a5,a3,80002768 <devintr+0x12>
    int irq = plic_claim();
    80002788:	00003097          	auipc	ra,0x3
    8000278c:	460080e7          	jalr	1120(ra) # 80005be8 <plic_claim>
    80002790:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002792:	47a9                	li	a5,10
    80002794:	02f50763          	beq	a0,a5,800027c2 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002798:	4785                	li	a5,1
    8000279a:	02f50963          	beq	a0,a5,800027cc <devintr+0x76>
    return 1;
    8000279e:	4505                	li	a0,1
    } else if(irq){
    800027a0:	d8f1                	beqz	s1,80002774 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800027a2:	85a6                	mv	a1,s1
    800027a4:	00006517          	auipc	a0,0x6
    800027a8:	b5450513          	addi	a0,a0,-1196 # 800082f8 <states.1731+0x38>
    800027ac:	ffffe097          	auipc	ra,0xffffe
    800027b0:	ddc080e7          	jalr	-548(ra) # 80000588 <printf>
      plic_complete(irq);
    800027b4:	8526                	mv	a0,s1
    800027b6:	00003097          	auipc	ra,0x3
    800027ba:	456080e7          	jalr	1110(ra) # 80005c0c <plic_complete>
    return 1;
    800027be:	4505                	li	a0,1
    800027c0:	bf55                	j	80002774 <devintr+0x1e>
      uartintr();
    800027c2:	ffffe097          	auipc	ra,0xffffe
    800027c6:	1e6080e7          	jalr	486(ra) # 800009a8 <uartintr>
    800027ca:	b7ed                	j	800027b4 <devintr+0x5e>
      virtio_disk_intr();
    800027cc:	00004097          	auipc	ra,0x4
    800027d0:	920080e7          	jalr	-1760(ra) # 800060ec <virtio_disk_intr>
    800027d4:	b7c5                	j	800027b4 <devintr+0x5e>
    if(cpuid() == 0){
    800027d6:	fffff097          	auipc	ra,0xfffff
    800027da:	21a080e7          	jalr	538(ra) # 800019f0 <cpuid>
    800027de:	c901                	beqz	a0,800027ee <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800027e0:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800027e4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800027e6:	14479073          	csrw	sip,a5
    return 2;
    800027ea:	4509                	li	a0,2
    800027ec:	b761                	j	80002774 <devintr+0x1e>
      clockintr();
    800027ee:	00000097          	auipc	ra,0x0
    800027f2:	f22080e7          	jalr	-222(ra) # 80002710 <clockintr>
    800027f6:	b7ed                	j	800027e0 <devintr+0x8a>

00000000800027f8 <usertrap>:
{
    800027f8:	1101                	addi	sp,sp,-32
    800027fa:	ec06                	sd	ra,24(sp)
    800027fc:	e822                	sd	s0,16(sp)
    800027fe:	e426                	sd	s1,8(sp)
    80002800:	e04a                	sd	s2,0(sp)
    80002802:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002804:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002808:	1007f793          	andi	a5,a5,256
    8000280c:	e3ad                	bnez	a5,8000286e <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000280e:	00003797          	auipc	a5,0x3
    80002812:	2d278793          	addi	a5,a5,722 # 80005ae0 <kernelvec>
    80002816:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    8000281a:	fffff097          	auipc	ra,0xfffff
    8000281e:	202080e7          	jalr	514(ra) # 80001a1c <myproc>
    80002822:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002824:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002826:	14102773          	csrr	a4,sepc
    8000282a:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000282c:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002830:	47a1                	li	a5,8
    80002832:	04f71c63          	bne	a4,a5,8000288a <usertrap+0x92>
    if(p->killed)
    80002836:	551c                	lw	a5,40(a0)
    80002838:	e3b9                	bnez	a5,8000287e <usertrap+0x86>
    p->trapframe->epc += 4;
    8000283a:	6cb8                	ld	a4,88(s1)
    8000283c:	6f1c                	ld	a5,24(a4)
    8000283e:	0791                	addi	a5,a5,4
    80002840:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002842:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002846:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000284a:	10079073          	csrw	sstatus,a5
    syscall();
    8000284e:	00000097          	auipc	ra,0x0
    80002852:	2e0080e7          	jalr	736(ra) # 80002b2e <syscall>
  if(p->killed)
    80002856:	549c                	lw	a5,40(s1)
    80002858:	ebc1                	bnez	a5,800028e8 <usertrap+0xf0>
  usertrapret();
    8000285a:	00000097          	auipc	ra,0x0
    8000285e:	e18080e7          	jalr	-488(ra) # 80002672 <usertrapret>
}
    80002862:	60e2                	ld	ra,24(sp)
    80002864:	6442                	ld	s0,16(sp)
    80002866:	64a2                	ld	s1,8(sp)
    80002868:	6902                	ld	s2,0(sp)
    8000286a:	6105                	addi	sp,sp,32
    8000286c:	8082                	ret
    panic("usertrap: not from user mode");
    8000286e:	00006517          	auipc	a0,0x6
    80002872:	aaa50513          	addi	a0,a0,-1366 # 80008318 <states.1731+0x58>
    80002876:	ffffe097          	auipc	ra,0xffffe
    8000287a:	cc8080e7          	jalr	-824(ra) # 8000053e <panic>
      exit(-1);
    8000287e:	557d                	li	a0,-1
    80002880:	00000097          	auipc	ra,0x0
    80002884:	aa6080e7          	jalr	-1370(ra) # 80002326 <exit>
    80002888:	bf4d                	j	8000283a <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    8000288a:	00000097          	auipc	ra,0x0
    8000288e:	ecc080e7          	jalr	-308(ra) # 80002756 <devintr>
    80002892:	892a                	mv	s2,a0
    80002894:	c501                	beqz	a0,8000289c <usertrap+0xa4>
  if(p->killed)
    80002896:	549c                	lw	a5,40(s1)
    80002898:	c3a1                	beqz	a5,800028d8 <usertrap+0xe0>
    8000289a:	a815                	j	800028ce <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000289c:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800028a0:	5890                	lw	a2,48(s1)
    800028a2:	00006517          	auipc	a0,0x6
    800028a6:	a9650513          	addi	a0,a0,-1386 # 80008338 <states.1731+0x78>
    800028aa:	ffffe097          	auipc	ra,0xffffe
    800028ae:	cde080e7          	jalr	-802(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028b2:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800028b6:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800028ba:	00006517          	auipc	a0,0x6
    800028be:	aae50513          	addi	a0,a0,-1362 # 80008368 <states.1731+0xa8>
    800028c2:	ffffe097          	auipc	ra,0xffffe
    800028c6:	cc6080e7          	jalr	-826(ra) # 80000588 <printf>
    p->killed = 1;
    800028ca:	4785                	li	a5,1
    800028cc:	d49c                	sw	a5,40(s1)
    exit(-1);
    800028ce:	557d                	li	a0,-1
    800028d0:	00000097          	auipc	ra,0x0
    800028d4:	a56080e7          	jalr	-1450(ra) # 80002326 <exit>
  if(which_dev == 2)
    800028d8:	4789                	li	a5,2
    800028da:	f8f910e3          	bne	s2,a5,8000285a <usertrap+0x62>
    yield();
    800028de:	fffff097          	auipc	ra,0xfffff
    800028e2:	7b0080e7          	jalr	1968(ra) # 8000208e <yield>
    800028e6:	bf95                	j	8000285a <usertrap+0x62>
  int which_dev = 0;
    800028e8:	4901                	li	s2,0
    800028ea:	b7d5                	j	800028ce <usertrap+0xd6>

00000000800028ec <kerneltrap>:
{
    800028ec:	7179                	addi	sp,sp,-48
    800028ee:	f406                	sd	ra,40(sp)
    800028f0:	f022                	sd	s0,32(sp)
    800028f2:	ec26                	sd	s1,24(sp)
    800028f4:	e84a                	sd	s2,16(sp)
    800028f6:	e44e                	sd	s3,8(sp)
    800028f8:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028fa:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028fe:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002902:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002906:	1004f793          	andi	a5,s1,256
    8000290a:	cb85                	beqz	a5,8000293a <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000290c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002910:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002912:	ef85                	bnez	a5,8000294a <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002914:	00000097          	auipc	ra,0x0
    80002918:	e42080e7          	jalr	-446(ra) # 80002756 <devintr>
    8000291c:	cd1d                	beqz	a0,8000295a <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000291e:	4789                	li	a5,2
    80002920:	06f50a63          	beq	a0,a5,80002994 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002924:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002928:	10049073          	csrw	sstatus,s1
}
    8000292c:	70a2                	ld	ra,40(sp)
    8000292e:	7402                	ld	s0,32(sp)
    80002930:	64e2                	ld	s1,24(sp)
    80002932:	6942                	ld	s2,16(sp)
    80002934:	69a2                	ld	s3,8(sp)
    80002936:	6145                	addi	sp,sp,48
    80002938:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    8000293a:	00006517          	auipc	a0,0x6
    8000293e:	a4e50513          	addi	a0,a0,-1458 # 80008388 <states.1731+0xc8>
    80002942:	ffffe097          	auipc	ra,0xffffe
    80002946:	bfc080e7          	jalr	-1028(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    8000294a:	00006517          	auipc	a0,0x6
    8000294e:	a6650513          	addi	a0,a0,-1434 # 800083b0 <states.1731+0xf0>
    80002952:	ffffe097          	auipc	ra,0xffffe
    80002956:	bec080e7          	jalr	-1044(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    8000295a:	85ce                	mv	a1,s3
    8000295c:	00006517          	auipc	a0,0x6
    80002960:	a7450513          	addi	a0,a0,-1420 # 800083d0 <states.1731+0x110>
    80002964:	ffffe097          	auipc	ra,0xffffe
    80002968:	c24080e7          	jalr	-988(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000296c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002970:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002974:	00006517          	auipc	a0,0x6
    80002978:	a6c50513          	addi	a0,a0,-1428 # 800083e0 <states.1731+0x120>
    8000297c:	ffffe097          	auipc	ra,0xffffe
    80002980:	c0c080e7          	jalr	-1012(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002984:	00006517          	auipc	a0,0x6
    80002988:	a7450513          	addi	a0,a0,-1420 # 800083f8 <states.1731+0x138>
    8000298c:	ffffe097          	auipc	ra,0xffffe
    80002990:	bb2080e7          	jalr	-1102(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002994:	fffff097          	auipc	ra,0xfffff
    80002998:	088080e7          	jalr	136(ra) # 80001a1c <myproc>
    8000299c:	d541                	beqz	a0,80002924 <kerneltrap+0x38>
    8000299e:	fffff097          	auipc	ra,0xfffff
    800029a2:	07e080e7          	jalr	126(ra) # 80001a1c <myproc>
    800029a6:	4d18                	lw	a4,24(a0)
    800029a8:	4791                	li	a5,4
    800029aa:	f6f71de3          	bne	a4,a5,80002924 <kerneltrap+0x38>
    yield();
    800029ae:	fffff097          	auipc	ra,0xfffff
    800029b2:	6e0080e7          	jalr	1760(ra) # 8000208e <yield>
    800029b6:	b7bd                	j	80002924 <kerneltrap+0x38>

00000000800029b8 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800029b8:	1101                	addi	sp,sp,-32
    800029ba:	ec06                	sd	ra,24(sp)
    800029bc:	e822                	sd	s0,16(sp)
    800029be:	e426                	sd	s1,8(sp)
    800029c0:	1000                	addi	s0,sp,32
    800029c2:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800029c4:	fffff097          	auipc	ra,0xfffff
    800029c8:	058080e7          	jalr	88(ra) # 80001a1c <myproc>
  switch (n) {
    800029cc:	4795                	li	a5,5
    800029ce:	0497e163          	bltu	a5,s1,80002a10 <argraw+0x58>
    800029d2:	048a                	slli	s1,s1,0x2
    800029d4:	00006717          	auipc	a4,0x6
    800029d8:	a5c70713          	addi	a4,a4,-1444 # 80008430 <states.1731+0x170>
    800029dc:	94ba                	add	s1,s1,a4
    800029de:	409c                	lw	a5,0(s1)
    800029e0:	97ba                	add	a5,a5,a4
    800029e2:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800029e4:	6d3c                	ld	a5,88(a0)
    800029e6:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800029e8:	60e2                	ld	ra,24(sp)
    800029ea:	6442                	ld	s0,16(sp)
    800029ec:	64a2                	ld	s1,8(sp)
    800029ee:	6105                	addi	sp,sp,32
    800029f0:	8082                	ret
    return p->trapframe->a1;
    800029f2:	6d3c                	ld	a5,88(a0)
    800029f4:	7fa8                	ld	a0,120(a5)
    800029f6:	bfcd                	j	800029e8 <argraw+0x30>
    return p->trapframe->a2;
    800029f8:	6d3c                	ld	a5,88(a0)
    800029fa:	63c8                	ld	a0,128(a5)
    800029fc:	b7f5                	j	800029e8 <argraw+0x30>
    return p->trapframe->a3;
    800029fe:	6d3c                	ld	a5,88(a0)
    80002a00:	67c8                	ld	a0,136(a5)
    80002a02:	b7dd                	j	800029e8 <argraw+0x30>
    return p->trapframe->a4;
    80002a04:	6d3c                	ld	a5,88(a0)
    80002a06:	6bc8                	ld	a0,144(a5)
    80002a08:	b7c5                	j	800029e8 <argraw+0x30>
    return p->trapframe->a5;
    80002a0a:	6d3c                	ld	a5,88(a0)
    80002a0c:	6fc8                	ld	a0,152(a5)
    80002a0e:	bfe9                	j	800029e8 <argraw+0x30>
  panic("argraw");
    80002a10:	00006517          	auipc	a0,0x6
    80002a14:	9f850513          	addi	a0,a0,-1544 # 80008408 <states.1731+0x148>
    80002a18:	ffffe097          	auipc	ra,0xffffe
    80002a1c:	b26080e7          	jalr	-1242(ra) # 8000053e <panic>

0000000080002a20 <fetchaddr>:
{
    80002a20:	1101                	addi	sp,sp,-32
    80002a22:	ec06                	sd	ra,24(sp)
    80002a24:	e822                	sd	s0,16(sp)
    80002a26:	e426                	sd	s1,8(sp)
    80002a28:	e04a                	sd	s2,0(sp)
    80002a2a:	1000                	addi	s0,sp,32
    80002a2c:	84aa                	mv	s1,a0
    80002a2e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002a30:	fffff097          	auipc	ra,0xfffff
    80002a34:	fec080e7          	jalr	-20(ra) # 80001a1c <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002a38:	653c                	ld	a5,72(a0)
    80002a3a:	02f4f863          	bgeu	s1,a5,80002a6a <fetchaddr+0x4a>
    80002a3e:	00848713          	addi	a4,s1,8
    80002a42:	02e7e663          	bltu	a5,a4,80002a6e <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002a46:	46a1                	li	a3,8
    80002a48:	8626                	mv	a2,s1
    80002a4a:	85ca                	mv	a1,s2
    80002a4c:	6928                	ld	a0,80(a0)
    80002a4e:	fffff097          	auipc	ra,0xfffff
    80002a52:	cb0080e7          	jalr	-848(ra) # 800016fe <copyin>
    80002a56:	00a03533          	snez	a0,a0
    80002a5a:	40a00533          	neg	a0,a0
}
    80002a5e:	60e2                	ld	ra,24(sp)
    80002a60:	6442                	ld	s0,16(sp)
    80002a62:	64a2                	ld	s1,8(sp)
    80002a64:	6902                	ld	s2,0(sp)
    80002a66:	6105                	addi	sp,sp,32
    80002a68:	8082                	ret
    return -1;
    80002a6a:	557d                	li	a0,-1
    80002a6c:	bfcd                	j	80002a5e <fetchaddr+0x3e>
    80002a6e:	557d                	li	a0,-1
    80002a70:	b7fd                	j	80002a5e <fetchaddr+0x3e>

0000000080002a72 <fetchstr>:
{
    80002a72:	7179                	addi	sp,sp,-48
    80002a74:	f406                	sd	ra,40(sp)
    80002a76:	f022                	sd	s0,32(sp)
    80002a78:	ec26                	sd	s1,24(sp)
    80002a7a:	e84a                	sd	s2,16(sp)
    80002a7c:	e44e                	sd	s3,8(sp)
    80002a7e:	1800                	addi	s0,sp,48
    80002a80:	892a                	mv	s2,a0
    80002a82:	84ae                	mv	s1,a1
    80002a84:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002a86:	fffff097          	auipc	ra,0xfffff
    80002a8a:	f96080e7          	jalr	-106(ra) # 80001a1c <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002a8e:	86ce                	mv	a3,s3
    80002a90:	864a                	mv	a2,s2
    80002a92:	85a6                	mv	a1,s1
    80002a94:	6928                	ld	a0,80(a0)
    80002a96:	fffff097          	auipc	ra,0xfffff
    80002a9a:	cf4080e7          	jalr	-780(ra) # 8000178a <copyinstr>
  if(err < 0)
    80002a9e:	00054763          	bltz	a0,80002aac <fetchstr+0x3a>
  return strlen(buf);
    80002aa2:	8526                	mv	a0,s1
    80002aa4:	ffffe097          	auipc	ra,0xffffe
    80002aa8:	3c0080e7          	jalr	960(ra) # 80000e64 <strlen>
}
    80002aac:	70a2                	ld	ra,40(sp)
    80002aae:	7402                	ld	s0,32(sp)
    80002ab0:	64e2                	ld	s1,24(sp)
    80002ab2:	6942                	ld	s2,16(sp)
    80002ab4:	69a2                	ld	s3,8(sp)
    80002ab6:	6145                	addi	sp,sp,48
    80002ab8:	8082                	ret

0000000080002aba <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002aba:	1101                	addi	sp,sp,-32
    80002abc:	ec06                	sd	ra,24(sp)
    80002abe:	e822                	sd	s0,16(sp)
    80002ac0:	e426                	sd	s1,8(sp)
    80002ac2:	1000                	addi	s0,sp,32
    80002ac4:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ac6:	00000097          	auipc	ra,0x0
    80002aca:	ef2080e7          	jalr	-270(ra) # 800029b8 <argraw>
    80002ace:	c088                	sw	a0,0(s1)
  return 0;
}
    80002ad0:	4501                	li	a0,0
    80002ad2:	60e2                	ld	ra,24(sp)
    80002ad4:	6442                	ld	s0,16(sp)
    80002ad6:	64a2                	ld	s1,8(sp)
    80002ad8:	6105                	addi	sp,sp,32
    80002ada:	8082                	ret

0000000080002adc <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002adc:	1101                	addi	sp,sp,-32
    80002ade:	ec06                	sd	ra,24(sp)
    80002ae0:	e822                	sd	s0,16(sp)
    80002ae2:	e426                	sd	s1,8(sp)
    80002ae4:	1000                	addi	s0,sp,32
    80002ae6:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ae8:	00000097          	auipc	ra,0x0
    80002aec:	ed0080e7          	jalr	-304(ra) # 800029b8 <argraw>
    80002af0:	e088                	sd	a0,0(s1)
  return 0;
}
    80002af2:	4501                	li	a0,0
    80002af4:	60e2                	ld	ra,24(sp)
    80002af6:	6442                	ld	s0,16(sp)
    80002af8:	64a2                	ld	s1,8(sp)
    80002afa:	6105                	addi	sp,sp,32
    80002afc:	8082                	ret

0000000080002afe <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002afe:	1101                	addi	sp,sp,-32
    80002b00:	ec06                	sd	ra,24(sp)
    80002b02:	e822                	sd	s0,16(sp)
    80002b04:	e426                	sd	s1,8(sp)
    80002b06:	e04a                	sd	s2,0(sp)
    80002b08:	1000                	addi	s0,sp,32
    80002b0a:	84ae                	mv	s1,a1
    80002b0c:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002b0e:	00000097          	auipc	ra,0x0
    80002b12:	eaa080e7          	jalr	-342(ra) # 800029b8 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002b16:	864a                	mv	a2,s2
    80002b18:	85a6                	mv	a1,s1
    80002b1a:	00000097          	auipc	ra,0x0
    80002b1e:	f58080e7          	jalr	-168(ra) # 80002a72 <fetchstr>
}
    80002b22:	60e2                	ld	ra,24(sp)
    80002b24:	6442                	ld	s0,16(sp)
    80002b26:	64a2                	ld	s1,8(sp)
    80002b28:	6902                	ld	s2,0(sp)
    80002b2a:	6105                	addi	sp,sp,32
    80002b2c:	8082                	ret

0000000080002b2e <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002b2e:	1101                	addi	sp,sp,-32
    80002b30:	ec06                	sd	ra,24(sp)
    80002b32:	e822                	sd	s0,16(sp)
    80002b34:	e426                	sd	s1,8(sp)
    80002b36:	e04a                	sd	s2,0(sp)
    80002b38:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002b3a:	fffff097          	auipc	ra,0xfffff
    80002b3e:	ee2080e7          	jalr	-286(ra) # 80001a1c <myproc>
    80002b42:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002b44:	05853903          	ld	s2,88(a0)
    80002b48:	0a893783          	ld	a5,168(s2)
    80002b4c:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002b50:	37fd                	addiw	a5,a5,-1
    80002b52:	4751                	li	a4,20
    80002b54:	00f76f63          	bltu	a4,a5,80002b72 <syscall+0x44>
    80002b58:	00369713          	slli	a4,a3,0x3
    80002b5c:	00006797          	auipc	a5,0x6
    80002b60:	8ec78793          	addi	a5,a5,-1812 # 80008448 <syscalls>
    80002b64:	97ba                	add	a5,a5,a4
    80002b66:	639c                	ld	a5,0(a5)
    80002b68:	c789                	beqz	a5,80002b72 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002b6a:	9782                	jalr	a5
    80002b6c:	06a93823          	sd	a0,112(s2)
    80002b70:	a839                	j	80002b8e <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002b72:	15848613          	addi	a2,s1,344
    80002b76:	588c                	lw	a1,48(s1)
    80002b78:	00006517          	auipc	a0,0x6
    80002b7c:	89850513          	addi	a0,a0,-1896 # 80008410 <states.1731+0x150>
    80002b80:	ffffe097          	auipc	ra,0xffffe
    80002b84:	a08080e7          	jalr	-1528(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002b88:	6cbc                	ld	a5,88(s1)
    80002b8a:	577d                	li	a4,-1
    80002b8c:	fbb8                	sd	a4,112(a5)
  }
}
    80002b8e:	60e2                	ld	ra,24(sp)
    80002b90:	6442                	ld	s0,16(sp)
    80002b92:	64a2                	ld	s1,8(sp)
    80002b94:	6902                	ld	s2,0(sp)
    80002b96:	6105                	addi	sp,sp,32
    80002b98:	8082                	ret

0000000080002b9a <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002b9a:	1101                	addi	sp,sp,-32
    80002b9c:	ec06                	sd	ra,24(sp)
    80002b9e:	e822                	sd	s0,16(sp)
    80002ba0:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002ba2:	fec40593          	addi	a1,s0,-20
    80002ba6:	4501                	li	a0,0
    80002ba8:	00000097          	auipc	ra,0x0
    80002bac:	f12080e7          	jalr	-238(ra) # 80002aba <argint>
    return -1;
    80002bb0:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002bb2:	00054963          	bltz	a0,80002bc4 <sys_exit+0x2a>
  exit(n);
    80002bb6:	fec42503          	lw	a0,-20(s0)
    80002bba:	fffff097          	auipc	ra,0xfffff
    80002bbe:	76c080e7          	jalr	1900(ra) # 80002326 <exit>
  return 0;  // not reached
    80002bc2:	4781                	li	a5,0
}
    80002bc4:	853e                	mv	a0,a5
    80002bc6:	60e2                	ld	ra,24(sp)
    80002bc8:	6442                	ld	s0,16(sp)
    80002bca:	6105                	addi	sp,sp,32
    80002bcc:	8082                	ret

0000000080002bce <sys_getpid>:

uint64
sys_getpid(void)
{
    80002bce:	1141                	addi	sp,sp,-16
    80002bd0:	e406                	sd	ra,8(sp)
    80002bd2:	e022                	sd	s0,0(sp)
    80002bd4:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002bd6:	fffff097          	auipc	ra,0xfffff
    80002bda:	e46080e7          	jalr	-442(ra) # 80001a1c <myproc>
}
    80002bde:	5908                	lw	a0,48(a0)
    80002be0:	60a2                	ld	ra,8(sp)
    80002be2:	6402                	ld	s0,0(sp)
    80002be4:	0141                	addi	sp,sp,16
    80002be6:	8082                	ret

0000000080002be8 <sys_fork>:

uint64
sys_fork(void)
{
    80002be8:	1141                	addi	sp,sp,-16
    80002bea:	e406                	sd	ra,8(sp)
    80002bec:	e022                	sd	s0,0(sp)
    80002bee:	0800                	addi	s0,sp,16
  return fork();
    80002bf0:	fffff097          	auipc	ra,0xfffff
    80002bf4:	1ec080e7          	jalr	492(ra) # 80001ddc <fork>
}
    80002bf8:	60a2                	ld	ra,8(sp)
    80002bfa:	6402                	ld	s0,0(sp)
    80002bfc:	0141                	addi	sp,sp,16
    80002bfe:	8082                	ret

0000000080002c00 <sys_wait>:

uint64
sys_wait(void)
{
    80002c00:	1101                	addi	sp,sp,-32
    80002c02:	ec06                	sd	ra,24(sp)
    80002c04:	e822                	sd	s0,16(sp)
    80002c06:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002c08:	fe840593          	addi	a1,s0,-24
    80002c0c:	4501                	li	a0,0
    80002c0e:	00000097          	auipc	ra,0x0
    80002c12:	ece080e7          	jalr	-306(ra) # 80002adc <argaddr>
    80002c16:	87aa                	mv	a5,a0
    return -1;
    80002c18:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002c1a:	0007c863          	bltz	a5,80002c2a <sys_wait+0x2a>
  return wait(p);
    80002c1e:	fe843503          	ld	a0,-24(s0)
    80002c22:	fffff097          	auipc	ra,0xfffff
    80002c26:	50c080e7          	jalr	1292(ra) # 8000212e <wait>
}
    80002c2a:	60e2                	ld	ra,24(sp)
    80002c2c:	6442                	ld	s0,16(sp)
    80002c2e:	6105                	addi	sp,sp,32
    80002c30:	8082                	ret

0000000080002c32 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002c32:	7179                	addi	sp,sp,-48
    80002c34:	f406                	sd	ra,40(sp)
    80002c36:	f022                	sd	s0,32(sp)
    80002c38:	ec26                	sd	s1,24(sp)
    80002c3a:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002c3c:	fdc40593          	addi	a1,s0,-36
    80002c40:	4501                	li	a0,0
    80002c42:	00000097          	auipc	ra,0x0
    80002c46:	e78080e7          	jalr	-392(ra) # 80002aba <argint>
    80002c4a:	87aa                	mv	a5,a0
    return -1;
    80002c4c:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002c4e:	0207c063          	bltz	a5,80002c6e <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002c52:	fffff097          	auipc	ra,0xfffff
    80002c56:	dca080e7          	jalr	-566(ra) # 80001a1c <myproc>
    80002c5a:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002c5c:	fdc42503          	lw	a0,-36(s0)
    80002c60:	fffff097          	auipc	ra,0xfffff
    80002c64:	108080e7          	jalr	264(ra) # 80001d68 <growproc>
    80002c68:	00054863          	bltz	a0,80002c78 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002c6c:	8526                	mv	a0,s1
}
    80002c6e:	70a2                	ld	ra,40(sp)
    80002c70:	7402                	ld	s0,32(sp)
    80002c72:	64e2                	ld	s1,24(sp)
    80002c74:	6145                	addi	sp,sp,48
    80002c76:	8082                	ret
    return -1;
    80002c78:	557d                	li	a0,-1
    80002c7a:	bfd5                	j	80002c6e <sys_sbrk+0x3c>

0000000080002c7c <sys_sleep>:

uint64
sys_sleep(void)
{
    80002c7c:	7139                	addi	sp,sp,-64
    80002c7e:	fc06                	sd	ra,56(sp)
    80002c80:	f822                	sd	s0,48(sp)
    80002c82:	f426                	sd	s1,40(sp)
    80002c84:	f04a                	sd	s2,32(sp)
    80002c86:	ec4e                	sd	s3,24(sp)
    80002c88:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002c8a:	fcc40593          	addi	a1,s0,-52
    80002c8e:	4501                	li	a0,0
    80002c90:	00000097          	auipc	ra,0x0
    80002c94:	e2a080e7          	jalr	-470(ra) # 80002aba <argint>
    return -1;
    80002c98:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002c9a:	06054563          	bltz	a0,80002d04 <sys_sleep+0x88>
  acquire(&tickslock);
    80002c9e:	00014517          	auipc	a0,0x14
    80002ca2:	63250513          	addi	a0,a0,1586 # 800172d0 <tickslock>
    80002ca6:	ffffe097          	auipc	ra,0xffffe
    80002caa:	f3e080e7          	jalr	-194(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80002cae:	00006917          	auipc	s2,0x6
    80002cb2:	38292903          	lw	s2,898(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002cb6:	fcc42783          	lw	a5,-52(s0)
    80002cba:	cf85                	beqz	a5,80002cf2 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002cbc:	00014997          	auipc	s3,0x14
    80002cc0:	61498993          	addi	s3,s3,1556 # 800172d0 <tickslock>
    80002cc4:	00006497          	auipc	s1,0x6
    80002cc8:	36c48493          	addi	s1,s1,876 # 80009030 <ticks>
    if(myproc()->killed){
    80002ccc:	fffff097          	auipc	ra,0xfffff
    80002cd0:	d50080e7          	jalr	-688(ra) # 80001a1c <myproc>
    80002cd4:	551c                	lw	a5,40(a0)
    80002cd6:	ef9d                	bnez	a5,80002d14 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002cd8:	85ce                	mv	a1,s3
    80002cda:	8526                	mv	a0,s1
    80002cdc:	fffff097          	auipc	ra,0xfffff
    80002ce0:	3ee080e7          	jalr	1006(ra) # 800020ca <sleep>
  while(ticks - ticks0 < n){
    80002ce4:	409c                	lw	a5,0(s1)
    80002ce6:	412787bb          	subw	a5,a5,s2
    80002cea:	fcc42703          	lw	a4,-52(s0)
    80002cee:	fce7efe3          	bltu	a5,a4,80002ccc <sys_sleep+0x50>
  }
  release(&tickslock);
    80002cf2:	00014517          	auipc	a0,0x14
    80002cf6:	5de50513          	addi	a0,a0,1502 # 800172d0 <tickslock>
    80002cfa:	ffffe097          	auipc	ra,0xffffe
    80002cfe:	f9e080e7          	jalr	-98(ra) # 80000c98 <release>
  return 0;
    80002d02:	4781                	li	a5,0
}
    80002d04:	853e                	mv	a0,a5
    80002d06:	70e2                	ld	ra,56(sp)
    80002d08:	7442                	ld	s0,48(sp)
    80002d0a:	74a2                	ld	s1,40(sp)
    80002d0c:	7902                	ld	s2,32(sp)
    80002d0e:	69e2                	ld	s3,24(sp)
    80002d10:	6121                	addi	sp,sp,64
    80002d12:	8082                	ret
      release(&tickslock);
    80002d14:	00014517          	auipc	a0,0x14
    80002d18:	5bc50513          	addi	a0,a0,1468 # 800172d0 <tickslock>
    80002d1c:	ffffe097          	auipc	ra,0xffffe
    80002d20:	f7c080e7          	jalr	-132(ra) # 80000c98 <release>
      return -1;
    80002d24:	57fd                	li	a5,-1
    80002d26:	bff9                	j	80002d04 <sys_sleep+0x88>

0000000080002d28 <sys_kill>:

uint64
sys_kill(void)
{
    80002d28:	1101                	addi	sp,sp,-32
    80002d2a:	ec06                	sd	ra,24(sp)
    80002d2c:	e822                	sd	s0,16(sp)
    80002d2e:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002d30:	fec40593          	addi	a1,s0,-20
    80002d34:	4501                	li	a0,0
    80002d36:	00000097          	auipc	ra,0x0
    80002d3a:	d84080e7          	jalr	-636(ra) # 80002aba <argint>
    80002d3e:	87aa                	mv	a5,a0
    return -1;
    80002d40:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002d42:	0007c863          	bltz	a5,80002d52 <sys_kill+0x2a>
  return kill(pid);
    80002d46:	fec42503          	lw	a0,-20(s0)
    80002d4a:	fffff097          	auipc	ra,0xfffff
    80002d4e:	6b2080e7          	jalr	1714(ra) # 800023fc <kill>
}
    80002d52:	60e2                	ld	ra,24(sp)
    80002d54:	6442                	ld	s0,16(sp)
    80002d56:	6105                	addi	sp,sp,32
    80002d58:	8082                	ret

0000000080002d5a <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002d5a:	1101                	addi	sp,sp,-32
    80002d5c:	ec06                	sd	ra,24(sp)
    80002d5e:	e822                	sd	s0,16(sp)
    80002d60:	e426                	sd	s1,8(sp)
    80002d62:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002d64:	00014517          	auipc	a0,0x14
    80002d68:	56c50513          	addi	a0,a0,1388 # 800172d0 <tickslock>
    80002d6c:	ffffe097          	auipc	ra,0xffffe
    80002d70:	e78080e7          	jalr	-392(ra) # 80000be4 <acquire>
  xticks = ticks;
    80002d74:	00006497          	auipc	s1,0x6
    80002d78:	2bc4a483          	lw	s1,700(s1) # 80009030 <ticks>
  release(&tickslock);
    80002d7c:	00014517          	auipc	a0,0x14
    80002d80:	55450513          	addi	a0,a0,1364 # 800172d0 <tickslock>
    80002d84:	ffffe097          	auipc	ra,0xffffe
    80002d88:	f14080e7          	jalr	-236(ra) # 80000c98 <release>
  return xticks;
}
    80002d8c:	02049513          	slli	a0,s1,0x20
    80002d90:	9101                	srli	a0,a0,0x20
    80002d92:	60e2                	ld	ra,24(sp)
    80002d94:	6442                	ld	s0,16(sp)
    80002d96:	64a2                	ld	s1,8(sp)
    80002d98:	6105                	addi	sp,sp,32
    80002d9a:	8082                	ret

0000000080002d9c <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002d9c:	7179                	addi	sp,sp,-48
    80002d9e:	f406                	sd	ra,40(sp)
    80002da0:	f022                	sd	s0,32(sp)
    80002da2:	ec26                	sd	s1,24(sp)
    80002da4:	e84a                	sd	s2,16(sp)
    80002da6:	e44e                	sd	s3,8(sp)
    80002da8:	e052                	sd	s4,0(sp)
    80002daa:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002dac:	00005597          	auipc	a1,0x5
    80002db0:	74c58593          	addi	a1,a1,1868 # 800084f8 <syscalls+0xb0>
    80002db4:	00014517          	auipc	a0,0x14
    80002db8:	53450513          	addi	a0,a0,1332 # 800172e8 <bcache>
    80002dbc:	ffffe097          	auipc	ra,0xffffe
    80002dc0:	d98080e7          	jalr	-616(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002dc4:	0001c797          	auipc	a5,0x1c
    80002dc8:	52478793          	addi	a5,a5,1316 # 8001f2e8 <bcache+0x8000>
    80002dcc:	0001c717          	auipc	a4,0x1c
    80002dd0:	78470713          	addi	a4,a4,1924 # 8001f550 <bcache+0x8268>
    80002dd4:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002dd8:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002ddc:	00014497          	auipc	s1,0x14
    80002de0:	52448493          	addi	s1,s1,1316 # 80017300 <bcache+0x18>
    b->next = bcache.head.next;
    80002de4:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002de6:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002de8:	00005a17          	auipc	s4,0x5
    80002dec:	718a0a13          	addi	s4,s4,1816 # 80008500 <syscalls+0xb8>
    b->next = bcache.head.next;
    80002df0:	2b893783          	ld	a5,696(s2)
    80002df4:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002df6:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002dfa:	85d2                	mv	a1,s4
    80002dfc:	01048513          	addi	a0,s1,16
    80002e00:	00001097          	auipc	ra,0x1
    80002e04:	4bc080e7          	jalr	1212(ra) # 800042bc <initsleeplock>
    bcache.head.next->prev = b;
    80002e08:	2b893783          	ld	a5,696(s2)
    80002e0c:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002e0e:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002e12:	45848493          	addi	s1,s1,1112
    80002e16:	fd349de3          	bne	s1,s3,80002df0 <binit+0x54>
  }
}
    80002e1a:	70a2                	ld	ra,40(sp)
    80002e1c:	7402                	ld	s0,32(sp)
    80002e1e:	64e2                	ld	s1,24(sp)
    80002e20:	6942                	ld	s2,16(sp)
    80002e22:	69a2                	ld	s3,8(sp)
    80002e24:	6a02                	ld	s4,0(sp)
    80002e26:	6145                	addi	sp,sp,48
    80002e28:	8082                	ret

0000000080002e2a <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002e2a:	7179                	addi	sp,sp,-48
    80002e2c:	f406                	sd	ra,40(sp)
    80002e2e:	f022                	sd	s0,32(sp)
    80002e30:	ec26                	sd	s1,24(sp)
    80002e32:	e84a                	sd	s2,16(sp)
    80002e34:	e44e                	sd	s3,8(sp)
    80002e36:	1800                	addi	s0,sp,48
    80002e38:	89aa                	mv	s3,a0
    80002e3a:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002e3c:	00014517          	auipc	a0,0x14
    80002e40:	4ac50513          	addi	a0,a0,1196 # 800172e8 <bcache>
    80002e44:	ffffe097          	auipc	ra,0xffffe
    80002e48:	da0080e7          	jalr	-608(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002e4c:	0001c497          	auipc	s1,0x1c
    80002e50:	7544b483          	ld	s1,1876(s1) # 8001f5a0 <bcache+0x82b8>
    80002e54:	0001c797          	auipc	a5,0x1c
    80002e58:	6fc78793          	addi	a5,a5,1788 # 8001f550 <bcache+0x8268>
    80002e5c:	02f48f63          	beq	s1,a5,80002e9a <bread+0x70>
    80002e60:	873e                	mv	a4,a5
    80002e62:	a021                	j	80002e6a <bread+0x40>
    80002e64:	68a4                	ld	s1,80(s1)
    80002e66:	02e48a63          	beq	s1,a4,80002e9a <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002e6a:	449c                	lw	a5,8(s1)
    80002e6c:	ff379ce3          	bne	a5,s3,80002e64 <bread+0x3a>
    80002e70:	44dc                	lw	a5,12(s1)
    80002e72:	ff2799e3          	bne	a5,s2,80002e64 <bread+0x3a>
      b->refcnt++;
    80002e76:	40bc                	lw	a5,64(s1)
    80002e78:	2785                	addiw	a5,a5,1
    80002e7a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002e7c:	00014517          	auipc	a0,0x14
    80002e80:	46c50513          	addi	a0,a0,1132 # 800172e8 <bcache>
    80002e84:	ffffe097          	auipc	ra,0xffffe
    80002e88:	e14080e7          	jalr	-492(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80002e8c:	01048513          	addi	a0,s1,16
    80002e90:	00001097          	auipc	ra,0x1
    80002e94:	466080e7          	jalr	1126(ra) # 800042f6 <acquiresleep>
      return b;
    80002e98:	a8b9                	j	80002ef6 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002e9a:	0001c497          	auipc	s1,0x1c
    80002e9e:	6fe4b483          	ld	s1,1790(s1) # 8001f598 <bcache+0x82b0>
    80002ea2:	0001c797          	auipc	a5,0x1c
    80002ea6:	6ae78793          	addi	a5,a5,1710 # 8001f550 <bcache+0x8268>
    80002eaa:	00f48863          	beq	s1,a5,80002eba <bread+0x90>
    80002eae:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002eb0:	40bc                	lw	a5,64(s1)
    80002eb2:	cf81                	beqz	a5,80002eca <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002eb4:	64a4                	ld	s1,72(s1)
    80002eb6:	fee49de3          	bne	s1,a4,80002eb0 <bread+0x86>
  panic("bget: no buffers");
    80002eba:	00005517          	auipc	a0,0x5
    80002ebe:	64e50513          	addi	a0,a0,1614 # 80008508 <syscalls+0xc0>
    80002ec2:	ffffd097          	auipc	ra,0xffffd
    80002ec6:	67c080e7          	jalr	1660(ra) # 8000053e <panic>
      b->dev = dev;
    80002eca:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80002ece:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80002ed2:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002ed6:	4785                	li	a5,1
    80002ed8:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002eda:	00014517          	auipc	a0,0x14
    80002ede:	40e50513          	addi	a0,a0,1038 # 800172e8 <bcache>
    80002ee2:	ffffe097          	auipc	ra,0xffffe
    80002ee6:	db6080e7          	jalr	-586(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80002eea:	01048513          	addi	a0,s1,16
    80002eee:	00001097          	auipc	ra,0x1
    80002ef2:	408080e7          	jalr	1032(ra) # 800042f6 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002ef6:	409c                	lw	a5,0(s1)
    80002ef8:	cb89                	beqz	a5,80002f0a <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002efa:	8526                	mv	a0,s1
    80002efc:	70a2                	ld	ra,40(sp)
    80002efe:	7402                	ld	s0,32(sp)
    80002f00:	64e2                	ld	s1,24(sp)
    80002f02:	6942                	ld	s2,16(sp)
    80002f04:	69a2                	ld	s3,8(sp)
    80002f06:	6145                	addi	sp,sp,48
    80002f08:	8082                	ret
    virtio_disk_rw(b, 0);
    80002f0a:	4581                	li	a1,0
    80002f0c:	8526                	mv	a0,s1
    80002f0e:	00003097          	auipc	ra,0x3
    80002f12:	f08080e7          	jalr	-248(ra) # 80005e16 <virtio_disk_rw>
    b->valid = 1;
    80002f16:	4785                	li	a5,1
    80002f18:	c09c                	sw	a5,0(s1)
  return b;
    80002f1a:	b7c5                	j	80002efa <bread+0xd0>

0000000080002f1c <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002f1c:	1101                	addi	sp,sp,-32
    80002f1e:	ec06                	sd	ra,24(sp)
    80002f20:	e822                	sd	s0,16(sp)
    80002f22:	e426                	sd	s1,8(sp)
    80002f24:	1000                	addi	s0,sp,32
    80002f26:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f28:	0541                	addi	a0,a0,16
    80002f2a:	00001097          	auipc	ra,0x1
    80002f2e:	466080e7          	jalr	1126(ra) # 80004390 <holdingsleep>
    80002f32:	cd01                	beqz	a0,80002f4a <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002f34:	4585                	li	a1,1
    80002f36:	8526                	mv	a0,s1
    80002f38:	00003097          	auipc	ra,0x3
    80002f3c:	ede080e7          	jalr	-290(ra) # 80005e16 <virtio_disk_rw>
}
    80002f40:	60e2                	ld	ra,24(sp)
    80002f42:	6442                	ld	s0,16(sp)
    80002f44:	64a2                	ld	s1,8(sp)
    80002f46:	6105                	addi	sp,sp,32
    80002f48:	8082                	ret
    panic("bwrite");
    80002f4a:	00005517          	auipc	a0,0x5
    80002f4e:	5d650513          	addi	a0,a0,1494 # 80008520 <syscalls+0xd8>
    80002f52:	ffffd097          	auipc	ra,0xffffd
    80002f56:	5ec080e7          	jalr	1516(ra) # 8000053e <panic>

0000000080002f5a <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002f5a:	1101                	addi	sp,sp,-32
    80002f5c:	ec06                	sd	ra,24(sp)
    80002f5e:	e822                	sd	s0,16(sp)
    80002f60:	e426                	sd	s1,8(sp)
    80002f62:	e04a                	sd	s2,0(sp)
    80002f64:	1000                	addi	s0,sp,32
    80002f66:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f68:	01050913          	addi	s2,a0,16
    80002f6c:	854a                	mv	a0,s2
    80002f6e:	00001097          	auipc	ra,0x1
    80002f72:	422080e7          	jalr	1058(ra) # 80004390 <holdingsleep>
    80002f76:	c92d                	beqz	a0,80002fe8 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80002f78:	854a                	mv	a0,s2
    80002f7a:	00001097          	auipc	ra,0x1
    80002f7e:	3d2080e7          	jalr	978(ra) # 8000434c <releasesleep>

  acquire(&bcache.lock);
    80002f82:	00014517          	auipc	a0,0x14
    80002f86:	36650513          	addi	a0,a0,870 # 800172e8 <bcache>
    80002f8a:	ffffe097          	auipc	ra,0xffffe
    80002f8e:	c5a080e7          	jalr	-934(ra) # 80000be4 <acquire>
  b->refcnt--;
    80002f92:	40bc                	lw	a5,64(s1)
    80002f94:	37fd                	addiw	a5,a5,-1
    80002f96:	0007871b          	sext.w	a4,a5
    80002f9a:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80002f9c:	eb05                	bnez	a4,80002fcc <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80002f9e:	68bc                	ld	a5,80(s1)
    80002fa0:	64b8                	ld	a4,72(s1)
    80002fa2:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80002fa4:	64bc                	ld	a5,72(s1)
    80002fa6:	68b8                	ld	a4,80(s1)
    80002fa8:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80002faa:	0001c797          	auipc	a5,0x1c
    80002fae:	33e78793          	addi	a5,a5,830 # 8001f2e8 <bcache+0x8000>
    80002fb2:	2b87b703          	ld	a4,696(a5)
    80002fb6:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80002fb8:	0001c717          	auipc	a4,0x1c
    80002fbc:	59870713          	addi	a4,a4,1432 # 8001f550 <bcache+0x8268>
    80002fc0:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80002fc2:	2b87b703          	ld	a4,696(a5)
    80002fc6:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80002fc8:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80002fcc:	00014517          	auipc	a0,0x14
    80002fd0:	31c50513          	addi	a0,a0,796 # 800172e8 <bcache>
    80002fd4:	ffffe097          	auipc	ra,0xffffe
    80002fd8:	cc4080e7          	jalr	-828(ra) # 80000c98 <release>
}
    80002fdc:	60e2                	ld	ra,24(sp)
    80002fde:	6442                	ld	s0,16(sp)
    80002fe0:	64a2                	ld	s1,8(sp)
    80002fe2:	6902                	ld	s2,0(sp)
    80002fe4:	6105                	addi	sp,sp,32
    80002fe6:	8082                	ret
    panic("brelse");
    80002fe8:	00005517          	auipc	a0,0x5
    80002fec:	54050513          	addi	a0,a0,1344 # 80008528 <syscalls+0xe0>
    80002ff0:	ffffd097          	auipc	ra,0xffffd
    80002ff4:	54e080e7          	jalr	1358(ra) # 8000053e <panic>

0000000080002ff8 <bpin>:

void
bpin(struct buf *b) {
    80002ff8:	1101                	addi	sp,sp,-32
    80002ffa:	ec06                	sd	ra,24(sp)
    80002ffc:	e822                	sd	s0,16(sp)
    80002ffe:	e426                	sd	s1,8(sp)
    80003000:	1000                	addi	s0,sp,32
    80003002:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003004:	00014517          	auipc	a0,0x14
    80003008:	2e450513          	addi	a0,a0,740 # 800172e8 <bcache>
    8000300c:	ffffe097          	auipc	ra,0xffffe
    80003010:	bd8080e7          	jalr	-1064(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003014:	40bc                	lw	a5,64(s1)
    80003016:	2785                	addiw	a5,a5,1
    80003018:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000301a:	00014517          	auipc	a0,0x14
    8000301e:	2ce50513          	addi	a0,a0,718 # 800172e8 <bcache>
    80003022:	ffffe097          	auipc	ra,0xffffe
    80003026:	c76080e7          	jalr	-906(ra) # 80000c98 <release>
}
    8000302a:	60e2                	ld	ra,24(sp)
    8000302c:	6442                	ld	s0,16(sp)
    8000302e:	64a2                	ld	s1,8(sp)
    80003030:	6105                	addi	sp,sp,32
    80003032:	8082                	ret

0000000080003034 <bunpin>:

void
bunpin(struct buf *b) {
    80003034:	1101                	addi	sp,sp,-32
    80003036:	ec06                	sd	ra,24(sp)
    80003038:	e822                	sd	s0,16(sp)
    8000303a:	e426                	sd	s1,8(sp)
    8000303c:	1000                	addi	s0,sp,32
    8000303e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003040:	00014517          	auipc	a0,0x14
    80003044:	2a850513          	addi	a0,a0,680 # 800172e8 <bcache>
    80003048:	ffffe097          	auipc	ra,0xffffe
    8000304c:	b9c080e7          	jalr	-1124(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003050:	40bc                	lw	a5,64(s1)
    80003052:	37fd                	addiw	a5,a5,-1
    80003054:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003056:	00014517          	auipc	a0,0x14
    8000305a:	29250513          	addi	a0,a0,658 # 800172e8 <bcache>
    8000305e:	ffffe097          	auipc	ra,0xffffe
    80003062:	c3a080e7          	jalr	-966(ra) # 80000c98 <release>
}
    80003066:	60e2                	ld	ra,24(sp)
    80003068:	6442                	ld	s0,16(sp)
    8000306a:	64a2                	ld	s1,8(sp)
    8000306c:	6105                	addi	sp,sp,32
    8000306e:	8082                	ret

0000000080003070 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003070:	1101                	addi	sp,sp,-32
    80003072:	ec06                	sd	ra,24(sp)
    80003074:	e822                	sd	s0,16(sp)
    80003076:	e426                	sd	s1,8(sp)
    80003078:	e04a                	sd	s2,0(sp)
    8000307a:	1000                	addi	s0,sp,32
    8000307c:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000307e:	00d5d59b          	srliw	a1,a1,0xd
    80003082:	0001d797          	auipc	a5,0x1d
    80003086:	9427a783          	lw	a5,-1726(a5) # 8001f9c4 <sb+0x1c>
    8000308a:	9dbd                	addw	a1,a1,a5
    8000308c:	00000097          	auipc	ra,0x0
    80003090:	d9e080e7          	jalr	-610(ra) # 80002e2a <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003094:	0074f713          	andi	a4,s1,7
    80003098:	4785                	li	a5,1
    8000309a:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000309e:	14ce                	slli	s1,s1,0x33
    800030a0:	90d9                	srli	s1,s1,0x36
    800030a2:	00950733          	add	a4,a0,s1
    800030a6:	05874703          	lbu	a4,88(a4)
    800030aa:	00e7f6b3          	and	a3,a5,a4
    800030ae:	c69d                	beqz	a3,800030dc <bfree+0x6c>
    800030b0:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800030b2:	94aa                	add	s1,s1,a0
    800030b4:	fff7c793          	not	a5,a5
    800030b8:	8ff9                	and	a5,a5,a4
    800030ba:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800030be:	00001097          	auipc	ra,0x1
    800030c2:	118080e7          	jalr	280(ra) # 800041d6 <log_write>
  brelse(bp);
    800030c6:	854a                	mv	a0,s2
    800030c8:	00000097          	auipc	ra,0x0
    800030cc:	e92080e7          	jalr	-366(ra) # 80002f5a <brelse>
}
    800030d0:	60e2                	ld	ra,24(sp)
    800030d2:	6442                	ld	s0,16(sp)
    800030d4:	64a2                	ld	s1,8(sp)
    800030d6:	6902                	ld	s2,0(sp)
    800030d8:	6105                	addi	sp,sp,32
    800030da:	8082                	ret
    panic("freeing free block");
    800030dc:	00005517          	auipc	a0,0x5
    800030e0:	45450513          	addi	a0,a0,1108 # 80008530 <syscalls+0xe8>
    800030e4:	ffffd097          	auipc	ra,0xffffd
    800030e8:	45a080e7          	jalr	1114(ra) # 8000053e <panic>

00000000800030ec <balloc>:
{
    800030ec:	711d                	addi	sp,sp,-96
    800030ee:	ec86                	sd	ra,88(sp)
    800030f0:	e8a2                	sd	s0,80(sp)
    800030f2:	e4a6                	sd	s1,72(sp)
    800030f4:	e0ca                	sd	s2,64(sp)
    800030f6:	fc4e                	sd	s3,56(sp)
    800030f8:	f852                	sd	s4,48(sp)
    800030fa:	f456                	sd	s5,40(sp)
    800030fc:	f05a                	sd	s6,32(sp)
    800030fe:	ec5e                	sd	s7,24(sp)
    80003100:	e862                	sd	s8,16(sp)
    80003102:	e466                	sd	s9,8(sp)
    80003104:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003106:	0001d797          	auipc	a5,0x1d
    8000310a:	8a67a783          	lw	a5,-1882(a5) # 8001f9ac <sb+0x4>
    8000310e:	cbd1                	beqz	a5,800031a2 <balloc+0xb6>
    80003110:	8baa                	mv	s7,a0
    80003112:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003114:	0001db17          	auipc	s6,0x1d
    80003118:	894b0b13          	addi	s6,s6,-1900 # 8001f9a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000311c:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000311e:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003120:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003122:	6c89                	lui	s9,0x2
    80003124:	a831                	j	80003140 <balloc+0x54>
    brelse(bp);
    80003126:	854a                	mv	a0,s2
    80003128:	00000097          	auipc	ra,0x0
    8000312c:	e32080e7          	jalr	-462(ra) # 80002f5a <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003130:	015c87bb          	addw	a5,s9,s5
    80003134:	00078a9b          	sext.w	s5,a5
    80003138:	004b2703          	lw	a4,4(s6)
    8000313c:	06eaf363          	bgeu	s5,a4,800031a2 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003140:	41fad79b          	sraiw	a5,s5,0x1f
    80003144:	0137d79b          	srliw	a5,a5,0x13
    80003148:	015787bb          	addw	a5,a5,s5
    8000314c:	40d7d79b          	sraiw	a5,a5,0xd
    80003150:	01cb2583          	lw	a1,28(s6)
    80003154:	9dbd                	addw	a1,a1,a5
    80003156:	855e                	mv	a0,s7
    80003158:	00000097          	auipc	ra,0x0
    8000315c:	cd2080e7          	jalr	-814(ra) # 80002e2a <bread>
    80003160:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003162:	004b2503          	lw	a0,4(s6)
    80003166:	000a849b          	sext.w	s1,s5
    8000316a:	8662                	mv	a2,s8
    8000316c:	faa4fde3          	bgeu	s1,a0,80003126 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003170:	41f6579b          	sraiw	a5,a2,0x1f
    80003174:	01d7d69b          	srliw	a3,a5,0x1d
    80003178:	00c6873b          	addw	a4,a3,a2
    8000317c:	00777793          	andi	a5,a4,7
    80003180:	9f95                	subw	a5,a5,a3
    80003182:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003186:	4037571b          	sraiw	a4,a4,0x3
    8000318a:	00e906b3          	add	a3,s2,a4
    8000318e:	0586c683          	lbu	a3,88(a3)
    80003192:	00d7f5b3          	and	a1,a5,a3
    80003196:	cd91                	beqz	a1,800031b2 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003198:	2605                	addiw	a2,a2,1
    8000319a:	2485                	addiw	s1,s1,1
    8000319c:	fd4618e3          	bne	a2,s4,8000316c <balloc+0x80>
    800031a0:	b759                	j	80003126 <balloc+0x3a>
  panic("balloc: out of blocks");
    800031a2:	00005517          	auipc	a0,0x5
    800031a6:	3a650513          	addi	a0,a0,934 # 80008548 <syscalls+0x100>
    800031aa:	ffffd097          	auipc	ra,0xffffd
    800031ae:	394080e7          	jalr	916(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800031b2:	974a                	add	a4,a4,s2
    800031b4:	8fd5                	or	a5,a5,a3
    800031b6:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800031ba:	854a                	mv	a0,s2
    800031bc:	00001097          	auipc	ra,0x1
    800031c0:	01a080e7          	jalr	26(ra) # 800041d6 <log_write>
        brelse(bp);
    800031c4:	854a                	mv	a0,s2
    800031c6:	00000097          	auipc	ra,0x0
    800031ca:	d94080e7          	jalr	-620(ra) # 80002f5a <brelse>
  bp = bread(dev, bno);
    800031ce:	85a6                	mv	a1,s1
    800031d0:	855e                	mv	a0,s7
    800031d2:	00000097          	auipc	ra,0x0
    800031d6:	c58080e7          	jalr	-936(ra) # 80002e2a <bread>
    800031da:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800031dc:	40000613          	li	a2,1024
    800031e0:	4581                	li	a1,0
    800031e2:	05850513          	addi	a0,a0,88
    800031e6:	ffffe097          	auipc	ra,0xffffe
    800031ea:	afa080e7          	jalr	-1286(ra) # 80000ce0 <memset>
  log_write(bp);
    800031ee:	854a                	mv	a0,s2
    800031f0:	00001097          	auipc	ra,0x1
    800031f4:	fe6080e7          	jalr	-26(ra) # 800041d6 <log_write>
  brelse(bp);
    800031f8:	854a                	mv	a0,s2
    800031fa:	00000097          	auipc	ra,0x0
    800031fe:	d60080e7          	jalr	-672(ra) # 80002f5a <brelse>
}
    80003202:	8526                	mv	a0,s1
    80003204:	60e6                	ld	ra,88(sp)
    80003206:	6446                	ld	s0,80(sp)
    80003208:	64a6                	ld	s1,72(sp)
    8000320a:	6906                	ld	s2,64(sp)
    8000320c:	79e2                	ld	s3,56(sp)
    8000320e:	7a42                	ld	s4,48(sp)
    80003210:	7aa2                	ld	s5,40(sp)
    80003212:	7b02                	ld	s6,32(sp)
    80003214:	6be2                	ld	s7,24(sp)
    80003216:	6c42                	ld	s8,16(sp)
    80003218:	6ca2                	ld	s9,8(sp)
    8000321a:	6125                	addi	sp,sp,96
    8000321c:	8082                	ret

000000008000321e <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000321e:	7179                	addi	sp,sp,-48
    80003220:	f406                	sd	ra,40(sp)
    80003222:	f022                	sd	s0,32(sp)
    80003224:	ec26                	sd	s1,24(sp)
    80003226:	e84a                	sd	s2,16(sp)
    80003228:	e44e                	sd	s3,8(sp)
    8000322a:	e052                	sd	s4,0(sp)
    8000322c:	1800                	addi	s0,sp,48
    8000322e:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003230:	47ad                	li	a5,11
    80003232:	04b7fe63          	bgeu	a5,a1,8000328e <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003236:	ff45849b          	addiw	s1,a1,-12
    8000323a:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000323e:	0ff00793          	li	a5,255
    80003242:	0ae7e363          	bltu	a5,a4,800032e8 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003246:	08052583          	lw	a1,128(a0)
    8000324a:	c5ad                	beqz	a1,800032b4 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000324c:	00092503          	lw	a0,0(s2)
    80003250:	00000097          	auipc	ra,0x0
    80003254:	bda080e7          	jalr	-1062(ra) # 80002e2a <bread>
    80003258:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000325a:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000325e:	02049593          	slli	a1,s1,0x20
    80003262:	9181                	srli	a1,a1,0x20
    80003264:	058a                	slli	a1,a1,0x2
    80003266:	00b784b3          	add	s1,a5,a1
    8000326a:	0004a983          	lw	s3,0(s1)
    8000326e:	04098d63          	beqz	s3,800032c8 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003272:	8552                	mv	a0,s4
    80003274:	00000097          	auipc	ra,0x0
    80003278:	ce6080e7          	jalr	-794(ra) # 80002f5a <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000327c:	854e                	mv	a0,s3
    8000327e:	70a2                	ld	ra,40(sp)
    80003280:	7402                	ld	s0,32(sp)
    80003282:	64e2                	ld	s1,24(sp)
    80003284:	6942                	ld	s2,16(sp)
    80003286:	69a2                	ld	s3,8(sp)
    80003288:	6a02                	ld	s4,0(sp)
    8000328a:	6145                	addi	sp,sp,48
    8000328c:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000328e:	02059493          	slli	s1,a1,0x20
    80003292:	9081                	srli	s1,s1,0x20
    80003294:	048a                	slli	s1,s1,0x2
    80003296:	94aa                	add	s1,s1,a0
    80003298:	0504a983          	lw	s3,80(s1)
    8000329c:	fe0990e3          	bnez	s3,8000327c <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800032a0:	4108                	lw	a0,0(a0)
    800032a2:	00000097          	auipc	ra,0x0
    800032a6:	e4a080e7          	jalr	-438(ra) # 800030ec <balloc>
    800032aa:	0005099b          	sext.w	s3,a0
    800032ae:	0534a823          	sw	s3,80(s1)
    800032b2:	b7e9                	j	8000327c <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800032b4:	4108                	lw	a0,0(a0)
    800032b6:	00000097          	auipc	ra,0x0
    800032ba:	e36080e7          	jalr	-458(ra) # 800030ec <balloc>
    800032be:	0005059b          	sext.w	a1,a0
    800032c2:	08b92023          	sw	a1,128(s2)
    800032c6:	b759                	j	8000324c <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800032c8:	00092503          	lw	a0,0(s2)
    800032cc:	00000097          	auipc	ra,0x0
    800032d0:	e20080e7          	jalr	-480(ra) # 800030ec <balloc>
    800032d4:	0005099b          	sext.w	s3,a0
    800032d8:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800032dc:	8552                	mv	a0,s4
    800032de:	00001097          	auipc	ra,0x1
    800032e2:	ef8080e7          	jalr	-264(ra) # 800041d6 <log_write>
    800032e6:	b771                	j	80003272 <bmap+0x54>
  panic("bmap: out of range");
    800032e8:	00005517          	auipc	a0,0x5
    800032ec:	27850513          	addi	a0,a0,632 # 80008560 <syscalls+0x118>
    800032f0:	ffffd097          	auipc	ra,0xffffd
    800032f4:	24e080e7          	jalr	590(ra) # 8000053e <panic>

00000000800032f8 <iget>:
{
    800032f8:	7179                	addi	sp,sp,-48
    800032fa:	f406                	sd	ra,40(sp)
    800032fc:	f022                	sd	s0,32(sp)
    800032fe:	ec26                	sd	s1,24(sp)
    80003300:	e84a                	sd	s2,16(sp)
    80003302:	e44e                	sd	s3,8(sp)
    80003304:	e052                	sd	s4,0(sp)
    80003306:	1800                	addi	s0,sp,48
    80003308:	89aa                	mv	s3,a0
    8000330a:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000330c:	0001c517          	auipc	a0,0x1c
    80003310:	6bc50513          	addi	a0,a0,1724 # 8001f9c8 <itable>
    80003314:	ffffe097          	auipc	ra,0xffffe
    80003318:	8d0080e7          	jalr	-1840(ra) # 80000be4 <acquire>
  empty = 0;
    8000331c:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000331e:	0001c497          	auipc	s1,0x1c
    80003322:	6c248493          	addi	s1,s1,1730 # 8001f9e0 <itable+0x18>
    80003326:	0001e697          	auipc	a3,0x1e
    8000332a:	14a68693          	addi	a3,a3,330 # 80021470 <log>
    8000332e:	a039                	j	8000333c <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003330:	02090b63          	beqz	s2,80003366 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003334:	08848493          	addi	s1,s1,136
    80003338:	02d48a63          	beq	s1,a3,8000336c <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000333c:	449c                	lw	a5,8(s1)
    8000333e:	fef059e3          	blez	a5,80003330 <iget+0x38>
    80003342:	4098                	lw	a4,0(s1)
    80003344:	ff3716e3          	bne	a4,s3,80003330 <iget+0x38>
    80003348:	40d8                	lw	a4,4(s1)
    8000334a:	ff4713e3          	bne	a4,s4,80003330 <iget+0x38>
      ip->ref++;
    8000334e:	2785                	addiw	a5,a5,1
    80003350:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003352:	0001c517          	auipc	a0,0x1c
    80003356:	67650513          	addi	a0,a0,1654 # 8001f9c8 <itable>
    8000335a:	ffffe097          	auipc	ra,0xffffe
    8000335e:	93e080e7          	jalr	-1730(ra) # 80000c98 <release>
      return ip;
    80003362:	8926                	mv	s2,s1
    80003364:	a03d                	j	80003392 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003366:	f7f9                	bnez	a5,80003334 <iget+0x3c>
    80003368:	8926                	mv	s2,s1
    8000336a:	b7e9                	j	80003334 <iget+0x3c>
  if(empty == 0)
    8000336c:	02090c63          	beqz	s2,800033a4 <iget+0xac>
  ip->dev = dev;
    80003370:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003374:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003378:	4785                	li	a5,1
    8000337a:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000337e:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003382:	0001c517          	auipc	a0,0x1c
    80003386:	64650513          	addi	a0,a0,1606 # 8001f9c8 <itable>
    8000338a:	ffffe097          	auipc	ra,0xffffe
    8000338e:	90e080e7          	jalr	-1778(ra) # 80000c98 <release>
}
    80003392:	854a                	mv	a0,s2
    80003394:	70a2                	ld	ra,40(sp)
    80003396:	7402                	ld	s0,32(sp)
    80003398:	64e2                	ld	s1,24(sp)
    8000339a:	6942                	ld	s2,16(sp)
    8000339c:	69a2                	ld	s3,8(sp)
    8000339e:	6a02                	ld	s4,0(sp)
    800033a0:	6145                	addi	sp,sp,48
    800033a2:	8082                	ret
    panic("iget: no inodes");
    800033a4:	00005517          	auipc	a0,0x5
    800033a8:	1d450513          	addi	a0,a0,468 # 80008578 <syscalls+0x130>
    800033ac:	ffffd097          	auipc	ra,0xffffd
    800033b0:	192080e7          	jalr	402(ra) # 8000053e <panic>

00000000800033b4 <fsinit>:
fsinit(int dev) {
    800033b4:	7179                	addi	sp,sp,-48
    800033b6:	f406                	sd	ra,40(sp)
    800033b8:	f022                	sd	s0,32(sp)
    800033ba:	ec26                	sd	s1,24(sp)
    800033bc:	e84a                	sd	s2,16(sp)
    800033be:	e44e                	sd	s3,8(sp)
    800033c0:	1800                	addi	s0,sp,48
    800033c2:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800033c4:	4585                	li	a1,1
    800033c6:	00000097          	auipc	ra,0x0
    800033ca:	a64080e7          	jalr	-1436(ra) # 80002e2a <bread>
    800033ce:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800033d0:	0001c997          	auipc	s3,0x1c
    800033d4:	5d898993          	addi	s3,s3,1496 # 8001f9a8 <sb>
    800033d8:	02000613          	li	a2,32
    800033dc:	05850593          	addi	a1,a0,88
    800033e0:	854e                	mv	a0,s3
    800033e2:	ffffe097          	auipc	ra,0xffffe
    800033e6:	95e080e7          	jalr	-1698(ra) # 80000d40 <memmove>
  brelse(bp);
    800033ea:	8526                	mv	a0,s1
    800033ec:	00000097          	auipc	ra,0x0
    800033f0:	b6e080e7          	jalr	-1170(ra) # 80002f5a <brelse>
  if(sb.magic != FSMAGIC)
    800033f4:	0009a703          	lw	a4,0(s3)
    800033f8:	102037b7          	lui	a5,0x10203
    800033fc:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003400:	02f71263          	bne	a4,a5,80003424 <fsinit+0x70>
  initlog(dev, &sb);
    80003404:	0001c597          	auipc	a1,0x1c
    80003408:	5a458593          	addi	a1,a1,1444 # 8001f9a8 <sb>
    8000340c:	854a                	mv	a0,s2
    8000340e:	00001097          	auipc	ra,0x1
    80003412:	b4c080e7          	jalr	-1204(ra) # 80003f5a <initlog>
}
    80003416:	70a2                	ld	ra,40(sp)
    80003418:	7402                	ld	s0,32(sp)
    8000341a:	64e2                	ld	s1,24(sp)
    8000341c:	6942                	ld	s2,16(sp)
    8000341e:	69a2                	ld	s3,8(sp)
    80003420:	6145                	addi	sp,sp,48
    80003422:	8082                	ret
    panic("invalid file system");
    80003424:	00005517          	auipc	a0,0x5
    80003428:	16450513          	addi	a0,a0,356 # 80008588 <syscalls+0x140>
    8000342c:	ffffd097          	auipc	ra,0xffffd
    80003430:	112080e7          	jalr	274(ra) # 8000053e <panic>

0000000080003434 <iinit>:
{
    80003434:	7179                	addi	sp,sp,-48
    80003436:	f406                	sd	ra,40(sp)
    80003438:	f022                	sd	s0,32(sp)
    8000343a:	ec26                	sd	s1,24(sp)
    8000343c:	e84a                	sd	s2,16(sp)
    8000343e:	e44e                	sd	s3,8(sp)
    80003440:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003442:	00005597          	auipc	a1,0x5
    80003446:	15e58593          	addi	a1,a1,350 # 800085a0 <syscalls+0x158>
    8000344a:	0001c517          	auipc	a0,0x1c
    8000344e:	57e50513          	addi	a0,a0,1406 # 8001f9c8 <itable>
    80003452:	ffffd097          	auipc	ra,0xffffd
    80003456:	702080e7          	jalr	1794(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000345a:	0001c497          	auipc	s1,0x1c
    8000345e:	59648493          	addi	s1,s1,1430 # 8001f9f0 <itable+0x28>
    80003462:	0001e997          	auipc	s3,0x1e
    80003466:	01e98993          	addi	s3,s3,30 # 80021480 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000346a:	00005917          	auipc	s2,0x5
    8000346e:	13e90913          	addi	s2,s2,318 # 800085a8 <syscalls+0x160>
    80003472:	85ca                	mv	a1,s2
    80003474:	8526                	mv	a0,s1
    80003476:	00001097          	auipc	ra,0x1
    8000347a:	e46080e7          	jalr	-442(ra) # 800042bc <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000347e:	08848493          	addi	s1,s1,136
    80003482:	ff3498e3          	bne	s1,s3,80003472 <iinit+0x3e>
}
    80003486:	70a2                	ld	ra,40(sp)
    80003488:	7402                	ld	s0,32(sp)
    8000348a:	64e2                	ld	s1,24(sp)
    8000348c:	6942                	ld	s2,16(sp)
    8000348e:	69a2                	ld	s3,8(sp)
    80003490:	6145                	addi	sp,sp,48
    80003492:	8082                	ret

0000000080003494 <ialloc>:
{
    80003494:	715d                	addi	sp,sp,-80
    80003496:	e486                	sd	ra,72(sp)
    80003498:	e0a2                	sd	s0,64(sp)
    8000349a:	fc26                	sd	s1,56(sp)
    8000349c:	f84a                	sd	s2,48(sp)
    8000349e:	f44e                	sd	s3,40(sp)
    800034a0:	f052                	sd	s4,32(sp)
    800034a2:	ec56                	sd	s5,24(sp)
    800034a4:	e85a                	sd	s6,16(sp)
    800034a6:	e45e                	sd	s7,8(sp)
    800034a8:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800034aa:	0001c717          	auipc	a4,0x1c
    800034ae:	50a72703          	lw	a4,1290(a4) # 8001f9b4 <sb+0xc>
    800034b2:	4785                	li	a5,1
    800034b4:	04e7fa63          	bgeu	a5,a4,80003508 <ialloc+0x74>
    800034b8:	8aaa                	mv	s5,a0
    800034ba:	8bae                	mv	s7,a1
    800034bc:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800034be:	0001ca17          	auipc	s4,0x1c
    800034c2:	4eaa0a13          	addi	s4,s4,1258 # 8001f9a8 <sb>
    800034c6:	00048b1b          	sext.w	s6,s1
    800034ca:	0044d593          	srli	a1,s1,0x4
    800034ce:	018a2783          	lw	a5,24(s4)
    800034d2:	9dbd                	addw	a1,a1,a5
    800034d4:	8556                	mv	a0,s5
    800034d6:	00000097          	auipc	ra,0x0
    800034da:	954080e7          	jalr	-1708(ra) # 80002e2a <bread>
    800034de:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800034e0:	05850993          	addi	s3,a0,88
    800034e4:	00f4f793          	andi	a5,s1,15
    800034e8:	079a                	slli	a5,a5,0x6
    800034ea:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800034ec:	00099783          	lh	a5,0(s3)
    800034f0:	c785                	beqz	a5,80003518 <ialloc+0x84>
    brelse(bp);
    800034f2:	00000097          	auipc	ra,0x0
    800034f6:	a68080e7          	jalr	-1432(ra) # 80002f5a <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800034fa:	0485                	addi	s1,s1,1
    800034fc:	00ca2703          	lw	a4,12(s4)
    80003500:	0004879b          	sext.w	a5,s1
    80003504:	fce7e1e3          	bltu	a5,a4,800034c6 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003508:	00005517          	auipc	a0,0x5
    8000350c:	0a850513          	addi	a0,a0,168 # 800085b0 <syscalls+0x168>
    80003510:	ffffd097          	auipc	ra,0xffffd
    80003514:	02e080e7          	jalr	46(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003518:	04000613          	li	a2,64
    8000351c:	4581                	li	a1,0
    8000351e:	854e                	mv	a0,s3
    80003520:	ffffd097          	auipc	ra,0xffffd
    80003524:	7c0080e7          	jalr	1984(ra) # 80000ce0 <memset>
      dip->type = type;
    80003528:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000352c:	854a                	mv	a0,s2
    8000352e:	00001097          	auipc	ra,0x1
    80003532:	ca8080e7          	jalr	-856(ra) # 800041d6 <log_write>
      brelse(bp);
    80003536:	854a                	mv	a0,s2
    80003538:	00000097          	auipc	ra,0x0
    8000353c:	a22080e7          	jalr	-1502(ra) # 80002f5a <brelse>
      return iget(dev, inum);
    80003540:	85da                	mv	a1,s6
    80003542:	8556                	mv	a0,s5
    80003544:	00000097          	auipc	ra,0x0
    80003548:	db4080e7          	jalr	-588(ra) # 800032f8 <iget>
}
    8000354c:	60a6                	ld	ra,72(sp)
    8000354e:	6406                	ld	s0,64(sp)
    80003550:	74e2                	ld	s1,56(sp)
    80003552:	7942                	ld	s2,48(sp)
    80003554:	79a2                	ld	s3,40(sp)
    80003556:	7a02                	ld	s4,32(sp)
    80003558:	6ae2                	ld	s5,24(sp)
    8000355a:	6b42                	ld	s6,16(sp)
    8000355c:	6ba2                	ld	s7,8(sp)
    8000355e:	6161                	addi	sp,sp,80
    80003560:	8082                	ret

0000000080003562 <iupdate>:
{
    80003562:	1101                	addi	sp,sp,-32
    80003564:	ec06                	sd	ra,24(sp)
    80003566:	e822                	sd	s0,16(sp)
    80003568:	e426                	sd	s1,8(sp)
    8000356a:	e04a                	sd	s2,0(sp)
    8000356c:	1000                	addi	s0,sp,32
    8000356e:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003570:	415c                	lw	a5,4(a0)
    80003572:	0047d79b          	srliw	a5,a5,0x4
    80003576:	0001c597          	auipc	a1,0x1c
    8000357a:	44a5a583          	lw	a1,1098(a1) # 8001f9c0 <sb+0x18>
    8000357e:	9dbd                	addw	a1,a1,a5
    80003580:	4108                	lw	a0,0(a0)
    80003582:	00000097          	auipc	ra,0x0
    80003586:	8a8080e7          	jalr	-1880(ra) # 80002e2a <bread>
    8000358a:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000358c:	05850793          	addi	a5,a0,88
    80003590:	40c8                	lw	a0,4(s1)
    80003592:	893d                	andi	a0,a0,15
    80003594:	051a                	slli	a0,a0,0x6
    80003596:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003598:	04449703          	lh	a4,68(s1)
    8000359c:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800035a0:	04649703          	lh	a4,70(s1)
    800035a4:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800035a8:	04849703          	lh	a4,72(s1)
    800035ac:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800035b0:	04a49703          	lh	a4,74(s1)
    800035b4:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800035b8:	44f8                	lw	a4,76(s1)
    800035ba:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800035bc:	03400613          	li	a2,52
    800035c0:	05048593          	addi	a1,s1,80
    800035c4:	0531                	addi	a0,a0,12
    800035c6:	ffffd097          	auipc	ra,0xffffd
    800035ca:	77a080e7          	jalr	1914(ra) # 80000d40 <memmove>
  log_write(bp);
    800035ce:	854a                	mv	a0,s2
    800035d0:	00001097          	auipc	ra,0x1
    800035d4:	c06080e7          	jalr	-1018(ra) # 800041d6 <log_write>
  brelse(bp);
    800035d8:	854a                	mv	a0,s2
    800035da:	00000097          	auipc	ra,0x0
    800035de:	980080e7          	jalr	-1664(ra) # 80002f5a <brelse>
}
    800035e2:	60e2                	ld	ra,24(sp)
    800035e4:	6442                	ld	s0,16(sp)
    800035e6:	64a2                	ld	s1,8(sp)
    800035e8:	6902                	ld	s2,0(sp)
    800035ea:	6105                	addi	sp,sp,32
    800035ec:	8082                	ret

00000000800035ee <idup>:
{
    800035ee:	1101                	addi	sp,sp,-32
    800035f0:	ec06                	sd	ra,24(sp)
    800035f2:	e822                	sd	s0,16(sp)
    800035f4:	e426                	sd	s1,8(sp)
    800035f6:	1000                	addi	s0,sp,32
    800035f8:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800035fa:	0001c517          	auipc	a0,0x1c
    800035fe:	3ce50513          	addi	a0,a0,974 # 8001f9c8 <itable>
    80003602:	ffffd097          	auipc	ra,0xffffd
    80003606:	5e2080e7          	jalr	1506(ra) # 80000be4 <acquire>
  ip->ref++;
    8000360a:	449c                	lw	a5,8(s1)
    8000360c:	2785                	addiw	a5,a5,1
    8000360e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003610:	0001c517          	auipc	a0,0x1c
    80003614:	3b850513          	addi	a0,a0,952 # 8001f9c8 <itable>
    80003618:	ffffd097          	auipc	ra,0xffffd
    8000361c:	680080e7          	jalr	1664(ra) # 80000c98 <release>
}
    80003620:	8526                	mv	a0,s1
    80003622:	60e2                	ld	ra,24(sp)
    80003624:	6442                	ld	s0,16(sp)
    80003626:	64a2                	ld	s1,8(sp)
    80003628:	6105                	addi	sp,sp,32
    8000362a:	8082                	ret

000000008000362c <ilock>:
{
    8000362c:	1101                	addi	sp,sp,-32
    8000362e:	ec06                	sd	ra,24(sp)
    80003630:	e822                	sd	s0,16(sp)
    80003632:	e426                	sd	s1,8(sp)
    80003634:	e04a                	sd	s2,0(sp)
    80003636:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003638:	c115                	beqz	a0,8000365c <ilock+0x30>
    8000363a:	84aa                	mv	s1,a0
    8000363c:	451c                	lw	a5,8(a0)
    8000363e:	00f05f63          	blez	a5,8000365c <ilock+0x30>
  acquiresleep(&ip->lock);
    80003642:	0541                	addi	a0,a0,16
    80003644:	00001097          	auipc	ra,0x1
    80003648:	cb2080e7          	jalr	-846(ra) # 800042f6 <acquiresleep>
  if(ip->valid == 0){
    8000364c:	40bc                	lw	a5,64(s1)
    8000364e:	cf99                	beqz	a5,8000366c <ilock+0x40>
}
    80003650:	60e2                	ld	ra,24(sp)
    80003652:	6442                	ld	s0,16(sp)
    80003654:	64a2                	ld	s1,8(sp)
    80003656:	6902                	ld	s2,0(sp)
    80003658:	6105                	addi	sp,sp,32
    8000365a:	8082                	ret
    panic("ilock");
    8000365c:	00005517          	auipc	a0,0x5
    80003660:	f6c50513          	addi	a0,a0,-148 # 800085c8 <syscalls+0x180>
    80003664:	ffffd097          	auipc	ra,0xffffd
    80003668:	eda080e7          	jalr	-294(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000366c:	40dc                	lw	a5,4(s1)
    8000366e:	0047d79b          	srliw	a5,a5,0x4
    80003672:	0001c597          	auipc	a1,0x1c
    80003676:	34e5a583          	lw	a1,846(a1) # 8001f9c0 <sb+0x18>
    8000367a:	9dbd                	addw	a1,a1,a5
    8000367c:	4088                	lw	a0,0(s1)
    8000367e:	fffff097          	auipc	ra,0xfffff
    80003682:	7ac080e7          	jalr	1964(ra) # 80002e2a <bread>
    80003686:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003688:	05850593          	addi	a1,a0,88
    8000368c:	40dc                	lw	a5,4(s1)
    8000368e:	8bbd                	andi	a5,a5,15
    80003690:	079a                	slli	a5,a5,0x6
    80003692:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003694:	00059783          	lh	a5,0(a1)
    80003698:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000369c:	00259783          	lh	a5,2(a1)
    800036a0:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800036a4:	00459783          	lh	a5,4(a1)
    800036a8:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800036ac:	00659783          	lh	a5,6(a1)
    800036b0:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800036b4:	459c                	lw	a5,8(a1)
    800036b6:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800036b8:	03400613          	li	a2,52
    800036bc:	05b1                	addi	a1,a1,12
    800036be:	05048513          	addi	a0,s1,80
    800036c2:	ffffd097          	auipc	ra,0xffffd
    800036c6:	67e080e7          	jalr	1662(ra) # 80000d40 <memmove>
    brelse(bp);
    800036ca:	854a                	mv	a0,s2
    800036cc:	00000097          	auipc	ra,0x0
    800036d0:	88e080e7          	jalr	-1906(ra) # 80002f5a <brelse>
    ip->valid = 1;
    800036d4:	4785                	li	a5,1
    800036d6:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800036d8:	04449783          	lh	a5,68(s1)
    800036dc:	fbb5                	bnez	a5,80003650 <ilock+0x24>
      panic("ilock: no type");
    800036de:	00005517          	auipc	a0,0x5
    800036e2:	ef250513          	addi	a0,a0,-270 # 800085d0 <syscalls+0x188>
    800036e6:	ffffd097          	auipc	ra,0xffffd
    800036ea:	e58080e7          	jalr	-424(ra) # 8000053e <panic>

00000000800036ee <iunlock>:
{
    800036ee:	1101                	addi	sp,sp,-32
    800036f0:	ec06                	sd	ra,24(sp)
    800036f2:	e822                	sd	s0,16(sp)
    800036f4:	e426                	sd	s1,8(sp)
    800036f6:	e04a                	sd	s2,0(sp)
    800036f8:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800036fa:	c905                	beqz	a0,8000372a <iunlock+0x3c>
    800036fc:	84aa                	mv	s1,a0
    800036fe:	01050913          	addi	s2,a0,16
    80003702:	854a                	mv	a0,s2
    80003704:	00001097          	auipc	ra,0x1
    80003708:	c8c080e7          	jalr	-884(ra) # 80004390 <holdingsleep>
    8000370c:	cd19                	beqz	a0,8000372a <iunlock+0x3c>
    8000370e:	449c                	lw	a5,8(s1)
    80003710:	00f05d63          	blez	a5,8000372a <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003714:	854a                	mv	a0,s2
    80003716:	00001097          	auipc	ra,0x1
    8000371a:	c36080e7          	jalr	-970(ra) # 8000434c <releasesleep>
}
    8000371e:	60e2                	ld	ra,24(sp)
    80003720:	6442                	ld	s0,16(sp)
    80003722:	64a2                	ld	s1,8(sp)
    80003724:	6902                	ld	s2,0(sp)
    80003726:	6105                	addi	sp,sp,32
    80003728:	8082                	ret
    panic("iunlock");
    8000372a:	00005517          	auipc	a0,0x5
    8000372e:	eb650513          	addi	a0,a0,-330 # 800085e0 <syscalls+0x198>
    80003732:	ffffd097          	auipc	ra,0xffffd
    80003736:	e0c080e7          	jalr	-500(ra) # 8000053e <panic>

000000008000373a <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000373a:	7179                	addi	sp,sp,-48
    8000373c:	f406                	sd	ra,40(sp)
    8000373e:	f022                	sd	s0,32(sp)
    80003740:	ec26                	sd	s1,24(sp)
    80003742:	e84a                	sd	s2,16(sp)
    80003744:	e44e                	sd	s3,8(sp)
    80003746:	e052                	sd	s4,0(sp)
    80003748:	1800                	addi	s0,sp,48
    8000374a:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000374c:	05050493          	addi	s1,a0,80
    80003750:	08050913          	addi	s2,a0,128
    80003754:	a021                	j	8000375c <itrunc+0x22>
    80003756:	0491                	addi	s1,s1,4
    80003758:	01248d63          	beq	s1,s2,80003772 <itrunc+0x38>
    if(ip->addrs[i]){
    8000375c:	408c                	lw	a1,0(s1)
    8000375e:	dde5                	beqz	a1,80003756 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003760:	0009a503          	lw	a0,0(s3)
    80003764:	00000097          	auipc	ra,0x0
    80003768:	90c080e7          	jalr	-1780(ra) # 80003070 <bfree>
      ip->addrs[i] = 0;
    8000376c:	0004a023          	sw	zero,0(s1)
    80003770:	b7dd                	j	80003756 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003772:	0809a583          	lw	a1,128(s3)
    80003776:	e185                	bnez	a1,80003796 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003778:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000377c:	854e                	mv	a0,s3
    8000377e:	00000097          	auipc	ra,0x0
    80003782:	de4080e7          	jalr	-540(ra) # 80003562 <iupdate>
}
    80003786:	70a2                	ld	ra,40(sp)
    80003788:	7402                	ld	s0,32(sp)
    8000378a:	64e2                	ld	s1,24(sp)
    8000378c:	6942                	ld	s2,16(sp)
    8000378e:	69a2                	ld	s3,8(sp)
    80003790:	6a02                	ld	s4,0(sp)
    80003792:	6145                	addi	sp,sp,48
    80003794:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003796:	0009a503          	lw	a0,0(s3)
    8000379a:	fffff097          	auipc	ra,0xfffff
    8000379e:	690080e7          	jalr	1680(ra) # 80002e2a <bread>
    800037a2:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800037a4:	05850493          	addi	s1,a0,88
    800037a8:	45850913          	addi	s2,a0,1112
    800037ac:	a811                	j	800037c0 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    800037ae:	0009a503          	lw	a0,0(s3)
    800037b2:	00000097          	auipc	ra,0x0
    800037b6:	8be080e7          	jalr	-1858(ra) # 80003070 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    800037ba:	0491                	addi	s1,s1,4
    800037bc:	01248563          	beq	s1,s2,800037c6 <itrunc+0x8c>
      if(a[j])
    800037c0:	408c                	lw	a1,0(s1)
    800037c2:	dde5                	beqz	a1,800037ba <itrunc+0x80>
    800037c4:	b7ed                	j	800037ae <itrunc+0x74>
    brelse(bp);
    800037c6:	8552                	mv	a0,s4
    800037c8:	fffff097          	auipc	ra,0xfffff
    800037cc:	792080e7          	jalr	1938(ra) # 80002f5a <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800037d0:	0809a583          	lw	a1,128(s3)
    800037d4:	0009a503          	lw	a0,0(s3)
    800037d8:	00000097          	auipc	ra,0x0
    800037dc:	898080e7          	jalr	-1896(ra) # 80003070 <bfree>
    ip->addrs[NDIRECT] = 0;
    800037e0:	0809a023          	sw	zero,128(s3)
    800037e4:	bf51                	j	80003778 <itrunc+0x3e>

00000000800037e6 <iput>:
{
    800037e6:	1101                	addi	sp,sp,-32
    800037e8:	ec06                	sd	ra,24(sp)
    800037ea:	e822                	sd	s0,16(sp)
    800037ec:	e426                	sd	s1,8(sp)
    800037ee:	e04a                	sd	s2,0(sp)
    800037f0:	1000                	addi	s0,sp,32
    800037f2:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800037f4:	0001c517          	auipc	a0,0x1c
    800037f8:	1d450513          	addi	a0,a0,468 # 8001f9c8 <itable>
    800037fc:	ffffd097          	auipc	ra,0xffffd
    80003800:	3e8080e7          	jalr	1000(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003804:	4498                	lw	a4,8(s1)
    80003806:	4785                	li	a5,1
    80003808:	02f70363          	beq	a4,a5,8000382e <iput+0x48>
  ip->ref--;
    8000380c:	449c                	lw	a5,8(s1)
    8000380e:	37fd                	addiw	a5,a5,-1
    80003810:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003812:	0001c517          	auipc	a0,0x1c
    80003816:	1b650513          	addi	a0,a0,438 # 8001f9c8 <itable>
    8000381a:	ffffd097          	auipc	ra,0xffffd
    8000381e:	47e080e7          	jalr	1150(ra) # 80000c98 <release>
}
    80003822:	60e2                	ld	ra,24(sp)
    80003824:	6442                	ld	s0,16(sp)
    80003826:	64a2                	ld	s1,8(sp)
    80003828:	6902                	ld	s2,0(sp)
    8000382a:	6105                	addi	sp,sp,32
    8000382c:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000382e:	40bc                	lw	a5,64(s1)
    80003830:	dff1                	beqz	a5,8000380c <iput+0x26>
    80003832:	04a49783          	lh	a5,74(s1)
    80003836:	fbf9                	bnez	a5,8000380c <iput+0x26>
    acquiresleep(&ip->lock);
    80003838:	01048913          	addi	s2,s1,16
    8000383c:	854a                	mv	a0,s2
    8000383e:	00001097          	auipc	ra,0x1
    80003842:	ab8080e7          	jalr	-1352(ra) # 800042f6 <acquiresleep>
    release(&itable.lock);
    80003846:	0001c517          	auipc	a0,0x1c
    8000384a:	18250513          	addi	a0,a0,386 # 8001f9c8 <itable>
    8000384e:	ffffd097          	auipc	ra,0xffffd
    80003852:	44a080e7          	jalr	1098(ra) # 80000c98 <release>
    itrunc(ip);
    80003856:	8526                	mv	a0,s1
    80003858:	00000097          	auipc	ra,0x0
    8000385c:	ee2080e7          	jalr	-286(ra) # 8000373a <itrunc>
    ip->type = 0;
    80003860:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003864:	8526                	mv	a0,s1
    80003866:	00000097          	auipc	ra,0x0
    8000386a:	cfc080e7          	jalr	-772(ra) # 80003562 <iupdate>
    ip->valid = 0;
    8000386e:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003872:	854a                	mv	a0,s2
    80003874:	00001097          	auipc	ra,0x1
    80003878:	ad8080e7          	jalr	-1320(ra) # 8000434c <releasesleep>
    acquire(&itable.lock);
    8000387c:	0001c517          	auipc	a0,0x1c
    80003880:	14c50513          	addi	a0,a0,332 # 8001f9c8 <itable>
    80003884:	ffffd097          	auipc	ra,0xffffd
    80003888:	360080e7          	jalr	864(ra) # 80000be4 <acquire>
    8000388c:	b741                	j	8000380c <iput+0x26>

000000008000388e <iunlockput>:
{
    8000388e:	1101                	addi	sp,sp,-32
    80003890:	ec06                	sd	ra,24(sp)
    80003892:	e822                	sd	s0,16(sp)
    80003894:	e426                	sd	s1,8(sp)
    80003896:	1000                	addi	s0,sp,32
    80003898:	84aa                	mv	s1,a0
  iunlock(ip);
    8000389a:	00000097          	auipc	ra,0x0
    8000389e:	e54080e7          	jalr	-428(ra) # 800036ee <iunlock>
  iput(ip);
    800038a2:	8526                	mv	a0,s1
    800038a4:	00000097          	auipc	ra,0x0
    800038a8:	f42080e7          	jalr	-190(ra) # 800037e6 <iput>
}
    800038ac:	60e2                	ld	ra,24(sp)
    800038ae:	6442                	ld	s0,16(sp)
    800038b0:	64a2                	ld	s1,8(sp)
    800038b2:	6105                	addi	sp,sp,32
    800038b4:	8082                	ret

00000000800038b6 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800038b6:	1141                	addi	sp,sp,-16
    800038b8:	e422                	sd	s0,8(sp)
    800038ba:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800038bc:	411c                	lw	a5,0(a0)
    800038be:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800038c0:	415c                	lw	a5,4(a0)
    800038c2:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800038c4:	04451783          	lh	a5,68(a0)
    800038c8:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800038cc:	04a51783          	lh	a5,74(a0)
    800038d0:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800038d4:	04c56783          	lwu	a5,76(a0)
    800038d8:	e99c                	sd	a5,16(a1)
}
    800038da:	6422                	ld	s0,8(sp)
    800038dc:	0141                	addi	sp,sp,16
    800038de:	8082                	ret

00000000800038e0 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800038e0:	457c                	lw	a5,76(a0)
    800038e2:	0ed7e963          	bltu	a5,a3,800039d4 <readi+0xf4>
{
    800038e6:	7159                	addi	sp,sp,-112
    800038e8:	f486                	sd	ra,104(sp)
    800038ea:	f0a2                	sd	s0,96(sp)
    800038ec:	eca6                	sd	s1,88(sp)
    800038ee:	e8ca                	sd	s2,80(sp)
    800038f0:	e4ce                	sd	s3,72(sp)
    800038f2:	e0d2                	sd	s4,64(sp)
    800038f4:	fc56                	sd	s5,56(sp)
    800038f6:	f85a                	sd	s6,48(sp)
    800038f8:	f45e                	sd	s7,40(sp)
    800038fa:	f062                	sd	s8,32(sp)
    800038fc:	ec66                	sd	s9,24(sp)
    800038fe:	e86a                	sd	s10,16(sp)
    80003900:	e46e                	sd	s11,8(sp)
    80003902:	1880                	addi	s0,sp,112
    80003904:	8baa                	mv	s7,a0
    80003906:	8c2e                	mv	s8,a1
    80003908:	8ab2                	mv	s5,a2
    8000390a:	84b6                	mv	s1,a3
    8000390c:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    8000390e:	9f35                	addw	a4,a4,a3
    return 0;
    80003910:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003912:	0ad76063          	bltu	a4,a3,800039b2 <readi+0xd2>
  if(off + n > ip->size)
    80003916:	00e7f463          	bgeu	a5,a4,8000391e <readi+0x3e>
    n = ip->size - off;
    8000391a:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000391e:	0a0b0963          	beqz	s6,800039d0 <readi+0xf0>
    80003922:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003924:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003928:	5cfd                	li	s9,-1
    8000392a:	a82d                	j	80003964 <readi+0x84>
    8000392c:	020a1d93          	slli	s11,s4,0x20
    80003930:	020ddd93          	srli	s11,s11,0x20
    80003934:	05890613          	addi	a2,s2,88
    80003938:	86ee                	mv	a3,s11
    8000393a:	963a                	add	a2,a2,a4
    8000393c:	85d6                	mv	a1,s5
    8000393e:	8562                	mv	a0,s8
    80003940:	fffff097          	auipc	ra,0xfffff
    80003944:	b2e080e7          	jalr	-1234(ra) # 8000246e <either_copyout>
    80003948:	05950d63          	beq	a0,s9,800039a2 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    8000394c:	854a                	mv	a0,s2
    8000394e:	fffff097          	auipc	ra,0xfffff
    80003952:	60c080e7          	jalr	1548(ra) # 80002f5a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003956:	013a09bb          	addw	s3,s4,s3
    8000395a:	009a04bb          	addw	s1,s4,s1
    8000395e:	9aee                	add	s5,s5,s11
    80003960:	0569f763          	bgeu	s3,s6,800039ae <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003964:	000ba903          	lw	s2,0(s7)
    80003968:	00a4d59b          	srliw	a1,s1,0xa
    8000396c:	855e                	mv	a0,s7
    8000396e:	00000097          	auipc	ra,0x0
    80003972:	8b0080e7          	jalr	-1872(ra) # 8000321e <bmap>
    80003976:	0005059b          	sext.w	a1,a0
    8000397a:	854a                	mv	a0,s2
    8000397c:	fffff097          	auipc	ra,0xfffff
    80003980:	4ae080e7          	jalr	1198(ra) # 80002e2a <bread>
    80003984:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003986:	3ff4f713          	andi	a4,s1,1023
    8000398a:	40ed07bb          	subw	a5,s10,a4
    8000398e:	413b06bb          	subw	a3,s6,s3
    80003992:	8a3e                	mv	s4,a5
    80003994:	2781                	sext.w	a5,a5
    80003996:	0006861b          	sext.w	a2,a3
    8000399a:	f8f679e3          	bgeu	a2,a5,8000392c <readi+0x4c>
    8000399e:	8a36                	mv	s4,a3
    800039a0:	b771                	j	8000392c <readi+0x4c>
      brelse(bp);
    800039a2:	854a                	mv	a0,s2
    800039a4:	fffff097          	auipc	ra,0xfffff
    800039a8:	5b6080e7          	jalr	1462(ra) # 80002f5a <brelse>
      tot = -1;
    800039ac:	59fd                	li	s3,-1
  }
  return tot;
    800039ae:	0009851b          	sext.w	a0,s3
}
    800039b2:	70a6                	ld	ra,104(sp)
    800039b4:	7406                	ld	s0,96(sp)
    800039b6:	64e6                	ld	s1,88(sp)
    800039b8:	6946                	ld	s2,80(sp)
    800039ba:	69a6                	ld	s3,72(sp)
    800039bc:	6a06                	ld	s4,64(sp)
    800039be:	7ae2                	ld	s5,56(sp)
    800039c0:	7b42                	ld	s6,48(sp)
    800039c2:	7ba2                	ld	s7,40(sp)
    800039c4:	7c02                	ld	s8,32(sp)
    800039c6:	6ce2                	ld	s9,24(sp)
    800039c8:	6d42                	ld	s10,16(sp)
    800039ca:	6da2                	ld	s11,8(sp)
    800039cc:	6165                	addi	sp,sp,112
    800039ce:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800039d0:	89da                	mv	s3,s6
    800039d2:	bff1                	j	800039ae <readi+0xce>
    return 0;
    800039d4:	4501                	li	a0,0
}
    800039d6:	8082                	ret

00000000800039d8 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800039d8:	457c                	lw	a5,76(a0)
    800039da:	10d7e863          	bltu	a5,a3,80003aea <writei+0x112>
{
    800039de:	7159                	addi	sp,sp,-112
    800039e0:	f486                	sd	ra,104(sp)
    800039e2:	f0a2                	sd	s0,96(sp)
    800039e4:	eca6                	sd	s1,88(sp)
    800039e6:	e8ca                	sd	s2,80(sp)
    800039e8:	e4ce                	sd	s3,72(sp)
    800039ea:	e0d2                	sd	s4,64(sp)
    800039ec:	fc56                	sd	s5,56(sp)
    800039ee:	f85a                	sd	s6,48(sp)
    800039f0:	f45e                	sd	s7,40(sp)
    800039f2:	f062                	sd	s8,32(sp)
    800039f4:	ec66                	sd	s9,24(sp)
    800039f6:	e86a                	sd	s10,16(sp)
    800039f8:	e46e                	sd	s11,8(sp)
    800039fa:	1880                	addi	s0,sp,112
    800039fc:	8b2a                	mv	s6,a0
    800039fe:	8c2e                	mv	s8,a1
    80003a00:	8ab2                	mv	s5,a2
    80003a02:	8936                	mv	s2,a3
    80003a04:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003a06:	00e687bb          	addw	a5,a3,a4
    80003a0a:	0ed7e263          	bltu	a5,a3,80003aee <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003a0e:	00043737          	lui	a4,0x43
    80003a12:	0ef76063          	bltu	a4,a5,80003af2 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a16:	0c0b8863          	beqz	s7,80003ae6 <writei+0x10e>
    80003a1a:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a1c:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003a20:	5cfd                	li	s9,-1
    80003a22:	a091                	j	80003a66 <writei+0x8e>
    80003a24:	02099d93          	slli	s11,s3,0x20
    80003a28:	020ddd93          	srli	s11,s11,0x20
    80003a2c:	05848513          	addi	a0,s1,88
    80003a30:	86ee                	mv	a3,s11
    80003a32:	8656                	mv	a2,s5
    80003a34:	85e2                	mv	a1,s8
    80003a36:	953a                	add	a0,a0,a4
    80003a38:	fffff097          	auipc	ra,0xfffff
    80003a3c:	a8c080e7          	jalr	-1396(ra) # 800024c4 <either_copyin>
    80003a40:	07950263          	beq	a0,s9,80003aa4 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003a44:	8526                	mv	a0,s1
    80003a46:	00000097          	auipc	ra,0x0
    80003a4a:	790080e7          	jalr	1936(ra) # 800041d6 <log_write>
    brelse(bp);
    80003a4e:	8526                	mv	a0,s1
    80003a50:	fffff097          	auipc	ra,0xfffff
    80003a54:	50a080e7          	jalr	1290(ra) # 80002f5a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a58:	01498a3b          	addw	s4,s3,s4
    80003a5c:	0129893b          	addw	s2,s3,s2
    80003a60:	9aee                	add	s5,s5,s11
    80003a62:	057a7663          	bgeu	s4,s7,80003aae <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003a66:	000b2483          	lw	s1,0(s6)
    80003a6a:	00a9559b          	srliw	a1,s2,0xa
    80003a6e:	855a                	mv	a0,s6
    80003a70:	fffff097          	auipc	ra,0xfffff
    80003a74:	7ae080e7          	jalr	1966(ra) # 8000321e <bmap>
    80003a78:	0005059b          	sext.w	a1,a0
    80003a7c:	8526                	mv	a0,s1
    80003a7e:	fffff097          	auipc	ra,0xfffff
    80003a82:	3ac080e7          	jalr	940(ra) # 80002e2a <bread>
    80003a86:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a88:	3ff97713          	andi	a4,s2,1023
    80003a8c:	40ed07bb          	subw	a5,s10,a4
    80003a90:	414b86bb          	subw	a3,s7,s4
    80003a94:	89be                	mv	s3,a5
    80003a96:	2781                	sext.w	a5,a5
    80003a98:	0006861b          	sext.w	a2,a3
    80003a9c:	f8f674e3          	bgeu	a2,a5,80003a24 <writei+0x4c>
    80003aa0:	89b6                	mv	s3,a3
    80003aa2:	b749                	j	80003a24 <writei+0x4c>
      brelse(bp);
    80003aa4:	8526                	mv	a0,s1
    80003aa6:	fffff097          	auipc	ra,0xfffff
    80003aaa:	4b4080e7          	jalr	1204(ra) # 80002f5a <brelse>
  }

  if(off > ip->size)
    80003aae:	04cb2783          	lw	a5,76(s6)
    80003ab2:	0127f463          	bgeu	a5,s2,80003aba <writei+0xe2>
    ip->size = off;
    80003ab6:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003aba:	855a                	mv	a0,s6
    80003abc:	00000097          	auipc	ra,0x0
    80003ac0:	aa6080e7          	jalr	-1370(ra) # 80003562 <iupdate>

  return tot;
    80003ac4:	000a051b          	sext.w	a0,s4
}
    80003ac8:	70a6                	ld	ra,104(sp)
    80003aca:	7406                	ld	s0,96(sp)
    80003acc:	64e6                	ld	s1,88(sp)
    80003ace:	6946                	ld	s2,80(sp)
    80003ad0:	69a6                	ld	s3,72(sp)
    80003ad2:	6a06                	ld	s4,64(sp)
    80003ad4:	7ae2                	ld	s5,56(sp)
    80003ad6:	7b42                	ld	s6,48(sp)
    80003ad8:	7ba2                	ld	s7,40(sp)
    80003ada:	7c02                	ld	s8,32(sp)
    80003adc:	6ce2                	ld	s9,24(sp)
    80003ade:	6d42                	ld	s10,16(sp)
    80003ae0:	6da2                	ld	s11,8(sp)
    80003ae2:	6165                	addi	sp,sp,112
    80003ae4:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ae6:	8a5e                	mv	s4,s7
    80003ae8:	bfc9                	j	80003aba <writei+0xe2>
    return -1;
    80003aea:	557d                	li	a0,-1
}
    80003aec:	8082                	ret
    return -1;
    80003aee:	557d                	li	a0,-1
    80003af0:	bfe1                	j	80003ac8 <writei+0xf0>
    return -1;
    80003af2:	557d                	li	a0,-1
    80003af4:	bfd1                	j	80003ac8 <writei+0xf0>

0000000080003af6 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003af6:	1141                	addi	sp,sp,-16
    80003af8:	e406                	sd	ra,8(sp)
    80003afa:	e022                	sd	s0,0(sp)
    80003afc:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003afe:	4639                	li	a2,14
    80003b00:	ffffd097          	auipc	ra,0xffffd
    80003b04:	2b8080e7          	jalr	696(ra) # 80000db8 <strncmp>
}
    80003b08:	60a2                	ld	ra,8(sp)
    80003b0a:	6402                	ld	s0,0(sp)
    80003b0c:	0141                	addi	sp,sp,16
    80003b0e:	8082                	ret

0000000080003b10 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003b10:	7139                	addi	sp,sp,-64
    80003b12:	fc06                	sd	ra,56(sp)
    80003b14:	f822                	sd	s0,48(sp)
    80003b16:	f426                	sd	s1,40(sp)
    80003b18:	f04a                	sd	s2,32(sp)
    80003b1a:	ec4e                	sd	s3,24(sp)
    80003b1c:	e852                	sd	s4,16(sp)
    80003b1e:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003b20:	04451703          	lh	a4,68(a0)
    80003b24:	4785                	li	a5,1
    80003b26:	00f71a63          	bne	a4,a5,80003b3a <dirlookup+0x2a>
    80003b2a:	892a                	mv	s2,a0
    80003b2c:	89ae                	mv	s3,a1
    80003b2e:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b30:	457c                	lw	a5,76(a0)
    80003b32:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003b34:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b36:	e79d                	bnez	a5,80003b64 <dirlookup+0x54>
    80003b38:	a8a5                	j	80003bb0 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003b3a:	00005517          	auipc	a0,0x5
    80003b3e:	aae50513          	addi	a0,a0,-1362 # 800085e8 <syscalls+0x1a0>
    80003b42:	ffffd097          	auipc	ra,0xffffd
    80003b46:	9fc080e7          	jalr	-1540(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003b4a:	00005517          	auipc	a0,0x5
    80003b4e:	ab650513          	addi	a0,a0,-1354 # 80008600 <syscalls+0x1b8>
    80003b52:	ffffd097          	auipc	ra,0xffffd
    80003b56:	9ec080e7          	jalr	-1556(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b5a:	24c1                	addiw	s1,s1,16
    80003b5c:	04c92783          	lw	a5,76(s2)
    80003b60:	04f4f763          	bgeu	s1,a5,80003bae <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003b64:	4741                	li	a4,16
    80003b66:	86a6                	mv	a3,s1
    80003b68:	fc040613          	addi	a2,s0,-64
    80003b6c:	4581                	li	a1,0
    80003b6e:	854a                	mv	a0,s2
    80003b70:	00000097          	auipc	ra,0x0
    80003b74:	d70080e7          	jalr	-656(ra) # 800038e0 <readi>
    80003b78:	47c1                	li	a5,16
    80003b7a:	fcf518e3          	bne	a0,a5,80003b4a <dirlookup+0x3a>
    if(de.inum == 0)
    80003b7e:	fc045783          	lhu	a5,-64(s0)
    80003b82:	dfe1                	beqz	a5,80003b5a <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003b84:	fc240593          	addi	a1,s0,-62
    80003b88:	854e                	mv	a0,s3
    80003b8a:	00000097          	auipc	ra,0x0
    80003b8e:	f6c080e7          	jalr	-148(ra) # 80003af6 <namecmp>
    80003b92:	f561                	bnez	a0,80003b5a <dirlookup+0x4a>
      if(poff)
    80003b94:	000a0463          	beqz	s4,80003b9c <dirlookup+0x8c>
        *poff = off;
    80003b98:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003b9c:	fc045583          	lhu	a1,-64(s0)
    80003ba0:	00092503          	lw	a0,0(s2)
    80003ba4:	fffff097          	auipc	ra,0xfffff
    80003ba8:	754080e7          	jalr	1876(ra) # 800032f8 <iget>
    80003bac:	a011                	j	80003bb0 <dirlookup+0xa0>
  return 0;
    80003bae:	4501                	li	a0,0
}
    80003bb0:	70e2                	ld	ra,56(sp)
    80003bb2:	7442                	ld	s0,48(sp)
    80003bb4:	74a2                	ld	s1,40(sp)
    80003bb6:	7902                	ld	s2,32(sp)
    80003bb8:	69e2                	ld	s3,24(sp)
    80003bba:	6a42                	ld	s4,16(sp)
    80003bbc:	6121                	addi	sp,sp,64
    80003bbe:	8082                	ret

0000000080003bc0 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003bc0:	711d                	addi	sp,sp,-96
    80003bc2:	ec86                	sd	ra,88(sp)
    80003bc4:	e8a2                	sd	s0,80(sp)
    80003bc6:	e4a6                	sd	s1,72(sp)
    80003bc8:	e0ca                	sd	s2,64(sp)
    80003bca:	fc4e                	sd	s3,56(sp)
    80003bcc:	f852                	sd	s4,48(sp)
    80003bce:	f456                	sd	s5,40(sp)
    80003bd0:	f05a                	sd	s6,32(sp)
    80003bd2:	ec5e                	sd	s7,24(sp)
    80003bd4:	e862                	sd	s8,16(sp)
    80003bd6:	e466                	sd	s9,8(sp)
    80003bd8:	1080                	addi	s0,sp,96
    80003bda:	84aa                	mv	s1,a0
    80003bdc:	8b2e                	mv	s6,a1
    80003bde:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003be0:	00054703          	lbu	a4,0(a0)
    80003be4:	02f00793          	li	a5,47
    80003be8:	02f70363          	beq	a4,a5,80003c0e <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003bec:	ffffe097          	auipc	ra,0xffffe
    80003bf0:	e30080e7          	jalr	-464(ra) # 80001a1c <myproc>
    80003bf4:	15053503          	ld	a0,336(a0)
    80003bf8:	00000097          	auipc	ra,0x0
    80003bfc:	9f6080e7          	jalr	-1546(ra) # 800035ee <idup>
    80003c00:	89aa                	mv	s3,a0
  while(*path == '/')
    80003c02:	02f00913          	li	s2,47
  len = path - s;
    80003c06:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003c08:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003c0a:	4c05                	li	s8,1
    80003c0c:	a865                	j	80003cc4 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003c0e:	4585                	li	a1,1
    80003c10:	4505                	li	a0,1
    80003c12:	fffff097          	auipc	ra,0xfffff
    80003c16:	6e6080e7          	jalr	1766(ra) # 800032f8 <iget>
    80003c1a:	89aa                	mv	s3,a0
    80003c1c:	b7dd                	j	80003c02 <namex+0x42>
      iunlockput(ip);
    80003c1e:	854e                	mv	a0,s3
    80003c20:	00000097          	auipc	ra,0x0
    80003c24:	c6e080e7          	jalr	-914(ra) # 8000388e <iunlockput>
      return 0;
    80003c28:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003c2a:	854e                	mv	a0,s3
    80003c2c:	60e6                	ld	ra,88(sp)
    80003c2e:	6446                	ld	s0,80(sp)
    80003c30:	64a6                	ld	s1,72(sp)
    80003c32:	6906                	ld	s2,64(sp)
    80003c34:	79e2                	ld	s3,56(sp)
    80003c36:	7a42                	ld	s4,48(sp)
    80003c38:	7aa2                	ld	s5,40(sp)
    80003c3a:	7b02                	ld	s6,32(sp)
    80003c3c:	6be2                	ld	s7,24(sp)
    80003c3e:	6c42                	ld	s8,16(sp)
    80003c40:	6ca2                	ld	s9,8(sp)
    80003c42:	6125                	addi	sp,sp,96
    80003c44:	8082                	ret
      iunlock(ip);
    80003c46:	854e                	mv	a0,s3
    80003c48:	00000097          	auipc	ra,0x0
    80003c4c:	aa6080e7          	jalr	-1370(ra) # 800036ee <iunlock>
      return ip;
    80003c50:	bfe9                	j	80003c2a <namex+0x6a>
      iunlockput(ip);
    80003c52:	854e                	mv	a0,s3
    80003c54:	00000097          	auipc	ra,0x0
    80003c58:	c3a080e7          	jalr	-966(ra) # 8000388e <iunlockput>
      return 0;
    80003c5c:	89d2                	mv	s3,s4
    80003c5e:	b7f1                	j	80003c2a <namex+0x6a>
  len = path - s;
    80003c60:	40b48633          	sub	a2,s1,a1
    80003c64:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003c68:	094cd463          	bge	s9,s4,80003cf0 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003c6c:	4639                	li	a2,14
    80003c6e:	8556                	mv	a0,s5
    80003c70:	ffffd097          	auipc	ra,0xffffd
    80003c74:	0d0080e7          	jalr	208(ra) # 80000d40 <memmove>
  while(*path == '/')
    80003c78:	0004c783          	lbu	a5,0(s1)
    80003c7c:	01279763          	bne	a5,s2,80003c8a <namex+0xca>
    path++;
    80003c80:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003c82:	0004c783          	lbu	a5,0(s1)
    80003c86:	ff278de3          	beq	a5,s2,80003c80 <namex+0xc0>
    ilock(ip);
    80003c8a:	854e                	mv	a0,s3
    80003c8c:	00000097          	auipc	ra,0x0
    80003c90:	9a0080e7          	jalr	-1632(ra) # 8000362c <ilock>
    if(ip->type != T_DIR){
    80003c94:	04499783          	lh	a5,68(s3)
    80003c98:	f98793e3          	bne	a5,s8,80003c1e <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003c9c:	000b0563          	beqz	s6,80003ca6 <namex+0xe6>
    80003ca0:	0004c783          	lbu	a5,0(s1)
    80003ca4:	d3cd                	beqz	a5,80003c46 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003ca6:	865e                	mv	a2,s7
    80003ca8:	85d6                	mv	a1,s5
    80003caa:	854e                	mv	a0,s3
    80003cac:	00000097          	auipc	ra,0x0
    80003cb0:	e64080e7          	jalr	-412(ra) # 80003b10 <dirlookup>
    80003cb4:	8a2a                	mv	s4,a0
    80003cb6:	dd51                	beqz	a0,80003c52 <namex+0x92>
    iunlockput(ip);
    80003cb8:	854e                	mv	a0,s3
    80003cba:	00000097          	auipc	ra,0x0
    80003cbe:	bd4080e7          	jalr	-1068(ra) # 8000388e <iunlockput>
    ip = next;
    80003cc2:	89d2                	mv	s3,s4
  while(*path == '/')
    80003cc4:	0004c783          	lbu	a5,0(s1)
    80003cc8:	05279763          	bne	a5,s2,80003d16 <namex+0x156>
    path++;
    80003ccc:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003cce:	0004c783          	lbu	a5,0(s1)
    80003cd2:	ff278de3          	beq	a5,s2,80003ccc <namex+0x10c>
  if(*path == 0)
    80003cd6:	c79d                	beqz	a5,80003d04 <namex+0x144>
    path++;
    80003cd8:	85a6                	mv	a1,s1
  len = path - s;
    80003cda:	8a5e                	mv	s4,s7
    80003cdc:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003cde:	01278963          	beq	a5,s2,80003cf0 <namex+0x130>
    80003ce2:	dfbd                	beqz	a5,80003c60 <namex+0xa0>
    path++;
    80003ce4:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003ce6:	0004c783          	lbu	a5,0(s1)
    80003cea:	ff279ce3          	bne	a5,s2,80003ce2 <namex+0x122>
    80003cee:	bf8d                	j	80003c60 <namex+0xa0>
    memmove(name, s, len);
    80003cf0:	2601                	sext.w	a2,a2
    80003cf2:	8556                	mv	a0,s5
    80003cf4:	ffffd097          	auipc	ra,0xffffd
    80003cf8:	04c080e7          	jalr	76(ra) # 80000d40 <memmove>
    name[len] = 0;
    80003cfc:	9a56                	add	s4,s4,s5
    80003cfe:	000a0023          	sb	zero,0(s4)
    80003d02:	bf9d                	j	80003c78 <namex+0xb8>
  if(nameiparent){
    80003d04:	f20b03e3          	beqz	s6,80003c2a <namex+0x6a>
    iput(ip);
    80003d08:	854e                	mv	a0,s3
    80003d0a:	00000097          	auipc	ra,0x0
    80003d0e:	adc080e7          	jalr	-1316(ra) # 800037e6 <iput>
    return 0;
    80003d12:	4981                	li	s3,0
    80003d14:	bf19                	j	80003c2a <namex+0x6a>
  if(*path == 0)
    80003d16:	d7fd                	beqz	a5,80003d04 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003d18:	0004c783          	lbu	a5,0(s1)
    80003d1c:	85a6                	mv	a1,s1
    80003d1e:	b7d1                	j	80003ce2 <namex+0x122>

0000000080003d20 <dirlink>:
{
    80003d20:	7139                	addi	sp,sp,-64
    80003d22:	fc06                	sd	ra,56(sp)
    80003d24:	f822                	sd	s0,48(sp)
    80003d26:	f426                	sd	s1,40(sp)
    80003d28:	f04a                	sd	s2,32(sp)
    80003d2a:	ec4e                	sd	s3,24(sp)
    80003d2c:	e852                	sd	s4,16(sp)
    80003d2e:	0080                	addi	s0,sp,64
    80003d30:	892a                	mv	s2,a0
    80003d32:	8a2e                	mv	s4,a1
    80003d34:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003d36:	4601                	li	a2,0
    80003d38:	00000097          	auipc	ra,0x0
    80003d3c:	dd8080e7          	jalr	-552(ra) # 80003b10 <dirlookup>
    80003d40:	e93d                	bnez	a0,80003db6 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d42:	04c92483          	lw	s1,76(s2)
    80003d46:	c49d                	beqz	s1,80003d74 <dirlink+0x54>
    80003d48:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d4a:	4741                	li	a4,16
    80003d4c:	86a6                	mv	a3,s1
    80003d4e:	fc040613          	addi	a2,s0,-64
    80003d52:	4581                	li	a1,0
    80003d54:	854a                	mv	a0,s2
    80003d56:	00000097          	auipc	ra,0x0
    80003d5a:	b8a080e7          	jalr	-1142(ra) # 800038e0 <readi>
    80003d5e:	47c1                	li	a5,16
    80003d60:	06f51163          	bne	a0,a5,80003dc2 <dirlink+0xa2>
    if(de.inum == 0)
    80003d64:	fc045783          	lhu	a5,-64(s0)
    80003d68:	c791                	beqz	a5,80003d74 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d6a:	24c1                	addiw	s1,s1,16
    80003d6c:	04c92783          	lw	a5,76(s2)
    80003d70:	fcf4ede3          	bltu	s1,a5,80003d4a <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003d74:	4639                	li	a2,14
    80003d76:	85d2                	mv	a1,s4
    80003d78:	fc240513          	addi	a0,s0,-62
    80003d7c:	ffffd097          	auipc	ra,0xffffd
    80003d80:	078080e7          	jalr	120(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80003d84:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d88:	4741                	li	a4,16
    80003d8a:	86a6                	mv	a3,s1
    80003d8c:	fc040613          	addi	a2,s0,-64
    80003d90:	4581                	li	a1,0
    80003d92:	854a                	mv	a0,s2
    80003d94:	00000097          	auipc	ra,0x0
    80003d98:	c44080e7          	jalr	-956(ra) # 800039d8 <writei>
    80003d9c:	872a                	mv	a4,a0
    80003d9e:	47c1                	li	a5,16
  return 0;
    80003da0:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003da2:	02f71863          	bne	a4,a5,80003dd2 <dirlink+0xb2>
}
    80003da6:	70e2                	ld	ra,56(sp)
    80003da8:	7442                	ld	s0,48(sp)
    80003daa:	74a2                	ld	s1,40(sp)
    80003dac:	7902                	ld	s2,32(sp)
    80003dae:	69e2                	ld	s3,24(sp)
    80003db0:	6a42                	ld	s4,16(sp)
    80003db2:	6121                	addi	sp,sp,64
    80003db4:	8082                	ret
    iput(ip);
    80003db6:	00000097          	auipc	ra,0x0
    80003dba:	a30080e7          	jalr	-1488(ra) # 800037e6 <iput>
    return -1;
    80003dbe:	557d                	li	a0,-1
    80003dc0:	b7dd                	j	80003da6 <dirlink+0x86>
      panic("dirlink read");
    80003dc2:	00005517          	auipc	a0,0x5
    80003dc6:	84e50513          	addi	a0,a0,-1970 # 80008610 <syscalls+0x1c8>
    80003dca:	ffffc097          	auipc	ra,0xffffc
    80003dce:	774080e7          	jalr	1908(ra) # 8000053e <panic>
    panic("dirlink");
    80003dd2:	00005517          	auipc	a0,0x5
    80003dd6:	94e50513          	addi	a0,a0,-1714 # 80008720 <syscalls+0x2d8>
    80003dda:	ffffc097          	auipc	ra,0xffffc
    80003dde:	764080e7          	jalr	1892(ra) # 8000053e <panic>

0000000080003de2 <namei>:

struct inode*
namei(char *path)
{
    80003de2:	1101                	addi	sp,sp,-32
    80003de4:	ec06                	sd	ra,24(sp)
    80003de6:	e822                	sd	s0,16(sp)
    80003de8:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003dea:	fe040613          	addi	a2,s0,-32
    80003dee:	4581                	li	a1,0
    80003df0:	00000097          	auipc	ra,0x0
    80003df4:	dd0080e7          	jalr	-560(ra) # 80003bc0 <namex>
}
    80003df8:	60e2                	ld	ra,24(sp)
    80003dfa:	6442                	ld	s0,16(sp)
    80003dfc:	6105                	addi	sp,sp,32
    80003dfe:	8082                	ret

0000000080003e00 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003e00:	1141                	addi	sp,sp,-16
    80003e02:	e406                	sd	ra,8(sp)
    80003e04:	e022                	sd	s0,0(sp)
    80003e06:	0800                	addi	s0,sp,16
    80003e08:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003e0a:	4585                	li	a1,1
    80003e0c:	00000097          	auipc	ra,0x0
    80003e10:	db4080e7          	jalr	-588(ra) # 80003bc0 <namex>
}
    80003e14:	60a2                	ld	ra,8(sp)
    80003e16:	6402                	ld	s0,0(sp)
    80003e18:	0141                	addi	sp,sp,16
    80003e1a:	8082                	ret

0000000080003e1c <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003e1c:	1101                	addi	sp,sp,-32
    80003e1e:	ec06                	sd	ra,24(sp)
    80003e20:	e822                	sd	s0,16(sp)
    80003e22:	e426                	sd	s1,8(sp)
    80003e24:	e04a                	sd	s2,0(sp)
    80003e26:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003e28:	0001d917          	auipc	s2,0x1d
    80003e2c:	64890913          	addi	s2,s2,1608 # 80021470 <log>
    80003e30:	01892583          	lw	a1,24(s2)
    80003e34:	02892503          	lw	a0,40(s2)
    80003e38:	fffff097          	auipc	ra,0xfffff
    80003e3c:	ff2080e7          	jalr	-14(ra) # 80002e2a <bread>
    80003e40:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003e42:	02c92683          	lw	a3,44(s2)
    80003e46:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003e48:	02d05763          	blez	a3,80003e76 <write_head+0x5a>
    80003e4c:	0001d797          	auipc	a5,0x1d
    80003e50:	65478793          	addi	a5,a5,1620 # 800214a0 <log+0x30>
    80003e54:	05c50713          	addi	a4,a0,92
    80003e58:	36fd                	addiw	a3,a3,-1
    80003e5a:	1682                	slli	a3,a3,0x20
    80003e5c:	9281                	srli	a3,a3,0x20
    80003e5e:	068a                	slli	a3,a3,0x2
    80003e60:	0001d617          	auipc	a2,0x1d
    80003e64:	64460613          	addi	a2,a2,1604 # 800214a4 <log+0x34>
    80003e68:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003e6a:	4390                	lw	a2,0(a5)
    80003e6c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003e6e:	0791                	addi	a5,a5,4
    80003e70:	0711                	addi	a4,a4,4
    80003e72:	fed79ce3          	bne	a5,a3,80003e6a <write_head+0x4e>
  }
  bwrite(buf);
    80003e76:	8526                	mv	a0,s1
    80003e78:	fffff097          	auipc	ra,0xfffff
    80003e7c:	0a4080e7          	jalr	164(ra) # 80002f1c <bwrite>
  brelse(buf);
    80003e80:	8526                	mv	a0,s1
    80003e82:	fffff097          	auipc	ra,0xfffff
    80003e86:	0d8080e7          	jalr	216(ra) # 80002f5a <brelse>
}
    80003e8a:	60e2                	ld	ra,24(sp)
    80003e8c:	6442                	ld	s0,16(sp)
    80003e8e:	64a2                	ld	s1,8(sp)
    80003e90:	6902                	ld	s2,0(sp)
    80003e92:	6105                	addi	sp,sp,32
    80003e94:	8082                	ret

0000000080003e96 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003e96:	0001d797          	auipc	a5,0x1d
    80003e9a:	6067a783          	lw	a5,1542(a5) # 8002149c <log+0x2c>
    80003e9e:	0af05d63          	blez	a5,80003f58 <install_trans+0xc2>
{
    80003ea2:	7139                	addi	sp,sp,-64
    80003ea4:	fc06                	sd	ra,56(sp)
    80003ea6:	f822                	sd	s0,48(sp)
    80003ea8:	f426                	sd	s1,40(sp)
    80003eaa:	f04a                	sd	s2,32(sp)
    80003eac:	ec4e                	sd	s3,24(sp)
    80003eae:	e852                	sd	s4,16(sp)
    80003eb0:	e456                	sd	s5,8(sp)
    80003eb2:	e05a                	sd	s6,0(sp)
    80003eb4:	0080                	addi	s0,sp,64
    80003eb6:	8b2a                	mv	s6,a0
    80003eb8:	0001da97          	auipc	s5,0x1d
    80003ebc:	5e8a8a93          	addi	s5,s5,1512 # 800214a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003ec0:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003ec2:	0001d997          	auipc	s3,0x1d
    80003ec6:	5ae98993          	addi	s3,s3,1454 # 80021470 <log>
    80003eca:	a035                	j	80003ef6 <install_trans+0x60>
      bunpin(dbuf);
    80003ecc:	8526                	mv	a0,s1
    80003ece:	fffff097          	auipc	ra,0xfffff
    80003ed2:	166080e7          	jalr	358(ra) # 80003034 <bunpin>
    brelse(lbuf);
    80003ed6:	854a                	mv	a0,s2
    80003ed8:	fffff097          	auipc	ra,0xfffff
    80003edc:	082080e7          	jalr	130(ra) # 80002f5a <brelse>
    brelse(dbuf);
    80003ee0:	8526                	mv	a0,s1
    80003ee2:	fffff097          	auipc	ra,0xfffff
    80003ee6:	078080e7          	jalr	120(ra) # 80002f5a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003eea:	2a05                	addiw	s4,s4,1
    80003eec:	0a91                	addi	s5,s5,4
    80003eee:	02c9a783          	lw	a5,44(s3)
    80003ef2:	04fa5963          	bge	s4,a5,80003f44 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003ef6:	0189a583          	lw	a1,24(s3)
    80003efa:	014585bb          	addw	a1,a1,s4
    80003efe:	2585                	addiw	a1,a1,1
    80003f00:	0289a503          	lw	a0,40(s3)
    80003f04:	fffff097          	auipc	ra,0xfffff
    80003f08:	f26080e7          	jalr	-218(ra) # 80002e2a <bread>
    80003f0c:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003f0e:	000aa583          	lw	a1,0(s5)
    80003f12:	0289a503          	lw	a0,40(s3)
    80003f16:	fffff097          	auipc	ra,0xfffff
    80003f1a:	f14080e7          	jalr	-236(ra) # 80002e2a <bread>
    80003f1e:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003f20:	40000613          	li	a2,1024
    80003f24:	05890593          	addi	a1,s2,88
    80003f28:	05850513          	addi	a0,a0,88
    80003f2c:	ffffd097          	auipc	ra,0xffffd
    80003f30:	e14080e7          	jalr	-492(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    80003f34:	8526                	mv	a0,s1
    80003f36:	fffff097          	auipc	ra,0xfffff
    80003f3a:	fe6080e7          	jalr	-26(ra) # 80002f1c <bwrite>
    if(recovering == 0)
    80003f3e:	f80b1ce3          	bnez	s6,80003ed6 <install_trans+0x40>
    80003f42:	b769                	j	80003ecc <install_trans+0x36>
}
    80003f44:	70e2                	ld	ra,56(sp)
    80003f46:	7442                	ld	s0,48(sp)
    80003f48:	74a2                	ld	s1,40(sp)
    80003f4a:	7902                	ld	s2,32(sp)
    80003f4c:	69e2                	ld	s3,24(sp)
    80003f4e:	6a42                	ld	s4,16(sp)
    80003f50:	6aa2                	ld	s5,8(sp)
    80003f52:	6b02                	ld	s6,0(sp)
    80003f54:	6121                	addi	sp,sp,64
    80003f56:	8082                	ret
    80003f58:	8082                	ret

0000000080003f5a <initlog>:
{
    80003f5a:	7179                	addi	sp,sp,-48
    80003f5c:	f406                	sd	ra,40(sp)
    80003f5e:	f022                	sd	s0,32(sp)
    80003f60:	ec26                	sd	s1,24(sp)
    80003f62:	e84a                	sd	s2,16(sp)
    80003f64:	e44e                	sd	s3,8(sp)
    80003f66:	1800                	addi	s0,sp,48
    80003f68:	892a                	mv	s2,a0
    80003f6a:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003f6c:	0001d497          	auipc	s1,0x1d
    80003f70:	50448493          	addi	s1,s1,1284 # 80021470 <log>
    80003f74:	00004597          	auipc	a1,0x4
    80003f78:	6ac58593          	addi	a1,a1,1708 # 80008620 <syscalls+0x1d8>
    80003f7c:	8526                	mv	a0,s1
    80003f7e:	ffffd097          	auipc	ra,0xffffd
    80003f82:	bd6080e7          	jalr	-1066(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80003f86:	0149a583          	lw	a1,20(s3)
    80003f8a:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80003f8c:	0109a783          	lw	a5,16(s3)
    80003f90:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80003f92:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80003f96:	854a                	mv	a0,s2
    80003f98:	fffff097          	auipc	ra,0xfffff
    80003f9c:	e92080e7          	jalr	-366(ra) # 80002e2a <bread>
  log.lh.n = lh->n;
    80003fa0:	4d3c                	lw	a5,88(a0)
    80003fa2:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80003fa4:	02f05563          	blez	a5,80003fce <initlog+0x74>
    80003fa8:	05c50713          	addi	a4,a0,92
    80003fac:	0001d697          	auipc	a3,0x1d
    80003fb0:	4f468693          	addi	a3,a3,1268 # 800214a0 <log+0x30>
    80003fb4:	37fd                	addiw	a5,a5,-1
    80003fb6:	1782                	slli	a5,a5,0x20
    80003fb8:	9381                	srli	a5,a5,0x20
    80003fba:	078a                	slli	a5,a5,0x2
    80003fbc:	06050613          	addi	a2,a0,96
    80003fc0:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80003fc2:	4310                	lw	a2,0(a4)
    80003fc4:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80003fc6:	0711                	addi	a4,a4,4
    80003fc8:	0691                	addi	a3,a3,4
    80003fca:	fef71ce3          	bne	a4,a5,80003fc2 <initlog+0x68>
  brelse(buf);
    80003fce:	fffff097          	auipc	ra,0xfffff
    80003fd2:	f8c080e7          	jalr	-116(ra) # 80002f5a <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80003fd6:	4505                	li	a0,1
    80003fd8:	00000097          	auipc	ra,0x0
    80003fdc:	ebe080e7          	jalr	-322(ra) # 80003e96 <install_trans>
  log.lh.n = 0;
    80003fe0:	0001d797          	auipc	a5,0x1d
    80003fe4:	4a07ae23          	sw	zero,1212(a5) # 8002149c <log+0x2c>
  write_head(); // clear the log
    80003fe8:	00000097          	auipc	ra,0x0
    80003fec:	e34080e7          	jalr	-460(ra) # 80003e1c <write_head>
}
    80003ff0:	70a2                	ld	ra,40(sp)
    80003ff2:	7402                	ld	s0,32(sp)
    80003ff4:	64e2                	ld	s1,24(sp)
    80003ff6:	6942                	ld	s2,16(sp)
    80003ff8:	69a2                	ld	s3,8(sp)
    80003ffa:	6145                	addi	sp,sp,48
    80003ffc:	8082                	ret

0000000080003ffe <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80003ffe:	1101                	addi	sp,sp,-32
    80004000:	ec06                	sd	ra,24(sp)
    80004002:	e822                	sd	s0,16(sp)
    80004004:	e426                	sd	s1,8(sp)
    80004006:	e04a                	sd	s2,0(sp)
    80004008:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000400a:	0001d517          	auipc	a0,0x1d
    8000400e:	46650513          	addi	a0,a0,1126 # 80021470 <log>
    80004012:	ffffd097          	auipc	ra,0xffffd
    80004016:	bd2080e7          	jalr	-1070(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    8000401a:	0001d497          	auipc	s1,0x1d
    8000401e:	45648493          	addi	s1,s1,1110 # 80021470 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004022:	4979                	li	s2,30
    80004024:	a039                	j	80004032 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004026:	85a6                	mv	a1,s1
    80004028:	8526                	mv	a0,s1
    8000402a:	ffffe097          	auipc	ra,0xffffe
    8000402e:	0a0080e7          	jalr	160(ra) # 800020ca <sleep>
    if(log.committing){
    80004032:	50dc                	lw	a5,36(s1)
    80004034:	fbed                	bnez	a5,80004026 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004036:	509c                	lw	a5,32(s1)
    80004038:	0017871b          	addiw	a4,a5,1
    8000403c:	0007069b          	sext.w	a3,a4
    80004040:	0027179b          	slliw	a5,a4,0x2
    80004044:	9fb9                	addw	a5,a5,a4
    80004046:	0017979b          	slliw	a5,a5,0x1
    8000404a:	54d8                	lw	a4,44(s1)
    8000404c:	9fb9                	addw	a5,a5,a4
    8000404e:	00f95963          	bge	s2,a5,80004060 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004052:	85a6                	mv	a1,s1
    80004054:	8526                	mv	a0,s1
    80004056:	ffffe097          	auipc	ra,0xffffe
    8000405a:	074080e7          	jalr	116(ra) # 800020ca <sleep>
    8000405e:	bfd1                	j	80004032 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004060:	0001d517          	auipc	a0,0x1d
    80004064:	41050513          	addi	a0,a0,1040 # 80021470 <log>
    80004068:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000406a:	ffffd097          	auipc	ra,0xffffd
    8000406e:	c2e080e7          	jalr	-978(ra) # 80000c98 <release>
      break;
    }
  }
}
    80004072:	60e2                	ld	ra,24(sp)
    80004074:	6442                	ld	s0,16(sp)
    80004076:	64a2                	ld	s1,8(sp)
    80004078:	6902                	ld	s2,0(sp)
    8000407a:	6105                	addi	sp,sp,32
    8000407c:	8082                	ret

000000008000407e <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000407e:	7139                	addi	sp,sp,-64
    80004080:	fc06                	sd	ra,56(sp)
    80004082:	f822                	sd	s0,48(sp)
    80004084:	f426                	sd	s1,40(sp)
    80004086:	f04a                	sd	s2,32(sp)
    80004088:	ec4e                	sd	s3,24(sp)
    8000408a:	e852                	sd	s4,16(sp)
    8000408c:	e456                	sd	s5,8(sp)
    8000408e:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004090:	0001d497          	auipc	s1,0x1d
    80004094:	3e048493          	addi	s1,s1,992 # 80021470 <log>
    80004098:	8526                	mv	a0,s1
    8000409a:	ffffd097          	auipc	ra,0xffffd
    8000409e:	b4a080e7          	jalr	-1206(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    800040a2:	509c                	lw	a5,32(s1)
    800040a4:	37fd                	addiw	a5,a5,-1
    800040a6:	0007891b          	sext.w	s2,a5
    800040aa:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800040ac:	50dc                	lw	a5,36(s1)
    800040ae:	efb9                	bnez	a5,8000410c <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800040b0:	06091663          	bnez	s2,8000411c <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800040b4:	0001d497          	auipc	s1,0x1d
    800040b8:	3bc48493          	addi	s1,s1,956 # 80021470 <log>
    800040bc:	4785                	li	a5,1
    800040be:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800040c0:	8526                	mv	a0,s1
    800040c2:	ffffd097          	auipc	ra,0xffffd
    800040c6:	bd6080e7          	jalr	-1066(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800040ca:	54dc                	lw	a5,44(s1)
    800040cc:	06f04763          	bgtz	a5,8000413a <end_op+0xbc>
    acquire(&log.lock);
    800040d0:	0001d497          	auipc	s1,0x1d
    800040d4:	3a048493          	addi	s1,s1,928 # 80021470 <log>
    800040d8:	8526                	mv	a0,s1
    800040da:	ffffd097          	auipc	ra,0xffffd
    800040de:	b0a080e7          	jalr	-1270(ra) # 80000be4 <acquire>
    log.committing = 0;
    800040e2:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800040e6:	8526                	mv	a0,s1
    800040e8:	ffffe097          	auipc	ra,0xffffe
    800040ec:	16e080e7          	jalr	366(ra) # 80002256 <wakeup>
    release(&log.lock);
    800040f0:	8526                	mv	a0,s1
    800040f2:	ffffd097          	auipc	ra,0xffffd
    800040f6:	ba6080e7          	jalr	-1114(ra) # 80000c98 <release>
}
    800040fa:	70e2                	ld	ra,56(sp)
    800040fc:	7442                	ld	s0,48(sp)
    800040fe:	74a2                	ld	s1,40(sp)
    80004100:	7902                	ld	s2,32(sp)
    80004102:	69e2                	ld	s3,24(sp)
    80004104:	6a42                	ld	s4,16(sp)
    80004106:	6aa2                	ld	s5,8(sp)
    80004108:	6121                	addi	sp,sp,64
    8000410a:	8082                	ret
    panic("log.committing");
    8000410c:	00004517          	auipc	a0,0x4
    80004110:	51c50513          	addi	a0,a0,1308 # 80008628 <syscalls+0x1e0>
    80004114:	ffffc097          	auipc	ra,0xffffc
    80004118:	42a080e7          	jalr	1066(ra) # 8000053e <panic>
    wakeup(&log);
    8000411c:	0001d497          	auipc	s1,0x1d
    80004120:	35448493          	addi	s1,s1,852 # 80021470 <log>
    80004124:	8526                	mv	a0,s1
    80004126:	ffffe097          	auipc	ra,0xffffe
    8000412a:	130080e7          	jalr	304(ra) # 80002256 <wakeup>
  release(&log.lock);
    8000412e:	8526                	mv	a0,s1
    80004130:	ffffd097          	auipc	ra,0xffffd
    80004134:	b68080e7          	jalr	-1176(ra) # 80000c98 <release>
  if(do_commit){
    80004138:	b7c9                	j	800040fa <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000413a:	0001da97          	auipc	s5,0x1d
    8000413e:	366a8a93          	addi	s5,s5,870 # 800214a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004142:	0001da17          	auipc	s4,0x1d
    80004146:	32ea0a13          	addi	s4,s4,814 # 80021470 <log>
    8000414a:	018a2583          	lw	a1,24(s4)
    8000414e:	012585bb          	addw	a1,a1,s2
    80004152:	2585                	addiw	a1,a1,1
    80004154:	028a2503          	lw	a0,40(s4)
    80004158:	fffff097          	auipc	ra,0xfffff
    8000415c:	cd2080e7          	jalr	-814(ra) # 80002e2a <bread>
    80004160:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004162:	000aa583          	lw	a1,0(s5)
    80004166:	028a2503          	lw	a0,40(s4)
    8000416a:	fffff097          	auipc	ra,0xfffff
    8000416e:	cc0080e7          	jalr	-832(ra) # 80002e2a <bread>
    80004172:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004174:	40000613          	li	a2,1024
    80004178:	05850593          	addi	a1,a0,88
    8000417c:	05848513          	addi	a0,s1,88
    80004180:	ffffd097          	auipc	ra,0xffffd
    80004184:	bc0080e7          	jalr	-1088(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    80004188:	8526                	mv	a0,s1
    8000418a:	fffff097          	auipc	ra,0xfffff
    8000418e:	d92080e7          	jalr	-622(ra) # 80002f1c <bwrite>
    brelse(from);
    80004192:	854e                	mv	a0,s3
    80004194:	fffff097          	auipc	ra,0xfffff
    80004198:	dc6080e7          	jalr	-570(ra) # 80002f5a <brelse>
    brelse(to);
    8000419c:	8526                	mv	a0,s1
    8000419e:	fffff097          	auipc	ra,0xfffff
    800041a2:	dbc080e7          	jalr	-580(ra) # 80002f5a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041a6:	2905                	addiw	s2,s2,1
    800041a8:	0a91                	addi	s5,s5,4
    800041aa:	02ca2783          	lw	a5,44(s4)
    800041ae:	f8f94ee3          	blt	s2,a5,8000414a <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800041b2:	00000097          	auipc	ra,0x0
    800041b6:	c6a080e7          	jalr	-918(ra) # 80003e1c <write_head>
    install_trans(0); // Now install writes to home locations
    800041ba:	4501                	li	a0,0
    800041bc:	00000097          	auipc	ra,0x0
    800041c0:	cda080e7          	jalr	-806(ra) # 80003e96 <install_trans>
    log.lh.n = 0;
    800041c4:	0001d797          	auipc	a5,0x1d
    800041c8:	2c07ac23          	sw	zero,728(a5) # 8002149c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800041cc:	00000097          	auipc	ra,0x0
    800041d0:	c50080e7          	jalr	-944(ra) # 80003e1c <write_head>
    800041d4:	bdf5                	j	800040d0 <end_op+0x52>

00000000800041d6 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800041d6:	1101                	addi	sp,sp,-32
    800041d8:	ec06                	sd	ra,24(sp)
    800041da:	e822                	sd	s0,16(sp)
    800041dc:	e426                	sd	s1,8(sp)
    800041de:	e04a                	sd	s2,0(sp)
    800041e0:	1000                	addi	s0,sp,32
    800041e2:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800041e4:	0001d917          	auipc	s2,0x1d
    800041e8:	28c90913          	addi	s2,s2,652 # 80021470 <log>
    800041ec:	854a                	mv	a0,s2
    800041ee:	ffffd097          	auipc	ra,0xffffd
    800041f2:	9f6080e7          	jalr	-1546(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800041f6:	02c92603          	lw	a2,44(s2)
    800041fa:	47f5                	li	a5,29
    800041fc:	06c7c563          	blt	a5,a2,80004266 <log_write+0x90>
    80004200:	0001d797          	auipc	a5,0x1d
    80004204:	28c7a783          	lw	a5,652(a5) # 8002148c <log+0x1c>
    80004208:	37fd                	addiw	a5,a5,-1
    8000420a:	04f65e63          	bge	a2,a5,80004266 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000420e:	0001d797          	auipc	a5,0x1d
    80004212:	2827a783          	lw	a5,642(a5) # 80021490 <log+0x20>
    80004216:	06f05063          	blez	a5,80004276 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000421a:	4781                	li	a5,0
    8000421c:	06c05563          	blez	a2,80004286 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004220:	44cc                	lw	a1,12(s1)
    80004222:	0001d717          	auipc	a4,0x1d
    80004226:	27e70713          	addi	a4,a4,638 # 800214a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000422a:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000422c:	4314                	lw	a3,0(a4)
    8000422e:	04b68c63          	beq	a3,a1,80004286 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004232:	2785                	addiw	a5,a5,1
    80004234:	0711                	addi	a4,a4,4
    80004236:	fef61be3          	bne	a2,a5,8000422c <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000423a:	0621                	addi	a2,a2,8
    8000423c:	060a                	slli	a2,a2,0x2
    8000423e:	0001d797          	auipc	a5,0x1d
    80004242:	23278793          	addi	a5,a5,562 # 80021470 <log>
    80004246:	963e                	add	a2,a2,a5
    80004248:	44dc                	lw	a5,12(s1)
    8000424a:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000424c:	8526                	mv	a0,s1
    8000424e:	fffff097          	auipc	ra,0xfffff
    80004252:	daa080e7          	jalr	-598(ra) # 80002ff8 <bpin>
    log.lh.n++;
    80004256:	0001d717          	auipc	a4,0x1d
    8000425a:	21a70713          	addi	a4,a4,538 # 80021470 <log>
    8000425e:	575c                	lw	a5,44(a4)
    80004260:	2785                	addiw	a5,a5,1
    80004262:	d75c                	sw	a5,44(a4)
    80004264:	a835                	j	800042a0 <log_write+0xca>
    panic("too big a transaction");
    80004266:	00004517          	auipc	a0,0x4
    8000426a:	3d250513          	addi	a0,a0,978 # 80008638 <syscalls+0x1f0>
    8000426e:	ffffc097          	auipc	ra,0xffffc
    80004272:	2d0080e7          	jalr	720(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004276:	00004517          	auipc	a0,0x4
    8000427a:	3da50513          	addi	a0,a0,986 # 80008650 <syscalls+0x208>
    8000427e:	ffffc097          	auipc	ra,0xffffc
    80004282:	2c0080e7          	jalr	704(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004286:	00878713          	addi	a4,a5,8
    8000428a:	00271693          	slli	a3,a4,0x2
    8000428e:	0001d717          	auipc	a4,0x1d
    80004292:	1e270713          	addi	a4,a4,482 # 80021470 <log>
    80004296:	9736                	add	a4,a4,a3
    80004298:	44d4                	lw	a3,12(s1)
    8000429a:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000429c:	faf608e3          	beq	a2,a5,8000424c <log_write+0x76>
  }
  release(&log.lock);
    800042a0:	0001d517          	auipc	a0,0x1d
    800042a4:	1d050513          	addi	a0,a0,464 # 80021470 <log>
    800042a8:	ffffd097          	auipc	ra,0xffffd
    800042ac:	9f0080e7          	jalr	-1552(ra) # 80000c98 <release>
}
    800042b0:	60e2                	ld	ra,24(sp)
    800042b2:	6442                	ld	s0,16(sp)
    800042b4:	64a2                	ld	s1,8(sp)
    800042b6:	6902                	ld	s2,0(sp)
    800042b8:	6105                	addi	sp,sp,32
    800042ba:	8082                	ret

00000000800042bc <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800042bc:	1101                	addi	sp,sp,-32
    800042be:	ec06                	sd	ra,24(sp)
    800042c0:	e822                	sd	s0,16(sp)
    800042c2:	e426                	sd	s1,8(sp)
    800042c4:	e04a                	sd	s2,0(sp)
    800042c6:	1000                	addi	s0,sp,32
    800042c8:	84aa                	mv	s1,a0
    800042ca:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800042cc:	00004597          	auipc	a1,0x4
    800042d0:	3a458593          	addi	a1,a1,932 # 80008670 <syscalls+0x228>
    800042d4:	0521                	addi	a0,a0,8
    800042d6:	ffffd097          	auipc	ra,0xffffd
    800042da:	87e080e7          	jalr	-1922(ra) # 80000b54 <initlock>
  lk->name = name;
    800042de:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800042e2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800042e6:	0204a423          	sw	zero,40(s1)
}
    800042ea:	60e2                	ld	ra,24(sp)
    800042ec:	6442                	ld	s0,16(sp)
    800042ee:	64a2                	ld	s1,8(sp)
    800042f0:	6902                	ld	s2,0(sp)
    800042f2:	6105                	addi	sp,sp,32
    800042f4:	8082                	ret

00000000800042f6 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800042f6:	1101                	addi	sp,sp,-32
    800042f8:	ec06                	sd	ra,24(sp)
    800042fa:	e822                	sd	s0,16(sp)
    800042fc:	e426                	sd	s1,8(sp)
    800042fe:	e04a                	sd	s2,0(sp)
    80004300:	1000                	addi	s0,sp,32
    80004302:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004304:	00850913          	addi	s2,a0,8
    80004308:	854a                	mv	a0,s2
    8000430a:	ffffd097          	auipc	ra,0xffffd
    8000430e:	8da080e7          	jalr	-1830(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004312:	409c                	lw	a5,0(s1)
    80004314:	cb89                	beqz	a5,80004326 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004316:	85ca                	mv	a1,s2
    80004318:	8526                	mv	a0,s1
    8000431a:	ffffe097          	auipc	ra,0xffffe
    8000431e:	db0080e7          	jalr	-592(ra) # 800020ca <sleep>
  while (lk->locked) {
    80004322:	409c                	lw	a5,0(s1)
    80004324:	fbed                	bnez	a5,80004316 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004326:	4785                	li	a5,1
    80004328:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000432a:	ffffd097          	auipc	ra,0xffffd
    8000432e:	6f2080e7          	jalr	1778(ra) # 80001a1c <myproc>
    80004332:	591c                	lw	a5,48(a0)
    80004334:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004336:	854a                	mv	a0,s2
    80004338:	ffffd097          	auipc	ra,0xffffd
    8000433c:	960080e7          	jalr	-1696(ra) # 80000c98 <release>
}
    80004340:	60e2                	ld	ra,24(sp)
    80004342:	6442                	ld	s0,16(sp)
    80004344:	64a2                	ld	s1,8(sp)
    80004346:	6902                	ld	s2,0(sp)
    80004348:	6105                	addi	sp,sp,32
    8000434a:	8082                	ret

000000008000434c <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000434c:	1101                	addi	sp,sp,-32
    8000434e:	ec06                	sd	ra,24(sp)
    80004350:	e822                	sd	s0,16(sp)
    80004352:	e426                	sd	s1,8(sp)
    80004354:	e04a                	sd	s2,0(sp)
    80004356:	1000                	addi	s0,sp,32
    80004358:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000435a:	00850913          	addi	s2,a0,8
    8000435e:	854a                	mv	a0,s2
    80004360:	ffffd097          	auipc	ra,0xffffd
    80004364:	884080e7          	jalr	-1916(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004368:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000436c:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004370:	8526                	mv	a0,s1
    80004372:	ffffe097          	auipc	ra,0xffffe
    80004376:	ee4080e7          	jalr	-284(ra) # 80002256 <wakeup>
  release(&lk->lk);
    8000437a:	854a                	mv	a0,s2
    8000437c:	ffffd097          	auipc	ra,0xffffd
    80004380:	91c080e7          	jalr	-1764(ra) # 80000c98 <release>
}
    80004384:	60e2                	ld	ra,24(sp)
    80004386:	6442                	ld	s0,16(sp)
    80004388:	64a2                	ld	s1,8(sp)
    8000438a:	6902                	ld	s2,0(sp)
    8000438c:	6105                	addi	sp,sp,32
    8000438e:	8082                	ret

0000000080004390 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004390:	7179                	addi	sp,sp,-48
    80004392:	f406                	sd	ra,40(sp)
    80004394:	f022                	sd	s0,32(sp)
    80004396:	ec26                	sd	s1,24(sp)
    80004398:	e84a                	sd	s2,16(sp)
    8000439a:	e44e                	sd	s3,8(sp)
    8000439c:	1800                	addi	s0,sp,48
    8000439e:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800043a0:	00850913          	addi	s2,a0,8
    800043a4:	854a                	mv	a0,s2
    800043a6:	ffffd097          	auipc	ra,0xffffd
    800043aa:	83e080e7          	jalr	-1986(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800043ae:	409c                	lw	a5,0(s1)
    800043b0:	ef99                	bnez	a5,800043ce <holdingsleep+0x3e>
    800043b2:	4481                	li	s1,0
  release(&lk->lk);
    800043b4:	854a                	mv	a0,s2
    800043b6:	ffffd097          	auipc	ra,0xffffd
    800043ba:	8e2080e7          	jalr	-1822(ra) # 80000c98 <release>
  return r;
}
    800043be:	8526                	mv	a0,s1
    800043c0:	70a2                	ld	ra,40(sp)
    800043c2:	7402                	ld	s0,32(sp)
    800043c4:	64e2                	ld	s1,24(sp)
    800043c6:	6942                	ld	s2,16(sp)
    800043c8:	69a2                	ld	s3,8(sp)
    800043ca:	6145                	addi	sp,sp,48
    800043cc:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800043ce:	0284a983          	lw	s3,40(s1)
    800043d2:	ffffd097          	auipc	ra,0xffffd
    800043d6:	64a080e7          	jalr	1610(ra) # 80001a1c <myproc>
    800043da:	5904                	lw	s1,48(a0)
    800043dc:	413484b3          	sub	s1,s1,s3
    800043e0:	0014b493          	seqz	s1,s1
    800043e4:	bfc1                	j	800043b4 <holdingsleep+0x24>

00000000800043e6 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800043e6:	1141                	addi	sp,sp,-16
    800043e8:	e406                	sd	ra,8(sp)
    800043ea:	e022                	sd	s0,0(sp)
    800043ec:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800043ee:	00004597          	auipc	a1,0x4
    800043f2:	29258593          	addi	a1,a1,658 # 80008680 <syscalls+0x238>
    800043f6:	0001d517          	auipc	a0,0x1d
    800043fa:	1c250513          	addi	a0,a0,450 # 800215b8 <ftable>
    800043fe:	ffffc097          	auipc	ra,0xffffc
    80004402:	756080e7          	jalr	1878(ra) # 80000b54 <initlock>
}
    80004406:	60a2                	ld	ra,8(sp)
    80004408:	6402                	ld	s0,0(sp)
    8000440a:	0141                	addi	sp,sp,16
    8000440c:	8082                	ret

000000008000440e <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000440e:	1101                	addi	sp,sp,-32
    80004410:	ec06                	sd	ra,24(sp)
    80004412:	e822                	sd	s0,16(sp)
    80004414:	e426                	sd	s1,8(sp)
    80004416:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004418:	0001d517          	auipc	a0,0x1d
    8000441c:	1a050513          	addi	a0,a0,416 # 800215b8 <ftable>
    80004420:	ffffc097          	auipc	ra,0xffffc
    80004424:	7c4080e7          	jalr	1988(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004428:	0001d497          	auipc	s1,0x1d
    8000442c:	1a848493          	addi	s1,s1,424 # 800215d0 <ftable+0x18>
    80004430:	0001e717          	auipc	a4,0x1e
    80004434:	14070713          	addi	a4,a4,320 # 80022570 <ftable+0xfb8>
    if(f->ref == 0){
    80004438:	40dc                	lw	a5,4(s1)
    8000443a:	cf99                	beqz	a5,80004458 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000443c:	02848493          	addi	s1,s1,40
    80004440:	fee49ce3          	bne	s1,a4,80004438 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004444:	0001d517          	auipc	a0,0x1d
    80004448:	17450513          	addi	a0,a0,372 # 800215b8 <ftable>
    8000444c:	ffffd097          	auipc	ra,0xffffd
    80004450:	84c080e7          	jalr	-1972(ra) # 80000c98 <release>
  return 0;
    80004454:	4481                	li	s1,0
    80004456:	a819                	j	8000446c <filealloc+0x5e>
      f->ref = 1;
    80004458:	4785                	li	a5,1
    8000445a:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000445c:	0001d517          	auipc	a0,0x1d
    80004460:	15c50513          	addi	a0,a0,348 # 800215b8 <ftable>
    80004464:	ffffd097          	auipc	ra,0xffffd
    80004468:	834080e7          	jalr	-1996(ra) # 80000c98 <release>
}
    8000446c:	8526                	mv	a0,s1
    8000446e:	60e2                	ld	ra,24(sp)
    80004470:	6442                	ld	s0,16(sp)
    80004472:	64a2                	ld	s1,8(sp)
    80004474:	6105                	addi	sp,sp,32
    80004476:	8082                	ret

0000000080004478 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004478:	1101                	addi	sp,sp,-32
    8000447a:	ec06                	sd	ra,24(sp)
    8000447c:	e822                	sd	s0,16(sp)
    8000447e:	e426                	sd	s1,8(sp)
    80004480:	1000                	addi	s0,sp,32
    80004482:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004484:	0001d517          	auipc	a0,0x1d
    80004488:	13450513          	addi	a0,a0,308 # 800215b8 <ftable>
    8000448c:	ffffc097          	auipc	ra,0xffffc
    80004490:	758080e7          	jalr	1880(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004494:	40dc                	lw	a5,4(s1)
    80004496:	02f05263          	blez	a5,800044ba <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000449a:	2785                	addiw	a5,a5,1
    8000449c:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000449e:	0001d517          	auipc	a0,0x1d
    800044a2:	11a50513          	addi	a0,a0,282 # 800215b8 <ftable>
    800044a6:	ffffc097          	auipc	ra,0xffffc
    800044aa:	7f2080e7          	jalr	2034(ra) # 80000c98 <release>
  return f;
}
    800044ae:	8526                	mv	a0,s1
    800044b0:	60e2                	ld	ra,24(sp)
    800044b2:	6442                	ld	s0,16(sp)
    800044b4:	64a2                	ld	s1,8(sp)
    800044b6:	6105                	addi	sp,sp,32
    800044b8:	8082                	ret
    panic("filedup");
    800044ba:	00004517          	auipc	a0,0x4
    800044be:	1ce50513          	addi	a0,a0,462 # 80008688 <syscalls+0x240>
    800044c2:	ffffc097          	auipc	ra,0xffffc
    800044c6:	07c080e7          	jalr	124(ra) # 8000053e <panic>

00000000800044ca <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800044ca:	7139                	addi	sp,sp,-64
    800044cc:	fc06                	sd	ra,56(sp)
    800044ce:	f822                	sd	s0,48(sp)
    800044d0:	f426                	sd	s1,40(sp)
    800044d2:	f04a                	sd	s2,32(sp)
    800044d4:	ec4e                	sd	s3,24(sp)
    800044d6:	e852                	sd	s4,16(sp)
    800044d8:	e456                	sd	s5,8(sp)
    800044da:	0080                	addi	s0,sp,64
    800044dc:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800044de:	0001d517          	auipc	a0,0x1d
    800044e2:	0da50513          	addi	a0,a0,218 # 800215b8 <ftable>
    800044e6:	ffffc097          	auipc	ra,0xffffc
    800044ea:	6fe080e7          	jalr	1790(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800044ee:	40dc                	lw	a5,4(s1)
    800044f0:	06f05163          	blez	a5,80004552 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800044f4:	37fd                	addiw	a5,a5,-1
    800044f6:	0007871b          	sext.w	a4,a5
    800044fa:	c0dc                	sw	a5,4(s1)
    800044fc:	06e04363          	bgtz	a4,80004562 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004500:	0004a903          	lw	s2,0(s1)
    80004504:	0094ca83          	lbu	s5,9(s1)
    80004508:	0104ba03          	ld	s4,16(s1)
    8000450c:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004510:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004514:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004518:	0001d517          	auipc	a0,0x1d
    8000451c:	0a050513          	addi	a0,a0,160 # 800215b8 <ftable>
    80004520:	ffffc097          	auipc	ra,0xffffc
    80004524:	778080e7          	jalr	1912(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004528:	4785                	li	a5,1
    8000452a:	04f90d63          	beq	s2,a5,80004584 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000452e:	3979                	addiw	s2,s2,-2
    80004530:	4785                	li	a5,1
    80004532:	0527e063          	bltu	a5,s2,80004572 <fileclose+0xa8>
    begin_op();
    80004536:	00000097          	auipc	ra,0x0
    8000453a:	ac8080e7          	jalr	-1336(ra) # 80003ffe <begin_op>
    iput(ff.ip);
    8000453e:	854e                	mv	a0,s3
    80004540:	fffff097          	auipc	ra,0xfffff
    80004544:	2a6080e7          	jalr	678(ra) # 800037e6 <iput>
    end_op();
    80004548:	00000097          	auipc	ra,0x0
    8000454c:	b36080e7          	jalr	-1226(ra) # 8000407e <end_op>
    80004550:	a00d                	j	80004572 <fileclose+0xa8>
    panic("fileclose");
    80004552:	00004517          	auipc	a0,0x4
    80004556:	13e50513          	addi	a0,a0,318 # 80008690 <syscalls+0x248>
    8000455a:	ffffc097          	auipc	ra,0xffffc
    8000455e:	fe4080e7          	jalr	-28(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004562:	0001d517          	auipc	a0,0x1d
    80004566:	05650513          	addi	a0,a0,86 # 800215b8 <ftable>
    8000456a:	ffffc097          	auipc	ra,0xffffc
    8000456e:	72e080e7          	jalr	1838(ra) # 80000c98 <release>
  }
}
    80004572:	70e2                	ld	ra,56(sp)
    80004574:	7442                	ld	s0,48(sp)
    80004576:	74a2                	ld	s1,40(sp)
    80004578:	7902                	ld	s2,32(sp)
    8000457a:	69e2                	ld	s3,24(sp)
    8000457c:	6a42                	ld	s4,16(sp)
    8000457e:	6aa2                	ld	s5,8(sp)
    80004580:	6121                	addi	sp,sp,64
    80004582:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004584:	85d6                	mv	a1,s5
    80004586:	8552                	mv	a0,s4
    80004588:	00000097          	auipc	ra,0x0
    8000458c:	34c080e7          	jalr	844(ra) # 800048d4 <pipeclose>
    80004590:	b7cd                	j	80004572 <fileclose+0xa8>

0000000080004592 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004592:	715d                	addi	sp,sp,-80
    80004594:	e486                	sd	ra,72(sp)
    80004596:	e0a2                	sd	s0,64(sp)
    80004598:	fc26                	sd	s1,56(sp)
    8000459a:	f84a                	sd	s2,48(sp)
    8000459c:	f44e                	sd	s3,40(sp)
    8000459e:	0880                	addi	s0,sp,80
    800045a0:	84aa                	mv	s1,a0
    800045a2:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800045a4:	ffffd097          	auipc	ra,0xffffd
    800045a8:	478080e7          	jalr	1144(ra) # 80001a1c <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800045ac:	409c                	lw	a5,0(s1)
    800045ae:	37f9                	addiw	a5,a5,-2
    800045b0:	4705                	li	a4,1
    800045b2:	04f76763          	bltu	a4,a5,80004600 <filestat+0x6e>
    800045b6:	892a                	mv	s2,a0
    ilock(f->ip);
    800045b8:	6c88                	ld	a0,24(s1)
    800045ba:	fffff097          	auipc	ra,0xfffff
    800045be:	072080e7          	jalr	114(ra) # 8000362c <ilock>
    stati(f->ip, &st);
    800045c2:	fb840593          	addi	a1,s0,-72
    800045c6:	6c88                	ld	a0,24(s1)
    800045c8:	fffff097          	auipc	ra,0xfffff
    800045cc:	2ee080e7          	jalr	750(ra) # 800038b6 <stati>
    iunlock(f->ip);
    800045d0:	6c88                	ld	a0,24(s1)
    800045d2:	fffff097          	auipc	ra,0xfffff
    800045d6:	11c080e7          	jalr	284(ra) # 800036ee <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800045da:	46e1                	li	a3,24
    800045dc:	fb840613          	addi	a2,s0,-72
    800045e0:	85ce                	mv	a1,s3
    800045e2:	05093503          	ld	a0,80(s2)
    800045e6:	ffffd097          	auipc	ra,0xffffd
    800045ea:	08c080e7          	jalr	140(ra) # 80001672 <copyout>
    800045ee:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800045f2:	60a6                	ld	ra,72(sp)
    800045f4:	6406                	ld	s0,64(sp)
    800045f6:	74e2                	ld	s1,56(sp)
    800045f8:	7942                	ld	s2,48(sp)
    800045fa:	79a2                	ld	s3,40(sp)
    800045fc:	6161                	addi	sp,sp,80
    800045fe:	8082                	ret
  return -1;
    80004600:	557d                	li	a0,-1
    80004602:	bfc5                	j	800045f2 <filestat+0x60>

0000000080004604 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004604:	7179                	addi	sp,sp,-48
    80004606:	f406                	sd	ra,40(sp)
    80004608:	f022                	sd	s0,32(sp)
    8000460a:	ec26                	sd	s1,24(sp)
    8000460c:	e84a                	sd	s2,16(sp)
    8000460e:	e44e                	sd	s3,8(sp)
    80004610:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004612:	00854783          	lbu	a5,8(a0)
    80004616:	c3d5                	beqz	a5,800046ba <fileread+0xb6>
    80004618:	84aa                	mv	s1,a0
    8000461a:	89ae                	mv	s3,a1
    8000461c:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000461e:	411c                	lw	a5,0(a0)
    80004620:	4705                	li	a4,1
    80004622:	04e78963          	beq	a5,a4,80004674 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004626:	470d                	li	a4,3
    80004628:	04e78d63          	beq	a5,a4,80004682 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000462c:	4709                	li	a4,2
    8000462e:	06e79e63          	bne	a5,a4,800046aa <fileread+0xa6>
    ilock(f->ip);
    80004632:	6d08                	ld	a0,24(a0)
    80004634:	fffff097          	auipc	ra,0xfffff
    80004638:	ff8080e7          	jalr	-8(ra) # 8000362c <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000463c:	874a                	mv	a4,s2
    8000463e:	5094                	lw	a3,32(s1)
    80004640:	864e                	mv	a2,s3
    80004642:	4585                	li	a1,1
    80004644:	6c88                	ld	a0,24(s1)
    80004646:	fffff097          	auipc	ra,0xfffff
    8000464a:	29a080e7          	jalr	666(ra) # 800038e0 <readi>
    8000464e:	892a                	mv	s2,a0
    80004650:	00a05563          	blez	a0,8000465a <fileread+0x56>
      f->off += r;
    80004654:	509c                	lw	a5,32(s1)
    80004656:	9fa9                	addw	a5,a5,a0
    80004658:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000465a:	6c88                	ld	a0,24(s1)
    8000465c:	fffff097          	auipc	ra,0xfffff
    80004660:	092080e7          	jalr	146(ra) # 800036ee <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004664:	854a                	mv	a0,s2
    80004666:	70a2                	ld	ra,40(sp)
    80004668:	7402                	ld	s0,32(sp)
    8000466a:	64e2                	ld	s1,24(sp)
    8000466c:	6942                	ld	s2,16(sp)
    8000466e:	69a2                	ld	s3,8(sp)
    80004670:	6145                	addi	sp,sp,48
    80004672:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004674:	6908                	ld	a0,16(a0)
    80004676:	00000097          	auipc	ra,0x0
    8000467a:	3c8080e7          	jalr	968(ra) # 80004a3e <piperead>
    8000467e:	892a                	mv	s2,a0
    80004680:	b7d5                	j	80004664 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004682:	02451783          	lh	a5,36(a0)
    80004686:	03079693          	slli	a3,a5,0x30
    8000468a:	92c1                	srli	a3,a3,0x30
    8000468c:	4725                	li	a4,9
    8000468e:	02d76863          	bltu	a4,a3,800046be <fileread+0xba>
    80004692:	0792                	slli	a5,a5,0x4
    80004694:	0001d717          	auipc	a4,0x1d
    80004698:	e8470713          	addi	a4,a4,-380 # 80021518 <devsw>
    8000469c:	97ba                	add	a5,a5,a4
    8000469e:	639c                	ld	a5,0(a5)
    800046a0:	c38d                	beqz	a5,800046c2 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800046a2:	4505                	li	a0,1
    800046a4:	9782                	jalr	a5
    800046a6:	892a                	mv	s2,a0
    800046a8:	bf75                	j	80004664 <fileread+0x60>
    panic("fileread");
    800046aa:	00004517          	auipc	a0,0x4
    800046ae:	ff650513          	addi	a0,a0,-10 # 800086a0 <syscalls+0x258>
    800046b2:	ffffc097          	auipc	ra,0xffffc
    800046b6:	e8c080e7          	jalr	-372(ra) # 8000053e <panic>
    return -1;
    800046ba:	597d                	li	s2,-1
    800046bc:	b765                	j	80004664 <fileread+0x60>
      return -1;
    800046be:	597d                	li	s2,-1
    800046c0:	b755                	j	80004664 <fileread+0x60>
    800046c2:	597d                	li	s2,-1
    800046c4:	b745                	j	80004664 <fileread+0x60>

00000000800046c6 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800046c6:	715d                	addi	sp,sp,-80
    800046c8:	e486                	sd	ra,72(sp)
    800046ca:	e0a2                	sd	s0,64(sp)
    800046cc:	fc26                	sd	s1,56(sp)
    800046ce:	f84a                	sd	s2,48(sp)
    800046d0:	f44e                	sd	s3,40(sp)
    800046d2:	f052                	sd	s4,32(sp)
    800046d4:	ec56                	sd	s5,24(sp)
    800046d6:	e85a                	sd	s6,16(sp)
    800046d8:	e45e                	sd	s7,8(sp)
    800046da:	e062                	sd	s8,0(sp)
    800046dc:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800046de:	00954783          	lbu	a5,9(a0)
    800046e2:	10078663          	beqz	a5,800047ee <filewrite+0x128>
    800046e6:	892a                	mv	s2,a0
    800046e8:	8aae                	mv	s5,a1
    800046ea:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800046ec:	411c                	lw	a5,0(a0)
    800046ee:	4705                	li	a4,1
    800046f0:	02e78263          	beq	a5,a4,80004714 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800046f4:	470d                	li	a4,3
    800046f6:	02e78663          	beq	a5,a4,80004722 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800046fa:	4709                	li	a4,2
    800046fc:	0ee79163          	bne	a5,a4,800047de <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004700:	0ac05d63          	blez	a2,800047ba <filewrite+0xf4>
    int i = 0;
    80004704:	4981                	li	s3,0
    80004706:	6b05                	lui	s6,0x1
    80004708:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    8000470c:	6b85                	lui	s7,0x1
    8000470e:	c00b8b9b          	addiw	s7,s7,-1024
    80004712:	a861                	j	800047aa <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004714:	6908                	ld	a0,16(a0)
    80004716:	00000097          	auipc	ra,0x0
    8000471a:	22e080e7          	jalr	558(ra) # 80004944 <pipewrite>
    8000471e:	8a2a                	mv	s4,a0
    80004720:	a045                	j	800047c0 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004722:	02451783          	lh	a5,36(a0)
    80004726:	03079693          	slli	a3,a5,0x30
    8000472a:	92c1                	srli	a3,a3,0x30
    8000472c:	4725                	li	a4,9
    8000472e:	0cd76263          	bltu	a4,a3,800047f2 <filewrite+0x12c>
    80004732:	0792                	slli	a5,a5,0x4
    80004734:	0001d717          	auipc	a4,0x1d
    80004738:	de470713          	addi	a4,a4,-540 # 80021518 <devsw>
    8000473c:	97ba                	add	a5,a5,a4
    8000473e:	679c                	ld	a5,8(a5)
    80004740:	cbdd                	beqz	a5,800047f6 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004742:	4505                	li	a0,1
    80004744:	9782                	jalr	a5
    80004746:	8a2a                	mv	s4,a0
    80004748:	a8a5                	j	800047c0 <filewrite+0xfa>
    8000474a:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000474e:	00000097          	auipc	ra,0x0
    80004752:	8b0080e7          	jalr	-1872(ra) # 80003ffe <begin_op>
      ilock(f->ip);
    80004756:	01893503          	ld	a0,24(s2)
    8000475a:	fffff097          	auipc	ra,0xfffff
    8000475e:	ed2080e7          	jalr	-302(ra) # 8000362c <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004762:	8762                	mv	a4,s8
    80004764:	02092683          	lw	a3,32(s2)
    80004768:	01598633          	add	a2,s3,s5
    8000476c:	4585                	li	a1,1
    8000476e:	01893503          	ld	a0,24(s2)
    80004772:	fffff097          	auipc	ra,0xfffff
    80004776:	266080e7          	jalr	614(ra) # 800039d8 <writei>
    8000477a:	84aa                	mv	s1,a0
    8000477c:	00a05763          	blez	a0,8000478a <filewrite+0xc4>
        f->off += r;
    80004780:	02092783          	lw	a5,32(s2)
    80004784:	9fa9                	addw	a5,a5,a0
    80004786:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000478a:	01893503          	ld	a0,24(s2)
    8000478e:	fffff097          	auipc	ra,0xfffff
    80004792:	f60080e7          	jalr	-160(ra) # 800036ee <iunlock>
      end_op();
    80004796:	00000097          	auipc	ra,0x0
    8000479a:	8e8080e7          	jalr	-1816(ra) # 8000407e <end_op>

      if(r != n1){
    8000479e:	009c1f63          	bne	s8,s1,800047bc <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800047a2:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800047a6:	0149db63          	bge	s3,s4,800047bc <filewrite+0xf6>
      int n1 = n - i;
    800047aa:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800047ae:	84be                	mv	s1,a5
    800047b0:	2781                	sext.w	a5,a5
    800047b2:	f8fb5ce3          	bge	s6,a5,8000474a <filewrite+0x84>
    800047b6:	84de                	mv	s1,s7
    800047b8:	bf49                	j	8000474a <filewrite+0x84>
    int i = 0;
    800047ba:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800047bc:	013a1f63          	bne	s4,s3,800047da <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800047c0:	8552                	mv	a0,s4
    800047c2:	60a6                	ld	ra,72(sp)
    800047c4:	6406                	ld	s0,64(sp)
    800047c6:	74e2                	ld	s1,56(sp)
    800047c8:	7942                	ld	s2,48(sp)
    800047ca:	79a2                	ld	s3,40(sp)
    800047cc:	7a02                	ld	s4,32(sp)
    800047ce:	6ae2                	ld	s5,24(sp)
    800047d0:	6b42                	ld	s6,16(sp)
    800047d2:	6ba2                	ld	s7,8(sp)
    800047d4:	6c02                	ld	s8,0(sp)
    800047d6:	6161                	addi	sp,sp,80
    800047d8:	8082                	ret
    ret = (i == n ? n : -1);
    800047da:	5a7d                	li	s4,-1
    800047dc:	b7d5                	j	800047c0 <filewrite+0xfa>
    panic("filewrite");
    800047de:	00004517          	auipc	a0,0x4
    800047e2:	ed250513          	addi	a0,a0,-302 # 800086b0 <syscalls+0x268>
    800047e6:	ffffc097          	auipc	ra,0xffffc
    800047ea:	d58080e7          	jalr	-680(ra) # 8000053e <panic>
    return -1;
    800047ee:	5a7d                	li	s4,-1
    800047f0:	bfc1                	j	800047c0 <filewrite+0xfa>
      return -1;
    800047f2:	5a7d                	li	s4,-1
    800047f4:	b7f1                	j	800047c0 <filewrite+0xfa>
    800047f6:	5a7d                	li	s4,-1
    800047f8:	b7e1                	j	800047c0 <filewrite+0xfa>

00000000800047fa <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800047fa:	7179                	addi	sp,sp,-48
    800047fc:	f406                	sd	ra,40(sp)
    800047fe:	f022                	sd	s0,32(sp)
    80004800:	ec26                	sd	s1,24(sp)
    80004802:	e84a                	sd	s2,16(sp)
    80004804:	e44e                	sd	s3,8(sp)
    80004806:	e052                	sd	s4,0(sp)
    80004808:	1800                	addi	s0,sp,48
    8000480a:	84aa                	mv	s1,a0
    8000480c:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000480e:	0005b023          	sd	zero,0(a1)
    80004812:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004816:	00000097          	auipc	ra,0x0
    8000481a:	bf8080e7          	jalr	-1032(ra) # 8000440e <filealloc>
    8000481e:	e088                	sd	a0,0(s1)
    80004820:	c551                	beqz	a0,800048ac <pipealloc+0xb2>
    80004822:	00000097          	auipc	ra,0x0
    80004826:	bec080e7          	jalr	-1044(ra) # 8000440e <filealloc>
    8000482a:	00aa3023          	sd	a0,0(s4)
    8000482e:	c92d                	beqz	a0,800048a0 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004830:	ffffc097          	auipc	ra,0xffffc
    80004834:	2c4080e7          	jalr	708(ra) # 80000af4 <kalloc>
    80004838:	892a                	mv	s2,a0
    8000483a:	c125                	beqz	a0,8000489a <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    8000483c:	4985                	li	s3,1
    8000483e:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004842:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004846:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    8000484a:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    8000484e:	00004597          	auipc	a1,0x4
    80004852:	e7258593          	addi	a1,a1,-398 # 800086c0 <syscalls+0x278>
    80004856:	ffffc097          	auipc	ra,0xffffc
    8000485a:	2fe080e7          	jalr	766(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    8000485e:	609c                	ld	a5,0(s1)
    80004860:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004864:	609c                	ld	a5,0(s1)
    80004866:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000486a:	609c                	ld	a5,0(s1)
    8000486c:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004870:	609c                	ld	a5,0(s1)
    80004872:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004876:	000a3783          	ld	a5,0(s4)
    8000487a:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000487e:	000a3783          	ld	a5,0(s4)
    80004882:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004886:	000a3783          	ld	a5,0(s4)
    8000488a:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000488e:	000a3783          	ld	a5,0(s4)
    80004892:	0127b823          	sd	s2,16(a5)
  return 0;
    80004896:	4501                	li	a0,0
    80004898:	a025                	j	800048c0 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    8000489a:	6088                	ld	a0,0(s1)
    8000489c:	e501                	bnez	a0,800048a4 <pipealloc+0xaa>
    8000489e:	a039                	j	800048ac <pipealloc+0xb2>
    800048a0:	6088                	ld	a0,0(s1)
    800048a2:	c51d                	beqz	a0,800048d0 <pipealloc+0xd6>
    fileclose(*f0);
    800048a4:	00000097          	auipc	ra,0x0
    800048a8:	c26080e7          	jalr	-986(ra) # 800044ca <fileclose>
  if(*f1)
    800048ac:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800048b0:	557d                	li	a0,-1
  if(*f1)
    800048b2:	c799                	beqz	a5,800048c0 <pipealloc+0xc6>
    fileclose(*f1);
    800048b4:	853e                	mv	a0,a5
    800048b6:	00000097          	auipc	ra,0x0
    800048ba:	c14080e7          	jalr	-1004(ra) # 800044ca <fileclose>
  return -1;
    800048be:	557d                	li	a0,-1
}
    800048c0:	70a2                	ld	ra,40(sp)
    800048c2:	7402                	ld	s0,32(sp)
    800048c4:	64e2                	ld	s1,24(sp)
    800048c6:	6942                	ld	s2,16(sp)
    800048c8:	69a2                	ld	s3,8(sp)
    800048ca:	6a02                	ld	s4,0(sp)
    800048cc:	6145                	addi	sp,sp,48
    800048ce:	8082                	ret
  return -1;
    800048d0:	557d                	li	a0,-1
    800048d2:	b7fd                	j	800048c0 <pipealloc+0xc6>

00000000800048d4 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800048d4:	1101                	addi	sp,sp,-32
    800048d6:	ec06                	sd	ra,24(sp)
    800048d8:	e822                	sd	s0,16(sp)
    800048da:	e426                	sd	s1,8(sp)
    800048dc:	e04a                	sd	s2,0(sp)
    800048de:	1000                	addi	s0,sp,32
    800048e0:	84aa                	mv	s1,a0
    800048e2:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800048e4:	ffffc097          	auipc	ra,0xffffc
    800048e8:	300080e7          	jalr	768(ra) # 80000be4 <acquire>
  if(writable){
    800048ec:	02090d63          	beqz	s2,80004926 <pipeclose+0x52>
    pi->writeopen = 0;
    800048f0:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800048f4:	21848513          	addi	a0,s1,536
    800048f8:	ffffe097          	auipc	ra,0xffffe
    800048fc:	95e080e7          	jalr	-1698(ra) # 80002256 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004900:	2204b783          	ld	a5,544(s1)
    80004904:	eb95                	bnez	a5,80004938 <pipeclose+0x64>
    release(&pi->lock);
    80004906:	8526                	mv	a0,s1
    80004908:	ffffc097          	auipc	ra,0xffffc
    8000490c:	390080e7          	jalr	912(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004910:	8526                	mv	a0,s1
    80004912:	ffffc097          	auipc	ra,0xffffc
    80004916:	0e6080e7          	jalr	230(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    8000491a:	60e2                	ld	ra,24(sp)
    8000491c:	6442                	ld	s0,16(sp)
    8000491e:	64a2                	ld	s1,8(sp)
    80004920:	6902                	ld	s2,0(sp)
    80004922:	6105                	addi	sp,sp,32
    80004924:	8082                	ret
    pi->readopen = 0;
    80004926:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    8000492a:	21c48513          	addi	a0,s1,540
    8000492e:	ffffe097          	auipc	ra,0xffffe
    80004932:	928080e7          	jalr	-1752(ra) # 80002256 <wakeup>
    80004936:	b7e9                	j	80004900 <pipeclose+0x2c>
    release(&pi->lock);
    80004938:	8526                	mv	a0,s1
    8000493a:	ffffc097          	auipc	ra,0xffffc
    8000493e:	35e080e7          	jalr	862(ra) # 80000c98 <release>
}
    80004942:	bfe1                	j	8000491a <pipeclose+0x46>

0000000080004944 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004944:	7159                	addi	sp,sp,-112
    80004946:	f486                	sd	ra,104(sp)
    80004948:	f0a2                	sd	s0,96(sp)
    8000494a:	eca6                	sd	s1,88(sp)
    8000494c:	e8ca                	sd	s2,80(sp)
    8000494e:	e4ce                	sd	s3,72(sp)
    80004950:	e0d2                	sd	s4,64(sp)
    80004952:	fc56                	sd	s5,56(sp)
    80004954:	f85a                	sd	s6,48(sp)
    80004956:	f45e                	sd	s7,40(sp)
    80004958:	f062                	sd	s8,32(sp)
    8000495a:	ec66                	sd	s9,24(sp)
    8000495c:	1880                	addi	s0,sp,112
    8000495e:	84aa                	mv	s1,a0
    80004960:	8aae                	mv	s5,a1
    80004962:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004964:	ffffd097          	auipc	ra,0xffffd
    80004968:	0b8080e7          	jalr	184(ra) # 80001a1c <myproc>
    8000496c:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    8000496e:	8526                	mv	a0,s1
    80004970:	ffffc097          	auipc	ra,0xffffc
    80004974:	274080e7          	jalr	628(ra) # 80000be4 <acquire>
  while(i < n){
    80004978:	0d405163          	blez	s4,80004a3a <pipewrite+0xf6>
    8000497c:	8ba6                	mv	s7,s1
  int i = 0;
    8000497e:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004980:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004982:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004986:	21c48c13          	addi	s8,s1,540
    8000498a:	a08d                	j	800049ec <pipewrite+0xa8>
      release(&pi->lock);
    8000498c:	8526                	mv	a0,s1
    8000498e:	ffffc097          	auipc	ra,0xffffc
    80004992:	30a080e7          	jalr	778(ra) # 80000c98 <release>
      return -1;
    80004996:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004998:	854a                	mv	a0,s2
    8000499a:	70a6                	ld	ra,104(sp)
    8000499c:	7406                	ld	s0,96(sp)
    8000499e:	64e6                	ld	s1,88(sp)
    800049a0:	6946                	ld	s2,80(sp)
    800049a2:	69a6                	ld	s3,72(sp)
    800049a4:	6a06                	ld	s4,64(sp)
    800049a6:	7ae2                	ld	s5,56(sp)
    800049a8:	7b42                	ld	s6,48(sp)
    800049aa:	7ba2                	ld	s7,40(sp)
    800049ac:	7c02                	ld	s8,32(sp)
    800049ae:	6ce2                	ld	s9,24(sp)
    800049b0:	6165                	addi	sp,sp,112
    800049b2:	8082                	ret
      wakeup(&pi->nread);
    800049b4:	8566                	mv	a0,s9
    800049b6:	ffffe097          	auipc	ra,0xffffe
    800049ba:	8a0080e7          	jalr	-1888(ra) # 80002256 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800049be:	85de                	mv	a1,s7
    800049c0:	8562                	mv	a0,s8
    800049c2:	ffffd097          	auipc	ra,0xffffd
    800049c6:	708080e7          	jalr	1800(ra) # 800020ca <sleep>
    800049ca:	a839                	j	800049e8 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800049cc:	21c4a783          	lw	a5,540(s1)
    800049d0:	0017871b          	addiw	a4,a5,1
    800049d4:	20e4ae23          	sw	a4,540(s1)
    800049d8:	1ff7f793          	andi	a5,a5,511
    800049dc:	97a6                	add	a5,a5,s1
    800049de:	f9f44703          	lbu	a4,-97(s0)
    800049e2:	00e78c23          	sb	a4,24(a5)
      i++;
    800049e6:	2905                	addiw	s2,s2,1
  while(i < n){
    800049e8:	03495d63          	bge	s2,s4,80004a22 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    800049ec:	2204a783          	lw	a5,544(s1)
    800049f0:	dfd1                	beqz	a5,8000498c <pipewrite+0x48>
    800049f2:	0289a783          	lw	a5,40(s3)
    800049f6:	fbd9                	bnez	a5,8000498c <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800049f8:	2184a783          	lw	a5,536(s1)
    800049fc:	21c4a703          	lw	a4,540(s1)
    80004a00:	2007879b          	addiw	a5,a5,512
    80004a04:	faf708e3          	beq	a4,a5,800049b4 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a08:	4685                	li	a3,1
    80004a0a:	01590633          	add	a2,s2,s5
    80004a0e:	f9f40593          	addi	a1,s0,-97
    80004a12:	0509b503          	ld	a0,80(s3)
    80004a16:	ffffd097          	auipc	ra,0xffffd
    80004a1a:	ce8080e7          	jalr	-792(ra) # 800016fe <copyin>
    80004a1e:	fb6517e3          	bne	a0,s6,800049cc <pipewrite+0x88>
  wakeup(&pi->nread);
    80004a22:	21848513          	addi	a0,s1,536
    80004a26:	ffffe097          	auipc	ra,0xffffe
    80004a2a:	830080e7          	jalr	-2000(ra) # 80002256 <wakeup>
  release(&pi->lock);
    80004a2e:	8526                	mv	a0,s1
    80004a30:	ffffc097          	auipc	ra,0xffffc
    80004a34:	268080e7          	jalr	616(ra) # 80000c98 <release>
  return i;
    80004a38:	b785                	j	80004998 <pipewrite+0x54>
  int i = 0;
    80004a3a:	4901                	li	s2,0
    80004a3c:	b7dd                	j	80004a22 <pipewrite+0xde>

0000000080004a3e <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004a3e:	715d                	addi	sp,sp,-80
    80004a40:	e486                	sd	ra,72(sp)
    80004a42:	e0a2                	sd	s0,64(sp)
    80004a44:	fc26                	sd	s1,56(sp)
    80004a46:	f84a                	sd	s2,48(sp)
    80004a48:	f44e                	sd	s3,40(sp)
    80004a4a:	f052                	sd	s4,32(sp)
    80004a4c:	ec56                	sd	s5,24(sp)
    80004a4e:	e85a                	sd	s6,16(sp)
    80004a50:	0880                	addi	s0,sp,80
    80004a52:	84aa                	mv	s1,a0
    80004a54:	892e                	mv	s2,a1
    80004a56:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004a58:	ffffd097          	auipc	ra,0xffffd
    80004a5c:	fc4080e7          	jalr	-60(ra) # 80001a1c <myproc>
    80004a60:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004a62:	8b26                	mv	s6,s1
    80004a64:	8526                	mv	a0,s1
    80004a66:	ffffc097          	auipc	ra,0xffffc
    80004a6a:	17e080e7          	jalr	382(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004a6e:	2184a703          	lw	a4,536(s1)
    80004a72:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004a76:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004a7a:	02f71463          	bne	a4,a5,80004aa2 <piperead+0x64>
    80004a7e:	2244a783          	lw	a5,548(s1)
    80004a82:	c385                	beqz	a5,80004aa2 <piperead+0x64>
    if(pr->killed){
    80004a84:	028a2783          	lw	a5,40(s4)
    80004a88:	ebc1                	bnez	a5,80004b18 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004a8a:	85da                	mv	a1,s6
    80004a8c:	854e                	mv	a0,s3
    80004a8e:	ffffd097          	auipc	ra,0xffffd
    80004a92:	63c080e7          	jalr	1596(ra) # 800020ca <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004a96:	2184a703          	lw	a4,536(s1)
    80004a9a:	21c4a783          	lw	a5,540(s1)
    80004a9e:	fef700e3          	beq	a4,a5,80004a7e <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004aa2:	09505263          	blez	s5,80004b26 <piperead+0xe8>
    80004aa6:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004aa8:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004aaa:	2184a783          	lw	a5,536(s1)
    80004aae:	21c4a703          	lw	a4,540(s1)
    80004ab2:	02f70d63          	beq	a4,a5,80004aec <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004ab6:	0017871b          	addiw	a4,a5,1
    80004aba:	20e4ac23          	sw	a4,536(s1)
    80004abe:	1ff7f793          	andi	a5,a5,511
    80004ac2:	97a6                	add	a5,a5,s1
    80004ac4:	0187c783          	lbu	a5,24(a5)
    80004ac8:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004acc:	4685                	li	a3,1
    80004ace:	fbf40613          	addi	a2,s0,-65
    80004ad2:	85ca                	mv	a1,s2
    80004ad4:	050a3503          	ld	a0,80(s4)
    80004ad8:	ffffd097          	auipc	ra,0xffffd
    80004adc:	b9a080e7          	jalr	-1126(ra) # 80001672 <copyout>
    80004ae0:	01650663          	beq	a0,s6,80004aec <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ae4:	2985                	addiw	s3,s3,1
    80004ae6:	0905                	addi	s2,s2,1
    80004ae8:	fd3a91e3          	bne	s5,s3,80004aaa <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004aec:	21c48513          	addi	a0,s1,540
    80004af0:	ffffd097          	auipc	ra,0xffffd
    80004af4:	766080e7          	jalr	1894(ra) # 80002256 <wakeup>
  release(&pi->lock);
    80004af8:	8526                	mv	a0,s1
    80004afa:	ffffc097          	auipc	ra,0xffffc
    80004afe:	19e080e7          	jalr	414(ra) # 80000c98 <release>
  return i;
}
    80004b02:	854e                	mv	a0,s3
    80004b04:	60a6                	ld	ra,72(sp)
    80004b06:	6406                	ld	s0,64(sp)
    80004b08:	74e2                	ld	s1,56(sp)
    80004b0a:	7942                	ld	s2,48(sp)
    80004b0c:	79a2                	ld	s3,40(sp)
    80004b0e:	7a02                	ld	s4,32(sp)
    80004b10:	6ae2                	ld	s5,24(sp)
    80004b12:	6b42                	ld	s6,16(sp)
    80004b14:	6161                	addi	sp,sp,80
    80004b16:	8082                	ret
      release(&pi->lock);
    80004b18:	8526                	mv	a0,s1
    80004b1a:	ffffc097          	auipc	ra,0xffffc
    80004b1e:	17e080e7          	jalr	382(ra) # 80000c98 <release>
      return -1;
    80004b22:	59fd                	li	s3,-1
    80004b24:	bff9                	j	80004b02 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b26:	4981                	li	s3,0
    80004b28:	b7d1                	j	80004aec <piperead+0xae>

0000000080004b2a <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004b2a:	df010113          	addi	sp,sp,-528
    80004b2e:	20113423          	sd	ra,520(sp)
    80004b32:	20813023          	sd	s0,512(sp)
    80004b36:	ffa6                	sd	s1,504(sp)
    80004b38:	fbca                	sd	s2,496(sp)
    80004b3a:	f7ce                	sd	s3,488(sp)
    80004b3c:	f3d2                	sd	s4,480(sp)
    80004b3e:	efd6                	sd	s5,472(sp)
    80004b40:	ebda                	sd	s6,464(sp)
    80004b42:	e7de                	sd	s7,456(sp)
    80004b44:	e3e2                	sd	s8,448(sp)
    80004b46:	ff66                	sd	s9,440(sp)
    80004b48:	fb6a                	sd	s10,432(sp)
    80004b4a:	f76e                	sd	s11,424(sp)
    80004b4c:	0c00                	addi	s0,sp,528
    80004b4e:	84aa                	mv	s1,a0
    80004b50:	dea43c23          	sd	a0,-520(s0)
    80004b54:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004b58:	ffffd097          	auipc	ra,0xffffd
    80004b5c:	ec4080e7          	jalr	-316(ra) # 80001a1c <myproc>
    80004b60:	892a                	mv	s2,a0

  begin_op();
    80004b62:	fffff097          	auipc	ra,0xfffff
    80004b66:	49c080e7          	jalr	1180(ra) # 80003ffe <begin_op>

  if((ip = namei(path)) == 0){
    80004b6a:	8526                	mv	a0,s1
    80004b6c:	fffff097          	auipc	ra,0xfffff
    80004b70:	276080e7          	jalr	630(ra) # 80003de2 <namei>
    80004b74:	c92d                	beqz	a0,80004be6 <exec+0xbc>
    80004b76:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004b78:	fffff097          	auipc	ra,0xfffff
    80004b7c:	ab4080e7          	jalr	-1356(ra) # 8000362c <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004b80:	04000713          	li	a4,64
    80004b84:	4681                	li	a3,0
    80004b86:	e5040613          	addi	a2,s0,-432
    80004b8a:	4581                	li	a1,0
    80004b8c:	8526                	mv	a0,s1
    80004b8e:	fffff097          	auipc	ra,0xfffff
    80004b92:	d52080e7          	jalr	-686(ra) # 800038e0 <readi>
    80004b96:	04000793          	li	a5,64
    80004b9a:	00f51a63          	bne	a0,a5,80004bae <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004b9e:	e5042703          	lw	a4,-432(s0)
    80004ba2:	464c47b7          	lui	a5,0x464c4
    80004ba6:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004baa:	04f70463          	beq	a4,a5,80004bf2 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004bae:	8526                	mv	a0,s1
    80004bb0:	fffff097          	auipc	ra,0xfffff
    80004bb4:	cde080e7          	jalr	-802(ra) # 8000388e <iunlockput>
    end_op();
    80004bb8:	fffff097          	auipc	ra,0xfffff
    80004bbc:	4c6080e7          	jalr	1222(ra) # 8000407e <end_op>
  }
  return -1;
    80004bc0:	557d                	li	a0,-1
}
    80004bc2:	20813083          	ld	ra,520(sp)
    80004bc6:	20013403          	ld	s0,512(sp)
    80004bca:	74fe                	ld	s1,504(sp)
    80004bcc:	795e                	ld	s2,496(sp)
    80004bce:	79be                	ld	s3,488(sp)
    80004bd0:	7a1e                	ld	s4,480(sp)
    80004bd2:	6afe                	ld	s5,472(sp)
    80004bd4:	6b5e                	ld	s6,464(sp)
    80004bd6:	6bbe                	ld	s7,456(sp)
    80004bd8:	6c1e                	ld	s8,448(sp)
    80004bda:	7cfa                	ld	s9,440(sp)
    80004bdc:	7d5a                	ld	s10,432(sp)
    80004bde:	7dba                	ld	s11,424(sp)
    80004be0:	21010113          	addi	sp,sp,528
    80004be4:	8082                	ret
    end_op();
    80004be6:	fffff097          	auipc	ra,0xfffff
    80004bea:	498080e7          	jalr	1176(ra) # 8000407e <end_op>
    return -1;
    80004bee:	557d                	li	a0,-1
    80004bf0:	bfc9                	j	80004bc2 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004bf2:	854a                	mv	a0,s2
    80004bf4:	ffffd097          	auipc	ra,0xffffd
    80004bf8:	ede080e7          	jalr	-290(ra) # 80001ad2 <proc_pagetable>
    80004bfc:	8baa                	mv	s7,a0
    80004bfe:	d945                	beqz	a0,80004bae <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004c00:	e7042983          	lw	s3,-400(s0)
    80004c04:	e8845783          	lhu	a5,-376(s0)
    80004c08:	c7ad                	beqz	a5,80004c72 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004c0a:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004c0c:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004c0e:	6c85                	lui	s9,0x1
    80004c10:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004c14:	def43823          	sd	a5,-528(s0)
    80004c18:	a42d                	j	80004e42 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004c1a:	00004517          	auipc	a0,0x4
    80004c1e:	aae50513          	addi	a0,a0,-1362 # 800086c8 <syscalls+0x280>
    80004c22:	ffffc097          	auipc	ra,0xffffc
    80004c26:	91c080e7          	jalr	-1764(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004c2a:	8756                	mv	a4,s5
    80004c2c:	012d86bb          	addw	a3,s11,s2
    80004c30:	4581                	li	a1,0
    80004c32:	8526                	mv	a0,s1
    80004c34:	fffff097          	auipc	ra,0xfffff
    80004c38:	cac080e7          	jalr	-852(ra) # 800038e0 <readi>
    80004c3c:	2501                	sext.w	a0,a0
    80004c3e:	1aaa9963          	bne	s5,a0,80004df0 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004c42:	6785                	lui	a5,0x1
    80004c44:	0127893b          	addw	s2,a5,s2
    80004c48:	77fd                	lui	a5,0xfffff
    80004c4a:	01478a3b          	addw	s4,a5,s4
    80004c4e:	1f897163          	bgeu	s2,s8,80004e30 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004c52:	02091593          	slli	a1,s2,0x20
    80004c56:	9181                	srli	a1,a1,0x20
    80004c58:	95ea                	add	a1,a1,s10
    80004c5a:	855e                	mv	a0,s7
    80004c5c:	ffffc097          	auipc	ra,0xffffc
    80004c60:	412080e7          	jalr	1042(ra) # 8000106e <walkaddr>
    80004c64:	862a                	mv	a2,a0
    if(pa == 0)
    80004c66:	d955                	beqz	a0,80004c1a <exec+0xf0>
      n = PGSIZE;
    80004c68:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004c6a:	fd9a70e3          	bgeu	s4,s9,80004c2a <exec+0x100>
      n = sz - i;
    80004c6e:	8ad2                	mv	s5,s4
    80004c70:	bf6d                	j	80004c2a <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004c72:	4901                	li	s2,0
  iunlockput(ip);
    80004c74:	8526                	mv	a0,s1
    80004c76:	fffff097          	auipc	ra,0xfffff
    80004c7a:	c18080e7          	jalr	-1000(ra) # 8000388e <iunlockput>
  end_op();
    80004c7e:	fffff097          	auipc	ra,0xfffff
    80004c82:	400080e7          	jalr	1024(ra) # 8000407e <end_op>
  p = myproc();
    80004c86:	ffffd097          	auipc	ra,0xffffd
    80004c8a:	d96080e7          	jalr	-618(ra) # 80001a1c <myproc>
    80004c8e:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004c90:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004c94:	6785                	lui	a5,0x1
    80004c96:	17fd                	addi	a5,a5,-1
    80004c98:	993e                	add	s2,s2,a5
    80004c9a:	757d                	lui	a0,0xfffff
    80004c9c:	00a977b3          	and	a5,s2,a0
    80004ca0:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004ca4:	6609                	lui	a2,0x2
    80004ca6:	963e                	add	a2,a2,a5
    80004ca8:	85be                	mv	a1,a5
    80004caa:	855e                	mv	a0,s7
    80004cac:	ffffc097          	auipc	ra,0xffffc
    80004cb0:	776080e7          	jalr	1910(ra) # 80001422 <uvmalloc>
    80004cb4:	8b2a                	mv	s6,a0
  ip = 0;
    80004cb6:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004cb8:	12050c63          	beqz	a0,80004df0 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004cbc:	75f9                	lui	a1,0xffffe
    80004cbe:	95aa                	add	a1,a1,a0
    80004cc0:	855e                	mv	a0,s7
    80004cc2:	ffffd097          	auipc	ra,0xffffd
    80004cc6:	97e080e7          	jalr	-1666(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    80004cca:	7c7d                	lui	s8,0xfffff
    80004ccc:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004cce:	e0043783          	ld	a5,-512(s0)
    80004cd2:	6388                	ld	a0,0(a5)
    80004cd4:	c535                	beqz	a0,80004d40 <exec+0x216>
    80004cd6:	e9040993          	addi	s3,s0,-368
    80004cda:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004cde:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004ce0:	ffffc097          	auipc	ra,0xffffc
    80004ce4:	184080e7          	jalr	388(ra) # 80000e64 <strlen>
    80004ce8:	2505                	addiw	a0,a0,1
    80004cea:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004cee:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004cf2:	13896363          	bltu	s2,s8,80004e18 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004cf6:	e0043d83          	ld	s11,-512(s0)
    80004cfa:	000dba03          	ld	s4,0(s11)
    80004cfe:	8552                	mv	a0,s4
    80004d00:	ffffc097          	auipc	ra,0xffffc
    80004d04:	164080e7          	jalr	356(ra) # 80000e64 <strlen>
    80004d08:	0015069b          	addiw	a3,a0,1
    80004d0c:	8652                	mv	a2,s4
    80004d0e:	85ca                	mv	a1,s2
    80004d10:	855e                	mv	a0,s7
    80004d12:	ffffd097          	auipc	ra,0xffffd
    80004d16:	960080e7          	jalr	-1696(ra) # 80001672 <copyout>
    80004d1a:	10054363          	bltz	a0,80004e20 <exec+0x2f6>
    ustack[argc] = sp;
    80004d1e:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004d22:	0485                	addi	s1,s1,1
    80004d24:	008d8793          	addi	a5,s11,8
    80004d28:	e0f43023          	sd	a5,-512(s0)
    80004d2c:	008db503          	ld	a0,8(s11)
    80004d30:	c911                	beqz	a0,80004d44 <exec+0x21a>
    if(argc >= MAXARG)
    80004d32:	09a1                	addi	s3,s3,8
    80004d34:	fb3c96e3          	bne	s9,s3,80004ce0 <exec+0x1b6>
  sz = sz1;
    80004d38:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004d3c:	4481                	li	s1,0
    80004d3e:	a84d                	j	80004df0 <exec+0x2c6>
  sp = sz;
    80004d40:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004d42:	4481                	li	s1,0
  ustack[argc] = 0;
    80004d44:	00349793          	slli	a5,s1,0x3
    80004d48:	f9040713          	addi	a4,s0,-112
    80004d4c:	97ba                	add	a5,a5,a4
    80004d4e:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80004d52:	00148693          	addi	a3,s1,1
    80004d56:	068e                	slli	a3,a3,0x3
    80004d58:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004d5c:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004d60:	01897663          	bgeu	s2,s8,80004d6c <exec+0x242>
  sz = sz1;
    80004d64:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004d68:	4481                	li	s1,0
    80004d6a:	a059                	j	80004df0 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004d6c:	e9040613          	addi	a2,s0,-368
    80004d70:	85ca                	mv	a1,s2
    80004d72:	855e                	mv	a0,s7
    80004d74:	ffffd097          	auipc	ra,0xffffd
    80004d78:	8fe080e7          	jalr	-1794(ra) # 80001672 <copyout>
    80004d7c:	0a054663          	bltz	a0,80004e28 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004d80:	058ab783          	ld	a5,88(s5)
    80004d84:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004d88:	df843783          	ld	a5,-520(s0)
    80004d8c:	0007c703          	lbu	a4,0(a5)
    80004d90:	cf11                	beqz	a4,80004dac <exec+0x282>
    80004d92:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004d94:	02f00693          	li	a3,47
    80004d98:	a039                	j	80004da6 <exec+0x27c>
      last = s+1;
    80004d9a:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004d9e:	0785                	addi	a5,a5,1
    80004da0:	fff7c703          	lbu	a4,-1(a5)
    80004da4:	c701                	beqz	a4,80004dac <exec+0x282>
    if(*s == '/')
    80004da6:	fed71ce3          	bne	a4,a3,80004d9e <exec+0x274>
    80004daa:	bfc5                	j	80004d9a <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004dac:	4641                	li	a2,16
    80004dae:	df843583          	ld	a1,-520(s0)
    80004db2:	158a8513          	addi	a0,s5,344
    80004db6:	ffffc097          	auipc	ra,0xffffc
    80004dba:	07c080e7          	jalr	124(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80004dbe:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004dc2:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004dc6:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004dca:	058ab783          	ld	a5,88(s5)
    80004dce:	e6843703          	ld	a4,-408(s0)
    80004dd2:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004dd4:	058ab783          	ld	a5,88(s5)
    80004dd8:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004ddc:	85ea                	mv	a1,s10
    80004dde:	ffffd097          	auipc	ra,0xffffd
    80004de2:	d90080e7          	jalr	-624(ra) # 80001b6e <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004de6:	0004851b          	sext.w	a0,s1
    80004dea:	bbe1                	j	80004bc2 <exec+0x98>
    80004dec:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004df0:	e0843583          	ld	a1,-504(s0)
    80004df4:	855e                	mv	a0,s7
    80004df6:	ffffd097          	auipc	ra,0xffffd
    80004dfa:	d78080e7          	jalr	-648(ra) # 80001b6e <proc_freepagetable>
  if(ip){
    80004dfe:	da0498e3          	bnez	s1,80004bae <exec+0x84>
  return -1;
    80004e02:	557d                	li	a0,-1
    80004e04:	bb7d                	j	80004bc2 <exec+0x98>
    80004e06:	e1243423          	sd	s2,-504(s0)
    80004e0a:	b7dd                	j	80004df0 <exec+0x2c6>
    80004e0c:	e1243423          	sd	s2,-504(s0)
    80004e10:	b7c5                	j	80004df0 <exec+0x2c6>
    80004e12:	e1243423          	sd	s2,-504(s0)
    80004e16:	bfe9                	j	80004df0 <exec+0x2c6>
  sz = sz1;
    80004e18:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004e1c:	4481                	li	s1,0
    80004e1e:	bfc9                	j	80004df0 <exec+0x2c6>
  sz = sz1;
    80004e20:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004e24:	4481                	li	s1,0
    80004e26:	b7e9                	j	80004df0 <exec+0x2c6>
  sz = sz1;
    80004e28:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004e2c:	4481                	li	s1,0
    80004e2e:	b7c9                	j	80004df0 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004e30:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e34:	2b05                	addiw	s6,s6,1
    80004e36:	0389899b          	addiw	s3,s3,56
    80004e3a:	e8845783          	lhu	a5,-376(s0)
    80004e3e:	e2fb5be3          	bge	s6,a5,80004c74 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004e42:	2981                	sext.w	s3,s3
    80004e44:	03800713          	li	a4,56
    80004e48:	86ce                	mv	a3,s3
    80004e4a:	e1840613          	addi	a2,s0,-488
    80004e4e:	4581                	li	a1,0
    80004e50:	8526                	mv	a0,s1
    80004e52:	fffff097          	auipc	ra,0xfffff
    80004e56:	a8e080e7          	jalr	-1394(ra) # 800038e0 <readi>
    80004e5a:	03800793          	li	a5,56
    80004e5e:	f8f517e3          	bne	a0,a5,80004dec <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80004e62:	e1842783          	lw	a5,-488(s0)
    80004e66:	4705                	li	a4,1
    80004e68:	fce796e3          	bne	a5,a4,80004e34 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80004e6c:	e4043603          	ld	a2,-448(s0)
    80004e70:	e3843783          	ld	a5,-456(s0)
    80004e74:	f8f669e3          	bltu	a2,a5,80004e06 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004e78:	e2843783          	ld	a5,-472(s0)
    80004e7c:	963e                	add	a2,a2,a5
    80004e7e:	f8f667e3          	bltu	a2,a5,80004e0c <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004e82:	85ca                	mv	a1,s2
    80004e84:	855e                	mv	a0,s7
    80004e86:	ffffc097          	auipc	ra,0xffffc
    80004e8a:	59c080e7          	jalr	1436(ra) # 80001422 <uvmalloc>
    80004e8e:	e0a43423          	sd	a0,-504(s0)
    80004e92:	d141                	beqz	a0,80004e12 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80004e94:	e2843d03          	ld	s10,-472(s0)
    80004e98:	df043783          	ld	a5,-528(s0)
    80004e9c:	00fd77b3          	and	a5,s10,a5
    80004ea0:	fba1                	bnez	a5,80004df0 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004ea2:	e2042d83          	lw	s11,-480(s0)
    80004ea6:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004eaa:	f80c03e3          	beqz	s8,80004e30 <exec+0x306>
    80004eae:	8a62                	mv	s4,s8
    80004eb0:	4901                	li	s2,0
    80004eb2:	b345                	j	80004c52 <exec+0x128>

0000000080004eb4 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004eb4:	7179                	addi	sp,sp,-48
    80004eb6:	f406                	sd	ra,40(sp)
    80004eb8:	f022                	sd	s0,32(sp)
    80004eba:	ec26                	sd	s1,24(sp)
    80004ebc:	e84a                	sd	s2,16(sp)
    80004ebe:	1800                	addi	s0,sp,48
    80004ec0:	892e                	mv	s2,a1
    80004ec2:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80004ec4:	fdc40593          	addi	a1,s0,-36
    80004ec8:	ffffe097          	auipc	ra,0xffffe
    80004ecc:	bf2080e7          	jalr	-1038(ra) # 80002aba <argint>
    80004ed0:	04054063          	bltz	a0,80004f10 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004ed4:	fdc42703          	lw	a4,-36(s0)
    80004ed8:	47bd                	li	a5,15
    80004eda:	02e7ed63          	bltu	a5,a4,80004f14 <argfd+0x60>
    80004ede:	ffffd097          	auipc	ra,0xffffd
    80004ee2:	b3e080e7          	jalr	-1218(ra) # 80001a1c <myproc>
    80004ee6:	fdc42703          	lw	a4,-36(s0)
    80004eea:	01a70793          	addi	a5,a4,26
    80004eee:	078e                	slli	a5,a5,0x3
    80004ef0:	953e                	add	a0,a0,a5
    80004ef2:	611c                	ld	a5,0(a0)
    80004ef4:	c395                	beqz	a5,80004f18 <argfd+0x64>
    return -1;
  if(pfd)
    80004ef6:	00090463          	beqz	s2,80004efe <argfd+0x4a>
    *pfd = fd;
    80004efa:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004efe:	4501                	li	a0,0
  if(pf)
    80004f00:	c091                	beqz	s1,80004f04 <argfd+0x50>
    *pf = f;
    80004f02:	e09c                	sd	a5,0(s1)
}
    80004f04:	70a2                	ld	ra,40(sp)
    80004f06:	7402                	ld	s0,32(sp)
    80004f08:	64e2                	ld	s1,24(sp)
    80004f0a:	6942                	ld	s2,16(sp)
    80004f0c:	6145                	addi	sp,sp,48
    80004f0e:	8082                	ret
    return -1;
    80004f10:	557d                	li	a0,-1
    80004f12:	bfcd                	j	80004f04 <argfd+0x50>
    return -1;
    80004f14:	557d                	li	a0,-1
    80004f16:	b7fd                	j	80004f04 <argfd+0x50>
    80004f18:	557d                	li	a0,-1
    80004f1a:	b7ed                	j	80004f04 <argfd+0x50>

0000000080004f1c <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004f1c:	1101                	addi	sp,sp,-32
    80004f1e:	ec06                	sd	ra,24(sp)
    80004f20:	e822                	sd	s0,16(sp)
    80004f22:	e426                	sd	s1,8(sp)
    80004f24:	1000                	addi	s0,sp,32
    80004f26:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004f28:	ffffd097          	auipc	ra,0xffffd
    80004f2c:	af4080e7          	jalr	-1292(ra) # 80001a1c <myproc>
    80004f30:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80004f32:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    80004f36:	4501                	li	a0,0
    80004f38:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80004f3a:	6398                	ld	a4,0(a5)
    80004f3c:	cb19                	beqz	a4,80004f52 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80004f3e:	2505                	addiw	a0,a0,1
    80004f40:	07a1                	addi	a5,a5,8
    80004f42:	fed51ce3          	bne	a0,a3,80004f3a <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80004f46:	557d                	li	a0,-1
}
    80004f48:	60e2                	ld	ra,24(sp)
    80004f4a:	6442                	ld	s0,16(sp)
    80004f4c:	64a2                	ld	s1,8(sp)
    80004f4e:	6105                	addi	sp,sp,32
    80004f50:	8082                	ret
      p->ofile[fd] = f;
    80004f52:	01a50793          	addi	a5,a0,26
    80004f56:	078e                	slli	a5,a5,0x3
    80004f58:	963e                	add	a2,a2,a5
    80004f5a:	e204                	sd	s1,0(a2)
      return fd;
    80004f5c:	b7f5                	j	80004f48 <fdalloc+0x2c>

0000000080004f5e <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80004f5e:	715d                	addi	sp,sp,-80
    80004f60:	e486                	sd	ra,72(sp)
    80004f62:	e0a2                	sd	s0,64(sp)
    80004f64:	fc26                	sd	s1,56(sp)
    80004f66:	f84a                	sd	s2,48(sp)
    80004f68:	f44e                	sd	s3,40(sp)
    80004f6a:	f052                	sd	s4,32(sp)
    80004f6c:	ec56                	sd	s5,24(sp)
    80004f6e:	0880                	addi	s0,sp,80
    80004f70:	89ae                	mv	s3,a1
    80004f72:	8ab2                	mv	s5,a2
    80004f74:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80004f76:	fb040593          	addi	a1,s0,-80
    80004f7a:	fffff097          	auipc	ra,0xfffff
    80004f7e:	e86080e7          	jalr	-378(ra) # 80003e00 <nameiparent>
    80004f82:	892a                	mv	s2,a0
    80004f84:	12050f63          	beqz	a0,800050c2 <create+0x164>
    return 0;

  ilock(dp);
    80004f88:	ffffe097          	auipc	ra,0xffffe
    80004f8c:	6a4080e7          	jalr	1700(ra) # 8000362c <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80004f90:	4601                	li	a2,0
    80004f92:	fb040593          	addi	a1,s0,-80
    80004f96:	854a                	mv	a0,s2
    80004f98:	fffff097          	auipc	ra,0xfffff
    80004f9c:	b78080e7          	jalr	-1160(ra) # 80003b10 <dirlookup>
    80004fa0:	84aa                	mv	s1,a0
    80004fa2:	c921                	beqz	a0,80004ff2 <create+0x94>
    iunlockput(dp);
    80004fa4:	854a                	mv	a0,s2
    80004fa6:	fffff097          	auipc	ra,0xfffff
    80004faa:	8e8080e7          	jalr	-1816(ra) # 8000388e <iunlockput>
    ilock(ip);
    80004fae:	8526                	mv	a0,s1
    80004fb0:	ffffe097          	auipc	ra,0xffffe
    80004fb4:	67c080e7          	jalr	1660(ra) # 8000362c <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80004fb8:	2981                	sext.w	s3,s3
    80004fba:	4789                	li	a5,2
    80004fbc:	02f99463          	bne	s3,a5,80004fe4 <create+0x86>
    80004fc0:	0444d783          	lhu	a5,68(s1)
    80004fc4:	37f9                	addiw	a5,a5,-2
    80004fc6:	17c2                	slli	a5,a5,0x30
    80004fc8:	93c1                	srli	a5,a5,0x30
    80004fca:	4705                	li	a4,1
    80004fcc:	00f76c63          	bltu	a4,a5,80004fe4 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80004fd0:	8526                	mv	a0,s1
    80004fd2:	60a6                	ld	ra,72(sp)
    80004fd4:	6406                	ld	s0,64(sp)
    80004fd6:	74e2                	ld	s1,56(sp)
    80004fd8:	7942                	ld	s2,48(sp)
    80004fda:	79a2                	ld	s3,40(sp)
    80004fdc:	7a02                	ld	s4,32(sp)
    80004fde:	6ae2                	ld	s5,24(sp)
    80004fe0:	6161                	addi	sp,sp,80
    80004fe2:	8082                	ret
    iunlockput(ip);
    80004fe4:	8526                	mv	a0,s1
    80004fe6:	fffff097          	auipc	ra,0xfffff
    80004fea:	8a8080e7          	jalr	-1880(ra) # 8000388e <iunlockput>
    return 0;
    80004fee:	4481                	li	s1,0
    80004ff0:	b7c5                	j	80004fd0 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80004ff2:	85ce                	mv	a1,s3
    80004ff4:	00092503          	lw	a0,0(s2)
    80004ff8:	ffffe097          	auipc	ra,0xffffe
    80004ffc:	49c080e7          	jalr	1180(ra) # 80003494 <ialloc>
    80005000:	84aa                	mv	s1,a0
    80005002:	c529                	beqz	a0,8000504c <create+0xee>
  ilock(ip);
    80005004:	ffffe097          	auipc	ra,0xffffe
    80005008:	628080e7          	jalr	1576(ra) # 8000362c <ilock>
  ip->major = major;
    8000500c:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005010:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005014:	4785                	li	a5,1
    80005016:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000501a:	8526                	mv	a0,s1
    8000501c:	ffffe097          	auipc	ra,0xffffe
    80005020:	546080e7          	jalr	1350(ra) # 80003562 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005024:	2981                	sext.w	s3,s3
    80005026:	4785                	li	a5,1
    80005028:	02f98a63          	beq	s3,a5,8000505c <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    8000502c:	40d0                	lw	a2,4(s1)
    8000502e:	fb040593          	addi	a1,s0,-80
    80005032:	854a                	mv	a0,s2
    80005034:	fffff097          	auipc	ra,0xfffff
    80005038:	cec080e7          	jalr	-788(ra) # 80003d20 <dirlink>
    8000503c:	06054b63          	bltz	a0,800050b2 <create+0x154>
  iunlockput(dp);
    80005040:	854a                	mv	a0,s2
    80005042:	fffff097          	auipc	ra,0xfffff
    80005046:	84c080e7          	jalr	-1972(ra) # 8000388e <iunlockput>
  return ip;
    8000504a:	b759                	j	80004fd0 <create+0x72>
    panic("create: ialloc");
    8000504c:	00003517          	auipc	a0,0x3
    80005050:	69c50513          	addi	a0,a0,1692 # 800086e8 <syscalls+0x2a0>
    80005054:	ffffb097          	auipc	ra,0xffffb
    80005058:	4ea080e7          	jalr	1258(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    8000505c:	04a95783          	lhu	a5,74(s2)
    80005060:	2785                	addiw	a5,a5,1
    80005062:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005066:	854a                	mv	a0,s2
    80005068:	ffffe097          	auipc	ra,0xffffe
    8000506c:	4fa080e7          	jalr	1274(ra) # 80003562 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005070:	40d0                	lw	a2,4(s1)
    80005072:	00003597          	auipc	a1,0x3
    80005076:	68658593          	addi	a1,a1,1670 # 800086f8 <syscalls+0x2b0>
    8000507a:	8526                	mv	a0,s1
    8000507c:	fffff097          	auipc	ra,0xfffff
    80005080:	ca4080e7          	jalr	-860(ra) # 80003d20 <dirlink>
    80005084:	00054f63          	bltz	a0,800050a2 <create+0x144>
    80005088:	00492603          	lw	a2,4(s2)
    8000508c:	00003597          	auipc	a1,0x3
    80005090:	67458593          	addi	a1,a1,1652 # 80008700 <syscalls+0x2b8>
    80005094:	8526                	mv	a0,s1
    80005096:	fffff097          	auipc	ra,0xfffff
    8000509a:	c8a080e7          	jalr	-886(ra) # 80003d20 <dirlink>
    8000509e:	f80557e3          	bgez	a0,8000502c <create+0xce>
      panic("create dots");
    800050a2:	00003517          	auipc	a0,0x3
    800050a6:	66650513          	addi	a0,a0,1638 # 80008708 <syscalls+0x2c0>
    800050aa:	ffffb097          	auipc	ra,0xffffb
    800050ae:	494080e7          	jalr	1172(ra) # 8000053e <panic>
    panic("create: dirlink");
    800050b2:	00003517          	auipc	a0,0x3
    800050b6:	66650513          	addi	a0,a0,1638 # 80008718 <syscalls+0x2d0>
    800050ba:	ffffb097          	auipc	ra,0xffffb
    800050be:	484080e7          	jalr	1156(ra) # 8000053e <panic>
    return 0;
    800050c2:	84aa                	mv	s1,a0
    800050c4:	b731                	j	80004fd0 <create+0x72>

00000000800050c6 <sys_dup>:
{
    800050c6:	7179                	addi	sp,sp,-48
    800050c8:	f406                	sd	ra,40(sp)
    800050ca:	f022                	sd	s0,32(sp)
    800050cc:	ec26                	sd	s1,24(sp)
    800050ce:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800050d0:	fd840613          	addi	a2,s0,-40
    800050d4:	4581                	li	a1,0
    800050d6:	4501                	li	a0,0
    800050d8:	00000097          	auipc	ra,0x0
    800050dc:	ddc080e7          	jalr	-548(ra) # 80004eb4 <argfd>
    return -1;
    800050e0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800050e2:	02054363          	bltz	a0,80005108 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800050e6:	fd843503          	ld	a0,-40(s0)
    800050ea:	00000097          	auipc	ra,0x0
    800050ee:	e32080e7          	jalr	-462(ra) # 80004f1c <fdalloc>
    800050f2:	84aa                	mv	s1,a0
    return -1;
    800050f4:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800050f6:	00054963          	bltz	a0,80005108 <sys_dup+0x42>
  filedup(f);
    800050fa:	fd843503          	ld	a0,-40(s0)
    800050fe:	fffff097          	auipc	ra,0xfffff
    80005102:	37a080e7          	jalr	890(ra) # 80004478 <filedup>
  return fd;
    80005106:	87a6                	mv	a5,s1
}
    80005108:	853e                	mv	a0,a5
    8000510a:	70a2                	ld	ra,40(sp)
    8000510c:	7402                	ld	s0,32(sp)
    8000510e:	64e2                	ld	s1,24(sp)
    80005110:	6145                	addi	sp,sp,48
    80005112:	8082                	ret

0000000080005114 <sys_read>:
{
    80005114:	7179                	addi	sp,sp,-48
    80005116:	f406                	sd	ra,40(sp)
    80005118:	f022                	sd	s0,32(sp)
    8000511a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000511c:	fe840613          	addi	a2,s0,-24
    80005120:	4581                	li	a1,0
    80005122:	4501                	li	a0,0
    80005124:	00000097          	auipc	ra,0x0
    80005128:	d90080e7          	jalr	-624(ra) # 80004eb4 <argfd>
    return -1;
    8000512c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000512e:	04054163          	bltz	a0,80005170 <sys_read+0x5c>
    80005132:	fe440593          	addi	a1,s0,-28
    80005136:	4509                	li	a0,2
    80005138:	ffffe097          	auipc	ra,0xffffe
    8000513c:	982080e7          	jalr	-1662(ra) # 80002aba <argint>
    return -1;
    80005140:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005142:	02054763          	bltz	a0,80005170 <sys_read+0x5c>
    80005146:	fd840593          	addi	a1,s0,-40
    8000514a:	4505                	li	a0,1
    8000514c:	ffffe097          	auipc	ra,0xffffe
    80005150:	990080e7          	jalr	-1648(ra) # 80002adc <argaddr>
    return -1;
    80005154:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005156:	00054d63          	bltz	a0,80005170 <sys_read+0x5c>
  return fileread(f, p, n);
    8000515a:	fe442603          	lw	a2,-28(s0)
    8000515e:	fd843583          	ld	a1,-40(s0)
    80005162:	fe843503          	ld	a0,-24(s0)
    80005166:	fffff097          	auipc	ra,0xfffff
    8000516a:	49e080e7          	jalr	1182(ra) # 80004604 <fileread>
    8000516e:	87aa                	mv	a5,a0
}
    80005170:	853e                	mv	a0,a5
    80005172:	70a2                	ld	ra,40(sp)
    80005174:	7402                	ld	s0,32(sp)
    80005176:	6145                	addi	sp,sp,48
    80005178:	8082                	ret

000000008000517a <sys_write>:
{
    8000517a:	7179                	addi	sp,sp,-48
    8000517c:	f406                	sd	ra,40(sp)
    8000517e:	f022                	sd	s0,32(sp)
    80005180:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005182:	fe840613          	addi	a2,s0,-24
    80005186:	4581                	li	a1,0
    80005188:	4501                	li	a0,0
    8000518a:	00000097          	auipc	ra,0x0
    8000518e:	d2a080e7          	jalr	-726(ra) # 80004eb4 <argfd>
    return -1;
    80005192:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005194:	04054163          	bltz	a0,800051d6 <sys_write+0x5c>
    80005198:	fe440593          	addi	a1,s0,-28
    8000519c:	4509                	li	a0,2
    8000519e:	ffffe097          	auipc	ra,0xffffe
    800051a2:	91c080e7          	jalr	-1764(ra) # 80002aba <argint>
    return -1;
    800051a6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051a8:	02054763          	bltz	a0,800051d6 <sys_write+0x5c>
    800051ac:	fd840593          	addi	a1,s0,-40
    800051b0:	4505                	li	a0,1
    800051b2:	ffffe097          	auipc	ra,0xffffe
    800051b6:	92a080e7          	jalr	-1750(ra) # 80002adc <argaddr>
    return -1;
    800051ba:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051bc:	00054d63          	bltz	a0,800051d6 <sys_write+0x5c>
  return filewrite(f, p, n);
    800051c0:	fe442603          	lw	a2,-28(s0)
    800051c4:	fd843583          	ld	a1,-40(s0)
    800051c8:	fe843503          	ld	a0,-24(s0)
    800051cc:	fffff097          	auipc	ra,0xfffff
    800051d0:	4fa080e7          	jalr	1274(ra) # 800046c6 <filewrite>
    800051d4:	87aa                	mv	a5,a0
}
    800051d6:	853e                	mv	a0,a5
    800051d8:	70a2                	ld	ra,40(sp)
    800051da:	7402                	ld	s0,32(sp)
    800051dc:	6145                	addi	sp,sp,48
    800051de:	8082                	ret

00000000800051e0 <sys_close>:
{
    800051e0:	1101                	addi	sp,sp,-32
    800051e2:	ec06                	sd	ra,24(sp)
    800051e4:	e822                	sd	s0,16(sp)
    800051e6:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800051e8:	fe040613          	addi	a2,s0,-32
    800051ec:	fec40593          	addi	a1,s0,-20
    800051f0:	4501                	li	a0,0
    800051f2:	00000097          	auipc	ra,0x0
    800051f6:	cc2080e7          	jalr	-830(ra) # 80004eb4 <argfd>
    return -1;
    800051fa:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800051fc:	02054463          	bltz	a0,80005224 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005200:	ffffd097          	auipc	ra,0xffffd
    80005204:	81c080e7          	jalr	-2020(ra) # 80001a1c <myproc>
    80005208:	fec42783          	lw	a5,-20(s0)
    8000520c:	07e9                	addi	a5,a5,26
    8000520e:	078e                	slli	a5,a5,0x3
    80005210:	97aa                	add	a5,a5,a0
    80005212:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005216:	fe043503          	ld	a0,-32(s0)
    8000521a:	fffff097          	auipc	ra,0xfffff
    8000521e:	2b0080e7          	jalr	688(ra) # 800044ca <fileclose>
  return 0;
    80005222:	4781                	li	a5,0
}
    80005224:	853e                	mv	a0,a5
    80005226:	60e2                	ld	ra,24(sp)
    80005228:	6442                	ld	s0,16(sp)
    8000522a:	6105                	addi	sp,sp,32
    8000522c:	8082                	ret

000000008000522e <sys_fstat>:
{
    8000522e:	1101                	addi	sp,sp,-32
    80005230:	ec06                	sd	ra,24(sp)
    80005232:	e822                	sd	s0,16(sp)
    80005234:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005236:	fe840613          	addi	a2,s0,-24
    8000523a:	4581                	li	a1,0
    8000523c:	4501                	li	a0,0
    8000523e:	00000097          	auipc	ra,0x0
    80005242:	c76080e7          	jalr	-906(ra) # 80004eb4 <argfd>
    return -1;
    80005246:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005248:	02054563          	bltz	a0,80005272 <sys_fstat+0x44>
    8000524c:	fe040593          	addi	a1,s0,-32
    80005250:	4505                	li	a0,1
    80005252:	ffffe097          	auipc	ra,0xffffe
    80005256:	88a080e7          	jalr	-1910(ra) # 80002adc <argaddr>
    return -1;
    8000525a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000525c:	00054b63          	bltz	a0,80005272 <sys_fstat+0x44>
  return filestat(f, st);
    80005260:	fe043583          	ld	a1,-32(s0)
    80005264:	fe843503          	ld	a0,-24(s0)
    80005268:	fffff097          	auipc	ra,0xfffff
    8000526c:	32a080e7          	jalr	810(ra) # 80004592 <filestat>
    80005270:	87aa                	mv	a5,a0
}
    80005272:	853e                	mv	a0,a5
    80005274:	60e2                	ld	ra,24(sp)
    80005276:	6442                	ld	s0,16(sp)
    80005278:	6105                	addi	sp,sp,32
    8000527a:	8082                	ret

000000008000527c <sys_link>:
{
    8000527c:	7169                	addi	sp,sp,-304
    8000527e:	f606                	sd	ra,296(sp)
    80005280:	f222                	sd	s0,288(sp)
    80005282:	ee26                	sd	s1,280(sp)
    80005284:	ea4a                	sd	s2,272(sp)
    80005286:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005288:	08000613          	li	a2,128
    8000528c:	ed040593          	addi	a1,s0,-304
    80005290:	4501                	li	a0,0
    80005292:	ffffe097          	auipc	ra,0xffffe
    80005296:	86c080e7          	jalr	-1940(ra) # 80002afe <argstr>
    return -1;
    8000529a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000529c:	10054e63          	bltz	a0,800053b8 <sys_link+0x13c>
    800052a0:	08000613          	li	a2,128
    800052a4:	f5040593          	addi	a1,s0,-176
    800052a8:	4505                	li	a0,1
    800052aa:	ffffe097          	auipc	ra,0xffffe
    800052ae:	854080e7          	jalr	-1964(ra) # 80002afe <argstr>
    return -1;
    800052b2:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800052b4:	10054263          	bltz	a0,800053b8 <sys_link+0x13c>
  begin_op();
    800052b8:	fffff097          	auipc	ra,0xfffff
    800052bc:	d46080e7          	jalr	-698(ra) # 80003ffe <begin_op>
  if((ip = namei(old)) == 0){
    800052c0:	ed040513          	addi	a0,s0,-304
    800052c4:	fffff097          	auipc	ra,0xfffff
    800052c8:	b1e080e7          	jalr	-1250(ra) # 80003de2 <namei>
    800052cc:	84aa                	mv	s1,a0
    800052ce:	c551                	beqz	a0,8000535a <sys_link+0xde>
  ilock(ip);
    800052d0:	ffffe097          	auipc	ra,0xffffe
    800052d4:	35c080e7          	jalr	860(ra) # 8000362c <ilock>
  if(ip->type == T_DIR){
    800052d8:	04449703          	lh	a4,68(s1)
    800052dc:	4785                	li	a5,1
    800052de:	08f70463          	beq	a4,a5,80005366 <sys_link+0xea>
  ip->nlink++;
    800052e2:	04a4d783          	lhu	a5,74(s1)
    800052e6:	2785                	addiw	a5,a5,1
    800052e8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800052ec:	8526                	mv	a0,s1
    800052ee:	ffffe097          	auipc	ra,0xffffe
    800052f2:	274080e7          	jalr	628(ra) # 80003562 <iupdate>
  iunlock(ip);
    800052f6:	8526                	mv	a0,s1
    800052f8:	ffffe097          	auipc	ra,0xffffe
    800052fc:	3f6080e7          	jalr	1014(ra) # 800036ee <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005300:	fd040593          	addi	a1,s0,-48
    80005304:	f5040513          	addi	a0,s0,-176
    80005308:	fffff097          	auipc	ra,0xfffff
    8000530c:	af8080e7          	jalr	-1288(ra) # 80003e00 <nameiparent>
    80005310:	892a                	mv	s2,a0
    80005312:	c935                	beqz	a0,80005386 <sys_link+0x10a>
  ilock(dp);
    80005314:	ffffe097          	auipc	ra,0xffffe
    80005318:	318080e7          	jalr	792(ra) # 8000362c <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000531c:	00092703          	lw	a4,0(s2)
    80005320:	409c                	lw	a5,0(s1)
    80005322:	04f71d63          	bne	a4,a5,8000537c <sys_link+0x100>
    80005326:	40d0                	lw	a2,4(s1)
    80005328:	fd040593          	addi	a1,s0,-48
    8000532c:	854a                	mv	a0,s2
    8000532e:	fffff097          	auipc	ra,0xfffff
    80005332:	9f2080e7          	jalr	-1550(ra) # 80003d20 <dirlink>
    80005336:	04054363          	bltz	a0,8000537c <sys_link+0x100>
  iunlockput(dp);
    8000533a:	854a                	mv	a0,s2
    8000533c:	ffffe097          	auipc	ra,0xffffe
    80005340:	552080e7          	jalr	1362(ra) # 8000388e <iunlockput>
  iput(ip);
    80005344:	8526                	mv	a0,s1
    80005346:	ffffe097          	auipc	ra,0xffffe
    8000534a:	4a0080e7          	jalr	1184(ra) # 800037e6 <iput>
  end_op();
    8000534e:	fffff097          	auipc	ra,0xfffff
    80005352:	d30080e7          	jalr	-720(ra) # 8000407e <end_op>
  return 0;
    80005356:	4781                	li	a5,0
    80005358:	a085                	j	800053b8 <sys_link+0x13c>
    end_op();
    8000535a:	fffff097          	auipc	ra,0xfffff
    8000535e:	d24080e7          	jalr	-732(ra) # 8000407e <end_op>
    return -1;
    80005362:	57fd                	li	a5,-1
    80005364:	a891                	j	800053b8 <sys_link+0x13c>
    iunlockput(ip);
    80005366:	8526                	mv	a0,s1
    80005368:	ffffe097          	auipc	ra,0xffffe
    8000536c:	526080e7          	jalr	1318(ra) # 8000388e <iunlockput>
    end_op();
    80005370:	fffff097          	auipc	ra,0xfffff
    80005374:	d0e080e7          	jalr	-754(ra) # 8000407e <end_op>
    return -1;
    80005378:	57fd                	li	a5,-1
    8000537a:	a83d                	j	800053b8 <sys_link+0x13c>
    iunlockput(dp);
    8000537c:	854a                	mv	a0,s2
    8000537e:	ffffe097          	auipc	ra,0xffffe
    80005382:	510080e7          	jalr	1296(ra) # 8000388e <iunlockput>
  ilock(ip);
    80005386:	8526                	mv	a0,s1
    80005388:	ffffe097          	auipc	ra,0xffffe
    8000538c:	2a4080e7          	jalr	676(ra) # 8000362c <ilock>
  ip->nlink--;
    80005390:	04a4d783          	lhu	a5,74(s1)
    80005394:	37fd                	addiw	a5,a5,-1
    80005396:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000539a:	8526                	mv	a0,s1
    8000539c:	ffffe097          	auipc	ra,0xffffe
    800053a0:	1c6080e7          	jalr	454(ra) # 80003562 <iupdate>
  iunlockput(ip);
    800053a4:	8526                	mv	a0,s1
    800053a6:	ffffe097          	auipc	ra,0xffffe
    800053aa:	4e8080e7          	jalr	1256(ra) # 8000388e <iunlockput>
  end_op();
    800053ae:	fffff097          	auipc	ra,0xfffff
    800053b2:	cd0080e7          	jalr	-816(ra) # 8000407e <end_op>
  return -1;
    800053b6:	57fd                	li	a5,-1
}
    800053b8:	853e                	mv	a0,a5
    800053ba:	70b2                	ld	ra,296(sp)
    800053bc:	7412                	ld	s0,288(sp)
    800053be:	64f2                	ld	s1,280(sp)
    800053c0:	6952                	ld	s2,272(sp)
    800053c2:	6155                	addi	sp,sp,304
    800053c4:	8082                	ret

00000000800053c6 <sys_unlink>:
{
    800053c6:	7151                	addi	sp,sp,-240
    800053c8:	f586                	sd	ra,232(sp)
    800053ca:	f1a2                	sd	s0,224(sp)
    800053cc:	eda6                	sd	s1,216(sp)
    800053ce:	e9ca                	sd	s2,208(sp)
    800053d0:	e5ce                	sd	s3,200(sp)
    800053d2:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800053d4:	08000613          	li	a2,128
    800053d8:	f3040593          	addi	a1,s0,-208
    800053dc:	4501                	li	a0,0
    800053de:	ffffd097          	auipc	ra,0xffffd
    800053e2:	720080e7          	jalr	1824(ra) # 80002afe <argstr>
    800053e6:	18054163          	bltz	a0,80005568 <sys_unlink+0x1a2>
  begin_op();
    800053ea:	fffff097          	auipc	ra,0xfffff
    800053ee:	c14080e7          	jalr	-1004(ra) # 80003ffe <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800053f2:	fb040593          	addi	a1,s0,-80
    800053f6:	f3040513          	addi	a0,s0,-208
    800053fa:	fffff097          	auipc	ra,0xfffff
    800053fe:	a06080e7          	jalr	-1530(ra) # 80003e00 <nameiparent>
    80005402:	84aa                	mv	s1,a0
    80005404:	c979                	beqz	a0,800054da <sys_unlink+0x114>
  ilock(dp);
    80005406:	ffffe097          	auipc	ra,0xffffe
    8000540a:	226080e7          	jalr	550(ra) # 8000362c <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000540e:	00003597          	auipc	a1,0x3
    80005412:	2ea58593          	addi	a1,a1,746 # 800086f8 <syscalls+0x2b0>
    80005416:	fb040513          	addi	a0,s0,-80
    8000541a:	ffffe097          	auipc	ra,0xffffe
    8000541e:	6dc080e7          	jalr	1756(ra) # 80003af6 <namecmp>
    80005422:	14050a63          	beqz	a0,80005576 <sys_unlink+0x1b0>
    80005426:	00003597          	auipc	a1,0x3
    8000542a:	2da58593          	addi	a1,a1,730 # 80008700 <syscalls+0x2b8>
    8000542e:	fb040513          	addi	a0,s0,-80
    80005432:	ffffe097          	auipc	ra,0xffffe
    80005436:	6c4080e7          	jalr	1732(ra) # 80003af6 <namecmp>
    8000543a:	12050e63          	beqz	a0,80005576 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000543e:	f2c40613          	addi	a2,s0,-212
    80005442:	fb040593          	addi	a1,s0,-80
    80005446:	8526                	mv	a0,s1
    80005448:	ffffe097          	auipc	ra,0xffffe
    8000544c:	6c8080e7          	jalr	1736(ra) # 80003b10 <dirlookup>
    80005450:	892a                	mv	s2,a0
    80005452:	12050263          	beqz	a0,80005576 <sys_unlink+0x1b0>
  ilock(ip);
    80005456:	ffffe097          	auipc	ra,0xffffe
    8000545a:	1d6080e7          	jalr	470(ra) # 8000362c <ilock>
  if(ip->nlink < 1)
    8000545e:	04a91783          	lh	a5,74(s2)
    80005462:	08f05263          	blez	a5,800054e6 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005466:	04491703          	lh	a4,68(s2)
    8000546a:	4785                	li	a5,1
    8000546c:	08f70563          	beq	a4,a5,800054f6 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005470:	4641                	li	a2,16
    80005472:	4581                	li	a1,0
    80005474:	fc040513          	addi	a0,s0,-64
    80005478:	ffffc097          	auipc	ra,0xffffc
    8000547c:	868080e7          	jalr	-1944(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005480:	4741                	li	a4,16
    80005482:	f2c42683          	lw	a3,-212(s0)
    80005486:	fc040613          	addi	a2,s0,-64
    8000548a:	4581                	li	a1,0
    8000548c:	8526                	mv	a0,s1
    8000548e:	ffffe097          	auipc	ra,0xffffe
    80005492:	54a080e7          	jalr	1354(ra) # 800039d8 <writei>
    80005496:	47c1                	li	a5,16
    80005498:	0af51563          	bne	a0,a5,80005542 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000549c:	04491703          	lh	a4,68(s2)
    800054a0:	4785                	li	a5,1
    800054a2:	0af70863          	beq	a4,a5,80005552 <sys_unlink+0x18c>
  iunlockput(dp);
    800054a6:	8526                	mv	a0,s1
    800054a8:	ffffe097          	auipc	ra,0xffffe
    800054ac:	3e6080e7          	jalr	998(ra) # 8000388e <iunlockput>
  ip->nlink--;
    800054b0:	04a95783          	lhu	a5,74(s2)
    800054b4:	37fd                	addiw	a5,a5,-1
    800054b6:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800054ba:	854a                	mv	a0,s2
    800054bc:	ffffe097          	auipc	ra,0xffffe
    800054c0:	0a6080e7          	jalr	166(ra) # 80003562 <iupdate>
  iunlockput(ip);
    800054c4:	854a                	mv	a0,s2
    800054c6:	ffffe097          	auipc	ra,0xffffe
    800054ca:	3c8080e7          	jalr	968(ra) # 8000388e <iunlockput>
  end_op();
    800054ce:	fffff097          	auipc	ra,0xfffff
    800054d2:	bb0080e7          	jalr	-1104(ra) # 8000407e <end_op>
  return 0;
    800054d6:	4501                	li	a0,0
    800054d8:	a84d                	j	8000558a <sys_unlink+0x1c4>
    end_op();
    800054da:	fffff097          	auipc	ra,0xfffff
    800054de:	ba4080e7          	jalr	-1116(ra) # 8000407e <end_op>
    return -1;
    800054e2:	557d                	li	a0,-1
    800054e4:	a05d                	j	8000558a <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800054e6:	00003517          	auipc	a0,0x3
    800054ea:	24250513          	addi	a0,a0,578 # 80008728 <syscalls+0x2e0>
    800054ee:	ffffb097          	auipc	ra,0xffffb
    800054f2:	050080e7          	jalr	80(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800054f6:	04c92703          	lw	a4,76(s2)
    800054fa:	02000793          	li	a5,32
    800054fe:	f6e7f9e3          	bgeu	a5,a4,80005470 <sys_unlink+0xaa>
    80005502:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005506:	4741                	li	a4,16
    80005508:	86ce                	mv	a3,s3
    8000550a:	f1840613          	addi	a2,s0,-232
    8000550e:	4581                	li	a1,0
    80005510:	854a                	mv	a0,s2
    80005512:	ffffe097          	auipc	ra,0xffffe
    80005516:	3ce080e7          	jalr	974(ra) # 800038e0 <readi>
    8000551a:	47c1                	li	a5,16
    8000551c:	00f51b63          	bne	a0,a5,80005532 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005520:	f1845783          	lhu	a5,-232(s0)
    80005524:	e7a1                	bnez	a5,8000556c <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005526:	29c1                	addiw	s3,s3,16
    80005528:	04c92783          	lw	a5,76(s2)
    8000552c:	fcf9ede3          	bltu	s3,a5,80005506 <sys_unlink+0x140>
    80005530:	b781                	j	80005470 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005532:	00003517          	auipc	a0,0x3
    80005536:	20e50513          	addi	a0,a0,526 # 80008740 <syscalls+0x2f8>
    8000553a:	ffffb097          	auipc	ra,0xffffb
    8000553e:	004080e7          	jalr	4(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005542:	00003517          	auipc	a0,0x3
    80005546:	21650513          	addi	a0,a0,534 # 80008758 <syscalls+0x310>
    8000554a:	ffffb097          	auipc	ra,0xffffb
    8000554e:	ff4080e7          	jalr	-12(ra) # 8000053e <panic>
    dp->nlink--;
    80005552:	04a4d783          	lhu	a5,74(s1)
    80005556:	37fd                	addiw	a5,a5,-1
    80005558:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000555c:	8526                	mv	a0,s1
    8000555e:	ffffe097          	auipc	ra,0xffffe
    80005562:	004080e7          	jalr	4(ra) # 80003562 <iupdate>
    80005566:	b781                	j	800054a6 <sys_unlink+0xe0>
    return -1;
    80005568:	557d                	li	a0,-1
    8000556a:	a005                	j	8000558a <sys_unlink+0x1c4>
    iunlockput(ip);
    8000556c:	854a                	mv	a0,s2
    8000556e:	ffffe097          	auipc	ra,0xffffe
    80005572:	320080e7          	jalr	800(ra) # 8000388e <iunlockput>
  iunlockput(dp);
    80005576:	8526                	mv	a0,s1
    80005578:	ffffe097          	auipc	ra,0xffffe
    8000557c:	316080e7          	jalr	790(ra) # 8000388e <iunlockput>
  end_op();
    80005580:	fffff097          	auipc	ra,0xfffff
    80005584:	afe080e7          	jalr	-1282(ra) # 8000407e <end_op>
  return -1;
    80005588:	557d                	li	a0,-1
}
    8000558a:	70ae                	ld	ra,232(sp)
    8000558c:	740e                	ld	s0,224(sp)
    8000558e:	64ee                	ld	s1,216(sp)
    80005590:	694e                	ld	s2,208(sp)
    80005592:	69ae                	ld	s3,200(sp)
    80005594:	616d                	addi	sp,sp,240
    80005596:	8082                	ret

0000000080005598 <sys_open>:

uint64
sys_open(void)
{
    80005598:	7131                	addi	sp,sp,-192
    8000559a:	fd06                	sd	ra,184(sp)
    8000559c:	f922                	sd	s0,176(sp)
    8000559e:	f526                	sd	s1,168(sp)
    800055a0:	f14a                	sd	s2,160(sp)
    800055a2:	ed4e                	sd	s3,152(sp)
    800055a4:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800055a6:	08000613          	li	a2,128
    800055aa:	f5040593          	addi	a1,s0,-176
    800055ae:	4501                	li	a0,0
    800055b0:	ffffd097          	auipc	ra,0xffffd
    800055b4:	54e080e7          	jalr	1358(ra) # 80002afe <argstr>
    return -1;
    800055b8:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800055ba:	0c054163          	bltz	a0,8000567c <sys_open+0xe4>
    800055be:	f4c40593          	addi	a1,s0,-180
    800055c2:	4505                	li	a0,1
    800055c4:	ffffd097          	auipc	ra,0xffffd
    800055c8:	4f6080e7          	jalr	1270(ra) # 80002aba <argint>
    800055cc:	0a054863          	bltz	a0,8000567c <sys_open+0xe4>

  begin_op();
    800055d0:	fffff097          	auipc	ra,0xfffff
    800055d4:	a2e080e7          	jalr	-1490(ra) # 80003ffe <begin_op>

  if(omode & O_CREATE){
    800055d8:	f4c42783          	lw	a5,-180(s0)
    800055dc:	2007f793          	andi	a5,a5,512
    800055e0:	cbdd                	beqz	a5,80005696 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800055e2:	4681                	li	a3,0
    800055e4:	4601                	li	a2,0
    800055e6:	4589                	li	a1,2
    800055e8:	f5040513          	addi	a0,s0,-176
    800055ec:	00000097          	auipc	ra,0x0
    800055f0:	972080e7          	jalr	-1678(ra) # 80004f5e <create>
    800055f4:	892a                	mv	s2,a0
    if(ip == 0){
    800055f6:	c959                	beqz	a0,8000568c <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800055f8:	04491703          	lh	a4,68(s2)
    800055fc:	478d                	li	a5,3
    800055fe:	00f71763          	bne	a4,a5,8000560c <sys_open+0x74>
    80005602:	04695703          	lhu	a4,70(s2)
    80005606:	47a5                	li	a5,9
    80005608:	0ce7ec63          	bltu	a5,a4,800056e0 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000560c:	fffff097          	auipc	ra,0xfffff
    80005610:	e02080e7          	jalr	-510(ra) # 8000440e <filealloc>
    80005614:	89aa                	mv	s3,a0
    80005616:	10050263          	beqz	a0,8000571a <sys_open+0x182>
    8000561a:	00000097          	auipc	ra,0x0
    8000561e:	902080e7          	jalr	-1790(ra) # 80004f1c <fdalloc>
    80005622:	84aa                	mv	s1,a0
    80005624:	0e054663          	bltz	a0,80005710 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005628:	04491703          	lh	a4,68(s2)
    8000562c:	478d                	li	a5,3
    8000562e:	0cf70463          	beq	a4,a5,800056f6 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005632:	4789                	li	a5,2
    80005634:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005638:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000563c:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005640:	f4c42783          	lw	a5,-180(s0)
    80005644:	0017c713          	xori	a4,a5,1
    80005648:	8b05                	andi	a4,a4,1
    8000564a:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000564e:	0037f713          	andi	a4,a5,3
    80005652:	00e03733          	snez	a4,a4
    80005656:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000565a:	4007f793          	andi	a5,a5,1024
    8000565e:	c791                	beqz	a5,8000566a <sys_open+0xd2>
    80005660:	04491703          	lh	a4,68(s2)
    80005664:	4789                	li	a5,2
    80005666:	08f70f63          	beq	a4,a5,80005704 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000566a:	854a                	mv	a0,s2
    8000566c:	ffffe097          	auipc	ra,0xffffe
    80005670:	082080e7          	jalr	130(ra) # 800036ee <iunlock>
  end_op();
    80005674:	fffff097          	auipc	ra,0xfffff
    80005678:	a0a080e7          	jalr	-1526(ra) # 8000407e <end_op>

  return fd;
}
    8000567c:	8526                	mv	a0,s1
    8000567e:	70ea                	ld	ra,184(sp)
    80005680:	744a                	ld	s0,176(sp)
    80005682:	74aa                	ld	s1,168(sp)
    80005684:	790a                	ld	s2,160(sp)
    80005686:	69ea                	ld	s3,152(sp)
    80005688:	6129                	addi	sp,sp,192
    8000568a:	8082                	ret
      end_op();
    8000568c:	fffff097          	auipc	ra,0xfffff
    80005690:	9f2080e7          	jalr	-1550(ra) # 8000407e <end_op>
      return -1;
    80005694:	b7e5                	j	8000567c <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005696:	f5040513          	addi	a0,s0,-176
    8000569a:	ffffe097          	auipc	ra,0xffffe
    8000569e:	748080e7          	jalr	1864(ra) # 80003de2 <namei>
    800056a2:	892a                	mv	s2,a0
    800056a4:	c905                	beqz	a0,800056d4 <sys_open+0x13c>
    ilock(ip);
    800056a6:	ffffe097          	auipc	ra,0xffffe
    800056aa:	f86080e7          	jalr	-122(ra) # 8000362c <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800056ae:	04491703          	lh	a4,68(s2)
    800056b2:	4785                	li	a5,1
    800056b4:	f4f712e3          	bne	a4,a5,800055f8 <sys_open+0x60>
    800056b8:	f4c42783          	lw	a5,-180(s0)
    800056bc:	dba1                	beqz	a5,8000560c <sys_open+0x74>
      iunlockput(ip);
    800056be:	854a                	mv	a0,s2
    800056c0:	ffffe097          	auipc	ra,0xffffe
    800056c4:	1ce080e7          	jalr	462(ra) # 8000388e <iunlockput>
      end_op();
    800056c8:	fffff097          	auipc	ra,0xfffff
    800056cc:	9b6080e7          	jalr	-1610(ra) # 8000407e <end_op>
      return -1;
    800056d0:	54fd                	li	s1,-1
    800056d2:	b76d                	j	8000567c <sys_open+0xe4>
      end_op();
    800056d4:	fffff097          	auipc	ra,0xfffff
    800056d8:	9aa080e7          	jalr	-1622(ra) # 8000407e <end_op>
      return -1;
    800056dc:	54fd                	li	s1,-1
    800056de:	bf79                	j	8000567c <sys_open+0xe4>
    iunlockput(ip);
    800056e0:	854a                	mv	a0,s2
    800056e2:	ffffe097          	auipc	ra,0xffffe
    800056e6:	1ac080e7          	jalr	428(ra) # 8000388e <iunlockput>
    end_op();
    800056ea:	fffff097          	auipc	ra,0xfffff
    800056ee:	994080e7          	jalr	-1644(ra) # 8000407e <end_op>
    return -1;
    800056f2:	54fd                	li	s1,-1
    800056f4:	b761                	j	8000567c <sys_open+0xe4>
    f->type = FD_DEVICE;
    800056f6:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800056fa:	04691783          	lh	a5,70(s2)
    800056fe:	02f99223          	sh	a5,36(s3)
    80005702:	bf2d                	j	8000563c <sys_open+0xa4>
    itrunc(ip);
    80005704:	854a                	mv	a0,s2
    80005706:	ffffe097          	auipc	ra,0xffffe
    8000570a:	034080e7          	jalr	52(ra) # 8000373a <itrunc>
    8000570e:	bfb1                	j	8000566a <sys_open+0xd2>
      fileclose(f);
    80005710:	854e                	mv	a0,s3
    80005712:	fffff097          	auipc	ra,0xfffff
    80005716:	db8080e7          	jalr	-584(ra) # 800044ca <fileclose>
    iunlockput(ip);
    8000571a:	854a                	mv	a0,s2
    8000571c:	ffffe097          	auipc	ra,0xffffe
    80005720:	172080e7          	jalr	370(ra) # 8000388e <iunlockput>
    end_op();
    80005724:	fffff097          	auipc	ra,0xfffff
    80005728:	95a080e7          	jalr	-1702(ra) # 8000407e <end_op>
    return -1;
    8000572c:	54fd                	li	s1,-1
    8000572e:	b7b9                	j	8000567c <sys_open+0xe4>

0000000080005730 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005730:	7175                	addi	sp,sp,-144
    80005732:	e506                	sd	ra,136(sp)
    80005734:	e122                	sd	s0,128(sp)
    80005736:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005738:	fffff097          	auipc	ra,0xfffff
    8000573c:	8c6080e7          	jalr	-1850(ra) # 80003ffe <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005740:	08000613          	li	a2,128
    80005744:	f7040593          	addi	a1,s0,-144
    80005748:	4501                	li	a0,0
    8000574a:	ffffd097          	auipc	ra,0xffffd
    8000574e:	3b4080e7          	jalr	948(ra) # 80002afe <argstr>
    80005752:	02054963          	bltz	a0,80005784 <sys_mkdir+0x54>
    80005756:	4681                	li	a3,0
    80005758:	4601                	li	a2,0
    8000575a:	4585                	li	a1,1
    8000575c:	f7040513          	addi	a0,s0,-144
    80005760:	fffff097          	auipc	ra,0xfffff
    80005764:	7fe080e7          	jalr	2046(ra) # 80004f5e <create>
    80005768:	cd11                	beqz	a0,80005784 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000576a:	ffffe097          	auipc	ra,0xffffe
    8000576e:	124080e7          	jalr	292(ra) # 8000388e <iunlockput>
  end_op();
    80005772:	fffff097          	auipc	ra,0xfffff
    80005776:	90c080e7          	jalr	-1780(ra) # 8000407e <end_op>
  return 0;
    8000577a:	4501                	li	a0,0
}
    8000577c:	60aa                	ld	ra,136(sp)
    8000577e:	640a                	ld	s0,128(sp)
    80005780:	6149                	addi	sp,sp,144
    80005782:	8082                	ret
    end_op();
    80005784:	fffff097          	auipc	ra,0xfffff
    80005788:	8fa080e7          	jalr	-1798(ra) # 8000407e <end_op>
    return -1;
    8000578c:	557d                	li	a0,-1
    8000578e:	b7fd                	j	8000577c <sys_mkdir+0x4c>

0000000080005790 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005790:	7135                	addi	sp,sp,-160
    80005792:	ed06                	sd	ra,152(sp)
    80005794:	e922                	sd	s0,144(sp)
    80005796:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005798:	fffff097          	auipc	ra,0xfffff
    8000579c:	866080e7          	jalr	-1946(ra) # 80003ffe <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800057a0:	08000613          	li	a2,128
    800057a4:	f7040593          	addi	a1,s0,-144
    800057a8:	4501                	li	a0,0
    800057aa:	ffffd097          	auipc	ra,0xffffd
    800057ae:	354080e7          	jalr	852(ra) # 80002afe <argstr>
    800057b2:	04054a63          	bltz	a0,80005806 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800057b6:	f6c40593          	addi	a1,s0,-148
    800057ba:	4505                	li	a0,1
    800057bc:	ffffd097          	auipc	ra,0xffffd
    800057c0:	2fe080e7          	jalr	766(ra) # 80002aba <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800057c4:	04054163          	bltz	a0,80005806 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800057c8:	f6840593          	addi	a1,s0,-152
    800057cc:	4509                	li	a0,2
    800057ce:	ffffd097          	auipc	ra,0xffffd
    800057d2:	2ec080e7          	jalr	748(ra) # 80002aba <argint>
     argint(1, &major) < 0 ||
    800057d6:	02054863          	bltz	a0,80005806 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800057da:	f6841683          	lh	a3,-152(s0)
    800057de:	f6c41603          	lh	a2,-148(s0)
    800057e2:	458d                	li	a1,3
    800057e4:	f7040513          	addi	a0,s0,-144
    800057e8:	fffff097          	auipc	ra,0xfffff
    800057ec:	776080e7          	jalr	1910(ra) # 80004f5e <create>
     argint(2, &minor) < 0 ||
    800057f0:	c919                	beqz	a0,80005806 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800057f2:	ffffe097          	auipc	ra,0xffffe
    800057f6:	09c080e7          	jalr	156(ra) # 8000388e <iunlockput>
  end_op();
    800057fa:	fffff097          	auipc	ra,0xfffff
    800057fe:	884080e7          	jalr	-1916(ra) # 8000407e <end_op>
  return 0;
    80005802:	4501                	li	a0,0
    80005804:	a031                	j	80005810 <sys_mknod+0x80>
    end_op();
    80005806:	fffff097          	auipc	ra,0xfffff
    8000580a:	878080e7          	jalr	-1928(ra) # 8000407e <end_op>
    return -1;
    8000580e:	557d                	li	a0,-1
}
    80005810:	60ea                	ld	ra,152(sp)
    80005812:	644a                	ld	s0,144(sp)
    80005814:	610d                	addi	sp,sp,160
    80005816:	8082                	ret

0000000080005818 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005818:	7135                	addi	sp,sp,-160
    8000581a:	ed06                	sd	ra,152(sp)
    8000581c:	e922                	sd	s0,144(sp)
    8000581e:	e526                	sd	s1,136(sp)
    80005820:	e14a                	sd	s2,128(sp)
    80005822:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005824:	ffffc097          	auipc	ra,0xffffc
    80005828:	1f8080e7          	jalr	504(ra) # 80001a1c <myproc>
    8000582c:	892a                	mv	s2,a0
  
  begin_op();
    8000582e:	ffffe097          	auipc	ra,0xffffe
    80005832:	7d0080e7          	jalr	2000(ra) # 80003ffe <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005836:	08000613          	li	a2,128
    8000583a:	f6040593          	addi	a1,s0,-160
    8000583e:	4501                	li	a0,0
    80005840:	ffffd097          	auipc	ra,0xffffd
    80005844:	2be080e7          	jalr	702(ra) # 80002afe <argstr>
    80005848:	04054b63          	bltz	a0,8000589e <sys_chdir+0x86>
    8000584c:	f6040513          	addi	a0,s0,-160
    80005850:	ffffe097          	auipc	ra,0xffffe
    80005854:	592080e7          	jalr	1426(ra) # 80003de2 <namei>
    80005858:	84aa                	mv	s1,a0
    8000585a:	c131                	beqz	a0,8000589e <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    8000585c:	ffffe097          	auipc	ra,0xffffe
    80005860:	dd0080e7          	jalr	-560(ra) # 8000362c <ilock>
  if(ip->type != T_DIR){
    80005864:	04449703          	lh	a4,68(s1)
    80005868:	4785                	li	a5,1
    8000586a:	04f71063          	bne	a4,a5,800058aa <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    8000586e:	8526                	mv	a0,s1
    80005870:	ffffe097          	auipc	ra,0xffffe
    80005874:	e7e080e7          	jalr	-386(ra) # 800036ee <iunlock>
  iput(p->cwd);
    80005878:	15093503          	ld	a0,336(s2)
    8000587c:	ffffe097          	auipc	ra,0xffffe
    80005880:	f6a080e7          	jalr	-150(ra) # 800037e6 <iput>
  end_op();
    80005884:	ffffe097          	auipc	ra,0xffffe
    80005888:	7fa080e7          	jalr	2042(ra) # 8000407e <end_op>
  p->cwd = ip;
    8000588c:	14993823          	sd	s1,336(s2)
  return 0;
    80005890:	4501                	li	a0,0
}
    80005892:	60ea                	ld	ra,152(sp)
    80005894:	644a                	ld	s0,144(sp)
    80005896:	64aa                	ld	s1,136(sp)
    80005898:	690a                	ld	s2,128(sp)
    8000589a:	610d                	addi	sp,sp,160
    8000589c:	8082                	ret
    end_op();
    8000589e:	ffffe097          	auipc	ra,0xffffe
    800058a2:	7e0080e7          	jalr	2016(ra) # 8000407e <end_op>
    return -1;
    800058a6:	557d                	li	a0,-1
    800058a8:	b7ed                	j	80005892 <sys_chdir+0x7a>
    iunlockput(ip);
    800058aa:	8526                	mv	a0,s1
    800058ac:	ffffe097          	auipc	ra,0xffffe
    800058b0:	fe2080e7          	jalr	-30(ra) # 8000388e <iunlockput>
    end_op();
    800058b4:	ffffe097          	auipc	ra,0xffffe
    800058b8:	7ca080e7          	jalr	1994(ra) # 8000407e <end_op>
    return -1;
    800058bc:	557d                	li	a0,-1
    800058be:	bfd1                	j	80005892 <sys_chdir+0x7a>

00000000800058c0 <sys_exec>:

uint64
sys_exec(void)
{
    800058c0:	7145                	addi	sp,sp,-464
    800058c2:	e786                	sd	ra,456(sp)
    800058c4:	e3a2                	sd	s0,448(sp)
    800058c6:	ff26                	sd	s1,440(sp)
    800058c8:	fb4a                	sd	s2,432(sp)
    800058ca:	f74e                	sd	s3,424(sp)
    800058cc:	f352                	sd	s4,416(sp)
    800058ce:	ef56                	sd	s5,408(sp)
    800058d0:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800058d2:	08000613          	li	a2,128
    800058d6:	f4040593          	addi	a1,s0,-192
    800058da:	4501                	li	a0,0
    800058dc:	ffffd097          	auipc	ra,0xffffd
    800058e0:	222080e7          	jalr	546(ra) # 80002afe <argstr>
    return -1;
    800058e4:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800058e6:	0c054a63          	bltz	a0,800059ba <sys_exec+0xfa>
    800058ea:	e3840593          	addi	a1,s0,-456
    800058ee:	4505                	li	a0,1
    800058f0:	ffffd097          	auipc	ra,0xffffd
    800058f4:	1ec080e7          	jalr	492(ra) # 80002adc <argaddr>
    800058f8:	0c054163          	bltz	a0,800059ba <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    800058fc:	10000613          	li	a2,256
    80005900:	4581                	li	a1,0
    80005902:	e4040513          	addi	a0,s0,-448
    80005906:	ffffb097          	auipc	ra,0xffffb
    8000590a:	3da080e7          	jalr	986(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    8000590e:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005912:	89a6                	mv	s3,s1
    80005914:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005916:	02000a13          	li	s4,32
    8000591a:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    8000591e:	00391513          	slli	a0,s2,0x3
    80005922:	e3040593          	addi	a1,s0,-464
    80005926:	e3843783          	ld	a5,-456(s0)
    8000592a:	953e                	add	a0,a0,a5
    8000592c:	ffffd097          	auipc	ra,0xffffd
    80005930:	0f4080e7          	jalr	244(ra) # 80002a20 <fetchaddr>
    80005934:	02054a63          	bltz	a0,80005968 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005938:	e3043783          	ld	a5,-464(s0)
    8000593c:	c3b9                	beqz	a5,80005982 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    8000593e:	ffffb097          	auipc	ra,0xffffb
    80005942:	1b6080e7          	jalr	438(ra) # 80000af4 <kalloc>
    80005946:	85aa                	mv	a1,a0
    80005948:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    8000594c:	cd11                	beqz	a0,80005968 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    8000594e:	6605                	lui	a2,0x1
    80005950:	e3043503          	ld	a0,-464(s0)
    80005954:	ffffd097          	auipc	ra,0xffffd
    80005958:	11e080e7          	jalr	286(ra) # 80002a72 <fetchstr>
    8000595c:	00054663          	bltz	a0,80005968 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005960:	0905                	addi	s2,s2,1
    80005962:	09a1                	addi	s3,s3,8
    80005964:	fb491be3          	bne	s2,s4,8000591a <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005968:	10048913          	addi	s2,s1,256
    8000596c:	6088                	ld	a0,0(s1)
    8000596e:	c529                	beqz	a0,800059b8 <sys_exec+0xf8>
    kfree(argv[i]);
    80005970:	ffffb097          	auipc	ra,0xffffb
    80005974:	088080e7          	jalr	136(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005978:	04a1                	addi	s1,s1,8
    8000597a:	ff2499e3          	bne	s1,s2,8000596c <sys_exec+0xac>
  return -1;
    8000597e:	597d                	li	s2,-1
    80005980:	a82d                	j	800059ba <sys_exec+0xfa>
      argv[i] = 0;
    80005982:	0a8e                	slli	s5,s5,0x3
    80005984:	fc040793          	addi	a5,s0,-64
    80005988:	9abe                	add	s5,s5,a5
    8000598a:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    8000598e:	e4040593          	addi	a1,s0,-448
    80005992:	f4040513          	addi	a0,s0,-192
    80005996:	fffff097          	auipc	ra,0xfffff
    8000599a:	194080e7          	jalr	404(ra) # 80004b2a <exec>
    8000599e:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800059a0:	10048993          	addi	s3,s1,256
    800059a4:	6088                	ld	a0,0(s1)
    800059a6:	c911                	beqz	a0,800059ba <sys_exec+0xfa>
    kfree(argv[i]);
    800059a8:	ffffb097          	auipc	ra,0xffffb
    800059ac:	050080e7          	jalr	80(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800059b0:	04a1                	addi	s1,s1,8
    800059b2:	ff3499e3          	bne	s1,s3,800059a4 <sys_exec+0xe4>
    800059b6:	a011                	j	800059ba <sys_exec+0xfa>
  return -1;
    800059b8:	597d                	li	s2,-1
}
    800059ba:	854a                	mv	a0,s2
    800059bc:	60be                	ld	ra,456(sp)
    800059be:	641e                	ld	s0,448(sp)
    800059c0:	74fa                	ld	s1,440(sp)
    800059c2:	795a                	ld	s2,432(sp)
    800059c4:	79ba                	ld	s3,424(sp)
    800059c6:	7a1a                	ld	s4,416(sp)
    800059c8:	6afa                	ld	s5,408(sp)
    800059ca:	6179                	addi	sp,sp,464
    800059cc:	8082                	ret

00000000800059ce <sys_pipe>:

uint64
sys_pipe(void)
{
    800059ce:	7139                	addi	sp,sp,-64
    800059d0:	fc06                	sd	ra,56(sp)
    800059d2:	f822                	sd	s0,48(sp)
    800059d4:	f426                	sd	s1,40(sp)
    800059d6:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800059d8:	ffffc097          	auipc	ra,0xffffc
    800059dc:	044080e7          	jalr	68(ra) # 80001a1c <myproc>
    800059e0:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    800059e2:	fd840593          	addi	a1,s0,-40
    800059e6:	4501                	li	a0,0
    800059e8:	ffffd097          	auipc	ra,0xffffd
    800059ec:	0f4080e7          	jalr	244(ra) # 80002adc <argaddr>
    return -1;
    800059f0:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    800059f2:	0e054063          	bltz	a0,80005ad2 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    800059f6:	fc840593          	addi	a1,s0,-56
    800059fa:	fd040513          	addi	a0,s0,-48
    800059fe:	fffff097          	auipc	ra,0xfffff
    80005a02:	dfc080e7          	jalr	-516(ra) # 800047fa <pipealloc>
    return -1;
    80005a06:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005a08:	0c054563          	bltz	a0,80005ad2 <sys_pipe+0x104>
  fd0 = -1;
    80005a0c:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005a10:	fd043503          	ld	a0,-48(s0)
    80005a14:	fffff097          	auipc	ra,0xfffff
    80005a18:	508080e7          	jalr	1288(ra) # 80004f1c <fdalloc>
    80005a1c:	fca42223          	sw	a0,-60(s0)
    80005a20:	08054c63          	bltz	a0,80005ab8 <sys_pipe+0xea>
    80005a24:	fc843503          	ld	a0,-56(s0)
    80005a28:	fffff097          	auipc	ra,0xfffff
    80005a2c:	4f4080e7          	jalr	1268(ra) # 80004f1c <fdalloc>
    80005a30:	fca42023          	sw	a0,-64(s0)
    80005a34:	06054863          	bltz	a0,80005aa4 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005a38:	4691                	li	a3,4
    80005a3a:	fc440613          	addi	a2,s0,-60
    80005a3e:	fd843583          	ld	a1,-40(s0)
    80005a42:	68a8                	ld	a0,80(s1)
    80005a44:	ffffc097          	auipc	ra,0xffffc
    80005a48:	c2e080e7          	jalr	-978(ra) # 80001672 <copyout>
    80005a4c:	02054063          	bltz	a0,80005a6c <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005a50:	4691                	li	a3,4
    80005a52:	fc040613          	addi	a2,s0,-64
    80005a56:	fd843583          	ld	a1,-40(s0)
    80005a5a:	0591                	addi	a1,a1,4
    80005a5c:	68a8                	ld	a0,80(s1)
    80005a5e:	ffffc097          	auipc	ra,0xffffc
    80005a62:	c14080e7          	jalr	-1004(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005a66:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005a68:	06055563          	bgez	a0,80005ad2 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005a6c:	fc442783          	lw	a5,-60(s0)
    80005a70:	07e9                	addi	a5,a5,26
    80005a72:	078e                	slli	a5,a5,0x3
    80005a74:	97a6                	add	a5,a5,s1
    80005a76:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005a7a:	fc042503          	lw	a0,-64(s0)
    80005a7e:	0569                	addi	a0,a0,26
    80005a80:	050e                	slli	a0,a0,0x3
    80005a82:	9526                	add	a0,a0,s1
    80005a84:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005a88:	fd043503          	ld	a0,-48(s0)
    80005a8c:	fffff097          	auipc	ra,0xfffff
    80005a90:	a3e080e7          	jalr	-1474(ra) # 800044ca <fileclose>
    fileclose(wf);
    80005a94:	fc843503          	ld	a0,-56(s0)
    80005a98:	fffff097          	auipc	ra,0xfffff
    80005a9c:	a32080e7          	jalr	-1486(ra) # 800044ca <fileclose>
    return -1;
    80005aa0:	57fd                	li	a5,-1
    80005aa2:	a805                	j	80005ad2 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005aa4:	fc442783          	lw	a5,-60(s0)
    80005aa8:	0007c863          	bltz	a5,80005ab8 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005aac:	01a78513          	addi	a0,a5,26
    80005ab0:	050e                	slli	a0,a0,0x3
    80005ab2:	9526                	add	a0,a0,s1
    80005ab4:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005ab8:	fd043503          	ld	a0,-48(s0)
    80005abc:	fffff097          	auipc	ra,0xfffff
    80005ac0:	a0e080e7          	jalr	-1522(ra) # 800044ca <fileclose>
    fileclose(wf);
    80005ac4:	fc843503          	ld	a0,-56(s0)
    80005ac8:	fffff097          	auipc	ra,0xfffff
    80005acc:	a02080e7          	jalr	-1534(ra) # 800044ca <fileclose>
    return -1;
    80005ad0:	57fd                	li	a5,-1
}
    80005ad2:	853e                	mv	a0,a5
    80005ad4:	70e2                	ld	ra,56(sp)
    80005ad6:	7442                	ld	s0,48(sp)
    80005ad8:	74a2                	ld	s1,40(sp)
    80005ada:	6121                	addi	sp,sp,64
    80005adc:	8082                	ret
	...

0000000080005ae0 <kernelvec>:
    80005ae0:	7111                	addi	sp,sp,-256
    80005ae2:	e006                	sd	ra,0(sp)
    80005ae4:	e40a                	sd	sp,8(sp)
    80005ae6:	e80e                	sd	gp,16(sp)
    80005ae8:	ec12                	sd	tp,24(sp)
    80005aea:	f016                	sd	t0,32(sp)
    80005aec:	f41a                	sd	t1,40(sp)
    80005aee:	f81e                	sd	t2,48(sp)
    80005af0:	fc22                	sd	s0,56(sp)
    80005af2:	e0a6                	sd	s1,64(sp)
    80005af4:	e4aa                	sd	a0,72(sp)
    80005af6:	e8ae                	sd	a1,80(sp)
    80005af8:	ecb2                	sd	a2,88(sp)
    80005afa:	f0b6                	sd	a3,96(sp)
    80005afc:	f4ba                	sd	a4,104(sp)
    80005afe:	f8be                	sd	a5,112(sp)
    80005b00:	fcc2                	sd	a6,120(sp)
    80005b02:	e146                	sd	a7,128(sp)
    80005b04:	e54a                	sd	s2,136(sp)
    80005b06:	e94e                	sd	s3,144(sp)
    80005b08:	ed52                	sd	s4,152(sp)
    80005b0a:	f156                	sd	s5,160(sp)
    80005b0c:	f55a                	sd	s6,168(sp)
    80005b0e:	f95e                	sd	s7,176(sp)
    80005b10:	fd62                	sd	s8,184(sp)
    80005b12:	e1e6                	sd	s9,192(sp)
    80005b14:	e5ea                	sd	s10,200(sp)
    80005b16:	e9ee                	sd	s11,208(sp)
    80005b18:	edf2                	sd	t3,216(sp)
    80005b1a:	f1f6                	sd	t4,224(sp)
    80005b1c:	f5fa                	sd	t5,232(sp)
    80005b1e:	f9fe                	sd	t6,240(sp)
    80005b20:	dcdfc0ef          	jal	ra,800028ec <kerneltrap>
    80005b24:	6082                	ld	ra,0(sp)
    80005b26:	6122                	ld	sp,8(sp)
    80005b28:	61c2                	ld	gp,16(sp)
    80005b2a:	7282                	ld	t0,32(sp)
    80005b2c:	7322                	ld	t1,40(sp)
    80005b2e:	73c2                	ld	t2,48(sp)
    80005b30:	7462                	ld	s0,56(sp)
    80005b32:	6486                	ld	s1,64(sp)
    80005b34:	6526                	ld	a0,72(sp)
    80005b36:	65c6                	ld	a1,80(sp)
    80005b38:	6666                	ld	a2,88(sp)
    80005b3a:	7686                	ld	a3,96(sp)
    80005b3c:	7726                	ld	a4,104(sp)
    80005b3e:	77c6                	ld	a5,112(sp)
    80005b40:	7866                	ld	a6,120(sp)
    80005b42:	688a                	ld	a7,128(sp)
    80005b44:	692a                	ld	s2,136(sp)
    80005b46:	69ca                	ld	s3,144(sp)
    80005b48:	6a6a                	ld	s4,152(sp)
    80005b4a:	7a8a                	ld	s5,160(sp)
    80005b4c:	7b2a                	ld	s6,168(sp)
    80005b4e:	7bca                	ld	s7,176(sp)
    80005b50:	7c6a                	ld	s8,184(sp)
    80005b52:	6c8e                	ld	s9,192(sp)
    80005b54:	6d2e                	ld	s10,200(sp)
    80005b56:	6dce                	ld	s11,208(sp)
    80005b58:	6e6e                	ld	t3,216(sp)
    80005b5a:	7e8e                	ld	t4,224(sp)
    80005b5c:	7f2e                	ld	t5,232(sp)
    80005b5e:	7fce                	ld	t6,240(sp)
    80005b60:	6111                	addi	sp,sp,256
    80005b62:	10200073          	sret
    80005b66:	00000013          	nop
    80005b6a:	00000013          	nop
    80005b6e:	0001                	nop

0000000080005b70 <timervec>:
    80005b70:	34051573          	csrrw	a0,mscratch,a0
    80005b74:	e10c                	sd	a1,0(a0)
    80005b76:	e510                	sd	a2,8(a0)
    80005b78:	e914                	sd	a3,16(a0)
    80005b7a:	6d0c                	ld	a1,24(a0)
    80005b7c:	7110                	ld	a2,32(a0)
    80005b7e:	6194                	ld	a3,0(a1)
    80005b80:	96b2                	add	a3,a3,a2
    80005b82:	e194                	sd	a3,0(a1)
    80005b84:	4589                	li	a1,2
    80005b86:	14459073          	csrw	sip,a1
    80005b8a:	6914                	ld	a3,16(a0)
    80005b8c:	6510                	ld	a2,8(a0)
    80005b8e:	610c                	ld	a1,0(a0)
    80005b90:	34051573          	csrrw	a0,mscratch,a0
    80005b94:	30200073          	mret
	...

0000000080005b9a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005b9a:	1141                	addi	sp,sp,-16
    80005b9c:	e422                	sd	s0,8(sp)
    80005b9e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005ba0:	0c0007b7          	lui	a5,0xc000
    80005ba4:	4705                	li	a4,1
    80005ba6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005ba8:	c3d8                	sw	a4,4(a5)
}
    80005baa:	6422                	ld	s0,8(sp)
    80005bac:	0141                	addi	sp,sp,16
    80005bae:	8082                	ret

0000000080005bb0 <plicinithart>:

void
plicinithart(void)
{
    80005bb0:	1141                	addi	sp,sp,-16
    80005bb2:	e406                	sd	ra,8(sp)
    80005bb4:	e022                	sd	s0,0(sp)
    80005bb6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005bb8:	ffffc097          	auipc	ra,0xffffc
    80005bbc:	e38080e7          	jalr	-456(ra) # 800019f0 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005bc0:	0085171b          	slliw	a4,a0,0x8
    80005bc4:	0c0027b7          	lui	a5,0xc002
    80005bc8:	97ba                	add	a5,a5,a4
    80005bca:	40200713          	li	a4,1026
    80005bce:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005bd2:	00d5151b          	slliw	a0,a0,0xd
    80005bd6:	0c2017b7          	lui	a5,0xc201
    80005bda:	953e                	add	a0,a0,a5
    80005bdc:	00052023          	sw	zero,0(a0)
}
    80005be0:	60a2                	ld	ra,8(sp)
    80005be2:	6402                	ld	s0,0(sp)
    80005be4:	0141                	addi	sp,sp,16
    80005be6:	8082                	ret

0000000080005be8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005be8:	1141                	addi	sp,sp,-16
    80005bea:	e406                	sd	ra,8(sp)
    80005bec:	e022                	sd	s0,0(sp)
    80005bee:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005bf0:	ffffc097          	auipc	ra,0xffffc
    80005bf4:	e00080e7          	jalr	-512(ra) # 800019f0 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005bf8:	00d5179b          	slliw	a5,a0,0xd
    80005bfc:	0c201537          	lui	a0,0xc201
    80005c00:	953e                	add	a0,a0,a5
  return irq;
}
    80005c02:	4148                	lw	a0,4(a0)
    80005c04:	60a2                	ld	ra,8(sp)
    80005c06:	6402                	ld	s0,0(sp)
    80005c08:	0141                	addi	sp,sp,16
    80005c0a:	8082                	ret

0000000080005c0c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005c0c:	1101                	addi	sp,sp,-32
    80005c0e:	ec06                	sd	ra,24(sp)
    80005c10:	e822                	sd	s0,16(sp)
    80005c12:	e426                	sd	s1,8(sp)
    80005c14:	1000                	addi	s0,sp,32
    80005c16:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005c18:	ffffc097          	auipc	ra,0xffffc
    80005c1c:	dd8080e7          	jalr	-552(ra) # 800019f0 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005c20:	00d5151b          	slliw	a0,a0,0xd
    80005c24:	0c2017b7          	lui	a5,0xc201
    80005c28:	97aa                	add	a5,a5,a0
    80005c2a:	c3c4                	sw	s1,4(a5)
}
    80005c2c:	60e2                	ld	ra,24(sp)
    80005c2e:	6442                	ld	s0,16(sp)
    80005c30:	64a2                	ld	s1,8(sp)
    80005c32:	6105                	addi	sp,sp,32
    80005c34:	8082                	ret

0000000080005c36 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005c36:	1141                	addi	sp,sp,-16
    80005c38:	e406                	sd	ra,8(sp)
    80005c3a:	e022                	sd	s0,0(sp)
    80005c3c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005c3e:	479d                	li	a5,7
    80005c40:	06a7c963          	blt	a5,a0,80005cb2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005c44:	0001d797          	auipc	a5,0x1d
    80005c48:	3bc78793          	addi	a5,a5,956 # 80023000 <disk>
    80005c4c:	00a78733          	add	a4,a5,a0
    80005c50:	6789                	lui	a5,0x2
    80005c52:	97ba                	add	a5,a5,a4
    80005c54:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005c58:	e7ad                	bnez	a5,80005cc2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005c5a:	00451793          	slli	a5,a0,0x4
    80005c5e:	0001f717          	auipc	a4,0x1f
    80005c62:	3a270713          	addi	a4,a4,930 # 80025000 <disk+0x2000>
    80005c66:	6314                	ld	a3,0(a4)
    80005c68:	96be                	add	a3,a3,a5
    80005c6a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005c6e:	6314                	ld	a3,0(a4)
    80005c70:	96be                	add	a3,a3,a5
    80005c72:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005c76:	6314                	ld	a3,0(a4)
    80005c78:	96be                	add	a3,a3,a5
    80005c7a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005c7e:	6318                	ld	a4,0(a4)
    80005c80:	97ba                	add	a5,a5,a4
    80005c82:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005c86:	0001d797          	auipc	a5,0x1d
    80005c8a:	37a78793          	addi	a5,a5,890 # 80023000 <disk>
    80005c8e:	97aa                	add	a5,a5,a0
    80005c90:	6509                	lui	a0,0x2
    80005c92:	953e                	add	a0,a0,a5
    80005c94:	4785                	li	a5,1
    80005c96:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005c9a:	0001f517          	auipc	a0,0x1f
    80005c9e:	37e50513          	addi	a0,a0,894 # 80025018 <disk+0x2018>
    80005ca2:	ffffc097          	auipc	ra,0xffffc
    80005ca6:	5b4080e7          	jalr	1460(ra) # 80002256 <wakeup>
}
    80005caa:	60a2                	ld	ra,8(sp)
    80005cac:	6402                	ld	s0,0(sp)
    80005cae:	0141                	addi	sp,sp,16
    80005cb0:	8082                	ret
    panic("free_desc 1");
    80005cb2:	00003517          	auipc	a0,0x3
    80005cb6:	ab650513          	addi	a0,a0,-1354 # 80008768 <syscalls+0x320>
    80005cba:	ffffb097          	auipc	ra,0xffffb
    80005cbe:	884080e7          	jalr	-1916(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005cc2:	00003517          	auipc	a0,0x3
    80005cc6:	ab650513          	addi	a0,a0,-1354 # 80008778 <syscalls+0x330>
    80005cca:	ffffb097          	auipc	ra,0xffffb
    80005cce:	874080e7          	jalr	-1932(ra) # 8000053e <panic>

0000000080005cd2 <virtio_disk_init>:
{
    80005cd2:	1101                	addi	sp,sp,-32
    80005cd4:	ec06                	sd	ra,24(sp)
    80005cd6:	e822                	sd	s0,16(sp)
    80005cd8:	e426                	sd	s1,8(sp)
    80005cda:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005cdc:	00003597          	auipc	a1,0x3
    80005ce0:	aac58593          	addi	a1,a1,-1364 # 80008788 <syscalls+0x340>
    80005ce4:	0001f517          	auipc	a0,0x1f
    80005ce8:	44450513          	addi	a0,a0,1092 # 80025128 <disk+0x2128>
    80005cec:	ffffb097          	auipc	ra,0xffffb
    80005cf0:	e68080e7          	jalr	-408(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005cf4:	100017b7          	lui	a5,0x10001
    80005cf8:	4398                	lw	a4,0(a5)
    80005cfa:	2701                	sext.w	a4,a4
    80005cfc:	747277b7          	lui	a5,0x74727
    80005d00:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005d04:	0ef71163          	bne	a4,a5,80005de6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005d08:	100017b7          	lui	a5,0x10001
    80005d0c:	43dc                	lw	a5,4(a5)
    80005d0e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005d10:	4705                	li	a4,1
    80005d12:	0ce79a63          	bne	a5,a4,80005de6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005d16:	100017b7          	lui	a5,0x10001
    80005d1a:	479c                	lw	a5,8(a5)
    80005d1c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005d1e:	4709                	li	a4,2
    80005d20:	0ce79363          	bne	a5,a4,80005de6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005d24:	100017b7          	lui	a5,0x10001
    80005d28:	47d8                	lw	a4,12(a5)
    80005d2a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005d2c:	554d47b7          	lui	a5,0x554d4
    80005d30:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005d34:	0af71963          	bne	a4,a5,80005de6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d38:	100017b7          	lui	a5,0x10001
    80005d3c:	4705                	li	a4,1
    80005d3e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d40:	470d                	li	a4,3
    80005d42:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005d44:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005d46:	c7ffe737          	lui	a4,0xc7ffe
    80005d4a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005d4e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005d50:	2701                	sext.w	a4,a4
    80005d52:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d54:	472d                	li	a4,11
    80005d56:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d58:	473d                	li	a4,15
    80005d5a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005d5c:	6705                	lui	a4,0x1
    80005d5e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005d60:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005d64:	5bdc                	lw	a5,52(a5)
    80005d66:	2781                	sext.w	a5,a5
  if(max == 0)
    80005d68:	c7d9                	beqz	a5,80005df6 <virtio_disk_init+0x124>
  if(max < NUM)
    80005d6a:	471d                	li	a4,7
    80005d6c:	08f77d63          	bgeu	a4,a5,80005e06 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005d70:	100014b7          	lui	s1,0x10001
    80005d74:	47a1                	li	a5,8
    80005d76:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005d78:	6609                	lui	a2,0x2
    80005d7a:	4581                	li	a1,0
    80005d7c:	0001d517          	auipc	a0,0x1d
    80005d80:	28450513          	addi	a0,a0,644 # 80023000 <disk>
    80005d84:	ffffb097          	auipc	ra,0xffffb
    80005d88:	f5c080e7          	jalr	-164(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005d8c:	0001d717          	auipc	a4,0x1d
    80005d90:	27470713          	addi	a4,a4,628 # 80023000 <disk>
    80005d94:	00c75793          	srli	a5,a4,0xc
    80005d98:	2781                	sext.w	a5,a5
    80005d9a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005d9c:	0001f797          	auipc	a5,0x1f
    80005da0:	26478793          	addi	a5,a5,612 # 80025000 <disk+0x2000>
    80005da4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005da6:	0001d717          	auipc	a4,0x1d
    80005daa:	2da70713          	addi	a4,a4,730 # 80023080 <disk+0x80>
    80005dae:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005db0:	0001e717          	auipc	a4,0x1e
    80005db4:	25070713          	addi	a4,a4,592 # 80024000 <disk+0x1000>
    80005db8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005dba:	4705                	li	a4,1
    80005dbc:	00e78c23          	sb	a4,24(a5)
    80005dc0:	00e78ca3          	sb	a4,25(a5)
    80005dc4:	00e78d23          	sb	a4,26(a5)
    80005dc8:	00e78da3          	sb	a4,27(a5)
    80005dcc:	00e78e23          	sb	a4,28(a5)
    80005dd0:	00e78ea3          	sb	a4,29(a5)
    80005dd4:	00e78f23          	sb	a4,30(a5)
    80005dd8:	00e78fa3          	sb	a4,31(a5)
}
    80005ddc:	60e2                	ld	ra,24(sp)
    80005dde:	6442                	ld	s0,16(sp)
    80005de0:	64a2                	ld	s1,8(sp)
    80005de2:	6105                	addi	sp,sp,32
    80005de4:	8082                	ret
    panic("could not find virtio disk");
    80005de6:	00003517          	auipc	a0,0x3
    80005dea:	9b250513          	addi	a0,a0,-1614 # 80008798 <syscalls+0x350>
    80005dee:	ffffa097          	auipc	ra,0xffffa
    80005df2:	750080e7          	jalr	1872(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80005df6:	00003517          	auipc	a0,0x3
    80005dfa:	9c250513          	addi	a0,a0,-1598 # 800087b8 <syscalls+0x370>
    80005dfe:	ffffa097          	auipc	ra,0xffffa
    80005e02:	740080e7          	jalr	1856(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80005e06:	00003517          	auipc	a0,0x3
    80005e0a:	9d250513          	addi	a0,a0,-1582 # 800087d8 <syscalls+0x390>
    80005e0e:	ffffa097          	auipc	ra,0xffffa
    80005e12:	730080e7          	jalr	1840(ra) # 8000053e <panic>

0000000080005e16 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005e16:	7159                	addi	sp,sp,-112
    80005e18:	f486                	sd	ra,104(sp)
    80005e1a:	f0a2                	sd	s0,96(sp)
    80005e1c:	eca6                	sd	s1,88(sp)
    80005e1e:	e8ca                	sd	s2,80(sp)
    80005e20:	e4ce                	sd	s3,72(sp)
    80005e22:	e0d2                	sd	s4,64(sp)
    80005e24:	fc56                	sd	s5,56(sp)
    80005e26:	f85a                	sd	s6,48(sp)
    80005e28:	f45e                	sd	s7,40(sp)
    80005e2a:	f062                	sd	s8,32(sp)
    80005e2c:	ec66                	sd	s9,24(sp)
    80005e2e:	e86a                	sd	s10,16(sp)
    80005e30:	1880                	addi	s0,sp,112
    80005e32:	892a                	mv	s2,a0
    80005e34:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005e36:	00c52c83          	lw	s9,12(a0)
    80005e3a:	001c9c9b          	slliw	s9,s9,0x1
    80005e3e:	1c82                	slli	s9,s9,0x20
    80005e40:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005e44:	0001f517          	auipc	a0,0x1f
    80005e48:	2e450513          	addi	a0,a0,740 # 80025128 <disk+0x2128>
    80005e4c:	ffffb097          	auipc	ra,0xffffb
    80005e50:	d98080e7          	jalr	-616(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80005e54:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005e56:	4c21                	li	s8,8
      disk.free[i] = 0;
    80005e58:	0001db97          	auipc	s7,0x1d
    80005e5c:	1a8b8b93          	addi	s7,s7,424 # 80023000 <disk>
    80005e60:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80005e62:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80005e64:	8a4e                	mv	s4,s3
    80005e66:	a051                	j	80005eea <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80005e68:	00fb86b3          	add	a3,s7,a5
    80005e6c:	96da                	add	a3,a3,s6
    80005e6e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80005e72:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80005e74:	0207c563          	bltz	a5,80005e9e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005e78:	2485                	addiw	s1,s1,1
    80005e7a:	0711                	addi	a4,a4,4
    80005e7c:	25548063          	beq	s1,s5,800060bc <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80005e80:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80005e82:	0001f697          	auipc	a3,0x1f
    80005e86:	19668693          	addi	a3,a3,406 # 80025018 <disk+0x2018>
    80005e8a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80005e8c:	0006c583          	lbu	a1,0(a3)
    80005e90:	fde1                	bnez	a1,80005e68 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005e92:	2785                	addiw	a5,a5,1
    80005e94:	0685                	addi	a3,a3,1
    80005e96:	ff879be3          	bne	a5,s8,80005e8c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005e9a:	57fd                	li	a5,-1
    80005e9c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80005e9e:	02905a63          	blez	s1,80005ed2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005ea2:	f9042503          	lw	a0,-112(s0)
    80005ea6:	00000097          	auipc	ra,0x0
    80005eaa:	d90080e7          	jalr	-624(ra) # 80005c36 <free_desc>
      for(int j = 0; j < i; j++)
    80005eae:	4785                	li	a5,1
    80005eb0:	0297d163          	bge	a5,s1,80005ed2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005eb4:	f9442503          	lw	a0,-108(s0)
    80005eb8:	00000097          	auipc	ra,0x0
    80005ebc:	d7e080e7          	jalr	-642(ra) # 80005c36 <free_desc>
      for(int j = 0; j < i; j++)
    80005ec0:	4789                	li	a5,2
    80005ec2:	0097d863          	bge	a5,s1,80005ed2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005ec6:	f9842503          	lw	a0,-104(s0)
    80005eca:	00000097          	auipc	ra,0x0
    80005ece:	d6c080e7          	jalr	-660(ra) # 80005c36 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005ed2:	0001f597          	auipc	a1,0x1f
    80005ed6:	25658593          	addi	a1,a1,598 # 80025128 <disk+0x2128>
    80005eda:	0001f517          	auipc	a0,0x1f
    80005ede:	13e50513          	addi	a0,a0,318 # 80025018 <disk+0x2018>
    80005ee2:	ffffc097          	auipc	ra,0xffffc
    80005ee6:	1e8080e7          	jalr	488(ra) # 800020ca <sleep>
  for(int i = 0; i < 3; i++){
    80005eea:	f9040713          	addi	a4,s0,-112
    80005eee:	84ce                	mv	s1,s3
    80005ef0:	bf41                	j	80005e80 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80005ef2:	20058713          	addi	a4,a1,512
    80005ef6:	00471693          	slli	a3,a4,0x4
    80005efa:	0001d717          	auipc	a4,0x1d
    80005efe:	10670713          	addi	a4,a4,262 # 80023000 <disk>
    80005f02:	9736                	add	a4,a4,a3
    80005f04:	4685                	li	a3,1
    80005f06:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80005f0a:	20058713          	addi	a4,a1,512
    80005f0e:	00471693          	slli	a3,a4,0x4
    80005f12:	0001d717          	auipc	a4,0x1d
    80005f16:	0ee70713          	addi	a4,a4,238 # 80023000 <disk>
    80005f1a:	9736                	add	a4,a4,a3
    80005f1c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80005f20:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80005f24:	7679                	lui	a2,0xffffe
    80005f26:	963e                	add	a2,a2,a5
    80005f28:	0001f697          	auipc	a3,0x1f
    80005f2c:	0d868693          	addi	a3,a3,216 # 80025000 <disk+0x2000>
    80005f30:	6298                	ld	a4,0(a3)
    80005f32:	9732                	add	a4,a4,a2
    80005f34:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80005f36:	6298                	ld	a4,0(a3)
    80005f38:	9732                	add	a4,a4,a2
    80005f3a:	4541                	li	a0,16
    80005f3c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80005f3e:	6298                	ld	a4,0(a3)
    80005f40:	9732                	add	a4,a4,a2
    80005f42:	4505                	li	a0,1
    80005f44:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80005f48:	f9442703          	lw	a4,-108(s0)
    80005f4c:	6288                	ld	a0,0(a3)
    80005f4e:	962a                	add	a2,a2,a0
    80005f50:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80005f54:	0712                	slli	a4,a4,0x4
    80005f56:	6290                	ld	a2,0(a3)
    80005f58:	963a                	add	a2,a2,a4
    80005f5a:	05890513          	addi	a0,s2,88
    80005f5e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80005f60:	6294                	ld	a3,0(a3)
    80005f62:	96ba                	add	a3,a3,a4
    80005f64:	40000613          	li	a2,1024
    80005f68:	c690                	sw	a2,8(a3)
  if(write)
    80005f6a:	140d0063          	beqz	s10,800060aa <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80005f6e:	0001f697          	auipc	a3,0x1f
    80005f72:	0926b683          	ld	a3,146(a3) # 80025000 <disk+0x2000>
    80005f76:	96ba                	add	a3,a3,a4
    80005f78:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80005f7c:	0001d817          	auipc	a6,0x1d
    80005f80:	08480813          	addi	a6,a6,132 # 80023000 <disk>
    80005f84:	0001f517          	auipc	a0,0x1f
    80005f88:	07c50513          	addi	a0,a0,124 # 80025000 <disk+0x2000>
    80005f8c:	6114                	ld	a3,0(a0)
    80005f8e:	96ba                	add	a3,a3,a4
    80005f90:	00c6d603          	lhu	a2,12(a3)
    80005f94:	00166613          	ori	a2,a2,1
    80005f98:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80005f9c:	f9842683          	lw	a3,-104(s0)
    80005fa0:	6110                	ld	a2,0(a0)
    80005fa2:	9732                	add	a4,a4,a2
    80005fa4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80005fa8:	20058613          	addi	a2,a1,512
    80005fac:	0612                	slli	a2,a2,0x4
    80005fae:	9642                	add	a2,a2,a6
    80005fb0:	577d                	li	a4,-1
    80005fb2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80005fb6:	00469713          	slli	a4,a3,0x4
    80005fba:	6114                	ld	a3,0(a0)
    80005fbc:	96ba                	add	a3,a3,a4
    80005fbe:	03078793          	addi	a5,a5,48
    80005fc2:	97c2                	add	a5,a5,a6
    80005fc4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80005fc6:	611c                	ld	a5,0(a0)
    80005fc8:	97ba                	add	a5,a5,a4
    80005fca:	4685                	li	a3,1
    80005fcc:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80005fce:	611c                	ld	a5,0(a0)
    80005fd0:	97ba                	add	a5,a5,a4
    80005fd2:	4809                	li	a6,2
    80005fd4:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80005fd8:	611c                	ld	a5,0(a0)
    80005fda:	973e                	add	a4,a4,a5
    80005fdc:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80005fe0:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80005fe4:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80005fe8:	6518                	ld	a4,8(a0)
    80005fea:	00275783          	lhu	a5,2(a4)
    80005fee:	8b9d                	andi	a5,a5,7
    80005ff0:	0786                	slli	a5,a5,0x1
    80005ff2:	97ba                	add	a5,a5,a4
    80005ff4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80005ff8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80005ffc:	6518                	ld	a4,8(a0)
    80005ffe:	00275783          	lhu	a5,2(a4)
    80006002:	2785                	addiw	a5,a5,1
    80006004:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006008:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000600c:	100017b7          	lui	a5,0x10001
    80006010:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006014:	00492703          	lw	a4,4(s2)
    80006018:	4785                	li	a5,1
    8000601a:	02f71163          	bne	a4,a5,8000603c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000601e:	0001f997          	auipc	s3,0x1f
    80006022:	10a98993          	addi	s3,s3,266 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006026:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006028:	85ce                	mv	a1,s3
    8000602a:	854a                	mv	a0,s2
    8000602c:	ffffc097          	auipc	ra,0xffffc
    80006030:	09e080e7          	jalr	158(ra) # 800020ca <sleep>
  while(b->disk == 1) {
    80006034:	00492783          	lw	a5,4(s2)
    80006038:	fe9788e3          	beq	a5,s1,80006028 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000603c:	f9042903          	lw	s2,-112(s0)
    80006040:	20090793          	addi	a5,s2,512
    80006044:	00479713          	slli	a4,a5,0x4
    80006048:	0001d797          	auipc	a5,0x1d
    8000604c:	fb878793          	addi	a5,a5,-72 # 80023000 <disk>
    80006050:	97ba                	add	a5,a5,a4
    80006052:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006056:	0001f997          	auipc	s3,0x1f
    8000605a:	faa98993          	addi	s3,s3,-86 # 80025000 <disk+0x2000>
    8000605e:	00491713          	slli	a4,s2,0x4
    80006062:	0009b783          	ld	a5,0(s3)
    80006066:	97ba                	add	a5,a5,a4
    80006068:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000606c:	854a                	mv	a0,s2
    8000606e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006072:	00000097          	auipc	ra,0x0
    80006076:	bc4080e7          	jalr	-1084(ra) # 80005c36 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000607a:	8885                	andi	s1,s1,1
    8000607c:	f0ed                	bnez	s1,8000605e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000607e:	0001f517          	auipc	a0,0x1f
    80006082:	0aa50513          	addi	a0,a0,170 # 80025128 <disk+0x2128>
    80006086:	ffffb097          	auipc	ra,0xffffb
    8000608a:	c12080e7          	jalr	-1006(ra) # 80000c98 <release>
}
    8000608e:	70a6                	ld	ra,104(sp)
    80006090:	7406                	ld	s0,96(sp)
    80006092:	64e6                	ld	s1,88(sp)
    80006094:	6946                	ld	s2,80(sp)
    80006096:	69a6                	ld	s3,72(sp)
    80006098:	6a06                	ld	s4,64(sp)
    8000609a:	7ae2                	ld	s5,56(sp)
    8000609c:	7b42                	ld	s6,48(sp)
    8000609e:	7ba2                	ld	s7,40(sp)
    800060a0:	7c02                	ld	s8,32(sp)
    800060a2:	6ce2                	ld	s9,24(sp)
    800060a4:	6d42                	ld	s10,16(sp)
    800060a6:	6165                	addi	sp,sp,112
    800060a8:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800060aa:	0001f697          	auipc	a3,0x1f
    800060ae:	f566b683          	ld	a3,-170(a3) # 80025000 <disk+0x2000>
    800060b2:	96ba                	add	a3,a3,a4
    800060b4:	4609                	li	a2,2
    800060b6:	00c69623          	sh	a2,12(a3)
    800060ba:	b5c9                	j	80005f7c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800060bc:	f9042583          	lw	a1,-112(s0)
    800060c0:	20058793          	addi	a5,a1,512
    800060c4:	0792                	slli	a5,a5,0x4
    800060c6:	0001d517          	auipc	a0,0x1d
    800060ca:	fe250513          	addi	a0,a0,-30 # 800230a8 <disk+0xa8>
    800060ce:	953e                	add	a0,a0,a5
  if(write)
    800060d0:	e20d11e3          	bnez	s10,80005ef2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800060d4:	20058713          	addi	a4,a1,512
    800060d8:	00471693          	slli	a3,a4,0x4
    800060dc:	0001d717          	auipc	a4,0x1d
    800060e0:	f2470713          	addi	a4,a4,-220 # 80023000 <disk>
    800060e4:	9736                	add	a4,a4,a3
    800060e6:	0a072423          	sw	zero,168(a4)
    800060ea:	b505                	j	80005f0a <virtio_disk_rw+0xf4>

00000000800060ec <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800060ec:	1101                	addi	sp,sp,-32
    800060ee:	ec06                	sd	ra,24(sp)
    800060f0:	e822                	sd	s0,16(sp)
    800060f2:	e426                	sd	s1,8(sp)
    800060f4:	e04a                	sd	s2,0(sp)
    800060f6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800060f8:	0001f517          	auipc	a0,0x1f
    800060fc:	03050513          	addi	a0,a0,48 # 80025128 <disk+0x2128>
    80006100:	ffffb097          	auipc	ra,0xffffb
    80006104:	ae4080e7          	jalr	-1308(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006108:	10001737          	lui	a4,0x10001
    8000610c:	533c                	lw	a5,96(a4)
    8000610e:	8b8d                	andi	a5,a5,3
    80006110:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006112:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006116:	0001f797          	auipc	a5,0x1f
    8000611a:	eea78793          	addi	a5,a5,-278 # 80025000 <disk+0x2000>
    8000611e:	6b94                	ld	a3,16(a5)
    80006120:	0207d703          	lhu	a4,32(a5)
    80006124:	0026d783          	lhu	a5,2(a3)
    80006128:	06f70163          	beq	a4,a5,8000618a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000612c:	0001d917          	auipc	s2,0x1d
    80006130:	ed490913          	addi	s2,s2,-300 # 80023000 <disk>
    80006134:	0001f497          	auipc	s1,0x1f
    80006138:	ecc48493          	addi	s1,s1,-308 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000613c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006140:	6898                	ld	a4,16(s1)
    80006142:	0204d783          	lhu	a5,32(s1)
    80006146:	8b9d                	andi	a5,a5,7
    80006148:	078e                	slli	a5,a5,0x3
    8000614a:	97ba                	add	a5,a5,a4
    8000614c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000614e:	20078713          	addi	a4,a5,512
    80006152:	0712                	slli	a4,a4,0x4
    80006154:	974a                	add	a4,a4,s2
    80006156:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000615a:	e731                	bnez	a4,800061a6 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000615c:	20078793          	addi	a5,a5,512
    80006160:	0792                	slli	a5,a5,0x4
    80006162:	97ca                	add	a5,a5,s2
    80006164:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006166:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000616a:	ffffc097          	auipc	ra,0xffffc
    8000616e:	0ec080e7          	jalr	236(ra) # 80002256 <wakeup>

    disk.used_idx += 1;
    80006172:	0204d783          	lhu	a5,32(s1)
    80006176:	2785                	addiw	a5,a5,1
    80006178:	17c2                	slli	a5,a5,0x30
    8000617a:	93c1                	srli	a5,a5,0x30
    8000617c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006180:	6898                	ld	a4,16(s1)
    80006182:	00275703          	lhu	a4,2(a4)
    80006186:	faf71be3          	bne	a4,a5,8000613c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000618a:	0001f517          	auipc	a0,0x1f
    8000618e:	f9e50513          	addi	a0,a0,-98 # 80025128 <disk+0x2128>
    80006192:	ffffb097          	auipc	ra,0xffffb
    80006196:	b06080e7          	jalr	-1274(ra) # 80000c98 <release>
}
    8000619a:	60e2                	ld	ra,24(sp)
    8000619c:	6442                	ld	s0,16(sp)
    8000619e:	64a2                	ld	s1,8(sp)
    800061a0:	6902                	ld	s2,0(sp)
    800061a2:	6105                	addi	sp,sp,32
    800061a4:	8082                	ret
      panic("virtio_disk_intr status");
    800061a6:	00002517          	auipc	a0,0x2
    800061aa:	65250513          	addi	a0,a0,1618 # 800087f8 <syscalls+0x3b0>
    800061ae:	ffffa097          	auipc	ra,0xffffa
    800061b2:	390080e7          	jalr	912(ra) # 8000053e <panic>

00000000800061b6 <cas>:
    800061b6:	100522af          	lr.w	t0,(a0)
    800061ba:	00b29563          	bne	t0,a1,800061c4 <fail>
    800061be:	18c5252f          	sc.w	a0,a2,(a0)
    800061c2:	8082                	ret

00000000800061c4 <fail>:
    800061c4:	4505                	li	a0,1
    800061c6:	8082                	ret
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
