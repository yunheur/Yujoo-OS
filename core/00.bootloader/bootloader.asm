[ORG 0x00]
[BITS 16]

SECTION .text

jmp 0x07C0:START

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; YUJOO-OS에 관련된 환경 설정 값
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
TOTALSECTORCOUNT:	dw 1024	; 부트 로더를 제외한 YUJOO-OS 이미지의 크기
				; 최대 1152 섹터(0x90000byte)까지 가능


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 코드 영역
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
START:

	mov ax, 0x07C0
	mov ds, ax
	mov ax, 0xB800
	mov es, ax

	; 스택을 0x0000:0000~0x0000:FFFF 영역에 64KB 크기로 생성
	mov ax, 0x0000	
	mov ss, ax	 
	mov sp, 0xFFFE 
	mov bp, 0xFFFE	 

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; 화면을 모두 지우고, 속성값을 녹색으로 변경	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov si, 0

.SCREENCLEARLOOP:
	mov byte [ es : si ], 0
	mov byte [ es : si+1], 0x0A

	add si, 2

	cmp si, 80 * 25 * 2

	jl .SCREENCLEARLOOP

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; 화면 상단에 시작 메시지 출력
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	push MESSAGE1
	push 0
	push 0
	call PRINTMESSAGE
	add sp, 6

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; OS 이미지를 로딩한다는 메시지 출력
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	push IMAGELOADINGMESSAGE
	push 1
	push 0
	call PRINTMESSAGE
	add sp, 6
		
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; 디스크에서 OS 이미지를 로딩 
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; 디스크를 읽기 전에 먼저 리셋
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
RESETDISK:	
	; 디스크를 리셋하는 코드의 시작
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; BIOS Reset Function 호출 
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; 서비스 번호 0, 드라이브 번호(0=Floppy)
	mov ax, 0
	mov dl, 0
	int 0x13
	; 에러가 발생하면 에러 처리로 이동
	jc HANDLEDISKERROR

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; 디스크에서 섹터를 읽음 
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; 디스크의 내용을 메모리로 복사할 어드레스(ES:BX)를 0x10000으로 설정
	mov si, 0x1000
	mov es, si
	mov bx, 0x0000
	
	mov di, word [ TOTALSECTORCOUNT ]

READDATA:
	; 모든 섹터를 다읽었는지 확인
	cmp di, 0
	je READEND
	sub di, 0x1
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; BIOS Read Function 호출 
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov ah, 0x02
	mov al, 0x1
	mov ch, byte [ TRACKNUMBER ]
	mov cl, byte [ SECTORNUMBER ]
	mov dh, byte [ HEADNUMBER ]
	mov dl, 0x00
	int 0x13
	jc HANDLEDISKERROR

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; 복사할 어드레스와 트랙, 헤드, 섹터 어드레스 계산 
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	add si, 0x0020

	mov es, si
	
	mov al, byte [ SECTORNUMBER ]
	add al, 0x01
	mov byte [ SECTORNUMBER ], al
	cmp al, 19
	jl READDATA
	
	; 마지막 섹터까지 읽었으면(섹터 번호가 19이면) 헤드를 토글(0->1, 1->0)하고,
	; 섹터 번호를 1로 설정
	xor byte [ HEADNUMBER ], 0x01
	mov byte [ SECTORNUMBER ], 0x01

	; 만약 헤드가 1->0로 바뀌었으면 양쪽 헤드를 모두 읽은 것이므로 아래로 이동하여
	; 트랙 번호를 1 증가
	cmp byte [ HEADNUMBER ], 0x00		; 헤드 번호를 0x00과 비교
	jne READDATA				; 헤드 번호가 0이 아니면 READDATA로 이동

	; 트랙을 1 증가시킨 후 다시 섹터 읽기로 이동
	add byte [ TRACKNUMBER ], 0x01
	jmp READDATA
READEND:
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; OS 이미지가 완료되었다는 메시지를 출력 
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	push LOADINGCOMPLETEMESSAGE
	push 1
	push 20
	call PRINTMESSAGE
	add sp, 6
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; 로딩한 가상 OS 이미지 실행 
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	jmp 0x1000:0x0000

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 함수 코드 영역 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 디스크 에러를 처리하는 함수
HANDLEDISKERROR:
	push DISKERRORMESSAGE
	push 1
	push 20
	call PRINTMESSAGE

	jmp $

; 메시지를 출력하는 함수
;  PARAM : x좌표, y좌표, 문자열
PRINTMESSAGE:
	push bp				; 베이스 포인터 레지스터(BP)를 스택에 삽입
	mov bp, sp			; 베이스 포인터 레지스터(BP)에 스택 포인터 레지스터(SP)의 값을 설정
					; 베이스 포인터 레지스터(BP)를 이용해서 파라미터에 접근할 목적

	push es				; ES 세그먼트 레지스터부터 DX 레지스터까지 스택에 삽입			
	push si				; 함수에서 임시로 사용하는 레지스터로 함수의 마지막 부분에서
	push di				; 스택에 삽입된 값을 꺼내 원래 값으로 복원
	push ax
	push cx
	push dx

	; ES 세그먼트 레지스터에 비디오 모드 어드레스 설정
	mov ax, 0xB800
	
	mov es, ax

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; X, Y의 좌표로 비디오 메모리의 어드레스를 계산함
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; Y 좌표를 이용해서 먼저 라인 어드레스를 구함
	mov ax, word [ bp + 6 ]
	mov si, 160
	mul si
	mov di, ax
	
	; X 좌표를 이용해서 2를 곱한 후 어드레스를 구함
	mov ax, word [ bp + 4 ]
	mov si, 2
	mul si
	add di, ax

	; 출력할 문자열의 어드레스
	mov si, word [ bp + 8 ]

.MESSAGELOOP:
	mov cl, byte [ si ]
	cmp cl, 0
	je .MESSAGEEND

	mov byte [ es : di ], cl

	add si, 1
	add di, 2

	jmp .MESSAGELOOP

.MESSAGEEND:
	pop dx
	pop cx
	pop ax
	pop di
	pop si
	pop es
	pop bp
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 데이터 영역
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 부트 로더 시작 메시지
MESSAGE1:	db 'YUJOO OS Boot Loader Start!!!', 0

DISKERRORMESSAGE:	db 'DISK Error~!!', 0
IMAGELOADINGMESSAGE:	db 'OS Image Loading...', 0
LOADINGCOMPLETEMESSAGE:	db 'Complete~!!', 0

; 디스크 읽기에 관련된 변수들
SECTORNUMBER:		db 0x02		; OS 이미지가 시작하는 섹터 번호를 저장하는 영역
HEADNUMBER:		db 0x00		; OS 이미지가 시작하는 헤드 번호를 저장하는 영역
TRACKNUMBER:		db 0x00		; OS 이미지가 시작하는 트랙 번호를 저장하는 영역

times 510 - ($ -$$)	db 0x00

db 0x55
db 0xAA
