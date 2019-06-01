#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <math.h>

#define MAX_LEN 100
#define MAX_FUNC_LEN 20

#define TOK_NUM     0
#define TOK_MULTI   1
#define TOK_DIV     2
#define TOK_PLUS    3
#define TOK_MINUS   4
#define TOK_LPAREN  5
#define TOK_RPAREN  6
#define TOK_FUNC    7
#define TOK_NEG     8
#define TOK_SIN     9
#define TOK_COS     10
#define TOK_TAN     11

#define SUCCESS             0
#define UNMATCHED_PAREN     1
#define INVALID_EXPR        2
#define INVALID_CHAR        3
#define DIVIDED_ZERO        4
#define UNSUPPORTED_FUNC    5

const char name_sin[] = "sin\0";
const char name_cos[] = "cos\0";
const char name_tan[] = "tan\0";

char expr[] = "1+3*(5/0+cos(5))\0";

int post_expr[MAX_LEN];
int parsed = 0;
int p[12] = {0, 2, 2, 1, 1, 0, 0, 4, 3, 4, 4, 4};

int len = 0;
int tokens[MAX_LEN];
float values[MAX_LEN];

int tokenize()
{
    int ch;
    int idx = 0;
    float value;
    float base;
    char func_name[MAX_FUNC_LEN];
    int func_len;

    while(idx < strlen(expr)) {
        ch = expr[idx]; 
        if(isdigit(ch)) {
            value = 0;
            do {
                value *= 10;
                value += ch - '0';
                idx++;
                ch = expr[idx];
            }while(isdigit(ch));

            base = 0.1;
            if(expr[idx] == '.') {
                idx++;
                ch = expr[idx];
                while(isdigit(ch)){
                    value += base * (ch - '0');
                    base /= 10;
                    idx++;
                    ch = expr[idx];
                }
            }
            tokens[len] = TOK_NUM;
            values[len] = value;
            len++;
            continue;
        }
        if(isalpha(ch)) {
            func_len = 0;
            while(isalpha(ch)) {
                func_name[func_len] = ch;
                func_len++;
                if(func_len >= MAX_FUNC_LEN)
                    return UNSUPPORTED_FUNC;
                idx++;
                ch = expr[idx]; 
            }
            func_name[func_len] = '\0';
            if(strcmp(func_name, name_sin) == 0) {
                tokens[len] = TOK_SIN;
                len++;
                continue;
            }
            if(strcmp(func_name, name_cos) == 0) {
                tokens[len] = TOK_COS;
                len++;
                continue;
            }
            if(strcmp(func_name, name_tan) == 0) {
                tokens[len] = TOK_TAN;
                len++;
                continue;
            }
            return UNSUPPORTED_FUNC;
        }
        switch(ch) {
            case '+':
                tokens[len] = TOK_PLUS;
                break;
            case '-':
                if(idx == 0 || ispunct(expr[idx-1]))
                    tokens[len] = TOK_NEG;
                else
                    tokens[len] = TOK_MINUS;
                break;
            case '*':
                tokens[len] = TOK_MULTI;
                break;
            case '/':
                tokens[len] = TOK_DIV;
                break;
            case '(':
                tokens[len] = TOK_LPAREN;
                break;
            case ')':
                tokens[len] = TOK_RPAREN;
                break;
            default:
                return INVALID_CHAR;
        }
        idx++;
        len++;
    }
    return SUCCESS;
}

int less(int op1, int op2) 
{
    return p[tokens[op1]] < p[tokens[op2]];
}

int check(int idx, int type)
{
    return tokens[idx] == type;
}

// convert to postfix expression
int parse()
{
    int stack[MAX_LEN];
    int top = 0;

    for(int i=0; i<len; ++i) {
        if(tokens[i] == TOK_NUM)  {
            post_expr[parsed] = i;
            parsed++;
            continue;
        }
        if(tokens[i] == TOK_LPAREN) {
            stack[top] = i;
            top ++;
            continue;
        }
        if(tokens[i] == TOK_RPAREN) {
            // 出现右括号,则弹出栈内所有符号直到遇到左括号
            while(top > 0 && !check(stack[top-1], TOK_LPAREN)) {
                post_expr[parsed] = stack[top-1];
                parsed ++;
                top --;
            }
            if(top == 0)
                return UNMATCHED_PAREN;
            top--;
            continue;
        }
        if(top == 0 || less(stack[top-1], i)) {
            stack[top] = i;
            top ++;
        } else {
            while(top != 0 && !less(stack[top-1], i)) {
                post_expr[parsed] = stack[top-1];
                parsed ++;
                top --;
            }
            stack[top] = i;
            top ++;
        }
    }

    while(top > 0) {
        post_expr[parsed] = stack[top-1];
        parsed ++;
        top --;
    }
    return SUCCESS;
}

int evaluate(float* ans)
{
    float stack[MAX_LEN];
    int top = 0;
    int cur_token;
    float op1;
    float op2;
    float result;
    for(int i=0; i<parsed; ++i) {
        cur_token = tokens[post_expr[i]];
        if(cur_token == TOK_LPAREN || cur_token == TOK_RPAREN)
            return UNMATCHED_PAREN;
        if(cur_token == TOK_NUM) {
            stack[top] = values[post_expr[i]];
            top++;
            continue;
        }
        if(cur_token == TOK_NEG) {
            if(top < 1)
                return INVALID_EXPR;
            op1 = stack[top-1];
            result = -op1;
            stack[top-1] = result;
            continue;
        }

        if(cur_token == TOK_SIN) {
            if(top < 1)
                return INVALID_EXPR;
            op1 = stack[top-1];
            result = sin(op1);
            stack[top-1] = result;
            continue;
        }

        if(cur_token == TOK_COS) {
            if(top < 1)
                return INVALID_EXPR;
            op1 = stack[top-1];
            result = cos(op1);
            stack[top-1] = result;
            continue;
        }

        if(cur_token == TOK_TAN) {
            if(top < 1)
                return INVALID_EXPR;
            op1 = stack[top-1];
            result = tan(op1);
            stack[top-1] = result;
            continue;
        }

        // must be binary operator, then
        if(top < 2)
            return INVALID_EXPR;
        op1 = stack[top-2];
        op2 = stack[top-1];
        top -= 2;
        switch(cur_token) {
            case TOK_MULTI:
                result = op1 * op2;
                break;
            case TOK_DIV:
                if(op2 == 0) 
                    return DIVIDED_ZERO;
                result = op1 / op2;
                break;
            case TOK_PLUS:
                result = op1 + op2;
                break;
            case TOK_MINUS:
                result = op1 - op2;
                break;
        }
        stack[top] = result;
        top ++;
    }
    *ans = stack[0];
    return SUCCESS;
}

int main()
{
    int status;
    status = tokenize();
    if(status != SUCCESS)
        return status;

    for(int i=0; i<len; ++i) 
        printf("%d ", tokens[i]);
    printf("\n");
    for(int i=0; i<len; ++i) 
        printf("%f ", values[i]);

    status = parse();
    if(status != SUCCESS)
        return status;
    printf("Parsed: %d\n", status);

    for(int i=0; i<parsed; ++i) 
        printf("%d ", post_expr[i]+1);

    float result;
    status = evaluate(&result);
    if(status != SUCCESS)
        return status;
    printf("%s=%f\n", expr, result);

    return 0;
}