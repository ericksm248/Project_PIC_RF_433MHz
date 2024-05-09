 __CONFIG   _CP_OFF &  _WDT_OFF & _PWRTE_ON & _XT_OSC; MCP19110 Configuration Bit Settings
; Assembly source line config statements

 LIST	   P=16F84A
 INCLUDE  <P16F84A.INC>

   ERRORLEVEL -302
   
variables udata_shr 0x0C
cuenta	    res 1	    ; El contador a visualizar.
Count1	    res 1
contador    res 1
datoserie   res 1
R_ContA	    res 1	    ; Contadores para los retardos.
R_ContB	    res 1
R_ContC	    res 1


; ZONA DE CÓDIGOS ********************************************************************

    ORG	    0x00	    ; El programa comienza en la dirección 0.
    goto    Inicio
    org	    0x04
    goto    Timer0_interrupcion
Inicio
    bsf	    STATUS,RP0	    ; Acceso al Banco 1.
    clrf    TRISB	    ; Las líneas del Puerto B se configuran como salida.
    movlw   b'00000001'	    ; Las 4 líneas del Puerto A se configuran como entrada.
    movwf   TRISA
    movlw   b'00000111'
    movwf   OPTION_REG	    ;prescaler a 256   
    bcf	    STATUS,RP0	    ; Acceso al Banco 0.
    clrf    PORTB
Principal
    movlw   0x08
    movwf   cuenta
    movlw   0x04
    movwf   contador
    btfsc   PORTA,0
    goto    Principal
;hay un tiempo aleatorio que debo esperar para obtener el uno del dato star.
EsperoUno
    btfss   PORTA,0
    goto    EsperoUno

;tiempo para reconocer 1 de dato STAR  (5ms)
TiempoUno
    ;se testea en cada momento
    btfss   PORTA,0	    ; sigue siendo 1?
    goto    Fin
    call    Retardo_500micros
    decfsz  cuenta,1
    goto    TiempoUno
    bsf	    PORTB,7	    ; PRUEBASSS
    movlw   0x08
    movwf   cuenta
;tiempo que es cero de dato STAR  (5ms)
    call    Retardo_1ms
TiempoCero
;se testea en cada momento
    call    Retardo_500micros
    btfsc   PORTA,0	    ; sigue siendo 1?
    goto    Fin
    decfsz  cuenta,1
    goto    TiempoCero
    clrf    datoserie
; verifico dato enviado durante 20ms
    call    Retardo_1ms
    movlw   d'14'
    movwf   TMR0	    ; CARGO EL TIMER0
    movlw   b'10100000'    
    movwf   INTCON	    ; AUTORIZO INTERRUPCION DEL TIMER0

LOOPDATOS
    call    Retardo_1ms
    movf    PORTA,0 
    movwf   Count1
    call    Retardo_1ms
    movf    Count1,0 
    subwf   PORTA,0
    btfss   STATUS,2
    goto    Fin
    call    Retardo_1ms
    movf    Count1,0 
    subwf   PORTA,0
    btfss   STATUS,2
    goto    Fin
    bsf     STATUS,0
    btfss   Count1,0 
    bcf     STATUS,0 
    rrf     datoserie,1  
    call    Retardo_2ms
    decfsz  contador,1
    goto    LOOPDATOS
;continua. El swapf es para obtener el verdadero dato     DATO ->  DATOSERIE
;se divide en 2 segmentos de 4 bits, el swapf cambia, luego    (DSERIE1)(DSERIE2)  ->  (DSERIE2)(DSERIE1)
    swapf   datoserie,1
    movf    datoserie,0 
    movwf   PORTB
;espero un tiempo menor a 40ms 
    call    Retardo_10ms
    goto    Principal
Fin
    clrf    PORTB
    goto    Principal
    
;Temporizacion por desbordamiento del Timer0
Timer0_interrupcion	    
    btfss   PORTA,0
    clrf    PORTB
    ;TEST/////////////////////////
    movlw   0x80
    xorwf   PORTB,F
    ;////////////////////////////////
    bcf     INTCON,T0IF
    retfie
;---------------------------------------------


;//////////////// RETARDOS ///////////////////////
;	===================================================================
;	  Del libro "MICROCONTROLADOR PIC16F84. DESARROLLO DE PROYECTOS"
;	  E. Palacios, F. Remiro y L. López.		www.pic16f84a.com
; 	  Editorial Ra-Ma.  www.ra-ma.es
;	===================================================================
; RETARDOS de 20 hasta 500 microsegundos ------------------------------------------------
;
Retardo_500micros			; La llamada "call" aporta 2 ciclos máquina.
	nop				; Aporta 1 ciclo máquina.
	movlw	d'164'			; Aporta 1 ciclo máquina. Este es el valor de "K".
	goto	RetardoMicros		; Aporta 2 ciclos máquina.
Retardo_200micros				; La llamada "call" aporta 2 ciclos máquina.
	nop				; Aporta 1 ciclo máquina.
	movlw	d'64'			; Aporta 1 ciclo máquina. Este es el valor de "K".
	goto	RetardoMicros		; Aporta 2 ciclos máquina.
Retardo_100micros				; La llamada "call" aporta 2 ciclos máquina.
	movlw	d'31'			; Aporta 1 ciclo máquina. Este es el valor de "K".
	goto	RetardoMicros		; Aporta 2 ciclos máquina.
Retardo_50micros				; La llamada "call" aporta 2 ciclos máquina.
	nop				; Aporta 1 ciclo máquina.
	movlw	d'14'			; Aporta 1 ciclo máquina. Este es el valor de "K".
	goto	RetardoMicros		; Aporta 2 ciclos máquina.
Retardo_20micros				; La llamada "call" aporta 2 ciclos máquina.
	movlw	d'5'			; Aporta 1 ciclo máquina. Este es el valor de "K".
;
; El próximo bloque "RetardoMicros" tarda:
; 1 + (K-1) + 2 + (K-1)x2 + 2 = (2 + 3K) ciclos máquina.
;
RetardoMicros
	movwf	R_ContA			; Aporta 1 ciclo máquina.
Rmicros_Bucle
	decfsz	R_ContA,F		; (K-1)x1 cm (cuando no salta) + 2 cm (al saltar).
	goto	Rmicros_Bucle		; Aporta (K-1)x2 ciclos máquina.
	return				; El salto del retorno aporta 2 ciclos máquina.
;
;En total estas subrutinas tardan:
; - Retardo_500micros:	2 + 1 + 1 + 2 + (2 + 3K) = 500 cm = 500 µs. (para K=164 y 4 MHz).
; - Retardo_200micros:	2 + 1 + 1 + 2 + (2 + 3K) = 200 cm = 200 µs. (para K= 64 y 4 MHz).
; - Retardo_100micros:	2     + 1 + 2 + (2 + 3K) = 100 cm = 100 µs. (para K= 31 y 4 MHz).
; - Retardo_50micros :	2 + 1 + 1 + 2 + (2 + 3K) =  50 cm =  50 µs. (para K= 14 y 4 MHz).
; - Retardo_20micros :	2     + 1     + (2 + 3K) =  20 cm =  20 µs. (para K=  5 y 4 MHz).
       
    
; RETARDOS de 1 ms hasta 200 ms. --------------------------------------------------------

Retardo_200ms				; La llamada "call" aporta 2 ciclos máquina.
	movlw	d'200'			; Aporta 1 ciclo máquina. Este es el valor de "M".
	goto	Retardos_ms		; Aporta 2 ciclos máquina.
Retardo_100ms				; La llamada "call" aporta 2 ciclos máquina.
	movlw	d'100'			; Aporta 1 ciclo máquina. Este es el valor de "M".
	goto	Retardos_ms		; Aporta 2 ciclos máquina.
Retardo_50ms				; La llamada "call" aporta 2 ciclos máquina.
	movlw	d'50'			; Aporta 1 ciclo máquina. Este es el valor de "M".
	goto	Retardos_ms		; Aporta 2 ciclos máquina.
Retardo_20ms				; La llamada "call" aporta 2 ciclos máquina.
	movlw	d'20'			; Aporta 1 ciclo máquina. Este es el valor de "M".
	goto	Retardos_ms		; Aporta 2 ciclos máquina.
Retardo_10ms				; La llamada "call" aporta 2 ciclos máquina.
	movlw	d'10'			; Aporta 1 ciclo máquina. Este es el valor de "M".
	goto	Retardos_ms		; Aporta 2 ciclos máquina.
Retardo_5ms				; La llamada "call" aporta 2 ciclos máquina.
	movlw	d'5'			; Aporta 1 ciclo máquina. Este es el valor de "M".
	goto	Retardos_ms		; Aporta 2 ciclos máquina.
Retardo_2ms				; La llamada "call" aporta 2 ciclos máquina.
	movlw	d'2'			; Aporta 1 ciclo máquina. Este es el valor de "M".
	goto	Retardos_ms		; Aporta 2 ciclos máquina.
Retardo_1ms				; La llamada "call" aporta 2 ciclos máquina.
	movlw	d'1'			; Aporta 1 ciclo máquina. Este es el valor de "M".
;
; El próximo bloque "Retardos_ms" tarda:
; 1 + M + M + KxM + (K-1)xM + Mx2 + (K-1)Mx2 + (M-1) + 2 + (M-1)x2 + 2 =
; = (2 + 4M + 4KM) ciclos máquina. Para K=249 y M=1 supone 1002 ciclos máquina
; que a 4 MHz son 1002 µs = 1 ms.
;
Retardos_ms
	movwf	R_ContB			; Aporta 1 ciclo máquina.
R1ms_BucleExterno
	movlw	d'249'			; Aporta Mx1 ciclos máquina. Este es el valor de "K".
	movwf	R_ContA			; Aporta Mx1 ciclos máquina.
R1ms_BucleInterno
	nop				; Aporta KxMx1 ciclos máquina.
	decfsz	R_ContA,F		; (K-1)xMx1 cm (cuando no salta) + Mx2 cm (al saltar).
	goto	R1ms_BucleInterno		; Aporta (K-1)xMx2 ciclos máquina.
	decfsz	R_ContB,F		; (M-1)x1 cm (cuando no salta) + 2 cm (al saltar).
	goto	R1ms_BucleExterno 	; Aporta (M-1)x2 ciclos máquina.
	return				; El salto del retorno aporta 2 ciclos máquina.

; RETARDOS de 0.5 hasta 20 segundos ---------------------------------------------------
;
Retardo_20s				; La llamada "call" aporta 2 ciclos máquina.
	movlw	d'200'			; Aporta 1 ciclo máquina. Este es el valor de "N".
	goto	Retardo_1Decima		; Aporta 2 ciclos máquina.
Retardo_10s				; La llamada "call" aporta 2 ciclos máquina.
	movlw	d'100'			; Aporta 1 ciclo máquina. Este es el valor de "N".
	goto	Retardo_1Decima		; Aporta 2 ciclos máquina.
Retardo_5s				; La llamada "call" aporta 2 ciclos máquina.
	movlw	d'50'			; Aporta 1 ciclo máquina. Este es el valor de "N".
	goto	Retardo_1Decima		; Aporta 2 ciclos máquina.
Retardo_2s				; La llamada "call" aporta 2 ciclos máquina.
	movlw	d'20'			; Aporta 1 ciclo máquina. Este es el valor de "N".
	goto	Retardo_1Decima		; Aporta 2 ciclos máquina.
Retardo_1s				; La llamada "call" aporta 2 ciclos máquina.
	movlw	d'10'			; Aporta 1 ciclo máquina. Este es el valor de "N".
	goto	Retardo_1Decima		; Aporta 2 ciclos máquina.
Retardo_500ms				; La llamada "call" aporta 2 ciclos máquina.
	movlw	d'5'			; Aporta 1 ciclo máquina. Este es el valor de "N".
;
; El próximo bloque "Retardo_1Decima" tarda:
; 1 + N + N + MxN + MxN + KxMxN + (K-1)xMxN + MxNx2 + (K-1)xMxNx2 +
;   + (M-1)xN + Nx2 + (M-1)xNx2 + (N-1) + 2 + (N-1)x2 + 2 =
; = (2 + 4M + 4MN + 4KM) ciclos máquina. Para K=249, M=100 y N=1 supone 100011
; ciclos máquina que a 4 MHz son 100011 µs = 100 ms = 0,1 s = 1 décima de segundo.
;
Retardo_1Decima
	movwf	R_ContC			; Aporta 1 ciclo máquina.
R1Decima_BucleExterno2
	movlw	d'100'			; Aporta Nx1 ciclos máquina. Este es el valor de "M".
	movwf	R_ContB			; Aporta Nx1 ciclos máquina.
R1Decima_BucleExterno
	movlw	d'249'			; Aporta MxNx1 ciclos máquina. Este es el valor de "K".
	movwf	R_ContA			; Aporta MxNx1 ciclos máquina.
R1Decima_BucleInterno          
	nop				; Aporta KxMxNx1 ciclos máquina.
	decfsz	R_ContA,F		; (K-1)xMxNx1 cm (si no salta) + MxNx2 cm (al saltar).
	goto	R1Decima_BucleInterno	; Aporta (K-1)xMxNx2 ciclos máquina.
	decfsz	R_ContB,F		; (M-1)xNx1 cm (cuando no salta) + Nx2 cm (al saltar).
	goto	R1Decima_BucleExterno	; Aporta (M-1)xNx2 ciclos máquina.
	decfsz	R_ContC,F		; (N-1)x1 cm (cuando no salta) + 2 cm (al saltar).
	goto	R1Decima_BucleExterno2	; Aporta (N-1)x2 ciclos máquina.
	return				; El salto del retorno aporta 2 ciclos máquina.	
	
    END