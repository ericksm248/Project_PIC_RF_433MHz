 __CONFIG   _CP_OFF &  _WDT_OFF & _PWRTE_ON & _XT_OSC
 LIST P=16F84A
 INCLUDE  <P16F84A.INC>

  ERRORLEVEL -302
  
variables udata_shr 0x0C
Contador    res 1	    ; El contador a visualizar.
Count1	    res 1
R_ContA	    res 1	    ; Contadores para los retardos.
R_ContB	    res 1
R_ContC	    res 1
	

; ZONA DE CÓDIGOS ********************************************************************
    org	    0x00
    goto    INICIO
 
INICIO
    bsf	    STATUS,RP0	    ; Acceso al Banco 1.
    clrf    TRISB	    ; Las líneas del Puerto B se configuran como salida.
    movlw   b'00001111'	    ; Las 4 líneas del Puerto A se configuran como entrada.
    movwf   TRISA
    bcf	    STATUS,RP0	    ; Acceso al Banco 0.
    clrf    PORTB	    ; comenzamos con bit 0 en la salida
Principal
    movf    PORTA,W	    ; Lee el valor de las variables de entrada.
    andlw   b'00001111'	    ; Se queda con los 4 bits bajos de entrada.
    movwf   Contador        ; guardo dato enviado
    btfsc   STATUS,2
    goto    Fin
    call    Retardo_20ms    ; Espera que se estabilicen los niveles de tensión.
;compruebo que sea el mismo dato
    movf    PORTA,W	    ; Lee el valor de las variables de entrada.
    andlw   b'00001111'	    ; Se queda con los 4 bits bajos de entrada.
    subwf   Contador,0
    btfss   STATUS,2	    ; Comprueba si es un rebote.
    goto    Fin		    ; Era un rebote y sale fuera.
    clrf    Count1
;Pulsador correcto, procedo a enviar datos.   
    bsf	    PORTB,3
;envia los datos
    bsf	    PORTB,1	    ; activa el tx
;primero envia el dato STAR   (1 7ms y 0 5ms)
    call    DATOUNO
    bcf	    PORTB,0
    call    Retardo_5ms	
;envio dato
BITS
    btfss   Contador,0
    goto    PREDATO
    call    DATOUNO
CONTINUAR
    rrf	    Contador,1
    incf    Count1
    movf    Count1,W	    ; Lee el valor de las variables de entrada.
    sublw   d'4'
    btfss   STATUS,2
    goto    BITS
;espacio entre dato y dato enviado
    bcf	    PORTB,0
    bcf	    PORTB,1
    bcf	    PORTB,3
    call    Retardo_20ms
Fin	
    goto    Principal

PREDATO
   call	    DATOCERO
   goto	    CONTINUAR
DATOUNO
   bsf	    PORTB,0
   call	    Retardo_5ms
   return
DATOCERO
   bcf	    PORTB,0
   call	    Retardo_5ms
   return

;//////////////// RETARDOS ///////////////////////
;	===================================================================
;	  Del libro "MICROCONTROLADOR PIC16F84. DESARROLLO DE PROYECTOS"
;	  E. Palacios, F. Remiro y L. López.		www.pic16f84a.com
; 	  Editorial Ra-Ma.  www.ra-ma.es
;	===================================================================
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