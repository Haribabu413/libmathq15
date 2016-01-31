;/* The MIT License (MIT)
; * Copyright (c) 2016 The Open-Source Community
; *
; * Permission is hereby granted, free of charge, to any person obtaining
; * a copy of this software and associated documentation files (the
; * "Software"), to deal in the Software without restriction, including
; * without limitation the rights to use, copy, modify, merge, publish,
; * distribute, sublicense, and/or sell copies of the Software, and to
; * permit persons to whom the Software is furnished to do so, subject
; * to the following conditions:
; *
; * The above copyright notice and this permission notice shall be included
; * in all copies or substantial portions of the Software.
; * 
; * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
; */

    .include "xc.inc"

    .text
    .global _q15_mul
    .global _q15_div
    .global _q15_add
    .global _q15_abs
    
_q15_mul:
    ; w3:w2 = w1 * w0
    mul.ss  w0, w1, w2
    
    ; w0 = (w3:w2) >> 15
    rlc	    w2, w2
    rlc	    w3, w3
    
    ; w0 = w3
    mov	    w3, w0
    
    return
    
_q15_div:
    ; w2 = w0
    ; w3 = w1
    mov	    w0, w2
    mov	    w1, w3
    
    ; w4 = abs(w0)
    call    _q15_abs
    mov	    w0, w4
    
    ; w5 = abs(w1)
    mov	    w3, w0
    call    _q15_abs
    mov	    w0, w5
    
    ; if w4 >= w5, then goto saturate
    cpslt   w4, w5
    goto    _q15_div_saturate
    
    ; if w2 == 0, then goto saturate
    clr	    w4
    cpsne   w4, w3
    goto    _q15_div_saturate
    
    ; otherwise, arrange and goto divide
    mov	    w2, w0
    mov	    w3, w1
    goto    _q15_div_div
    
_q15_div_saturate:
    ; mask = 0x8000
    mov	    #32768, w4
    
    ; w2 &= mask
    and	    w2, w4, w2
    
    ; w3 &= mask
    and	    w3, w4, w3
    
    ; w2 = w2 ^ w3
    xor	    w2, w3, w2
    
    ; if w2 == 0, return 32767, otherwise, return -32768
    mov	    #32767, w0
    clr	    w1
    cpseq   w2, w1
    mov	    #32768, w0
    
    return
    
_q15_div_div:
    ; at this point w1 = divisor, w0 = dividend
    
    ; w2 = w1
    ; w5:w4 = w0 << 16
    mov	    w1, w2
    mov	    w0, w5
    clr	    w4
    
    ; w5:w4 = w5:w4 >> 1
    asr	    w5, #1, w5
    
    ; w0 = w5:w4 / w2
    repeat  #17
    div.sd  w4, w2
    
    return
    
_q15_add:
    add	    w0, w1, w2
    btsc    SR, #2	; check the overflow bit
    goto    _q15_add_sat
    mov	    w2, w0
    return
    
    ; if the code gets here, then an overflow occured, need to saturate
    ; mask = 0x8000
_q15_add_sat:
    ; if w0 is negative, then saturate negative, otherwise positive
    btsc    w0, #15
    goto    _q15_add_neg_sat
    
_q15_add_pos_sat:
    mov	    #32767, w0
    return
    
_q15_add_neg_sat:
    mov	    #32768, w0
    return
    
_q15_abs:
    btss    w0, #15
    return
    
    ; number is negative, so reverse its form
    com	    w0, w1
    inc	    w1, w0
    
    return
    

    
    .end
    
    