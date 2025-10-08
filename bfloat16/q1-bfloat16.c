#include <stdio.h>
#include <stdbool.h>
#include <stdint.h>
#include <string.h>

typedef struct {
    uint16_t bits;
} bf16_t;

#define BF16_SIGN_MASK 0x8000U
#define BF16_EXP_MASK 0x7F80U
#define BF16_MANT_MASK 0x007FU
#define BF16_EXP_BIAS 127

#define BF16_NAN() ((bf16_t) {.bits = 0x7FC0})
#define BF16_ZERO() ((bf16_t) {.bits = 0x0000})

static inline bool bf16_isnan(bf16_t a)
{
    return ((a.bits & BF16_EXP_MASK) == BF16_EXP_MASK) &&
           (a.bits & BF16_MANT_MASK);
}

static inline bool bf16_isinf(bf16_t a)
{
    return ((a.bits & BF16_EXP_MASK) == BF16_EXP_MASK) &&
           !(a.bits & BF16_MANT_MASK);
}

static inline bool bf16_iszero(bf16_t a)
{
    return !(a.bits & 0x7FFF);
}

static inline bf16_t f32_to_bf16(uint32_t val)
{
    uint32_t f32bits = val;
    if (((f32bits >> 23) & 0xFF) == 0xFF)
        return (bf16_t) {.bits = (f32bits >> 16) & 0xFFFF};
    f32bits += ((f32bits >> 16) & 1) + 0x7FFF;
    return (bf16_t) {.bits = f32bits >> 16};
}

static inline float bf16_to_f32(bf16_t val)
{
    uint32_t f32bits = ((uint32_t) val.bits) << 16;
    float result;
    memcpy(&result, &f32bits, sizeof(float));
    return result;
}

static inline bf16_t bf16_add(bf16_t a, bf16_t b)
{
    uint16_t sign_a = (a.bits >> 15) & 1;
    uint16_t sign_b = (b.bits >> 15) & 1;
    int16_t exp_a = ((a.bits >> 7) & 0xFF);
    int16_t exp_b = ((b.bits >> 7) & 0xFF);
    uint16_t mant_a = a.bits & 0x7F;
    uint16_t mant_b = b.bits & 0x7F;

    if (exp_a == 0xFF) {
        if (mant_a)
            return a;
        if (exp_b == 0xFF)
            return (mant_b || sign_a == sign_b) ? b : BF16_NAN();
        return a;
    }
    if (exp_b == 0xFF)
        return b;
    if (!exp_a && !mant_a)
        return b;
    if (!exp_b && !mant_b)
        return a;
    if (exp_a)
        mant_a |= 0x80;
    if (exp_b)
        mant_b |= 0x80;

    int16_t exp_diff = exp_a - exp_b;
    uint16_t result_sign;
    int16_t result_exp;
    uint32_t result_mant;

    if (exp_diff > 0) {
        result_exp = exp_a;
        if (exp_diff > 8)
            return a;
        mant_b >>= exp_diff;
    } else if (exp_diff < 0) {
        result_exp = exp_b;
        if (exp_diff < -8)
            return b;
        mant_a >>= -exp_diff;
    } else {
        result_exp = exp_a;
    }

    if (sign_a == sign_b) {
        result_sign = sign_a;
        result_mant = (uint32_t) mant_a + mant_b;

        if (result_mant & 0x100) {
            result_mant >>= 1;
            if (++result_exp >= 0xFF)
                return (bf16_t) {.bits = (result_sign << 15) | 0x7F80};
        }
    } else {
        if (mant_a >= mant_b) {
            result_sign = sign_a;
            result_mant = mant_a - mant_b;
        } else {
            result_sign = sign_b;
            result_mant = mant_b - mant_a;
        }

        if (!result_mant)
            return BF16_ZERO();
        while (!(result_mant & 0x80)) {
            result_mant <<= 1;
            if (--result_exp <= 0)
                return BF16_ZERO();
        }
    }

    return (bf16_t) {
        .bits = (result_sign << 15) | ((result_exp & 0xFF) << 7) |
                (result_mant & 0x7F),
    };
}

static inline bf16_t bf16_sub(bf16_t a, bf16_t b)
{
    b.bits ^= BF16_SIGN_MASK;
    return bf16_add(a, b);
}

static inline bf16_t bf16_mul(bf16_t a, bf16_t b)
{
    uint16_t sign_a = (a.bits >> 15) & 1;
    uint16_t sign_b = (b.bits >> 15) & 1;
    int16_t exp_a = ((a.bits >> 7) & 0xFF);
    int16_t exp_b = ((b.bits >> 7) & 0xFF);
    uint16_t mant_a = a.bits & 0x7F;
    uint16_t mant_b = b.bits & 0x7F;

    uint16_t result_sign = sign_a ^ sign_b;

    if (exp_a == 0xFF) {
        if (mant_a)
            return a;
        if (!exp_b && !mant_b)
            return BF16_NAN();
        return (bf16_t) {.bits = (result_sign << 15) | 0x7F80};
    }
    if (exp_b == 0xFF) {
        if (mant_b)
            return b;
        if (!exp_a && !mant_a)
            return BF16_NAN();
        return (bf16_t) {.bits = (result_sign << 15) | 0x7F80};
    }
    if ((!exp_a && !mant_a) || (!exp_b && !mant_b))
        return (bf16_t) {.bits = result_sign << 15};

    int16_t exp_adjust = 0;
    if (!exp_a) {
        while (!(mant_a & 0x80)) {
            mant_a <<= 1;
            exp_adjust--;
        }
        exp_a = 1;
    } else
        mant_a |= 0x80;
    if (!exp_b) {
        while (!(mant_b & 0x80)) {
            mant_b <<= 1;
            exp_adjust--;
        }
        exp_b = 1;
    } else
        mant_b |= 0x80;

    uint32_t result_mant = (uint32_t) mant_a * mant_b;

    int32_t result_exp = (int32_t) exp_a + exp_b - BF16_EXP_BIAS + exp_adjust;

    if (result_mant & 0x8000) {
        result_mant = (result_mant >> 8) & 0x7F;
        result_exp++;
    } else
        result_mant = (result_mant >> 7) & 0x7F;

    if (result_exp >= 0xFF)
        return (bf16_t) {.bits = (result_sign << 15) | 0x7F80};
    if (result_exp <= 0) {
        if (result_exp < -6)
            return (bf16_t) {.bits = result_sign << 15};
        result_mant >>= (1 - result_exp);
        result_exp = 0;
    }

    return (bf16_t) {.bits = (result_sign << 15) | ((result_exp & 0xFF) << 7) |
                             (result_mant & 0x7F)};
}

static inline bf16_t bf16_div(bf16_t a, bf16_t b)
{
    uint16_t sign_a = (a.bits >> 15) & 1;
    uint16_t sign_b = (b.bits >> 15) & 1;
    int16_t exp_a = ((a.bits >> 7) & 0xFF);
    int16_t exp_b = ((b.bits >> 7) & 0xFF);
    uint16_t mant_a = a.bits & 0x7F;
    uint16_t mant_b = b.bits & 0x7F;

    uint16_t result_sign = sign_a ^ sign_b;

    if (exp_b == 0xFF) {
        if (mant_b)
            return b;
        /* Inf/Inf = NaN */
        if (exp_a == 0xFF && !mant_a)
            return BF16_NAN();
        return (bf16_t) {.bits = result_sign << 15};
    }
    if (!exp_b && !mant_b) {
        if (!exp_a && !mant_a)
            return BF16_NAN();
        return (bf16_t) {.bits = (result_sign << 15) | 0x7F80};
    }
    if (exp_a == 0xFF) {
        if (mant_a)
            return a;
        return (bf16_t) {.bits = (result_sign << 15) | 0x7F80};
    }
    if (!exp_a && !mant_a)
        return (bf16_t) {.bits = result_sign << 15};

    if (exp_a)
        mant_a |= 0x80;
    if (exp_b)
        mant_b |= 0x80;

    uint32_t dividend = (uint32_t) mant_a << 15;
    uint32_t divisor = mant_b;
    uint32_t quotient = 0;

    for (int i = 0; i < 16; i++) {
        quotient <<= 1;
        if (dividend >= (divisor << (15 - i))) {
            dividend -= (divisor << (15 - i));
            quotient |= 1;
        }
    }

    int32_t result_exp = (int32_t) exp_a - exp_b + BF16_EXP_BIAS;

    if (!exp_a)
        result_exp--;
    if (!exp_b)
        result_exp++;

    if (quotient & 0x8000)
        quotient >>= 8;
    else {
        while (!(quotient & 0x8000) && result_exp > 1) {
            quotient <<= 1;
            result_exp--;
        }
        quotient >>= 8;
    }
    quotient &= 0x7F;

    if (result_exp >= 0xFF)
        return (bf16_t) {.bits = (result_sign << 15) | 0x7F80};
    if (result_exp <= 0)
        return (bf16_t) {.bits = result_sign << 15};
    return (bf16_t) {.bits = (result_sign << 15) | ((result_exp & 0xFF) << 7) |
                             (quotient & 0x7F)};
}

static inline bf16_t bf16_sqrt(bf16_t a)
{
    uint16_t sign = (a.bits >> 15) & 1;
    int16_t exp = ((a.bits >> 7) & 0xFF);
    uint16_t mant = a.bits & 0x7F;

    /* Handle special cases */
    if (exp == 0xFF) {
        if (mant)
            return a; /* NaN propagation */
        if (sign)
            return BF16_NAN(); /* sqrt(-Inf) = NaN */
        return a;              /* sqrt(+Inf) = +Inf */
    }

    /* sqrt(0) = 0 (handle both +0 and -0) */
    if (!exp && !mant)
        return BF16_ZERO();

    /* sqrt of negative number is NaN */
    if (sign)
        return BF16_NAN();

    /* Flush denormals to zero */
    if (!exp)
        return BF16_ZERO();

    /* Direct bit manipulation square root algorithm */
    /* For sqrt: new_exp = (old_exp - bias) / 2 + bias */
    int32_t e = exp - BF16_EXP_BIAS;
    int32_t new_exp;
    
    /* Get full mantissa with implicit 1 */
    uint32_t m = 0x80 | mant;  /* Range [128, 256) representing [1.0, 2.0) */
    
    /* Adjust for odd exponents: sqrt(2^odd * m) = 2^((odd-1)/2) * sqrt(2*m) */
    if (e & 1) {
        m <<= 1;  /* Double mantissa for odd exponent */
        new_exp = ((e - 1) >> 1) + BF16_EXP_BIAS;
    } else {
        new_exp = (e >> 1) + BF16_EXP_BIAS;
    }
    
    /* Now m is in range [128, 256) or [256, 512) if exponent was odd */
    /* Binary search for integer square root */
    /* We want result where result^2 = m * 128 (since 128 represents 1.0) */
    
    uint32_t low = 90;          /* Min sqrt (roughly sqrt(128)) */
    uint32_t high = 256;        /* Max sqrt (roughly sqrt(512)) */
    uint32_t result = 128;      /* Default */
    
    /* Binary search for square root of m */
    while (low <= high) {
        uint32_t mid = (low + high) >> 1;
        uint32_t sq = (mid * mid) / 128;  /* Square and scale */
        
        if (sq <= m) {
            result = mid;  /* This could be our answer */
            low = mid + 1;
        } else {
            high = mid - 1;
        }
    }
    
    /* result now contains sqrt(m) * sqrt(128) / sqrt(128) = sqrt(m) */
    /* But we need to adjust the scale */
    /* Since m is scaled where 128=1.0, result should also be scaled same way */
    
    /* Normalize to ensure result is in [128, 256) */
    if (result >= 256) {
        result >>= 1;
        new_exp++;
    } else if (result < 128) {
        while (result < 128 && new_exp > 1) {
            result <<= 1;
            new_exp--;
        }
    }
    
    /* Extract 7-bit mantissa (remove implicit 1) */
    uint16_t new_mant = result & 0x7F;
    
    /* Check for overflow/underflow */
    if (new_exp >= 0xFF)
        return (bf16_t) {.bits = 0x7F80};  /* +Inf */
    if (new_exp <= 0)
        return BF16_ZERO();
    
    return (bf16_t) {.bits = ((new_exp & 0xFF) << 7) | new_mant};
}

int main()
{
    bf16_t a[15] = {
        {.bits = 0x0000},  // 0: +0.0
        {.bits = 0x8000},  // 1: -0.0
        {.bits = 0x3f80},  // 2: 1.0
        {.bits = 0x4000},  // 3: 2.0
        {.bits = 0x4040},  // 4: 3.0
        {.bits = 0xbf80},  // 5: -1.0
        {.bits = 0x7f80},  // 6: +Inf
        {.bits = 0xff80},  // 7: -Inf
        {.bits = 0x7fc1},  // 8: NaN (quiet)
        {.bits = 0x4110},  // 9: 9.0
        {.bits = 0xc080},  //10: -4.0
        {.bits = 0x0001},  //11: subnormal small
        {.bits = 0x0a4b},  //12: 1e-8
        {.bits = 0x40a0},  //13: 5.0
        {.bits = 0x7f00},  //14: large (may overflow)
    };

    bf16_t b[15] = {
        {.bits = 0x0000},  //  0: +0.0             
        {.bits = 0x0000},  //  1: +0.0             
        {.bits = 0x4000},  //  2: 2.0              
        {.bits = 0x3f80},  //  3: 1.0             
        {.bits = 0x4000},  //  4: 2.0              
        {.bits = 0x3f80},  //  5: 1.0          
        {.bits = 0x3f80},  //  6: 1.0           
        {.bits = 0x7f80},  //  7: +Inf          
        {.bits = 0x3f80},  //  8: 1.0              
        {.bits = 0x0000},  //  9: 0.0              
        {.bits = 0x0000},  // 10: 0.0              
        {.bits = 0x0001},  // 11: small subnormal  
        {.bits = 0x0a4b},  // 12: very small       
        {.bits = 0x0000},  // 13: 0.0            
        {.bits = 0x7f00},  // 14: large           
    };

    uint32_t test_float_bits[15] = {
        0x3F800000, // 1.0
        0x3FC00000, // 1.5
        0x3F81AE14, // 1.01
        0x00000000, // 0.0
        0x80000000, // -0.0
        0x477FE000, // 65504.0
        0x7F800000, // +INF
        0xFF800000, // -INF
        0x7FC00000, // NaN
        0x00000001, // Subnormal
        0xC0200000, // -2.5
        0x40490FDB, // pi ≈ 3.14159265
        0xC2F6E979, // -123.456
        0x3EAAAAAB, // ~0.33333334
        0x2F06C6D6, // 1e-10
    };


    bool isNanAns[15] = {
        false, false, false, false, false,
        false, false, false, true,  false,
        false, false, false, false, false
    };

    bool isInfAns[15] = {
        false, false, false, false, false,
        false, true,  true,  false, false,
        false, false, false, false, false
    };

    bool isZeroAns[15] = {
        true,  true,  false, false, false,
        false, false, false, false, false,
        false, false, false, false, false
    };

    bf16_t f32tob16Ans[15] = {
        {.bits = 0x4e7e}, {.bits = 0x4e7f}, {.bits = 0x4e7e}, {.bits = 0x0000}, {.bits = 0x4f00},
        {.bits = 0x4e8f}, {.bits = 0x4eff}, {.bits = 0x4f80}, {.bits = 0x4f00}, {.bits = 0x3f80},
        {.bits = 0x4f40}, {.bits = 0x4e81}, {.bits = 0x4f43}, {.bits = 0x4e7b}, {.bits = 0x4e3c}
    };

    uint32_t b16tof32Ans[15] = {
        0x00000000, 0x80000000, 0x3f800000, 0x40000000, 0x40400000,
        0xbf800000, 0x7f800000, 0xff800000, 0x7fc10000, 0x41100000,
        0xc0800000, 0x00010000, 0x0a4b0000, 0x40a00000, 0x7f000000
    };

    bf16_t addAns[15] = {
        {.bits = 0x0000}, {.bits = 0x0000}, {.bits = 0x4040}, {.bits = 0x4040}, {.bits = 0x40a0},
        {.bits = 0x0000}, {.bits = 0x7f80}, {.bits = 0x7fc0}, {.bits = 0x7fc1}, {.bits = 0x4110},
        {.bits = 0xc080}, {.bits = 0x0002}, {.bits = 0x0acb}, {.bits = 0x40a0}, {.bits = 0x7f80}
    };

    bf16_t subAns[15] = {
        {.bits = 0x8000}, {.bits = 0x8000}, {.bits = 0xbf80}, {.bits = 0x3f80}, {.bits = 0x3f80},
        {.bits = 0xc000}, {.bits = 0x7f80}, {.bits = 0xff80}, {.bits = 0x7fc1}, {.bits = 0x4110},
        {.bits = 0xc080}, {.bits = 0x0000}, {.bits = 0x0000}, {.bits = 0x40a0}, {.bits = 0x0000}
    };

    bf16_t mulAns[15] = {
        {.bits = 0x0000}, {.bits = 0x8000}, {.bits = 0x4000}, {.bits = 0x4000}, {.bits = 0x40c0},
        {.bits = 0xbf80}, {.bits = 0x7f80}, {.bits = 0xff80}, {.bits = 0x7fc1}, {.bits = 0x0000},
        {.bits = 0x8000}, {.bits = 0x0000}, {.bits = 0x0000}, {.bits = 0x0000}, {.bits = 0x7f80}
    };

    bf16_t divAns[15] = {
        {.bits = 0x7fc0}, {.bits = 0x7fc0}, {.bits = 0x3f00}, {.bits = 0x4000}, {.bits = 0x3fc0},
        {.bits = 0xbf80}, {.bits = 0x7f80}, {.bits = 0x7fc0}, {.bits = 0x7fc1}, {.bits = 0x7f80},
        {.bits = 0xff80}, {.bits = 0x3f80}, {.bits = 0x3f80}, {.bits = 0x7f80}, {.bits = 0x3f80}
    };

    bf16_t squrAns[15] = {
        {.bits = 0x0000}, {.bits = 0x0000}, {.bits = 0x3f80}, {.bits = 0x3fb5}, {.bits = 0x3fdd},
        {.bits = 0x7fc0}, {.bits = 0x7f80}, {.bits = 0x7fc0}, {.bits = 0x7fc1}, {.bits = 0x4040},
        {.bits = 0x7fc0}, {.bits = 0x0000}, {.bits = 0x24e4}, {.bits = 0x400f}, {.bits = 0x5f35}
    };


    for (int i = 0 ; i < 15 ; ++i)
    {
        printf("%d\n", i);
        printf("Nan = %d\n", bf16_isnan(a[i]));
        printf("INF = %d\n", bf16_isinf(a[i]));
        printf("Zero = %d\n", bf16_iszero(a[i]));
        printf("f32tob16 = %04hx\n", f32_to_bf16(test_float_bits[i]).bits);
        float f = bf16_to_f32(a[i]);
        uint32_t bits;
        memcpy(&bits, &f, sizeof(bits));
        printf("b16tof32 = %08x\n", bits);
        printf("add = %04hx\n", bf16_add(a[i], b[i]).bits);
        printf("sub = %04hx\n", bf16_sub(a[i], b[i]).bits);
        printf("mul = %04hx\n", bf16_mul(a[i], b[i]).bits);
        printf("div = %04hx\n", bf16_div(a[i], b[i]).bits);
        printf("sqrt = %04hx\n", bf16_sqrt(a[i]).bits);
    }

    return 0;
}
/*int main()
{
    int function;
    bf16_t a, b, ans;
    uint16_t input_a, input_b;
    float  fInput_a; 
    while (1)
    {
        printf("---------------------------------------\n");
        printf("Function \n");
        printf("0(NAN)     , 1(INF), 2(Zero), 3(F32toB16),\n");
        printf("4(B16toF32), 5(Add), 6(Sub) , 7(Mul)     ,\n");
        printf("8(Div)     , 9(Sqrt) : ");
        scanf("%d", &function);
        
        switch(function)
        {
            case 0:
                printf("Please input a(4-digit hex): 0x");
                scanf("%hx", &input_a);
                a.bits = input_a;
                printf("isnan(a): %s\n", bf16_isnan(a) ? "true" : "false");
                break;

            case 1:
                printf("Please input a(4-digit hex): 0x");
                scanf("%hx", &input_a);
                a.bits = input_a;
                printf("isinf(a): %s\n", bf16_isinf(a) ? "true" : "false");
                break;

            case 2:
                printf("Please input a(4-digit hex): 0x");
                scanf("%hx", &input_a);
                a.bits = input_a;
                printf("iszero(a): %s\n", bf16_iszero(a) ? "true" : "false");
                break;

            case 3:
                printf("Please input f32: ");
                scanf("%f", &fInput_a);
                a = f32_to_bf16(fInput_a);
                printf("bf16 result: 0x%04hx\n", a.bits);
                break;

            case 4:
                printf("Please input b16(4-digit hex): 0x");
                scanf("%hx", &input_a);
                a.bits = input_a;
                printf("float result: %f\n", bf16_to_f32(a));
                break;

            case 5:
                printf("Please input a(4-digit hex): 0x");
                scanf("%hx", &input_a);
                printf("Please input b(4-digit hex): 0x");
                scanf("%hx", &input_b);
                a.bits = input_a;
                b.bits = input_b;
                ans = bf16_add(a, b);
                printf("add result: 0x%04hx\n", ans.bits);
                break;


            case 6:
                printf("Please input a(4-digit hex): 0x");
                scanf("%hx", &input_a);
                printf("Please input b(4-digit hex): 0x");
                scanf("%hx", &input_b);
                a.bits = input_a;
                b.bits = input_b;
                ans = bf16_sub(a, b);
                printf("sub result: 0x%04hx\n", ans.bits);
                break;

            case 7:
                printf("Please input a(4-digit hex): 0x");
                scanf("%hx", &input_a);
                printf("Please input b(4-digit hex): 0x");
                scanf("%hx", &input_b);
                a.bits = input_a;
                b.bits = input_b;
                ans = bf16_mul(a, b);
                printf("mul result: 0x%04hx\n", ans.bits);
                break;

            case 8:
                printf("Please input a(4-digit hex): 0x");
                scanf("%hx", &input_a);
                printf("Please input b(4-digit hex): 0x");
                scanf("%hx", &input_b);
                a.bits = input_a;
                b.bits = input_b;
                ans = bf16_div(a, b);
                printf("div result: 0x%04hx\n", ans.bits);
                break;

            case 9:
                printf("Please input a(4-digit hex): 0x");
                scanf("%hx", &input_a);
                a.bits = input_a;
                ans = bf16_sqrt(a);
                printf("sqrt result: 0x%04hx\n", ans.bits);
                break;

            default:
                break;
        }
    
    }


    return 0;
    
}*/