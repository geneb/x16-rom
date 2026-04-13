;----------------------------------------------------------------------
; Channel: OPEN
;----------------------------------------------------------------------
; (C)1983 Commodore Business Machines (CBM)
; additions: (C)2020 Michael Steil, License: 2-clause BSD

;***********************************
;*                                 *
;* open function                   *
;*                                 *
;* creates an entry in the logical *
;* files tables consisting of      *
;* logical file number--la, device *
;* number--fa, and secondary cmd-- *
;* sa.                             *
;*                                 *
;* a file name descriptor, fnadr & *
;* fnlen are passed to this routine*
;*                                 *
;***********************************
;
.import addr232, baudrate, serial_regs

nopen	ldx la          ;check file #
	bne op98        ;is not the keyboard
;
	jmp error6      ;not input file...
;
op98	jsr lookup      ;see if in table
	bne op100       ;not found...o.k.
;
	jmp error2      ;file open
;
op100	ldx ldtnd       ;logical device table end
	cpx #10         ;maximum # of open files
	bcc op110       ;less than 10...o.k.
;
	jmp error1      ;too many files
;
op110	inc ldtnd       ;new file
	lda la
	sta lat,x       ;store logical file #
	lda sa
	ora #$60        ;make sa an serial command
	sta sa
	sta sat,x       ;store command #
	lda fa
	sta fat,x       ;store device #
;
;perform device specific open tasks
;
	beq op175       ;is keyboard...done.
	cmp #3
	beq op175       ;is screen...done.
	bcc op150       ;are cassettes 1 & 2
;
	jsr openi       ;is on serial...open it
	bcc op175       ;branch always...done
;
;perform tape open stuff
;
op150	cmp #2		; device #2?
	bne op152
;
	jmp open232
op152	jmp error9
op175	clc             ;flag good open
	rts             ;exit in peace

openi	lda sa
	bmi op175       ;no sa...done
;
	ldy fnlen
	beq op175       ;no file name...done
;
	lda #0          ;clear the serial status
	sta status
;
	lda fa
	jsr listn       ;device la to listen
;
	lda sa
	ora #$f0
	jsr secnd
;
	lda status      ;anybody home?
	bpl op35        ;yes...continue
;
;this routine is called by other
;kernal routines which are called
;directly by os.  kill return
;address to return to os.
;
	pla
	pla
	jmp error5      ;device not present
;
op35	lda fnlen
	beq op45        ;no name...done sequence
;
;send file name over serial
;
	ldy #0
op40	lda (fnadr),y
	jsr ciout
	iny
	cpy fnlen
	bne op40
;
op45	jmp cunlsn      ;jsr unlsn: clc: rts


;uart_base         = addr232
uart_rbr_thr      = $00     ; rbr (read) / thr (write)
uart_ier          = $01     ; interrupt enable register
uart_iir_fcr      = $02     ; interrupt identification register / fifo control register
uart_lcr          = $03		; line control register
uart_mcr		  = $04     ; modem control register
uart_lsr          = $05     ; read-only — line status register
uart_msr          = $07		; scratch register
;
uart_dll		  = $00     ; divisor latch low byte (when DLAB=1)
uart_dlm		  = $01     ; divisor latch high byte (when DLAB=1)
;
dlab_init		  = %10000011 ; 8 bits, no parity, 1 stop bit, DLAB=1
;
fifo_init		  = %11000111 ; enable FIFO, clear TX/RX queues, 14-byte threshold
mcr_init		  = %00010011 ; enable DTR, RTS, and auto-RTS/CTS flow control

;
; init232 - CLEAN UP 232 SYSTEM FOR OPEN/CLOSE
;  should set up for 8/N/1, 115200 baud. (rate is default for the Network I/O port)
;
;init232:
    ; this should be set before we get here...
    ;lda #$e0 ; BFE0 is a place we can write to in the emulator.
    ;sta addr232
;    lda #$bf
;    sta addr232 + 1

    ; Set default baud rate of 115,200
;    lda #$08
;    sta baudrate
;    lda #$00
;    sta baudrate + 1

    ; Calculate addr232 + 3 and store baudrate values
;    lda addr232
;    clc
;    adc #$03
;    sta tmp2
;    lda addr232 + 1
;    adc #$00
;    sta tmp2 + 1

    ; Store baudrate low byte at addr232 + 3
;    lda baudrate
;    ldy #$00
;    sta (tmp2), y

    ; Store baudrate high byte at addr232 + 4
;    lda baudrate + 1
;    iny
;    sta (tmp2), y

;    rts

;OPEN
;
open232:
; open232 - Open RS-232 device.
; call format from BASIC is:
; OPEN 1,2,1,"<port addr lo><control register><baud rate lo><baud rate hi>"
; The high byte of the port address is assumed to be 0x9F for the X16.

;
; Variables initalized:
;   addr232 - base port address - 2 bytes
;   baudrate - baud rate divisor - 2 bytes. (in init232)
;	serial_regs - Line Control Register setting. - 1 byte

	;jsr init232      ;SET UP RS232, .Y=0 ON RETURN
; TODO test to make sure there's four parameters in fnadr.

;
; set high byte of port address - this is always fixed.
; using 0xbf for testing.  Production should use 0x9f.
; When testing, view bank 1 in the debugger to see activity.
;
;	lda #$9f
    lda #$bf
    sta addr232 + 1
	ldy #$00 ; make sure we're at the start of the fnadr buffer.  

open232_020:
;
; since the open requires four parameters, we never loop like the original did, so 
; I'm not certain if this cpy/beq test is needed any longer..
; maybe test to see if fnlen = 4, and if not, jump to an error handler?

	cpy fnlen		 ; check if at end of filename...
	beq open232_done ; yes...
;
; read low byte of port address, control register value, and low & high bytes of the baud rate.
;
	lda (fnadr), y	; 
	sta addr232		; sets the low byte of the port address. High byte is assumed to be 0x9F.
	iny

	lda (fnadr), y  ; get control register value
	sta serial_regs ;, y
	iny

	lda (fnadr), y ; get baud rate low byte
	sta baudrate ;, y
	iny

	lda (fnadr), y ; get baud rate high byte
	sta baudrate + 1 ;, y
	iny

	; serial_regs must have its MSB set to 1 (DLAB=1) to allow baud rate to be set.
	lda serial_regs
	; Forcing the DLAB bit here, just in case the caller forgets it..
	ora #$80 ; set DLAB=1 to allow baud rate to be set.
	sta serial_regs
	
	jsr set_serial_lcr

	;
    ; set baud rate
	;
	lda addr232
	clc
	adc #uart_dll ; calculate addr232 + uart_dll
	sta tmp2
	lda addr232 + 1
	adc #$00
	sta tmp2 + 1
	; store baudrate low byte at addr232 + uart_dll
	lda baudrate
	ldy #$00
	sta (tmp2), y
	; store baudrate high byte at addr232 + uart_dlm
	lda baudrate + 1
	iny
	sta (tmp2), y	

	;
	; Clear DLAB bit.
	;

	lda serial_regs
	and #$7F ; clear DLAB bit
	sta serial_regs
	jsr set_serial_lcr

	jsr set_serial_fcr
	jsr set_serial_mcr

	;sta addr232 + uart_lcr ; set control register

	;lda baudrate
	;sta addr232 + uart_dll ; set baud rate low byte
	;lda baudrate + 1
	;sta addr232 + uart_dlm ; set baud rate high byte	
	
	;lda serial_regs
	; Clear DLAB bit after setting baud rate.
	;and #$7F ; clear DLAB bit
	;sta serial_regs
	;sta addr232 + uart_lcr ; update control register with DLAB cleared.

	; set up FIFO...
	;lda #fifo_init
	;sta addr232 + uart_iir_fcr

	; set up modem control register - just enable RTS and DTR for now.
	;lda #mcr_init
	;sta addr232 + uart_mcr

	;cpy #4
	;bne open232_020
	
open232_done:


	rts

set_serial_lcr:
	;
	; save port address to tmp2.
	;
	lda addr232
	clc
	adc #uart_lcr ; calculate addr232 + uart_lcr
	sta tmp2
	lda addr232 + 1
	adc #$00
	sta tmp2 + 1
	;
	; set line control register.
	; [this correctly writes the memory location pointed to by tmp2 - 10Apr26]
	lda serial_regs
	ldy #$00
	sta (tmp2), y ; tmp2 should be pointing to 9fe3 (for example)

	rts

set_serial_fcr:
	;
	; save port address to tmp2.
	;
	lda addr232
	clc
	adc #uart_iir_fcr 
	sta tmp2
	lda addr232 + 1
	adc #$00
	sta tmp2 + 1
	;
	; set fifo control register.
	; [this correctly writes the memory location pointed to by tmp2 - 10Apr26]
	lda fifo_init
	ldy #$00
	sta (tmp2), y ; tmp2 should be pointing to 9fe3 (for example)

	rts


set_serial_mcr:
	;
	; save port address to tmp2.
	;
	lda addr232
	clc
	adc #uart_mcr
	sta tmp2
	lda addr232 + 1
	adc #$00
	sta tmp2 + 1
	;
	; set modem control register.
	; [this correctly writes the memory location pointed to by tmp2 - 10Apr26]
	lda mcr_init
	ldy #$00
	sta (tmp2), y ; tmp2 should be pointing to 9fe3 (for example)

	rts


; rsr  8/25/80 - add rs-232 code
; rsr  8/26/80 - top of memory handler
; rsr  8/29/80 - add filename to m51regs
; rsr  9/02/80 - fix ordering of rs-232 routines
; rsr  12/11/81 - modify for vic-40 i/o
; rsr  2/08/82 - clear status in openi
; rsr  5/12/82 - compact rs232 open/close code
