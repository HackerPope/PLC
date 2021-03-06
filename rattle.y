%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define MAX 1024

int spot = 0;                       //contador para marcar ifs
int fors = 0;                       //contador para marcar ciclos
int erro = 0;                       //flag de erro
int gp = 0;                         //contador para gp


typedef struct variable{          
      char* id;
      int posStack;
      int nArray;
} *Variable;

Variable v[MAX] = {0};      


void createVar (char* id){          
      Variable variavel = (Variable)malloc(sizeof(struct variable));
      variavel->id = id;
      variavel->posStack = gp;
      variavel->nArray = 0; 
      if(gp>=MAX){     
            printf("Memoria Máxima Excedida!");       
            erro = 1;
      }
      v[gp]=variavel;
      gp++;
}

void createArray(char* id, int N, int M){
      Variable variavel = (Variable)malloc(sizeof(struct variable));
      variavel->id = id;
      variavel->posStack = gp;  
      variavel->nArray = N;  
      int i;
      if(M==0){ 
            i = gp + N;
      }else{
            i = gp + (N*M);
      }
      if(gp>=MAX){       
            printf("Memoria Máxima Excedida!");         
            erro = 1;
      }
      while(gp<i){
            v[gp]=variavel;
            gp++;
      }
} 

int inArray(char* id){              //procura na lista de variaveis v
      int i;
      for(i=0; i<MAX; i++){
            if(strcmp(v[i]->id,id)==0){
                return 1;
            }
      }
      return 0;
}

int getPos(char* id){            //retorna posiçao na stack da var id
      int i;
      for(i=0; i<MAX; i++){
            if(strcmp(v[i]->id,id)==0){ return v[i]->posStack; }
      }
}

int getN(char* id){     //retorna N de a[N] ou a[N][M]
      int i;
      for(i=0; i<MAX; i++){
            if(strcmp(v[i]->id,id)==0){ return v[i]->nArray; }
      }
}
%}

%union { int valN; char* valS; float valF; }
%token <valN>NUM
%token <valS>ID 
%token <valF>FLOAT
%token VAR
%token IF ELSE
%token FOR DO
%token INPUT
%token OUTPUT
%token EQ NE LT LE GT GE 
%token TRUE FALSE
%type  <valS> Decls Decl Cmds Rat Atrib If For Inp Out Cond Expr Termo Fator

%%
Rattle: Decls Cmds                                              { printf("%sstart\n%sstop\n",$1,$2); }
      | Cmds                                                    { printf("start\n%sstop\n",$1); }
      ;

Decls : Decls Decl                                              { asprintf(&$$,"%s%s",$1,$2); }
      | Decl                                                    { asprintf(&$$,"%s",$1); }
      ;

Decl  : VAR ID                                                  { asprintf(&$$,"pushi 0\n"); createVar($2); } 
      | VAR ID '[' NUM ']'                                      { asprintf(&$$,"pushn %d\n",$4); createArray($2,$4,0); } 
      | VAR ID '[' NUM ']' '[' NUM ']'                          { asprintf(&$$,"pushn %d\n",$4*$7); createArray($2,$4,$7); } 
      ;

Cmds  : Cmds Rat                                                { asprintf(&$$,"%s%s",$1,$2); }
      | Rat                                                     { asprintf(&$$,"%s",$1); }
      ;

Rat   : Atrib                                                   { asprintf(&$$,"%s",$1); }
      | If                                                      { asprintf(&$$,"%s",$1); }
      | For                                                     { asprintf(&$$,"%s",$1); }
      | Inp                                                     { asprintf(&$$,"%s",$1); }
      | Out                                                     { asprintf(&$$,"%s",$1); }
      ;

Atrib : ID '=' Expr                                             { asprintf(&$$,"%sstoreg %d\n",$3,getPos($1)); }
      | ID '[' Expr ']' '=' Expr                                { asprintf(&$$,"pushgp\npushi %d\n%sadd\n%sstoren\n",getPos($1),$3,$6); }
      | ID '[' Expr ']' '[' Expr ']' '=' Expr                   { asprintf(&$$,"pushgp\npushi %d\n%s%spushi %d\nmul\nadd\nadd\n%sstoren\n",getPos($1),$3,$6,getN($1),$9); }
      ;                  
      
If    : IF '(' Cond ')' '{' Cmds '}'                            { asprintf(&$$,"%sjz spot%d\n%sspot%d:\n",$3,spot,$6,spot); spot++; }
      | IF '(' Cond ')' '{' Cmds '}' ELSE '{' Cmds '}'          { asprintf(&$$,"%sjz spot%d\n%sjump spot%d\nspot%d:\n%sspot%d:\n",$3,spot,$6,spot+1,spot,$10,spot+1); spot++; spot++; }
      ;

For   : FOR '(' ID '|' Cond ')' DO '{' Cmds '}'                 { asprintf(&$$, "for%d:\n%sjz endfor%d\n%sjump for%d\nendfor%d:\n",fors,$5,fors,$9,fors,fors); fors++;}
      | FOR '(' Atrib '|' Cond ')' DO '{' Cmds '}'              { asprintf(&$$, "%sfor%d:\n%sjz endfor%d\n%sjump for%d\nendfor%d:\n",$3,fors,$5,fors,$9,fors,fors);fors++;}
      ;

Inp   : INPUT '(' ID ')'                                        { asprintf(&$$,"read\natoi\nstoreg %d\n",getPos($3)); }
      | INPUT '(' ID '[' Expr ']' ')'                           { asprintf(&$$,"pushgp\npushi %d\n%sadd\nread\natoi\nstoren\n",getPos($3),$5); }
      | INPUT '(' ID '[' Expr ']' '[' Expr ']' ')'              { asprintf(&$$,"pushgp\npushi %d\n%s%spushi %d\nmul\nadd\nadd\nread\natoi\nstoren\n",getPos($3),$5,$8,getN($3)); }    
      ;

Out   : OUTPUT '(' Expr ')'                                     { asprintf(&$$,"%swritei\n",$3); }
      ;

Cond  : Expr EQ Expr                                            { asprintf(&$$,"%s%sequal\n", $1, $3); }
      | Expr NE Expr                                            { asprintf(&$$,"%s%sequal\nnot\n", $1, $3); }
      | Expr LT Expr                                            { asprintf(&$$,"%s%sinf\n", $1, $3); }
      | Expr LE Expr                                            { asprintf(&$$,"%s%sinfeq\n", $1, $3); }
      | Expr GT Expr                                            { asprintf(&$$,"%s%ssup\n", $1, $3); }
      | Expr GE Expr                                            { asprintf(&$$,"%s%ssupeq\n", $1, $3); }
      ;

Expr  : Termo                                                   { asprintf(&$$,"%s",$1); }            
      | Expr '+' Termo                                          { asprintf(&$$,"%s%sadd\n",$1,$3); }
      | Expr '-' Termo                                          { asprintf(&$$,"%s%ssub\n",$1,$3); }
      ;

Termo : Fator                                                   { asprintf(&$$,"%s",$1); }
      | Expr '*' Fator                                          { asprintf(&$$,"%s%smul\n",$1,$3); }
      | Expr '/' Fator                                          { if($3){ asprintf(&$$,"%s%sdiv\n",$1,$3); }else{printf("Erro: Divisao por 0"); $$=0; erro=1;} }                 
      | Expr '%' Fator                                          { asprintf(&$$,"%s%smod\n",$1,$3); }
      ;
         
Fator : NUM                                                     { asprintf(&$$,"pushi %d\n",$1); }               
      | ID                                                      { if(inArray($1)==1){ asprintf(&$$,"pushg %d\n",getPos($1)); }else{printf("Erro: Variavel %s não existe",$1); $$=0; erro=1;} }
      | ID '[' Expr ']'                                         { if(inArray($1)==1){ asprintf(&$$,"pushgp\npushi %d\n%sadd\nloadn\n",getPos($1),$3); }else{printf("Erro: Array %s não existe",$1); $$=0; erro=1;} }
      | ID '[' Expr ']' '[' Expr ']'                            { if(inArray($1)==1){ asprintf(&$$,"pushgp\npushi %d\n%s%spushi %d\nmul\nadd\nadd\nloadn\n",getPos($1),$3,$6,getN($1)); }else{printf("Erro: Array %s não existe",$1); $$=0; erro=1;} }
      | TRUE                                                    { asprintf(&$$,"pushi %d\n",1); }
      | FALSE                                                   { asprintf(&$$,"pushi %d\n",0); }
      | '(' Expr ')'                                            { asprintf(&$$,"%s",$2); }
      ;
%%

#include "lex.yy.c"

void yyerror(char *s){
    printf("%s \n", s);
}

int main(){
    yyparse();
    if(erro==1){ printf("Erro a compilar programa!"); }
    return(0);
}