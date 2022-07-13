%{
#include<iostream>
#include<cstdlib>
#include<cstring>
#include<cmath>
#include<vector>
#include<fstream>
#include"SymbolTable.cpp"

#define ISVAR -1
#define ISFUNC -2
#define ISFUNCDEF -3



using namespace std;

extern int yylineno;
extern int yyparse(void);
extern int yylex(void);
extern FILE *yyin;
FILE *fp;
ofstream errOut;

bool isErr = false;
string retType;
int errorCount = 0;

SymbolTable *symbolTable = new SymbolTable(7);

void printErr(string message);

void yyerror(const char *s){
	string ss(s);
	printErr(s);
}

bool isIdInList(vector<SymbolInfo*>* v, SymbolInfo* s){
	for(auto a : *v){
		if(a->getName() == s->getName()){
			return true;
		}
	}
	return false;
}

void printErr(string message){
	errOut << "Error at line " << yylineno << ": " << message <<"\n\n";
	cout << "Error at line " << yylineno << ": " << message <<"\n\n";
}

string makeDecListString(vector<SymbolInfo*>* v){
	string s = "";
	for(auto a : *v) {
		s += a->getName();
		if(a->getSize() != ISVAR){
			s += "[" + to_string(a->getSize()) + "]";
		}
		s += ",";
	}
	s.pop_back();
	return s;
}


string makeParamListString(vector<SymbolInfo*>* v){
	string s = "";
	if(v->size() == 0){
		return s;
	}
	for(auto a : *v) {
		if(a->getName() == ""){
			s += a->getIdType();
		}
		else {
			s += a->getIdType() + " " + a->getName();
		}
		s += ",";
	}
	s.pop_back();
	return s;
}


string makeArgListString(vector<SymbolInfo*>* v){
	string s = "";
	if(v->size() == 0){
		return s;
	}
	for(auto a : *v) {
		s += a->getName() + ",";
	}
	s.pop_back();
	return s;
}

string makeStatementsString(vector<SymbolInfo*>* v){
	bool flag = false;
	string s = "";
	if(v->size() == 2 && v->front()->getName() == "{" && v->back()->getName() == "}"){
		return "{}\n\n";
	}
	for(auto a : *v){
		if(a->getType() == "if" || a->getType() == "while" || a->getType() == "for"){
			flag = true;
		}
		if(a->getName() == "{" && flag){
			s.pop_back();
			flag = false;
		}
		s += a->getName() + "\n";
	}
	return s;
}


%}

%define parse.error verbose

%union {
    SymbolInfo* symbolInfo;
	string* type;
	vector<SymbolInfo*>* list;
}

// DO DOUBLE CHAR SWITCH DEFAULT BREAK CASE CONTINUE CONST_CHAR
//Not used in any rules

%token IF ELSE FOR WHILE INT FLOAT VOID RETURN
%token LCURL RCURL LPAREN RPAREN COMMA SEMICOLON LTHIRD RTHIRD
%token ASSIGNOP INCOP DECOP NOT 
%token PRINTLN
%token<symbolInfo> ID CONST_INT CONST_FLOAT
%token<type> MULOP RELOP ADDOP LOGICOP

%type<symbolInfo> start program unit func_declaration func_definition variable 
%type<symbolInfo> expression_statement logic_expression var_declaration 
%type<symbolInfo> term expression rel_expression simple_expression unary_expression factor
%type<type> type_specifier
%type<list> declaration_list parameter_list arguments argument_list statements compound_statement statement

%nonassoc LOWER_PREC_THAN_ELSE
%nonassoc ELSE

%%

start : 
		program {
			cout << "Line " << yylineno << ": start : program\n\n";
			symbolTable->printAllScopeTable();

			cout << "Total lines: " << yylineno << endl;
			cout << "Total error: " << errorCount << endl;
		}


program :
		program unit {
			$$ = new SymbolInfo($1->getName() + "\n" + $2->getName(), "program");
			cout << "Line " << yylineno << ": program : program unit\n\n";
			cout << $$->getName() << "\n\n\n";
		}
		| unit {
			$$ = $1;
			cout << "Line " << yylineno << ": program : unit\n\n";
			cout << $$->getName() << "\n\n\n";
		}



unit :
		var_declaration {
			$$ = $1;
			cout << "Line " << yylineno << ": unit : var_declaration\n\n";
			cout << $$->getName() << "\n\n\n";
		}
		| func_declaration {
			$$ = $1;
			cout << "Line " << yylineno << ": unit : func_declaration\n\n";
			cout << $$->getName() << "\n\n\n";
		}
		| func_definition {
			$$ = $1;
			cout << "Line " << yylineno << ": unit : func_definition\n\n";
			cout << $$->getName() << "\n\n\n";
		}


func_declaration :
		type_specifier ID LPAREN parameter_list RPAREN SEMICOLON {
			SymbolInfo* id = symbolTable->lookup($2->getName());
			SymbolInfo* func = new SymbolInfo($2->getName(), $2->getType(), $1[0]);
			func->setParamList($4);
			func->setSize(ISFUNC);
			if(id != nullptr){
				errorCount++;
				printErr("Multiple declaration of " + id->getName());
			}
			else {
				symbolTable->insert(func);
			}
			$$ = new SymbolInfo($1[0] + " " + $2->getName() + "(" + makeParamListString($4) + ");", "func_dec");
			cout << "Line " << yylineno << ": func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON\n\n";
			cout << $$->getName() << "\n\n\n";
		}
		| type_specifier ID LPAREN parameter_list error RPAREN SEMICOLON {
			errorCount++;
			cout << makeParamListString($4) << "\n\n";
			SymbolInfo* id = symbolTable->lookup($2->getName());
			SymbolInfo* func = new SymbolInfo($2->getName(), $2->getType(), $1[0]);
			func->setParamList($4);
			func->setSize(ISFUNC);
			if(id != nullptr){
				errorCount++;
				printErr("Multiple declaration of " + id->getName());
			}
			else {
				symbolTable->insert(func);
			}
			$$ = new SymbolInfo($1[0] + " " + $2->getName() + "(" + makeParamListString($4) + ");", "func_dec");
			cout << "Line " << yylineno << ": func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON\n\n";
			cout << $$->getName() << "\n\n\n";
		}
		| type_specifier ID LPAREN RPAREN SEMICOLON {
			SymbolInfo* id = symbolTable->lookup($2->getName());
			SymbolInfo* func = new SymbolInfo($2->getName(), $2->getType(), $1[0]);
			func->setParamList(new vector<SymbolInfo*>());
			func->setSize(ISFUNC);
			if(id != nullptr){
				errorCount++;
				printErr("Multiple declaration of " + id->getName());
			}
			else {
				symbolTable->insert(func);
			}
			$$ = new SymbolInfo($1[0] + " " + $2->getName() + "();", "func_dec");
			cout << "Line " << yylineno << ": func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON\n\n";
			cout << $$->getName() << "\n\n\n";
		}
		;

func_definition : 
		type_specifier ID LPAREN parameter_list RPAREN {
			retType = $1[0];
			SymbolInfo* id = symbolTable->lookup($2->getName());
			if(id == nullptr){
				SymbolInfo* func = new SymbolInfo($2->getName(), $2->getType(), $1[0]);
				func->setSize(ISFUNCDEF);
				func->setParamList($4);
				symbolTable->insert(func);
			}
			else {
				if(id->getSize() != ISFUNC){
					if(id->getSize() == ISFUNCDEF){
						errorCount++;
						printErr("Multiple definition of function " + id->getName());
					}
					else {
						errorCount++;
						printErr("Multiple declaration of " + id->getName());
					}
				}
				else {
					if($1[0] != id->getIdType()){
						errorCount++;
						printErr("Return type mismatch with function declaration in function " + id->getName());
					}
					int decParamSize = id->getParamList()->size();
					int defParamSize = $4->size();
					if(decParamSize != defParamSize){
						errorCount++;
						printErr("Total number of arguments mismatch with declaration in function " + id->getName());
					}

					for(int i = 0; i < $4->size(); i++){
						SymbolInfo* var = $4->at(i);
						if(var->getIdType() != id->getParamList()->at(i)->getIdType()){
						errorCount++;
						printErr("Type mispatch in parameter list");
					}
					}
				}
			}
			symbolTable->enterScope();

			for(int i = 0; i < $4->size(); i++){
				SymbolInfo* var = $4->at(i);
				if(var->getName() == ""){
					errorCount++;
					printErr(to_string(i + 1) + "th parameter's name not given in function definition of " + $2->getName());
					continue;
				}
				if(!symbolTable->insert(var)){
					errorCount++;
					printErr("Multiple declaration of " + var->getName());
				}
			}

		} compound_statement {
			$$ = new SymbolInfo($1[0] + " " + $2->getName() + "(" + makeParamListString($4) + ")" + makeStatementsString($7), "func_def");
			cout << "Line " << yylineno << ": func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement\n\n";
			cout << $$->getName() << "\n\n";
		}
		| type_specifier ID LPAREN parameter_list error RPAREN{
			errorCount++;
			cout << makeParamListString($4) << "\n\n";
			retType = $1[0];
			SymbolInfo* id = symbolTable->lookup($2->getName());
			if(id == nullptr){
				SymbolInfo* func = new SymbolInfo($2->getName(), $2->getType(), $1[0]);
				func->setSize(ISFUNCDEF);
				func->setParamList($4);
				symbolTable->insert(func);
			}
			else {
				if(id->getSize() != ISFUNC){
					if(id->getSize() == ISFUNCDEF){
						errorCount++;
						printErr("Multiple definition of function " + id->getName());
					}
					else {
						errorCount++;
						printErr("Multiple declaration of " + id->getName());
					}
				}
				else {
					if($1[0] != id->getIdType()){
						errorCount++;
						printErr("Return type mismatch with function declaration in function " + id->getName());
					}
					int decParamSize = id->getParamList()->size();
					int defParamSize = $4->size();
					if(decParamSize != defParamSize){
						errorCount++;
						printErr("Total number of arguments mismatch with declaration in function " + id->getName());
					}

					for(int i = 0; i < $4->size(); i++){
						SymbolInfo* var = $4->at(i);
						if(var->getIdType() != id->getParamList()->at(i)->getIdType()){
						errorCount++;
						printErr("Type mispatch in parameter list");
					}
					}
				}
			}
			symbolTable->enterScope();

			for(int i = 0; i < $4->size(); i++){
				SymbolInfo* var = $4->at(i);
				if(var->getName() == ""){
					errorCount++;
					printErr(to_string(i + 1) + "th parameter's name not given in function definition of " + $2->getName());
					continue;
				}
				if(!symbolTable->insert(var)){
					errorCount++;
					printErr("Multiple declaration of " + var->getName());
				}
			}

		} compound_statement {
			$$ = new SymbolInfo($1[0] + " " + $2->getName() + "(" + makeParamListString($4) + ")" + makeStatementsString($8), "func_def");
			cout << "Line " << yylineno << ": func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement\n\n";
			cout << $$->getName() << "\n\n";
		} | type_specifier ID LPAREN RPAREN {
			retType = $1[0];
			SymbolInfo* id = symbolTable->lookup($2->getName());
			if(id == nullptr){
				SymbolInfo* func = new SymbolInfo($2->getName(), $2->getType(), $1[0]);
				func->setSize(ISFUNCDEF);
				func->setParamList(new vector<SymbolInfo*>());
				symbolTable->insert(func);
			}
						else {
				if(id->getSize() != ISFUNC){
					if(id->getSize() == ISFUNCDEF){
						errorCount++;
						printErr("Multiple definition of function " + id->getName());
					}
					else {
						errorCount++;
						printErr("Multiple declaration of " + id->getName());
					}
				}
				else {
					if($1[0] != id->getIdType()){
						errorCount++;
						printErr("Return type mismatch with function declaration in function " + id->getName());
					}
					int decParamSize = id->getParamList()->size();
					int defParamSize = 0;
					if(decParamSize != defParamSize){
						errorCount++;
						printErr("Total number of arguments mismatch with declaration in function " + id->getName());
					}
				}
			}
			symbolTable->enterScope();
		} compound_statement {
			$$ = new SymbolInfo($1[0] + " " + $2->getName() + "()" + makeStatementsString($6), "func_def");
			cout << "Line " << yylineno << ": func_definition : type_specifier ID LPAREN RPAREN compound_statement\n\n";
			cout << $$->getName() << "\n\n";
		}
		;


parameter_list : 
		parameter_list COMMA type_specifier ID {
			$$ = $1;
			if(isIdInList($$, $4)){
				errorCount++;
				printErr("Multiple declaration of " + $4->getName() + " in parameter");
			}
			$4->setIdType($3[0]);
			$$->push_back($4);
			cout << "Line " << yylineno << ": parameter_list : parameter_list COMMA type_specifier ID\n\n";
			cout << makeParamListString($$);
			cout << "\n\n";
		}
		| parameter_list COMMA type_specifier {
			cout << "Line " << yylineno << ": parameter_list : parameter_list COMMA type_specifier\n\n";
			$$ = $1;
			SymbolInfo* param = new SymbolInfo($3[0], "");
			$$->push_back(param);
			cout << makeParamListString($$);
			cout << "\n\n";
		}
		| type_specifier ID {
			cout << "Line " << yylineno << ": parameter_list : type_specifier ID\n\n";
			$$ = new vector<SymbolInfo*>();
			$2->setIdType($1[0]);
			$$->push_back($2);
			cout << makeParamListString($$);
			cout << "\n\n";
		}		
		| type_specifier {
			cout << "Line " << yylineno << ": parameter_list : type_specifier\n\n";
			$$ = new vector<SymbolInfo*>();
			SymbolInfo* param = new SymbolInfo("", $1[0]);
			$$->push_back(param);
			cout << makeParamListString($$);
			cout << "\n\n";
		}
		;


compound_statement :
		LCURL statements RCURL {
			$$ = $2;
			$$->push_back(new SymbolInfo("}", ""));
			$$->insert($$->begin(),new SymbolInfo("{", ""));
			cout << "Line " << yylineno << ": compound_statement : LCURL statements RCURL\n\n";
			cout << makeStatementsString($$) << "\n\n";
			symbolTable->printAllScopeTable();
			symbolTable->exitScope();
		}
		| LCURL RCURL {
			$$ = new vector<SymbolInfo*>();
			$$->push_back(new SymbolInfo("{", ""));
			$$->push_back(new SymbolInfo("}", ""));
			cout << "Line " << yylineno << ": compound_statement : LCURL RCURL\n\n";
			cout << makeStatementsString($$);
			symbolTable->printAllScopeTable();
			symbolTable->exitScope();
		}
		;

var_declaration : 
		type_specifier declaration_list SEMICOLON {
			string name = $1[0] + " ";
			if($1[0] == "void") {
				errorCount++;
				printErr("Variable type can't be void");
				for(auto a : *$2) {
					a->setIdType($1[0]);
					if(a->getSize() > 0){
						name = name + a->getName() + "[" + to_string(a->getSize()) + "],";
					}
					else {
						name = name + a->getName() + ",";
					}

				}

				name.pop_back();
				name += ";";
			}
			else{
				for(auto a : *$2) {
					a->setIdType($1[0]);
					if(!symbolTable->insert(a)){
						errorCount++;
						printErr("Multiple declaration of " + a->getName());
					}
					if(a->getSize() > 0){
						name = name + a->getName() + "[" + to_string(a->getSize()) + "],";
					}
					else {
						name = name + a->getName() + ",";
					}

				}
				name.pop_back();
				name += ";";
			}

			cout << "Line " << yylineno << ": var_declaration : type_specifier declaration_list SEMICOLON\n\n";
			$$ = new SymbolInfo(name, $1[0], $1[0]);
			cout << $$->getName() << "\n\n";
		}
		| type_specifier declaration_list error SEMICOLON {
			errorCount++;
			string name = $1[0] + " ";
			if($1[0] == "void") {
				errorCount++;
				printErr("Variable type can't be void");
				for(auto a : *$2) {
					a->setIdType($1[0]);
					if(a->getSize() > 0){
						name = name + a->getName() + "[" + to_string(a->getSize()) + "],";
					}
					else {
						name = name + a->getName() + ",";
					}

				}

				name.pop_back();
				name += ";";
			}
			else{
				for(auto a : *$2) {
					a->setIdType($1[0]);
					if(!symbolTable->insert(a)){
						errorCount++;
						printErr("Multiple declaration of " + a->getName());
					}
					if(a->getSize() > 0){
						name = name + a->getName() + "[" + to_string(a->getSize()) + "],";
					}
					else {
						name = name + a->getName() + ",";
					}

				}
				name.pop_back();
				name += ";";
			}

			cout << "Line " << yylineno << ": var_declaration : type_specifier declaration_list SEMICOLON\n\n";
			$$ = new SymbolInfo(name, $1[0], $1[0]);
			cout << $$->getName() << "\n\n";
		}
 		;

type_specifier : 
		INT{
			cout << "Line " << yylineno << ": type_specifier : INT\n\nint\n\n";
		}
 		| FLOAT{
			cout << "Line " << yylineno << ": type_specifier : FLOAT\n\nfloat\n\n";
		}
 		| VOID{
			cout << "Line " << yylineno << ": type_specifier : VOID\n\nvoid\n\n";
		}
 		;
			
declaration_list : 
		declaration_list COMMA ID {
			$$ = $1;
			$$->push_back($3);
			cout << "Line " << yylineno << ": declaration_list : declaration_list COMMA ID \n\n"; 
			cout << makeDecListString($$);
			cout << "\n\n";
		}
		| declaration_list ID {
			if(!isErr){
				printErr("Stntax error");
				errorCount++;
			}
			else {
				isErr = false;
			}
			$$ = $1;
			$$->push_back($2);
			cout << "Line " << yylineno << ": declaration_list : declaration_list COMMA ID \n\n"; 
			cout << makeDecListString($$);
			cout << "\n\n";
		}
 	  	| declaration_list COMMA ID LTHIRD CONST_INT RTHIRD {
			$$ = $1;
			$3->setSize( stoi($5->getName()));
			$$->push_back($3);
			cout << "Line " << yylineno << ": declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD \n\n"; 
			cout << makeDecListString($$);
			cout << "\n\n";
	  	}
		| declaration_list ID LTHIRD CONST_INT RTHIRD {
			if(!isErr){
				printErr("Stntax error");
				errorCount++;
			}
			else {
				isErr = false;
			}
			$$ = $1;
			$2->setSize( stoi($4->getName()));
			$$->push_back($2);
			cout << "Line " << yylineno << ": declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD \n\n"; 
			cout << makeDecListString($$);
			cout << "\n\n";
	  	}
		| declaration_list error COMMA {
			yyerrok;
			isErr = true;
			errorCount++;
			$$ = $1;
		}
 	  	| ID { 
			$$ = new vector<SymbolInfo*>();
			$$->push_back($1);
			cout << "Line " << yylineno << ": declaration_list : ID \n\n"; 
			cout << $1->getName() << "\n\n";
		}
		| ID LTHIRD CONST_INT RTHIRD {
			$$ = new vector<SymbolInfo*>();
			$1->setSize( stoi($3->getName()));
			$$->push_back($1);
			cout << "Line " << yylineno << ": declaration_list : ID LTHIRD CONST_INT RTHIRD \n\n"; 
			cout << $1->getName() << endl << endl;
	  	}
 	  ;


statements :
		statement {
			$$ = $1;
			cout << "Line " << yylineno << ": statements : statement\n\n";
			cout << makeStatementsString($$) << "\n\n";
		}
		| statements statement {
			$$ = $1;
			$$->insert($$->end(), $2->begin(), $2->end());
			cout << "Line " << yylineno << ": statements : statements statement\n\n";
			cout << makeStatementsString($$) << "\n\n";
		}


statement : 
		var_declaration {
			$$ = new vector<SymbolInfo*>();
			$$->push_back($1); 
			cout << "Line " << yylineno << ": statement : var_declaration\n\n";
			cout << makeStatementsString($$) << "\n\n";
		}
		| expression_statement {
			$$ = new vector<SymbolInfo*>();
			$$->push_back($1); 
			cout << "Line " << yylineno << ": statement : expression_statement\n\n";
			cout << makeStatementsString($$) <<  "\n\n";
		}
		| {symbolTable->enterScope();} compound_statement {
			$$ = $2;
			cout << "Line " << yylineno << ": statement : compound_statement\n\n";
			cout << makeStatementsString($$) << "\n\n";
		}
		| FOR LPAREN expression_statement expression_statement expression RPAREN statement {
			$$ = new vector<SymbolInfo*>();
			$$->push_back(new SymbolInfo("for(" + $3->getName() + $4->getName() + $5->getName() + ")", "for"));
			$$->insert($$->end(), $7->begin(), $7->end());
			cout << "Line " << yylineno << ": statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement\n\n";
			cout << makeStatementsString($$) << "\n\n";
		}
		| IF LPAREN expression RPAREN statement %prec LOWER_PREC_THAN_ELSE{
			$$ = new vector<SymbolInfo*>(); 
			$$->push_back(new SymbolInfo("if (" + $3->getName() + ")", "if"));
			$$->insert($$->end(), $5->begin(), $5->end());
			cout << "Line " << yylineno << ": statement : IF LPAREN expression RPAREN statement\n\n";
			cout << makeStatementsString($$) << "\n\n";
		}
		| IF LPAREN expression RPAREN statement ELSE statement {
			$$ = new vector<SymbolInfo*>(); 
			$$->push_back(new SymbolInfo("if (" + $3->getName() + ")" ,	"if"));
			$$->insert($$->end(), $5->begin(), $5->end());
			$$->push_back(new SymbolInfo("else", "else"));
			$$->insert($$->end(), $7->begin(), $7->end());
			cout << "Line " << yylineno << ": statement : IF LPAREN expression RPAREN statement ELSE statement\n\n";
			cout << makeStatementsString($$) << "\n\n";
		}
		| WHILE LPAREN expression RPAREN statement {
			$$ = new vector<SymbolInfo*>(); 
			$$->push_back(new SymbolInfo("while (" + $3->getName() + ")", "while"));
			$$->insert($$->end(), $5->begin(), $5->end());
			cout << "Line " << yylineno << ": statement : WHILE LPAREN expression RPAREN statement\n\n";
			cout << makeStatementsString($$) << "\n\n";
		}
		| PRINTLN LPAREN ID RPAREN SEMICOLON {
			$$ = new vector<SymbolInfo*>(); 
			$$->push_back(new SymbolInfo("printf(" + $3->getName() + ");", "printf"));
			SymbolInfo* id = symbolTable->lookup($3->getName());
			if(id == nullptr){
				errorCount++;
				printErr("Undeclared variable " + $3->getName());
			}
			else {
				if(id->getSize() != ISVAR){
					errorCount++;
				printErr($3->getName() + " is not a variable");
				}
			}
			cout << "Line " << yylineno << ": statement : PRINTLN LPAREN ID RPAREN SEMICOLON\n\n";
			cout << makeStatementsString($$) << "\n\n";
		}
		| RETURN expression SEMICOLON {
			$$ = new vector<SymbolInfo*>();
			$$->push_back(new SymbolInfo("return " + $2->getName() + ";", "return", $2->getIdType()));
			if(retType == "void") {
				printErr("Void function can't have return statement");
			}
			cout << "Line " << yylineno << ": statement : RETURN expression SEMICOLON\n\n";
			cout << makeStatementsString($$) << "\n\n";
		}
		;
expression_statement : 
		SEMICOLON{
			$$ = new SymbolInfo(";", "");
			cout << "Line " << yylineno << ": expression_statement : SEMICOLON\n\n";
			cout << $$->getName() << "\n\n";
		}
		| expression SEMICOLON {
			$$ = new SymbolInfo($1->getName() + ";", $1->getType(), $1->getIdType());
			cout << "Line " << yylineno << ": expression_statement : expression SEMICOLON\n\n";
			cout << $$->getName() << "\n\n";
		}


variable :
		ID {
			SymbolInfo* id = symbolTable->lookup($1->getName());
			if(id == nullptr){
				errorCount++;
				printErr("Undeclared variable " + $1->getName());
				$$ = new SymbolInfo($1->getName(), "ERROR");
				
			}
			else {
				$$ = new SymbolInfo(id->getName(), id->getType(), id->getIdType());
				$$->setSize(id->getSize());
			}
			cout << "Line " << yylineno << ": variable : ID\n\n";
			cout << $$->getName() << "\n\n";
		}
		| ID LTHIRD expression RTHIRD {
			SymbolInfo* id = symbolTable->lookup($1->getName());

			if(id == nullptr){
				errorCount++;
				printErr("Undeclared variable " + $1->getName());
				$$ = new SymbolInfo($1->getName() + "[" + $3->getName() + "]", "ERROR");
			}
			else if(id->getSize() < 0){
				errorCount++;
				printErr($1->getName() + " is not an array");
				$$ = new SymbolInfo(id->getName() + "[" + $3->getName() + "]", "ERROR");
			}
			else {
				if($3->getIdType() != "int"){
					errorCount++;
					printErr("Expression inside third brackets is not an integer");
					$$ = new SymbolInfo(id->getName() + "[" + $3->getName() + "]", id->getType(), id->getIdType());
				}
				else{
					if($3->getName().at(0) == '-'){
						errorCount++;
						printErr("Index can't be negative");
						$$ = new SymbolInfo(id->getName() + "[" + $3->getName() + "]", id->getType(), id->getIdType());
					}
					else
						$$ = new SymbolInfo(id->getName() + "[" + $3->getName() + "]", id->getType(), id->getIdType());
				}
			}
			cout << "Line " << yylineno << ": variable : ID LTHIRD expression RTHIRD\n\n";
			cout << $$->getName() << "\n\n";

		}
		;

expression :
		logic_expression {
			cout << "Line " << yylineno << ": expression : logic_expression\n\n";
			if($1->getIdType() == "void"){
				errorCount++;
				if($1->getType() == "function"){
					printErr("Void function used in expression");
				}
				$1->setType("ERROR");
			}
			$$ = $1;
			cout << $$->getName() << "\n\n";
		}
		| variable ASSIGNOP logic_expression {
			string left = $1->getIdType();
			string right = $3->getIdType();
			if($1->getSize() > 0){
				errorCount++;
				printErr("Type mismatch, " + $1->getName() + " is an array");
			}
			else if($3->getSize() > 0){
				errorCount++;
				printErr("Type mismatch, " + $3->getName() + " is an array");
			}
			else if(left == "int" && right == "float"){
				errorCount++;
				printErr("Type mismatch");
			}
			else if(right == "void"){
				errorCount++;
				if($3->getType() == "function"){
					printErr("Void function used in expression");
				}
			}
			$$ = new SymbolInfo($1->getName() + "=" + $3->getName(), left);
			cout << "Line " << yylineno << ": expression : variable ASSIGNOP logic_expression\n\n";
			cout << $$->getName() << "\n\n";
		}
		;


logic_expression :
		rel_expression {
			$$ = $1;
			cout << "Line " << yylineno << ": logic_expression : rel_expression\n\n";
			cout << $$->getName() << "\n\n";
		}
		| rel_expression LOGICOP rel_expression {
			string left = $1->getIdType();
			string right = $3->getIdType();
			string resultType = "int";
			if(left != "int" || right != "int"){
				resultType = "ERROR";
				errorCount++;
				printErr("Non int operand in logic_expression");
			}
			$$ = new SymbolInfo($1->getName() + $2[0] + $3->getName(), (left != "int" || right != "int")?"ERROR":"int");
			cout << "Line " << yylineno << ": logic_expression : rel_expression LOGICOP rel_expression\n\n";
			cout << $$->getName() << "\n\n";
		}
		;

rel_expression :
		simple_expression{
			$$ = $1;
			cout << "Line " << yylineno << ": rel_expression : simple_expression\n\n";
			cout << $$->getName() << "\n\n";
		}
		| simple_expression RELOP simple_expression {
			cout << "Line " << yylineno << ": rel_expression : simple_expression RELOP simple_expression\n\n";
			$$ = new SymbolInfo($1->getName() + $2[0] + $3->getName(), "int");
			cout << $$->getName() << "\n\n";
		}
		;

simple_expression :
		term {
			cout << "Line " << yylineno << ": simple_expression : term\n\n";
			$$ = $1;
			cout << $$->getName() << "\n\n";
		}
		| simple_expression ADDOP term {
			string left = $1->getIdType();
			string right = $3->getIdType();
			cout << "Line " << yylineno << ": simple_expression : simple_expression ADDOP term\n\n";
			$$ = new SymbolInfo($1->getName() + $2[0] + $3->getName(), (left == "float" || right == "float")?"float":"int");
			cout << $$->getName() << "\n\n";
		}
		;
term :
		unary_expression{
			$$ = $1;
			cout << "Line " << yylineno << ": term : unary_expression\n\n";
			cout << $$->getName() << "\n\n";
		}
		| term MULOP unary_expression{
			string left = $1->getIdType();
			string right = $3->getIdType();
			string resultType;
			if($2[0] == "%"){
				if(left != "int" || right != "int"){
					errorCount++;
					printErr("Non-Integer operand on modulus operator");
					resultType = "ERROR";
				}
				else{
					if($3->getName() == "0"){
						errorCount++;
						printErr("Division by 0");
						resultType = "ERROR";
					}
					else {
						resultType = "int";
					}
				}
			}
			else if($2[0] == "/"){
				if($3->getName() == "0"){
					errorCount++;
					printErr("Division by 0");
					resultType = "ERROR";
				}
				else {
					resultType = (left == "float" || right == "float")?"float":"int";
				}
			}
			else{
				resultType = (left == "float" || right == "float")?"float":"int";
			}


			$$ = new SymbolInfo($1->getName() + $2[0] + $3->getName(), resultType);
			cout << "Line " << yylineno << ": term : term MULOP unary_expression\n\n";
			cout << $$->getName() << "\n\n";
		}

unary_expression :
		ADDOP unary_expression{
			$$ = new SymbolInfo($1[0] + $2->getName(), $2->getType(), $2->getIdType());
			cout << "Line " << yylineno << ": unary_expression : ADDOP unary_expression\n\n";
			cout << $$->getName() << "\n\n";
		}
		| NOT unary_expression{
			$$ = new SymbolInfo("!" + $2->getName(), $2->getType(), $2->getIdType());
			cout << "Line " << yylineno << ": unary_expression : NOT unary_expression\n\n";
			cout << $$->getName() << "\n\n";
		}
		| factor{
			$$ = $1;
			cout << "Line " << yylineno << ": unary_expression : factor\n\n";
			cout << $$->getName() << "\n\n";
		}
		;

factor : 
		variable{
			$$ = $1;
			cout << "Line " << yylineno << ": factor : variable\n\n";
			cout << $$->getName() << "\n\n";
		}
		| ID LPAREN argument_list RPAREN {
			SymbolInfo* id = symbolTable->lookup($1->getName());
			string retType;
			if(id == nullptr){
				errorCount++;
				printErr("Undeclared function " + $1->getName());
				retType = "ERROR";
			}
			else{
				if(id->getSize() == ISFUNC || id->getSize() == ISFUNCDEF){
					retType = id->getIdType();
					vector<SymbolInfo*>* paramList = id->getParamList();
					if(paramList->size() != $3->size()){
						errorCount++;
						printErr("Total number of arguments mismatch with declaration in function " + id->getName());
					}
					else {
						for(int i = 0; i < paramList->size(); i++){
							if(paramList->at(i)->getIdType() != $3->at(i)->getIdType()){
								errorCount++;
								printErr(to_string(i + 1) + "th argument mismatch in function " + id->getName());
								printErr($3->at(i)->getIdType());
							}
							else if($3->at(i)->getSize() != ISVAR){
								if($3->at(i)->getSize() == ISFUNC || $3->at(i)->getSize() == ISFUNCDEF){
									errorCount++;
									printErr("Type mismatch, " + $3->at(i)->getName() + " is a function");
								}
								else{
									errorCount++;
									printErr("Type mismatch, " + $3->at(i)->getName() + " is an array");
								}
							}
						}
					}
				}
			}
			$$ = new SymbolInfo($1->getName() + "(" + makeArgListString($3) + ")", "function", retType);

			cout << "Line " << yylineno << ": factor : ID LPAREN argument_list RPAREN \n\n";
			cout << $$->getName() << "\n\n";
		}
		| LPAREN expression RPAREN {
			$$ = new SymbolInfo("(" + $2->getName() + ")" , $2->getType(), $2->getIdType());
			cout << "Line " << yylineno << ": factor : LPAREN expression RPAREN\n\n";
			cout << $$->getName() << "\n\n";

		}
		| CONST_INT {
			$$ = $1;
			$$->setIdType("int");
			cout << "Line " << yylineno << ": factor : CONST_INT\n\n";
			cout << $$->getName() << "\n\n";
		}
		| CONST_FLOAT {
			$$ = $1;
			$$->setIdType("float");
			cout << "Line " << yylineno << ": factor : CONST_FLOAT\n\n";
			cout << $$->getName() << "\n\n";
		}
		| variable INCOP{
			$$ = new SymbolInfo($1->getName() + "++", $1->getType(), $1->getIdType());
			cout << "Line " << yylineno << ": factor : variable INCOP\n\n";
			cout << $$->getName() << "\n\n";
		}
		| variable DECOP{
			$$ = new SymbolInfo($1->getName() + "--", $1->getType(), $1->getIdType());
			cout << "Line " << yylineno << ": factor : variable DECOP\n\n";
			cout << $$->getName() << "\n\n";
		}
		;

arguments :
		arguments COMMA logic_expression {
			$$ = $1;
			$$->push_back($3);
			cout << "Line " << yylineno << ": arguments : arguments COMMA logic_expression\n\n";
			cout << makeArgListString($$);
			cout << "\n\n";
		}
		| logic_expression {
			$$ = new vector<SymbolInfo*>();
			$$->push_back($1);
			cout << "Line " << yylineno << ": arguments : logic_expression\n\n";
			cout << makeArgListString($$);
			cout << "\n\n";
		}
		;

argument_list :
		arguments {
			$$ = $1;
			cout << "Line " << yylineno << ": argument_list : arguments\n\n";
			cout << makeArgListString($$);
			cout << "\n\n";
		}
		| {
			$$ = new vector<SymbolInfo*>();
			cout << "Line " << yylineno << ": argument_list : \n\n";
		}
		;
%%

int main(int argc,char *argv[]) {

	if((fp=fopen(argv[1],"r"))==NULL)
	{
		printf("Cannot Open Input File.\n");
		exit(1);
	}

	freopen("1805089_log.txt", "w", stdout);
	errOut.open("1805089_error.txt");

	yyin=fp;
	yyparse();
	

	
	return 0;
}

