
user/_init:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:

char *argv[] = { "sh", 0 };

int
main(void)
{
   0:	1101                	addi	sp,sp,-32
   2:	ec06                	sd	ra,24(sp)
   4:	e822                	sd	s0,16(sp)
   6:	e426                	sd	s1,8(sp)
   8:	e04a                	sd	s2,0(sp)
   a:	1000                	addi	s0,sp,32
  int pid, wpid;

  if(open("console", O_RDWR) < 0){
   c:	4589                	li	a1,2
   e:	00001517          	auipc	a0,0x1
  12:	88a50513          	addi	a0,a0,-1910 # 898 <malloc+0xe4>
  16:	00000097          	auipc	ra,0x0
  1a:	3a8080e7          	jalr	936(ra) # 3be <open>
  1e:	06054b63          	bltz	a0,94 <main+0x94>
    mknod("console", CONSOLE, 0);
    open("console", O_RDWR);
  }
  dup(0);  // stdout
  22:	4501                	li	a0,0
  24:	00000097          	auipc	ra,0x0
  28:	3d2080e7          	jalr	978(ra) # 3f6 <dup>
  dup(0);  // stderr
  2c:	4501                	li	a0,0
  2e:	00000097          	auipc	ra,0x0
  32:	3c8080e7          	jalr	968(ra) # 3f6 <dup>
  printf("got to here in user program\n");
  36:	00001517          	auipc	a0,0x1
  3a:	86a50513          	addi	a0,a0,-1942 # 8a0 <malloc+0xec>
  3e:	00000097          	auipc	ra,0x0
  42:	6b8080e7          	jalr	1720(ra) # 6f6 <printf>
  for(;;){
    printf("init: starting sh\n");
  46:	00001917          	auipc	s2,0x1
  4a:	87a90913          	addi	s2,s2,-1926 # 8c0 <malloc+0x10c>
  4e:	854a                	mv	a0,s2
  50:	00000097          	auipc	ra,0x0
  54:	6a6080e7          	jalr	1702(ra) # 6f6 <printf>
    pid = fork();
  58:	00000097          	auipc	ra,0x0
  5c:	31e080e7          	jalr	798(ra) # 376 <fork>
  60:	84aa                	mv	s1,a0
    if(pid < 0){
  62:	04054d63          	bltz	a0,bc <main+0xbc>
      printf("init: fork failed\n");
      exit(1);
    }
    if(pid == 0){
  66:	c925                	beqz	a0,d6 <main+0xd6>
    }

    for(;;){
      // this call to wait() returns if the shell exits,
      // or if a parentless process exits.
      wpid = wait((int *) 0);
  68:	4501                	li	a0,0
  6a:	00000097          	auipc	ra,0x0
  6e:	31c080e7          	jalr	796(ra) # 386 <wait>
      if(wpid == pid){
  72:	fca48ee3          	beq	s1,a0,4e <main+0x4e>
        // the shell exited; restart it.
        break;
      } else if(wpid < 0){
  76:	fe0559e3          	bgez	a0,68 <main+0x68>
        printf("init: wait returned an error\n");
  7a:	00001517          	auipc	a0,0x1
  7e:	89650513          	addi	a0,a0,-1898 # 910 <malloc+0x15c>
  82:	00000097          	auipc	ra,0x0
  86:	674080e7          	jalr	1652(ra) # 6f6 <printf>
        exit(1);
  8a:	4505                	li	a0,1
  8c:	00000097          	auipc	ra,0x0
  90:	2f2080e7          	jalr	754(ra) # 37e <exit>
    mknod("console", CONSOLE, 0);
  94:	4601                	li	a2,0
  96:	4585                	li	a1,1
  98:	00001517          	auipc	a0,0x1
  9c:	80050513          	addi	a0,a0,-2048 # 898 <malloc+0xe4>
  a0:	00000097          	auipc	ra,0x0
  a4:	326080e7          	jalr	806(ra) # 3c6 <mknod>
    open("console", O_RDWR);
  a8:	4589                	li	a1,2
  aa:	00000517          	auipc	a0,0x0
  ae:	7ee50513          	addi	a0,a0,2030 # 898 <malloc+0xe4>
  b2:	00000097          	auipc	ra,0x0
  b6:	30c080e7          	jalr	780(ra) # 3be <open>
  ba:	b7a5                	j	22 <main+0x22>
      printf("init: fork failed\n");
  bc:	00001517          	auipc	a0,0x1
  c0:	81c50513          	addi	a0,a0,-2020 # 8d8 <malloc+0x124>
  c4:	00000097          	auipc	ra,0x0
  c8:	632080e7          	jalr	1586(ra) # 6f6 <printf>
      exit(1);
  cc:	4505                	li	a0,1
  ce:	00000097          	auipc	ra,0x0
  d2:	2b0080e7          	jalr	688(ra) # 37e <exit>
      exec("sh", argv);
  d6:	00001597          	auipc	a1,0x1
  da:	87a58593          	addi	a1,a1,-1926 # 950 <argv>
  de:	00001517          	auipc	a0,0x1
  e2:	81250513          	addi	a0,a0,-2030 # 8f0 <malloc+0x13c>
  e6:	00000097          	auipc	ra,0x0
  ea:	2d0080e7          	jalr	720(ra) # 3b6 <exec>
      printf("init: exec sh failed\n");
  ee:	00001517          	auipc	a0,0x1
  f2:	80a50513          	addi	a0,a0,-2038 # 8f8 <malloc+0x144>
  f6:	00000097          	auipc	ra,0x0
  fa:	600080e7          	jalr	1536(ra) # 6f6 <printf>
      exit(1);
  fe:	4505                	li	a0,1
 100:	00000097          	auipc	ra,0x0
 104:	27e080e7          	jalr	638(ra) # 37e <exit>

0000000000000108 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 108:	1141                	addi	sp,sp,-16
 10a:	e422                	sd	s0,8(sp)
 10c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 10e:	87aa                	mv	a5,a0
 110:	0585                	addi	a1,a1,1
 112:	0785                	addi	a5,a5,1
 114:	fff5c703          	lbu	a4,-1(a1)
 118:	fee78fa3          	sb	a4,-1(a5)
 11c:	fb75                	bnez	a4,110 <strcpy+0x8>
    ;
  return os;
}
 11e:	6422                	ld	s0,8(sp)
 120:	0141                	addi	sp,sp,16
 122:	8082                	ret

0000000000000124 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 124:	1141                	addi	sp,sp,-16
 126:	e422                	sd	s0,8(sp)
 128:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 12a:	00054783          	lbu	a5,0(a0)
 12e:	cb91                	beqz	a5,142 <strcmp+0x1e>
 130:	0005c703          	lbu	a4,0(a1)
 134:	00f71763          	bne	a4,a5,142 <strcmp+0x1e>
    p++, q++;
 138:	0505                	addi	a0,a0,1
 13a:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 13c:	00054783          	lbu	a5,0(a0)
 140:	fbe5                	bnez	a5,130 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 142:	0005c503          	lbu	a0,0(a1)
}
 146:	40a7853b          	subw	a0,a5,a0
 14a:	6422                	ld	s0,8(sp)
 14c:	0141                	addi	sp,sp,16
 14e:	8082                	ret

0000000000000150 <strlen>:

uint
strlen(const char *s)
{
 150:	1141                	addi	sp,sp,-16
 152:	e422                	sd	s0,8(sp)
 154:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 156:	00054783          	lbu	a5,0(a0)
 15a:	cf91                	beqz	a5,176 <strlen+0x26>
 15c:	0505                	addi	a0,a0,1
 15e:	87aa                	mv	a5,a0
 160:	4685                	li	a3,1
 162:	9e89                	subw	a3,a3,a0
 164:	00f6853b          	addw	a0,a3,a5
 168:	0785                	addi	a5,a5,1
 16a:	fff7c703          	lbu	a4,-1(a5)
 16e:	fb7d                	bnez	a4,164 <strlen+0x14>
    ;
  return n;
}
 170:	6422                	ld	s0,8(sp)
 172:	0141                	addi	sp,sp,16
 174:	8082                	ret
  for(n = 0; s[n]; n++)
 176:	4501                	li	a0,0
 178:	bfe5                	j	170 <strlen+0x20>

000000000000017a <memset>:

void*
memset(void *dst, int c, uint n)
{
 17a:	1141                	addi	sp,sp,-16
 17c:	e422                	sd	s0,8(sp)
 17e:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 180:	ce09                	beqz	a2,19a <memset+0x20>
 182:	87aa                	mv	a5,a0
 184:	fff6071b          	addiw	a4,a2,-1
 188:	1702                	slli	a4,a4,0x20
 18a:	9301                	srli	a4,a4,0x20
 18c:	0705                	addi	a4,a4,1
 18e:	972a                	add	a4,a4,a0
    cdst[i] = c;
 190:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 194:	0785                	addi	a5,a5,1
 196:	fee79de3          	bne	a5,a4,190 <memset+0x16>
  }
  return dst;
}
 19a:	6422                	ld	s0,8(sp)
 19c:	0141                	addi	sp,sp,16
 19e:	8082                	ret

00000000000001a0 <strchr>:

char*
strchr(const char *s, char c)
{
 1a0:	1141                	addi	sp,sp,-16
 1a2:	e422                	sd	s0,8(sp)
 1a4:	0800                	addi	s0,sp,16
  for(; *s; s++)
 1a6:	00054783          	lbu	a5,0(a0)
 1aa:	cb99                	beqz	a5,1c0 <strchr+0x20>
    if(*s == c)
 1ac:	00f58763          	beq	a1,a5,1ba <strchr+0x1a>
  for(; *s; s++)
 1b0:	0505                	addi	a0,a0,1
 1b2:	00054783          	lbu	a5,0(a0)
 1b6:	fbfd                	bnez	a5,1ac <strchr+0xc>
      return (char*)s;
  return 0;
 1b8:	4501                	li	a0,0
}
 1ba:	6422                	ld	s0,8(sp)
 1bc:	0141                	addi	sp,sp,16
 1be:	8082                	ret
  return 0;
 1c0:	4501                	li	a0,0
 1c2:	bfe5                	j	1ba <strchr+0x1a>

00000000000001c4 <gets>:

char*
gets(char *buf, int max)
{
 1c4:	711d                	addi	sp,sp,-96
 1c6:	ec86                	sd	ra,88(sp)
 1c8:	e8a2                	sd	s0,80(sp)
 1ca:	e4a6                	sd	s1,72(sp)
 1cc:	e0ca                	sd	s2,64(sp)
 1ce:	fc4e                	sd	s3,56(sp)
 1d0:	f852                	sd	s4,48(sp)
 1d2:	f456                	sd	s5,40(sp)
 1d4:	f05a                	sd	s6,32(sp)
 1d6:	ec5e                	sd	s7,24(sp)
 1d8:	1080                	addi	s0,sp,96
 1da:	8baa                	mv	s7,a0
 1dc:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 1de:	892a                	mv	s2,a0
 1e0:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 1e2:	4aa9                	li	s5,10
 1e4:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 1e6:	89a6                	mv	s3,s1
 1e8:	2485                	addiw	s1,s1,1
 1ea:	0344d863          	bge	s1,s4,21a <gets+0x56>
    cc = read(0, &c, 1);
 1ee:	4605                	li	a2,1
 1f0:	faf40593          	addi	a1,s0,-81
 1f4:	4501                	li	a0,0
 1f6:	00000097          	auipc	ra,0x0
 1fa:	1a0080e7          	jalr	416(ra) # 396 <read>
    if(cc < 1)
 1fe:	00a05e63          	blez	a0,21a <gets+0x56>
    buf[i++] = c;
 202:	faf44783          	lbu	a5,-81(s0)
 206:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 20a:	01578763          	beq	a5,s5,218 <gets+0x54>
 20e:	0905                	addi	s2,s2,1
 210:	fd679be3          	bne	a5,s6,1e6 <gets+0x22>
  for(i=0; i+1 < max; ){
 214:	89a6                	mv	s3,s1
 216:	a011                	j	21a <gets+0x56>
 218:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 21a:	99de                	add	s3,s3,s7
 21c:	00098023          	sb	zero,0(s3)
  return buf;
}
 220:	855e                	mv	a0,s7
 222:	60e6                	ld	ra,88(sp)
 224:	6446                	ld	s0,80(sp)
 226:	64a6                	ld	s1,72(sp)
 228:	6906                	ld	s2,64(sp)
 22a:	79e2                	ld	s3,56(sp)
 22c:	7a42                	ld	s4,48(sp)
 22e:	7aa2                	ld	s5,40(sp)
 230:	7b02                	ld	s6,32(sp)
 232:	6be2                	ld	s7,24(sp)
 234:	6125                	addi	sp,sp,96
 236:	8082                	ret

0000000000000238 <stat>:

int
stat(const char *n, struct stat *st)
{
 238:	1101                	addi	sp,sp,-32
 23a:	ec06                	sd	ra,24(sp)
 23c:	e822                	sd	s0,16(sp)
 23e:	e426                	sd	s1,8(sp)
 240:	e04a                	sd	s2,0(sp)
 242:	1000                	addi	s0,sp,32
 244:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 246:	4581                	li	a1,0
 248:	00000097          	auipc	ra,0x0
 24c:	176080e7          	jalr	374(ra) # 3be <open>
  if(fd < 0)
 250:	02054563          	bltz	a0,27a <stat+0x42>
 254:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 256:	85ca                	mv	a1,s2
 258:	00000097          	auipc	ra,0x0
 25c:	17e080e7          	jalr	382(ra) # 3d6 <fstat>
 260:	892a                	mv	s2,a0
  close(fd);
 262:	8526                	mv	a0,s1
 264:	00000097          	auipc	ra,0x0
 268:	142080e7          	jalr	322(ra) # 3a6 <close>
  return r;
}
 26c:	854a                	mv	a0,s2
 26e:	60e2                	ld	ra,24(sp)
 270:	6442                	ld	s0,16(sp)
 272:	64a2                	ld	s1,8(sp)
 274:	6902                	ld	s2,0(sp)
 276:	6105                	addi	sp,sp,32
 278:	8082                	ret
    return -1;
 27a:	597d                	li	s2,-1
 27c:	bfc5                	j	26c <stat+0x34>

000000000000027e <atoi>:

int
atoi(const char *s)
{
 27e:	1141                	addi	sp,sp,-16
 280:	e422                	sd	s0,8(sp)
 282:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 284:	00054603          	lbu	a2,0(a0)
 288:	fd06079b          	addiw	a5,a2,-48
 28c:	0ff7f793          	andi	a5,a5,255
 290:	4725                	li	a4,9
 292:	02f76963          	bltu	a4,a5,2c4 <atoi+0x46>
 296:	86aa                	mv	a3,a0
  n = 0;
 298:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 29a:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 29c:	0685                	addi	a3,a3,1
 29e:	0025179b          	slliw	a5,a0,0x2
 2a2:	9fa9                	addw	a5,a5,a0
 2a4:	0017979b          	slliw	a5,a5,0x1
 2a8:	9fb1                	addw	a5,a5,a2
 2aa:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 2ae:	0006c603          	lbu	a2,0(a3)
 2b2:	fd06071b          	addiw	a4,a2,-48
 2b6:	0ff77713          	andi	a4,a4,255
 2ba:	fee5f1e3          	bgeu	a1,a4,29c <atoi+0x1e>
  return n;
}
 2be:	6422                	ld	s0,8(sp)
 2c0:	0141                	addi	sp,sp,16
 2c2:	8082                	ret
  n = 0;
 2c4:	4501                	li	a0,0
 2c6:	bfe5                	j	2be <atoi+0x40>

00000000000002c8 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 2c8:	1141                	addi	sp,sp,-16
 2ca:	e422                	sd	s0,8(sp)
 2cc:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 2ce:	02b57663          	bgeu	a0,a1,2fa <memmove+0x32>
    while(n-- > 0)
 2d2:	02c05163          	blez	a2,2f4 <memmove+0x2c>
 2d6:	fff6079b          	addiw	a5,a2,-1
 2da:	1782                	slli	a5,a5,0x20
 2dc:	9381                	srli	a5,a5,0x20
 2de:	0785                	addi	a5,a5,1
 2e0:	97aa                	add	a5,a5,a0
  dst = vdst;
 2e2:	872a                	mv	a4,a0
      *dst++ = *src++;
 2e4:	0585                	addi	a1,a1,1
 2e6:	0705                	addi	a4,a4,1
 2e8:	fff5c683          	lbu	a3,-1(a1)
 2ec:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 2f0:	fee79ae3          	bne	a5,a4,2e4 <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 2f4:	6422                	ld	s0,8(sp)
 2f6:	0141                	addi	sp,sp,16
 2f8:	8082                	ret
    dst += n;
 2fa:	00c50733          	add	a4,a0,a2
    src += n;
 2fe:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 300:	fec05ae3          	blez	a2,2f4 <memmove+0x2c>
 304:	fff6079b          	addiw	a5,a2,-1
 308:	1782                	slli	a5,a5,0x20
 30a:	9381                	srli	a5,a5,0x20
 30c:	fff7c793          	not	a5,a5
 310:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 312:	15fd                	addi	a1,a1,-1
 314:	177d                	addi	a4,a4,-1
 316:	0005c683          	lbu	a3,0(a1)
 31a:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 31e:	fee79ae3          	bne	a5,a4,312 <memmove+0x4a>
 322:	bfc9                	j	2f4 <memmove+0x2c>

0000000000000324 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 324:	1141                	addi	sp,sp,-16
 326:	e422                	sd	s0,8(sp)
 328:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 32a:	ca05                	beqz	a2,35a <memcmp+0x36>
 32c:	fff6069b          	addiw	a3,a2,-1
 330:	1682                	slli	a3,a3,0x20
 332:	9281                	srli	a3,a3,0x20
 334:	0685                	addi	a3,a3,1
 336:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 338:	00054783          	lbu	a5,0(a0)
 33c:	0005c703          	lbu	a4,0(a1)
 340:	00e79863          	bne	a5,a4,350 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 344:	0505                	addi	a0,a0,1
    p2++;
 346:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 348:	fed518e3          	bne	a0,a3,338 <memcmp+0x14>
  }
  return 0;
 34c:	4501                	li	a0,0
 34e:	a019                	j	354 <memcmp+0x30>
      return *p1 - *p2;
 350:	40e7853b          	subw	a0,a5,a4
}
 354:	6422                	ld	s0,8(sp)
 356:	0141                	addi	sp,sp,16
 358:	8082                	ret
  return 0;
 35a:	4501                	li	a0,0
 35c:	bfe5                	j	354 <memcmp+0x30>

000000000000035e <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 35e:	1141                	addi	sp,sp,-16
 360:	e406                	sd	ra,8(sp)
 362:	e022                	sd	s0,0(sp)
 364:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 366:	00000097          	auipc	ra,0x0
 36a:	f62080e7          	jalr	-158(ra) # 2c8 <memmove>
}
 36e:	60a2                	ld	ra,8(sp)
 370:	6402                	ld	s0,0(sp)
 372:	0141                	addi	sp,sp,16
 374:	8082                	ret

0000000000000376 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 376:	4885                	li	a7,1
 ecall
 378:	00000073          	ecall
 ret
 37c:	8082                	ret

000000000000037e <exit>:
.global exit
exit:
 li a7, SYS_exit
 37e:	4889                	li	a7,2
 ecall
 380:	00000073          	ecall
 ret
 384:	8082                	ret

0000000000000386 <wait>:
.global wait
wait:
 li a7, SYS_wait
 386:	488d                	li	a7,3
 ecall
 388:	00000073          	ecall
 ret
 38c:	8082                	ret

000000000000038e <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 38e:	4891                	li	a7,4
 ecall
 390:	00000073          	ecall
 ret
 394:	8082                	ret

0000000000000396 <read>:
.global read
read:
 li a7, SYS_read
 396:	4895                	li	a7,5
 ecall
 398:	00000073          	ecall
 ret
 39c:	8082                	ret

000000000000039e <write>:
.global write
write:
 li a7, SYS_write
 39e:	48c1                	li	a7,16
 ecall
 3a0:	00000073          	ecall
 ret
 3a4:	8082                	ret

00000000000003a6 <close>:
.global close
close:
 li a7, SYS_close
 3a6:	48d5                	li	a7,21
 ecall
 3a8:	00000073          	ecall
 ret
 3ac:	8082                	ret

00000000000003ae <kill>:
.global kill
kill:
 li a7, SYS_kill
 3ae:	4899                	li	a7,6
 ecall
 3b0:	00000073          	ecall
 ret
 3b4:	8082                	ret

00000000000003b6 <exec>:
.global exec
exec:
 li a7, SYS_exec
 3b6:	489d                	li	a7,7
 ecall
 3b8:	00000073          	ecall
 ret
 3bc:	8082                	ret

00000000000003be <open>:
.global open
open:
 li a7, SYS_open
 3be:	48bd                	li	a7,15
 ecall
 3c0:	00000073          	ecall
 ret
 3c4:	8082                	ret

00000000000003c6 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 3c6:	48c5                	li	a7,17
 ecall
 3c8:	00000073          	ecall
 ret
 3cc:	8082                	ret

00000000000003ce <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 3ce:	48c9                	li	a7,18
 ecall
 3d0:	00000073          	ecall
 ret
 3d4:	8082                	ret

00000000000003d6 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 3d6:	48a1                	li	a7,8
 ecall
 3d8:	00000073          	ecall
 ret
 3dc:	8082                	ret

00000000000003de <link>:
.global link
link:
 li a7, SYS_link
 3de:	48cd                	li	a7,19
 ecall
 3e0:	00000073          	ecall
 ret
 3e4:	8082                	ret

00000000000003e6 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 3e6:	48d1                	li	a7,20
 ecall
 3e8:	00000073          	ecall
 ret
 3ec:	8082                	ret

00000000000003ee <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 3ee:	48a5                	li	a7,9
 ecall
 3f0:	00000073          	ecall
 ret
 3f4:	8082                	ret

00000000000003f6 <dup>:
.global dup
dup:
 li a7, SYS_dup
 3f6:	48a9                	li	a7,10
 ecall
 3f8:	00000073          	ecall
 ret
 3fc:	8082                	ret

00000000000003fe <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 3fe:	48ad                	li	a7,11
 ecall
 400:	00000073          	ecall
 ret
 404:	8082                	ret

0000000000000406 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 406:	48b1                	li	a7,12
 ecall
 408:	00000073          	ecall
 ret
 40c:	8082                	ret

000000000000040e <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 40e:	48b5                	li	a7,13
 ecall
 410:	00000073          	ecall
 ret
 414:	8082                	ret

0000000000000416 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 416:	48b9                	li	a7,14
 ecall
 418:	00000073          	ecall
 ret
 41c:	8082                	ret

000000000000041e <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 41e:	1101                	addi	sp,sp,-32
 420:	ec06                	sd	ra,24(sp)
 422:	e822                	sd	s0,16(sp)
 424:	1000                	addi	s0,sp,32
 426:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 42a:	4605                	li	a2,1
 42c:	fef40593          	addi	a1,s0,-17
 430:	00000097          	auipc	ra,0x0
 434:	f6e080e7          	jalr	-146(ra) # 39e <write>
}
 438:	60e2                	ld	ra,24(sp)
 43a:	6442                	ld	s0,16(sp)
 43c:	6105                	addi	sp,sp,32
 43e:	8082                	ret

0000000000000440 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 440:	7139                	addi	sp,sp,-64
 442:	fc06                	sd	ra,56(sp)
 444:	f822                	sd	s0,48(sp)
 446:	f426                	sd	s1,40(sp)
 448:	f04a                	sd	s2,32(sp)
 44a:	ec4e                	sd	s3,24(sp)
 44c:	0080                	addi	s0,sp,64
 44e:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 450:	c299                	beqz	a3,456 <printint+0x16>
 452:	0805c863          	bltz	a1,4e2 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 456:	2581                	sext.w	a1,a1
  neg = 0;
 458:	4881                	li	a7,0
 45a:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 45e:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 460:	2601                	sext.w	a2,a2
 462:	00000517          	auipc	a0,0x0
 466:	4d650513          	addi	a0,a0,1238 # 938 <digits>
 46a:	883a                	mv	a6,a4
 46c:	2705                	addiw	a4,a4,1
 46e:	02c5f7bb          	remuw	a5,a1,a2
 472:	1782                	slli	a5,a5,0x20
 474:	9381                	srli	a5,a5,0x20
 476:	97aa                	add	a5,a5,a0
 478:	0007c783          	lbu	a5,0(a5)
 47c:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 480:	0005879b          	sext.w	a5,a1
 484:	02c5d5bb          	divuw	a1,a1,a2
 488:	0685                	addi	a3,a3,1
 48a:	fec7f0e3          	bgeu	a5,a2,46a <printint+0x2a>
  if(neg)
 48e:	00088b63          	beqz	a7,4a4 <printint+0x64>
    buf[i++] = '-';
 492:	fd040793          	addi	a5,s0,-48
 496:	973e                	add	a4,a4,a5
 498:	02d00793          	li	a5,45
 49c:	fef70823          	sb	a5,-16(a4)
 4a0:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 4a4:	02e05863          	blez	a4,4d4 <printint+0x94>
 4a8:	fc040793          	addi	a5,s0,-64
 4ac:	00e78933          	add	s2,a5,a4
 4b0:	fff78993          	addi	s3,a5,-1
 4b4:	99ba                	add	s3,s3,a4
 4b6:	377d                	addiw	a4,a4,-1
 4b8:	1702                	slli	a4,a4,0x20
 4ba:	9301                	srli	a4,a4,0x20
 4bc:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 4c0:	fff94583          	lbu	a1,-1(s2)
 4c4:	8526                	mv	a0,s1
 4c6:	00000097          	auipc	ra,0x0
 4ca:	f58080e7          	jalr	-168(ra) # 41e <putc>
  while(--i >= 0)
 4ce:	197d                	addi	s2,s2,-1
 4d0:	ff3918e3          	bne	s2,s3,4c0 <printint+0x80>
}
 4d4:	70e2                	ld	ra,56(sp)
 4d6:	7442                	ld	s0,48(sp)
 4d8:	74a2                	ld	s1,40(sp)
 4da:	7902                	ld	s2,32(sp)
 4dc:	69e2                	ld	s3,24(sp)
 4de:	6121                	addi	sp,sp,64
 4e0:	8082                	ret
    x = -xx;
 4e2:	40b005bb          	negw	a1,a1
    neg = 1;
 4e6:	4885                	li	a7,1
    x = -xx;
 4e8:	bf8d                	j	45a <printint+0x1a>

00000000000004ea <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 4ea:	7119                	addi	sp,sp,-128
 4ec:	fc86                	sd	ra,120(sp)
 4ee:	f8a2                	sd	s0,112(sp)
 4f0:	f4a6                	sd	s1,104(sp)
 4f2:	f0ca                	sd	s2,96(sp)
 4f4:	ecce                	sd	s3,88(sp)
 4f6:	e8d2                	sd	s4,80(sp)
 4f8:	e4d6                	sd	s5,72(sp)
 4fa:	e0da                	sd	s6,64(sp)
 4fc:	fc5e                	sd	s7,56(sp)
 4fe:	f862                	sd	s8,48(sp)
 500:	f466                	sd	s9,40(sp)
 502:	f06a                	sd	s10,32(sp)
 504:	ec6e                	sd	s11,24(sp)
 506:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 508:	0005c903          	lbu	s2,0(a1)
 50c:	18090f63          	beqz	s2,6aa <vprintf+0x1c0>
 510:	8aaa                	mv	s5,a0
 512:	8b32                	mv	s6,a2
 514:	00158493          	addi	s1,a1,1
  state = 0;
 518:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 51a:	02500a13          	li	s4,37
      if(c == 'd'){
 51e:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 522:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 526:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 52a:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 52e:	00000b97          	auipc	s7,0x0
 532:	40ab8b93          	addi	s7,s7,1034 # 938 <digits>
 536:	a839                	j	554 <vprintf+0x6a>
        putc(fd, c);
 538:	85ca                	mv	a1,s2
 53a:	8556                	mv	a0,s5
 53c:	00000097          	auipc	ra,0x0
 540:	ee2080e7          	jalr	-286(ra) # 41e <putc>
 544:	a019                	j	54a <vprintf+0x60>
    } else if(state == '%'){
 546:	01498f63          	beq	s3,s4,564 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 54a:	0485                	addi	s1,s1,1
 54c:	fff4c903          	lbu	s2,-1(s1)
 550:	14090d63          	beqz	s2,6aa <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 554:	0009079b          	sext.w	a5,s2
    if(state == 0){
 558:	fe0997e3          	bnez	s3,546 <vprintf+0x5c>
      if(c == '%'){
 55c:	fd479ee3          	bne	a5,s4,538 <vprintf+0x4e>
        state = '%';
 560:	89be                	mv	s3,a5
 562:	b7e5                	j	54a <vprintf+0x60>
      if(c == 'd'){
 564:	05878063          	beq	a5,s8,5a4 <vprintf+0xba>
      } else if(c == 'l') {
 568:	05978c63          	beq	a5,s9,5c0 <vprintf+0xd6>
      } else if(c == 'x') {
 56c:	07a78863          	beq	a5,s10,5dc <vprintf+0xf2>
      } else if(c == 'p') {
 570:	09b78463          	beq	a5,s11,5f8 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 574:	07300713          	li	a4,115
 578:	0ce78663          	beq	a5,a4,644 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 57c:	06300713          	li	a4,99
 580:	0ee78e63          	beq	a5,a4,67c <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 584:	11478863          	beq	a5,s4,694 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 588:	85d2                	mv	a1,s4
 58a:	8556                	mv	a0,s5
 58c:	00000097          	auipc	ra,0x0
 590:	e92080e7          	jalr	-366(ra) # 41e <putc>
        putc(fd, c);
 594:	85ca                	mv	a1,s2
 596:	8556                	mv	a0,s5
 598:	00000097          	auipc	ra,0x0
 59c:	e86080e7          	jalr	-378(ra) # 41e <putc>
      }
      state = 0;
 5a0:	4981                	li	s3,0
 5a2:	b765                	j	54a <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 5a4:	008b0913          	addi	s2,s6,8
 5a8:	4685                	li	a3,1
 5aa:	4629                	li	a2,10
 5ac:	000b2583          	lw	a1,0(s6)
 5b0:	8556                	mv	a0,s5
 5b2:	00000097          	auipc	ra,0x0
 5b6:	e8e080e7          	jalr	-370(ra) # 440 <printint>
 5ba:	8b4a                	mv	s6,s2
      state = 0;
 5bc:	4981                	li	s3,0
 5be:	b771                	j	54a <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 5c0:	008b0913          	addi	s2,s6,8
 5c4:	4681                	li	a3,0
 5c6:	4629                	li	a2,10
 5c8:	000b2583          	lw	a1,0(s6)
 5cc:	8556                	mv	a0,s5
 5ce:	00000097          	auipc	ra,0x0
 5d2:	e72080e7          	jalr	-398(ra) # 440 <printint>
 5d6:	8b4a                	mv	s6,s2
      state = 0;
 5d8:	4981                	li	s3,0
 5da:	bf85                	j	54a <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 5dc:	008b0913          	addi	s2,s6,8
 5e0:	4681                	li	a3,0
 5e2:	4641                	li	a2,16
 5e4:	000b2583          	lw	a1,0(s6)
 5e8:	8556                	mv	a0,s5
 5ea:	00000097          	auipc	ra,0x0
 5ee:	e56080e7          	jalr	-426(ra) # 440 <printint>
 5f2:	8b4a                	mv	s6,s2
      state = 0;
 5f4:	4981                	li	s3,0
 5f6:	bf91                	j	54a <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 5f8:	008b0793          	addi	a5,s6,8
 5fc:	f8f43423          	sd	a5,-120(s0)
 600:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 604:	03000593          	li	a1,48
 608:	8556                	mv	a0,s5
 60a:	00000097          	auipc	ra,0x0
 60e:	e14080e7          	jalr	-492(ra) # 41e <putc>
  putc(fd, 'x');
 612:	85ea                	mv	a1,s10
 614:	8556                	mv	a0,s5
 616:	00000097          	auipc	ra,0x0
 61a:	e08080e7          	jalr	-504(ra) # 41e <putc>
 61e:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 620:	03c9d793          	srli	a5,s3,0x3c
 624:	97de                	add	a5,a5,s7
 626:	0007c583          	lbu	a1,0(a5)
 62a:	8556                	mv	a0,s5
 62c:	00000097          	auipc	ra,0x0
 630:	df2080e7          	jalr	-526(ra) # 41e <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 634:	0992                	slli	s3,s3,0x4
 636:	397d                	addiw	s2,s2,-1
 638:	fe0914e3          	bnez	s2,620 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 63c:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 640:	4981                	li	s3,0
 642:	b721                	j	54a <vprintf+0x60>
        s = va_arg(ap, char*);
 644:	008b0993          	addi	s3,s6,8
 648:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 64c:	02090163          	beqz	s2,66e <vprintf+0x184>
        while(*s != 0){
 650:	00094583          	lbu	a1,0(s2)
 654:	c9a1                	beqz	a1,6a4 <vprintf+0x1ba>
          putc(fd, *s);
 656:	8556                	mv	a0,s5
 658:	00000097          	auipc	ra,0x0
 65c:	dc6080e7          	jalr	-570(ra) # 41e <putc>
          s++;
 660:	0905                	addi	s2,s2,1
        while(*s != 0){
 662:	00094583          	lbu	a1,0(s2)
 666:	f9e5                	bnez	a1,656 <vprintf+0x16c>
        s = va_arg(ap, char*);
 668:	8b4e                	mv	s6,s3
      state = 0;
 66a:	4981                	li	s3,0
 66c:	bdf9                	j	54a <vprintf+0x60>
          s = "(null)";
 66e:	00000917          	auipc	s2,0x0
 672:	2c290913          	addi	s2,s2,706 # 930 <malloc+0x17c>
        while(*s != 0){
 676:	02800593          	li	a1,40
 67a:	bff1                	j	656 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 67c:	008b0913          	addi	s2,s6,8
 680:	000b4583          	lbu	a1,0(s6)
 684:	8556                	mv	a0,s5
 686:	00000097          	auipc	ra,0x0
 68a:	d98080e7          	jalr	-616(ra) # 41e <putc>
 68e:	8b4a                	mv	s6,s2
      state = 0;
 690:	4981                	li	s3,0
 692:	bd65                	j	54a <vprintf+0x60>
        putc(fd, c);
 694:	85d2                	mv	a1,s4
 696:	8556                	mv	a0,s5
 698:	00000097          	auipc	ra,0x0
 69c:	d86080e7          	jalr	-634(ra) # 41e <putc>
      state = 0;
 6a0:	4981                	li	s3,0
 6a2:	b565                	j	54a <vprintf+0x60>
        s = va_arg(ap, char*);
 6a4:	8b4e                	mv	s6,s3
      state = 0;
 6a6:	4981                	li	s3,0
 6a8:	b54d                	j	54a <vprintf+0x60>
    }
  }
}
 6aa:	70e6                	ld	ra,120(sp)
 6ac:	7446                	ld	s0,112(sp)
 6ae:	74a6                	ld	s1,104(sp)
 6b0:	7906                	ld	s2,96(sp)
 6b2:	69e6                	ld	s3,88(sp)
 6b4:	6a46                	ld	s4,80(sp)
 6b6:	6aa6                	ld	s5,72(sp)
 6b8:	6b06                	ld	s6,64(sp)
 6ba:	7be2                	ld	s7,56(sp)
 6bc:	7c42                	ld	s8,48(sp)
 6be:	7ca2                	ld	s9,40(sp)
 6c0:	7d02                	ld	s10,32(sp)
 6c2:	6de2                	ld	s11,24(sp)
 6c4:	6109                	addi	sp,sp,128
 6c6:	8082                	ret

00000000000006c8 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 6c8:	715d                	addi	sp,sp,-80
 6ca:	ec06                	sd	ra,24(sp)
 6cc:	e822                	sd	s0,16(sp)
 6ce:	1000                	addi	s0,sp,32
 6d0:	e010                	sd	a2,0(s0)
 6d2:	e414                	sd	a3,8(s0)
 6d4:	e818                	sd	a4,16(s0)
 6d6:	ec1c                	sd	a5,24(s0)
 6d8:	03043023          	sd	a6,32(s0)
 6dc:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 6e0:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 6e4:	8622                	mv	a2,s0
 6e6:	00000097          	auipc	ra,0x0
 6ea:	e04080e7          	jalr	-508(ra) # 4ea <vprintf>
}
 6ee:	60e2                	ld	ra,24(sp)
 6f0:	6442                	ld	s0,16(sp)
 6f2:	6161                	addi	sp,sp,80
 6f4:	8082                	ret

00000000000006f6 <printf>:

void
printf(const char *fmt, ...)
{
 6f6:	711d                	addi	sp,sp,-96
 6f8:	ec06                	sd	ra,24(sp)
 6fa:	e822                	sd	s0,16(sp)
 6fc:	1000                	addi	s0,sp,32
 6fe:	e40c                	sd	a1,8(s0)
 700:	e810                	sd	a2,16(s0)
 702:	ec14                	sd	a3,24(s0)
 704:	f018                	sd	a4,32(s0)
 706:	f41c                	sd	a5,40(s0)
 708:	03043823          	sd	a6,48(s0)
 70c:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 710:	00840613          	addi	a2,s0,8
 714:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 718:	85aa                	mv	a1,a0
 71a:	4505                	li	a0,1
 71c:	00000097          	auipc	ra,0x0
 720:	dce080e7          	jalr	-562(ra) # 4ea <vprintf>
}
 724:	60e2                	ld	ra,24(sp)
 726:	6442                	ld	s0,16(sp)
 728:	6125                	addi	sp,sp,96
 72a:	8082                	ret

000000000000072c <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 72c:	1141                	addi	sp,sp,-16
 72e:	e422                	sd	s0,8(sp)
 730:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 732:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 736:	00000797          	auipc	a5,0x0
 73a:	22a7b783          	ld	a5,554(a5) # 960 <freep>
 73e:	a805                	j	76e <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 740:	4618                	lw	a4,8(a2)
 742:	9db9                	addw	a1,a1,a4
 744:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 748:	6398                	ld	a4,0(a5)
 74a:	6318                	ld	a4,0(a4)
 74c:	fee53823          	sd	a4,-16(a0)
 750:	a091                	j	794 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 752:	ff852703          	lw	a4,-8(a0)
 756:	9e39                	addw	a2,a2,a4
 758:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 75a:	ff053703          	ld	a4,-16(a0)
 75e:	e398                	sd	a4,0(a5)
 760:	a099                	j	7a6 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 762:	6398                	ld	a4,0(a5)
 764:	00e7e463          	bltu	a5,a4,76c <free+0x40>
 768:	00e6ea63          	bltu	a3,a4,77c <free+0x50>
{
 76c:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 76e:	fed7fae3          	bgeu	a5,a3,762 <free+0x36>
 772:	6398                	ld	a4,0(a5)
 774:	00e6e463          	bltu	a3,a4,77c <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 778:	fee7eae3          	bltu	a5,a4,76c <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 77c:	ff852583          	lw	a1,-8(a0)
 780:	6390                	ld	a2,0(a5)
 782:	02059713          	slli	a4,a1,0x20
 786:	9301                	srli	a4,a4,0x20
 788:	0712                	slli	a4,a4,0x4
 78a:	9736                	add	a4,a4,a3
 78c:	fae60ae3          	beq	a2,a4,740 <free+0x14>
    bp->s.ptr = p->s.ptr;
 790:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 794:	4790                	lw	a2,8(a5)
 796:	02061713          	slli	a4,a2,0x20
 79a:	9301                	srli	a4,a4,0x20
 79c:	0712                	slli	a4,a4,0x4
 79e:	973e                	add	a4,a4,a5
 7a0:	fae689e3          	beq	a3,a4,752 <free+0x26>
  } else
    p->s.ptr = bp;
 7a4:	e394                	sd	a3,0(a5)
  freep = p;
 7a6:	00000717          	auipc	a4,0x0
 7aa:	1af73d23          	sd	a5,442(a4) # 960 <freep>
}
 7ae:	6422                	ld	s0,8(sp)
 7b0:	0141                	addi	sp,sp,16
 7b2:	8082                	ret

00000000000007b4 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 7b4:	7139                	addi	sp,sp,-64
 7b6:	fc06                	sd	ra,56(sp)
 7b8:	f822                	sd	s0,48(sp)
 7ba:	f426                	sd	s1,40(sp)
 7bc:	f04a                	sd	s2,32(sp)
 7be:	ec4e                	sd	s3,24(sp)
 7c0:	e852                	sd	s4,16(sp)
 7c2:	e456                	sd	s5,8(sp)
 7c4:	e05a                	sd	s6,0(sp)
 7c6:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 7c8:	02051493          	slli	s1,a0,0x20
 7cc:	9081                	srli	s1,s1,0x20
 7ce:	04bd                	addi	s1,s1,15
 7d0:	8091                	srli	s1,s1,0x4
 7d2:	0014899b          	addiw	s3,s1,1
 7d6:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 7d8:	00000517          	auipc	a0,0x0
 7dc:	18853503          	ld	a0,392(a0) # 960 <freep>
 7e0:	c515                	beqz	a0,80c <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7e2:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 7e4:	4798                	lw	a4,8(a5)
 7e6:	02977f63          	bgeu	a4,s1,824 <malloc+0x70>
 7ea:	8a4e                	mv	s4,s3
 7ec:	0009871b          	sext.w	a4,s3
 7f0:	6685                	lui	a3,0x1
 7f2:	00d77363          	bgeu	a4,a3,7f8 <malloc+0x44>
 7f6:	6a05                	lui	s4,0x1
 7f8:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 7fc:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 800:	00000917          	auipc	s2,0x0
 804:	16090913          	addi	s2,s2,352 # 960 <freep>
  if(p == (char*)-1)
 808:	5afd                	li	s5,-1
 80a:	a88d                	j	87c <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 80c:	00000797          	auipc	a5,0x0
 810:	15c78793          	addi	a5,a5,348 # 968 <base>
 814:	00000717          	auipc	a4,0x0
 818:	14f73623          	sd	a5,332(a4) # 960 <freep>
 81c:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 81e:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 822:	b7e1                	j	7ea <malloc+0x36>
      if(p->s.size == nunits)
 824:	02e48b63          	beq	s1,a4,85a <malloc+0xa6>
        p->s.size -= nunits;
 828:	4137073b          	subw	a4,a4,s3
 82c:	c798                	sw	a4,8(a5)
        p += p->s.size;
 82e:	1702                	slli	a4,a4,0x20
 830:	9301                	srli	a4,a4,0x20
 832:	0712                	slli	a4,a4,0x4
 834:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 836:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 83a:	00000717          	auipc	a4,0x0
 83e:	12a73323          	sd	a0,294(a4) # 960 <freep>
      return (void*)(p + 1);
 842:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 846:	70e2                	ld	ra,56(sp)
 848:	7442                	ld	s0,48(sp)
 84a:	74a2                	ld	s1,40(sp)
 84c:	7902                	ld	s2,32(sp)
 84e:	69e2                	ld	s3,24(sp)
 850:	6a42                	ld	s4,16(sp)
 852:	6aa2                	ld	s5,8(sp)
 854:	6b02                	ld	s6,0(sp)
 856:	6121                	addi	sp,sp,64
 858:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 85a:	6398                	ld	a4,0(a5)
 85c:	e118                	sd	a4,0(a0)
 85e:	bff1                	j	83a <malloc+0x86>
  hp->s.size = nu;
 860:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 864:	0541                	addi	a0,a0,16
 866:	00000097          	auipc	ra,0x0
 86a:	ec6080e7          	jalr	-314(ra) # 72c <free>
  return freep;
 86e:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 872:	d971                	beqz	a0,846 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 874:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 876:	4798                	lw	a4,8(a5)
 878:	fa9776e3          	bgeu	a4,s1,824 <malloc+0x70>
    if(p == freep)
 87c:	00093703          	ld	a4,0(s2)
 880:	853e                	mv	a0,a5
 882:	fef719e3          	bne	a4,a5,874 <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 886:	8552                	mv	a0,s4
 888:	00000097          	auipc	ra,0x0
 88c:	b7e080e7          	jalr	-1154(ra) # 406 <sbrk>
  if(p == (char*)-1)
 890:	fd5518e3          	bne	a0,s5,860 <malloc+0xac>
        return 0;
 894:	4501                	li	a0,0
 896:	bf45                	j	846 <malloc+0x92>
