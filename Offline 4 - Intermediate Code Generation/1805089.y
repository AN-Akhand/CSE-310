%{
#include<iostream>
#include<cstdlib>
#include<cstring>
#include<cmath>
#include<vector>
#include<fstream>
#include<iterator>
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
ofstream logOut;
int offset = 2;
int labelCount = 0;
bool isGlobal = false;
bool isCode = false;

bool isErr = false;
bool isErrEnd = false;
string retType;
int errorCount = 0;
string startLabel;
string endLabel;
string forBodyLabel;
string forUpdateLabel;
vector<string> labels;
vector<int> offsets;
string currFunc;

string lbl1;
string lbl2;

SymbolTable *symbolTable = new SymbolTable(7);

void printErr(string message);

void yyerror(const char *s){
	printErr(s);
}

string makeLabel(){
	return "label" + to_string(labelCount++);
}

bool isIdInList(vector<SymbolInfo*>* v, SymbolInfo* s){
	for(auto a : *v){
		if(a->getName() == s->getName()){
			return true;
		}
	}
	return false;
}

vector<string> tokenize(string s, string del) {
	vector<string> temp;
    int start = 0;
    int end = s.find(del);
    while (end != -1) {
		temp.push_back(s.substr(start, end - start));
        start = end + del.size();
        end = s.find(del, start);
    }
    temp.push_back(s.substr(start, end - start));
	return temp;
}

void printErr(string message){
	errOut << "Error at line " << yylineno << ": " << message <<"\n\n";
	isErrEnd = true;
	//logOut << "Error at line " << yylineno << ": " << message <<"\n\n";
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

void optimize(){
	ifstream oin;
	oin.open("code.asm");
	string s;
	vector<string> code;
	getline(oin, s);
	code.push_back(s);
	getline(oin, s);
	code.push_back(s);
	getline(oin, s);
	code.push_back(s);
    getline(oin, s);
	code.push_back(s);
    while(1){
        auto i = code.end();
        if(*(i - 1) == "POP SI"){
			auto j = i;
            while(*(j - 1) != ".CODE"){
				j--;
				if(((j - 1)[0].rfind("MOV SI", 0) == 0) || 
					((j - 1)[0].rfind("ADD SI", 0) == 0) ||
					((j - 1)[0].rfind("SUB SI", 0) == 0) ||
					((j - 1)[0].rfind("LEA SI", 0) == 0) ||
					((j - 1)[0].rfind("CALL", 0) == 0)) {
						break;
					}
				else if((j - 1)[0] == "PUSH SI"){
					code.erase(i - 1);
					code.erase(j - 1);
					break;
				}
			}
        }
		else if(*(i - 1) == "POP BX"){
            if(*(i - 3) == "PUSH AX" && (i - 4)[0].rfind("MOV AX", 0) == 0){
                (i - 4)[0][4] = 'B';
                code.erase(i - 3);
				code.erase(i - 1);
            }
        }
		else if((i - 1)[0].rfind("ADD", 0) == 0 || (i - 1)[0].rfind("SUB", 0) == 0){
			if((i - 1)[0][(i - 1)[0].size() - 1] == '0'){
				code.erase(i - 1);
			}
		}
		else if((i - 1)[0].rfind("MOV", 0) == 0 && (i - 2)[0].rfind("MOV", 0) == 0){ 
			auto temp1 = tokenize((i - 1)[0], ",");
			auto temp2 = tokenize((i - 2)[0], ",");
			if(temp1.at(0) == "MOV" + temp2.at(1) && "MOV" + temp1.at(1) == temp2.at(0)){
				code.erase(i - 1);
			}
		}
		if(oin.eof()){
			break;
		}
        getline(oin, s);
        code.push_back(s);
        if(s == "END MAIN"){
            break;
        }
    }
    ofstream output_file("./optimized_code.asm");
    ostream_iterator<string> output_iterator(output_file, "\n");
    copy(code.begin(), code.end(), output_iterator);
}


%}

%define parse.error verbose

%union {
    SymbolInfo* symbolInfo;
	string* type;
	vector<SymbolInfo*>* list;
}

%token IF ELSE FOR WHILE DO INT FLOAT DOUBLE CHAR VOID SWITCH DEFAULT BREAK RETURN CASE CONTINUE
%token LCURL RCURL LPAREN RPAREN COMMA SEMICOLON LTHIRD RTHIRD
%token ASSIGNOP INCOP DECOP NOT 
%token PRINTLN
%token<symbolInfo> ID CONST_INT CONST_FLOAT CONST_CHAR
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
		{
			logOut << ".MODEL SMALL\n.STACK 100H \n\nCR EQU 0DH\nLF EQU 0AH\n\n.DATA\n\n";
		}
		 program {
			//logOut << "Line " << yylineno << ": start : program\n\n";
			//symbolTable->printAllScopeTable();

			//logOut << "Total lines: " << yylineno << endl;
			//logOut << "Total errors: " << errorCount << "\n\n";
			logOut << "\nPRINT_INT PROC\
						\n\n\tOR AX, AX\
						\n\tJGE END_IF1\
						\n\tPUSH AX\
						\n\tMOV DL,'-'\
						\n\tMOV AH, 2\
						\n\tINT 21H\
						\n\tPOP AX\
						\n\tNEG AX\
						\n\nEND_IF1:\
						\n\tXOR CX, CX\
						\n\tMOV BX, 10D\
						\n\nREPEAT1:\
						\n\tXOR DX, DX\
						\n\tDIV BX\
						\n\tPUSH DX\
						\n\tINC CX\
						\n\n\tOR AX, AX\
						\n\tJNE REPEAT1\
						\n\n\tMOV AH, 2\
						\n\nPRINT_LOOP:\
						\n\tPOP DX\
						\n\tOR DL, 30H\
						\n\tINT 21H\
						\n\tLOOP PRINT_LOOP\
						\n\tMOV AH, 2\
						\n\tMOV DL, 10\
						\n\tINT 21H\
						\n\n\tMOV DL, 13\
						\n\tINT 21H\
						\n\tRET\
						\nPRINT_INT ENDP\n\n";
			logOut << "END MAIN";
		}


program :
		program unit {
			$$ = new SymbolInfo($1->getName() + "\n" + $2->getName(), "program");
			//logOut << "Line " << yylineno << ": program : program unit\n\n";
			//logOut << $$->getName() << "\n\n\n";
		}
		| unit {
			$$ = $1;
			//logOut << "Line " << yylineno << ": program : unit\n\n";
			//logOut << $$->getName() << "\n\n\n";
		}



unit :
		var_declaration {
			$$ = $1;
			//logOut << "Line " << yylineno << ": unit : var_declaration\n\n";
			//logOut << $$->getName() << "\n\n\n";
		}
		| func_declaration {
			$$ = $1;
			//logOut << "Line " << yylineno << ": unit : func_declaration\n\n";
			//logOut << $$->getName() << "\n\n\n";
		}
		| func_definition {
			$$ = $1;
			//logOut << "Line " << yylineno << ": unit : func_definition\n\n";
			//logOut << $$->getName() << "\n\n\n";
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
			//logOut << "Line " << yylineno << ": func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON\n\n";
			//logOut << $$->getName() << "\n\n\n";
		}
		| type_specifier ID LPAREN parameter_list error RPAREN SEMICOLON {

			//errors like int foo(int-);
			yyerrok;
			errorCount++;
			//logOut << makeParamListString($4) << "\n\n";
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
			//logOut << "Line " << yylineno << ": func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON\n\n";
			//logOut << $$->getName() << "\n\n\n";
		}
		| type_specifier ID LPAREN RPAREN SEMICOLON {
			//logOut << "Line " << yylineno << ": func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON\n\n";
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
			//logOut << $$->getName() << "\n\n\n";
		}
		;

func_definition : 
		type_specifier ID LPAREN parameter_list RPAREN {
			currFunc = $2->getName();
			if(!isCode){
				logOut << ".CODE\n\n";
				isCode = true;
			}
			logOut << ";" <<$1[0] + " " + $2->getName() + "(" + makeParamListString($4) + ")\n"; 
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
			offsets.push_back(offset);
			offset = 2;
			logOut << $2->getName() << " PROC\n";

			for(int i = $4->size() - 1; i >= 0; i--){
				SymbolInfo* var = $4->at(i);
				if(var->getName() == ""){
					errorCount++;
					printErr(to_string(i + 1) + "th parameter's name not given in function definition of " + $2->getName());
					continue;
				}
				var->setOffset(-offset);
				offset += 2;
				if(!symbolTable->insert(var)){
					errorCount++;
					printErr("Multiple declaration of " + var->getName());
				}
			}

			offset = 2;

		} compound_statement {
			//logOut << "Line " << yylineno << ": func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement\n\n";
			$$ = new SymbolInfo($1[0] + " " + $2->getName() + "(" + makeParamListString($4) + ")" + makeStatementsString($7), "func_def");
			//logOut << $$->getName() << "\n\n";
			logOut << "MOV SP, BP\n";
			logOut << "RET\n";
			logOut << $2->getName() << " ENDP\n";
			offset = offsets.back();
			offsets.pop_back();
		}
		| type_specifier ID LPAREN parameter_list error RPAREN{

			//errors like int foo(int-){}
			yyerrok;
			errorCount++;
			//logOut << makeParamListString($4) << "\n\n";
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
			//logOut << "Line " << yylineno << ": func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement\n\n";
			$$ = new SymbolInfo($1[0] + " " + $2->getName() + "(" + makeParamListString($4) + ")" + makeStatementsString($8), "func_def");
			//logOut << $$->getName() << "\n\n";
		} | type_specifier ID LPAREN RPAREN {
			currFunc = $2->getName();
			if(!isCode){
				logOut << ".CODE\n\n";
				isCode = true;
			}

			logOut << ";" << $1[0] + " " + $2->getName() + "()\n";

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
			offsets.push_back(offset);
			offset = 2;
			logOut << "\n\n" << $2->getName() << " PROC\n";
			if($2->getName() == "main"){
				logOut << "MOV AX, @DATA\nMOV DS, AX\n\n";
				logOut << "PUSH BP\nMOV BP, SP\n\n";
				offset = 2;
			}
		} compound_statement {
			//logOut << "Line " << yylineno << ": func_definition : type_specifier ID LPAREN RPAREN compound_statement\n\n";
			$$ = new SymbolInfo($1[0] + " " + $2->getName() + "()" + makeStatementsString($6), "func_def");
			//logOut << $$->getName() << "\n\n";
			logOut << "MOV SP, BP\n";
			if($2->getName() == "main"){
				logOut << "MOV AH, 4CH\nINT 21H\n";
			}
			else{
				logOut << "RET\n";
			}
			logOut << $2->getName() << " ENDP\n\n\n";
			offset = offsets.back();
			offsets.pop_back();
		}
		;


parameter_list : 
		parameter_list COMMA type_specifier ID {
			//logOut << "Line " << yylineno << ": parameter_list : parameter_list COMMA type_specifier ID\n\n";
			$$ = $1;
			if(isIdInList($$, $4)){
				errorCount++;
				printErr("Multiple declaration of " + $4->getName() + " in parameter");
			}
			$4->setIdType($3[0]);
			$$->push_back($4);
			//logOut << makeParamListString($$);
			//logOut << "\n\n";
		}
		| parameter_list COMMA type_specifier {
			//logOut << "Line " << yylineno << ": parameter_list : parameter_list COMMA type_specifier\n\n";
			$$ = $1;
			SymbolInfo* param = new SymbolInfo($3[0], "");
			$$->push_back(param);
			//logOut << makeParamListString($$);
			//logOut << "\n\n";
		}
		| type_specifier ID {
			//logOut << "Line " << yylineno << ": parameter_list : type_specifier ID\n\n";
			$$ = new vector<SymbolInfo*>();
			$2->setIdType($1[0]);
			$$->push_back($2);
			//logOut << makeParamListString($$);
			//logOut << "\n\n";
		}		
		| type_specifier {
			//logOut << "Line " << yylineno << ": parameter_list : type_specifier\n\n";
			$$ = new vector<SymbolInfo*>();
			SymbolInfo* param = new SymbolInfo("", $1[0]);
			$$->push_back(param);
			//logOut << makeParamListString($$);
			//logOut << "\n\n";
		}
		;


compound_statement :
		LCURL statements RCURL {
			$$ = $2;
			$$->push_back(new SymbolInfo("}", ""));
			$$->insert($$->begin(),new SymbolInfo("{", ""));
			//logOut << "Line " << yylineno << ": compound_statement : LCURL statements RCURL\n\n";
			//logOut << makeStatementsString($$) << "\n\n";
			//symbolTable->printAllScopeTable();
			symbolTable->exitScope();
		}
		| LCURL statements expression error RCURL{
			
			//error in last line of compound statement

			yyerrok;
			errorCount++;

			$$ = $2;
			$3->setName($3->getName() + ";");
			$$->push_back($3);
			$$->push_back(new SymbolInfo("}", ""));
			$$->insert($$->begin(),new SymbolInfo("{", ""));
			//logOut << "Line " << yylineno << ": compound_statement : LCURL statements RCURL\n\n";
			//logOut << makeStatementsString($$) << "\n\n";
			//symbolTable->printAllScopeTable();
			symbolTable->exitScope();
		}
		| LCURL expression error RCURL{
			
			//error in compound statement that has only one statement

			yyerrok;
			errorCount++;

			$$ = new vector<SymbolInfo*>();
			$2->setName($2->getName() + ";");
			$$->push_back($2);
			$$->push_back(new SymbolInfo("}", ""));
			$$->insert($$->begin(),new SymbolInfo("{", ""));
			//logOut << "Line " << yylineno << ": compound_statement : LCURL statements RCURL\n\n";
			//logOut << makeStatementsString($$) << "\n\n";
			//symbolTable->printAllScopeTable();
			symbolTable->exitScope();
		}
		| LCURL RCURL {
			$$ = new vector<SymbolInfo*>();
			$$->push_back(new SymbolInfo("{", ""));
			$$->push_back(new SymbolInfo("}", ""));
			//logOut << "Line " << yylineno << ": compound_statement : LCURL RCURL\n\n";
			//logOut << makeStatementsString($$);
			//symbolTable->printAllScopeTable();
			symbolTable->exitScope();
		}
		;

var_declaration : 
		type_specifier declaration_list SEMICOLON {
			string name = $1[0] + " ";
			if($1[0] == "void") {
				errorCount++;
				printErr("Variable type cannot be void");
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
				logOut << ";" + $$->getName() << "\n";
				name += ";";
			}
			else{
				for(auto a : *$2) {
					if(a->getSize() > 0){
						name = name + a->getName() + "[" + to_string(a->getSize()) + "],";
					}
					else {
						name = name + a->getName() + ",";
					}

				}
				name.pop_back();
				logOut << ";" + name << "\n";
				name += ";";
			}

			$$ = new SymbolInfo(name, $1[0], $1[0]);
		}
		| type_specifier declaration_list error SEMICOLON {
			//logOut << "Line " << yylineno << ": var_declaration : type_specifier declaration_list SEMICOLON\n\n";

			//errors like int a, b, ;
			yyerrok;
			errorCount++;
			string name = $1[0] + " ";
			if($1[0] == "void") {
				errorCount++;
				printErr("Variable type cannot be void");
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

			$$ = new SymbolInfo(name, $1[0], $1[0]);
			//logOut << $$->getName() << "\n\n";
		}
 		;

type_specifier : 
		INT{
			//logOut << "Line " << yylineno << ": type_specifier : INT\n\nint\n\n";
		}
 		| FLOAT{
			//logOut << "Line " << yylineno << ": type_specifier : FLOAT\n\nfloat\n\n";
		}
 		| VOID{
			//logOut << "Line " << yylineno << ": type_specifier : VOID\n\nvoid\n\n";
		}
 		;
			
declaration_list : 
		declaration_list COMMA ID {
			$$ = $1;
			$$->push_back($3);
			$3->setIdType($<type>0[0]);
			if(symbolTable->getCurrentScopeId() == "1"){
				$3->isGlobal = true;
				logOut << $3->getName() << " DW ?\n";
			}
			else{
				$3->setOffset(offset);
				offset+=2;
				logOut << "PUSH 0\n";
			}
			if(!symbolTable->insert($3)){
				printErr("Multiple declaration of " + $3->getName());
			}
			//logOut << "Line " << yylineno << ": declaration_list : declaration_list COMMA ID \n\n"; 
			//logOut << makeDecListString($$);
			//logOut << "\n\n";
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
			//logOut << "Line " << yylineno << ": declaration_list : declaration_list COMMA ID \n\n"; 
			//logOut << makeDecListString($$);
			//logOut << "\n\n";
		}
 	  	| declaration_list COMMA ID LTHIRD CONST_INT RTHIRD {
			$$ = $1;
			$$->push_back($3);
			int size = stoi($5->getName());
			$3->setSize(size);
			$3->setIdType($<type>0[0]);
			if(symbolTable->getCurrentScopeId() == "1"){
				$3->isGlobal = true;	
				logOut << $3->getName() << " DW " << size <<" DUP(?)\n";
			}
			else {
				$3->setOffset(offset);
				offset += size * 2;
				for(int i = 0; i < size; i++)
					logOut << "PUSH 0\n";
			}
			if(!symbolTable->insert($3)){
				printErr("Multiple declaration of " + $3->getName());
			}
			//logOut << "Line " << yylineno << ": declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD \n\n"; 
			//logOut << makeDecListString($$);
			//logOut << "\n\n";
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
			//logOut << "Line " << yylineno << ": declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD \n\n"; 
			//logOut << makeDecListString($$);
			//logOut << "\n\n";
	  	}
		| declaration_list error COMMA {

			//errors like int x-y, z;

			yyerrok;
			isErr = true;
			errorCount++;
			$$ = $1;
		}
 	  	| ID { 
			$$ = new vector<SymbolInfo*>();
			$$->push_back($1);
			$1->setIdType($<type>0[0]);
			if(symbolTable->getCurrentScopeId() == "1"){
				$1->isGlobal = true;
				logOut << $1->getName() << " DW ?\n";
			}
			else{
				$1->setOffset(offset);
				offset+=2;
				logOut << "PUSH 0\n";
			}
			
			if(!symbolTable->insert($1)){
				printErr("Multiple declaration of " + $1->getName());
			}
			//logOut << "Line " << yylineno << ": declaration_list : ID \n\n"; 
			//logOut << $1->getName() << "\n\n";
		}
		| ID LTHIRD CONST_INT RTHIRD {
			$$ = new vector<SymbolInfo*>();
			$$->push_back($1);
			int size = stoi($3->getName());
			$1->setSize(size);
			$1->setIdType($<type>0[0]);
			if(symbolTable->getCurrentScopeId() == "1"){
				$1->isGlobal = true;
				logOut << $1->getName() << " DW " << size <<" DUP(?)\n";
			}
			else {
				$1->setOffset(offset);
				offset += size * 2;
				for(int i = 0; i < size; i++)
					logOut << "PUSH 0\n";
			}
			
			if(!symbolTable->insert($1)){
				printErr("Multiple declaration of " + $1->getName());
			}
			//logOut << "Line " << yylineno << ": declaration_list : ID LTHIRD CONST_INT RTHIRD \n\n"; 
			//logOut << makeDecListString($$) << "\n\n";
	  	}
 	  ;


statements :
		statement {
			$$ = $1;
			//logOut << "Line " << yylineno << ": statements : statement\n\n";
			//logOut << makeStatementsString($$) << "\n\n";
		}
		| statements statement {
			$$ = $1;
			$$->insert($$->end(), $2->begin(), $2->end());
			//logOut << "Line " << yylineno << ": statements : statements statement\n\n";
			//logOut << makeStatementsString($$) << "\n\n";
		}


statement : 
		var_declaration {
			$$ = new vector<SymbolInfo*>();
			$$->push_back($1); 
			//logOut << "Line " << yylineno << ": statement : var_declaration\n\n";
			//logOut << makeStatementsString($$) << "\n\n";
		}
		| expression_statement {
			$$ = new vector<SymbolInfo*>();
			$$->push_back($1); 
			//logOut << "Line " << yylineno << ": statement : expression_statement\n\n";
			//logOut << makeStatementsString($$) <<  "\n\n";
		}
		| {symbolTable->enterScope();} compound_statement {
			$$ = $2;
			//logOut << "Line " << yylineno << ": statement : compound_statement\n\n";
			//logOut << makeStatementsString($$) << "\n\n";
		}
		| FOR LPAREN expression_statement {
			startLabel = makeLabel(); 
			endLabel = makeLabel();
			forBodyLabel = makeLabel();
			forUpdateLabel = makeLabel();
			labels.push_back(endLabel);
			labels.push_back(forUpdateLabel);
			logOut << startLabel << ":\n";
		} 
		expression_statement {
			logOut << "CMP AX, 0\n";
			logOut << "JE " <<  endLabel << endl;
			logOut << "JMP " << forBodyLabel << endl;
			logOut << forUpdateLabel << ":\n";
		} 
		expression {logOut << "JMP " << startLabel << endl;} RPAREN {
			logOut << forBodyLabel << ":\n";logOut << ";for(" + $3->getName() + $5->getName() + $7->getName() + ")\n";
		} statement {
			$$ = new vector<SymbolInfo*>();
			$$->push_back(new SymbolInfo("for(" + $3->getName() + $5->getName() + $7->getName() + ")", "for"));
			$$->insert($$->end(), $11->begin(), $11->end());
			logOut << "JMP " << labels.back() << endl;
			labels.pop_back();
			logOut << labels.back() << ":\n";
			labels.pop_back();
			//logOut << "Line " << yylineno << ": statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement\n\n";
			//logOut << makeStatementsString($$) << "\n\n";
		}
		| IF LPAREN expression subroutine RPAREN statement %prec LOWER_PREC_THAN_ELSE {
			vector<string> temp = tokenize(labels.back(), "_");
			$$ = new vector<SymbolInfo*>(); 
			$$->push_back(new SymbolInfo("if (" + $3->getName() + ")", "if"));
			$$->insert($$->end(), $6->begin(), $6->end());
			logOut << temp.at(0) << ":\n";
			labels.pop_back();
			logOut << ";if (" + $3->getName() + ")\n";
			//logOut << "Line " << yylineno << ": statement : IF LPAREN expression RPAREN statement\n\n";
			//logOut << makeStatementsString($$) << "\n\n";
		}
		| IF LPAREN expression subroutine RPAREN statement ELSE {
			logOut << ";if (" + $3->getName() + ")\n";
			vector<string> temp = tokenize(labels.back(), "_");
			logOut << "JMP " << temp.back() << endl;
			logOut << temp.at(0) << ":\n";

		} statement {
			vector<string> temp = tokenize(labels.back(), "_");
			labels.pop_back();
			logOut << ";else\n";
			logOut << temp.back() << ":\n";
			$$ = new vector<SymbolInfo*>(); 
			$$->push_back(new SymbolInfo("if (" + $3->getName() + ")" ,	"if"));
			$$->insert($$->end(), $6->begin(), $6->end());
			$$->push_back(new SymbolInfo("else", "else"));
			$$->insert($$->end(), $9->begin(), $9->end());
			//logOut << "Line " << yylineno << ": statement : IF LPAREN expression RPAREN statement ELSE statement\n\n";
			//logOut << makeStatementsString($$) << "\n\n";
		}
		| WHILE LPAREN {
			startLabel = makeLabel();
			endLabel = makeLabel();
			labels.push_back(endLabel);
			labels.push_back(startLabel);
			logOut << startLabel << ":\n";
		} expression {
			logOut << "CMP AX, 0\n";
			logOut << "JE " <<  endLabel << endl;
			logOut << ";while (" + $4->getName() + ")\n";
		} RPAREN statement {
			$$ = new vector<SymbolInfo*>(); 
			$$->push_back(new SymbolInfo("while (" + $4->getName() + ")", "while"));
			$$->insert($$->end(), $7->begin(), $7->end());
			logOut << "JMP " << labels.back() << endl;
			labels.pop_back();
			logOut << labels.back() << ":\n";
			labels.pop_back();
			//logOut << "Line " << yylineno << ": statement : WHILE LPAREN expression RPAREN statement\n\n";
			//logOut << makeStatementsString($$) << "\n\n";
		}
		| PRINTLN LPAREN ID RPAREN SEMICOLON {
			//logOut << "Line " << yylineno << ": statement : PRINTLN LPAREN ID RPAREN SEMICOLON\n\n";
			$$ = new vector<SymbolInfo*>(); 
			$$->push_back(new SymbolInfo("println(" + $3->getName() + ");", "printf"));
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
				if(id->isGlobal){
					logOut << "LEA SI, " << id->getName() << endl;
					logOut << "MOV AX, [SI]\n";
				}
				else {
					logOut << "MOV AX, [BP - " << id->getOffset() << "]\n";
				}
				logOut << ";println(" + $3->getName() + ")\n";
				logOut << "CALL PRINT_INT\n";
			}
			//logOut << makeStatementsString($$) << "\n\n";
		}
		| RETURN expression SEMICOLON {
			//logOut << "Line " << yylineno << ": statement : RETURN expression SEMICOLON\n\n";
			$$ = new vector<SymbolInfo*>();
			$$->push_back(new SymbolInfo("return " + $2->getName() + ";", "return", $2->getIdType()));
			if(retType == "void") {
				printErr("Void function can't have return statement");
			}
			else if(retType != $2->getIdType()){
				errorCount++;
				printErr("Return type mismatch");
			}
			logOut << ";return " + $2->getName() + "\n";
			if(currFunc != "main"){
				logOut << "MOV SP, BP\nRET\n";
			}
			//logOut << makeStatementsString($$) << "\n\n";
		}
		;

expression_statement : 
		SEMICOLON{
			$$ = new SymbolInfo(";", "");
			//logOut << "Line " << yylineno << ": expression_statement : SEMICOLON\n\n";
			//logOut << $$->getName() << "\n\n";
		}
		| expression SEMICOLON {
			$$ = new SymbolInfo($1->getName() + ";", $1->getType(), $1->getIdType());
			//logOut << "Line " << yylineno << ": expression_statement : expression SEMICOLON\n\n";
			//logOut << $$->getName() << "\n\n";
		}
		| expression error SEMICOLON{

			//panic mode recovery, keeps discarding tokens untill it finds a semicolon

			yyerrok;
			errorCount++;
			$$ = new SymbolInfo($1->getName() + ";", $1->getType(), $1->getIdType());
			//logOut << "Line " << yylineno << ": expression_statement : expression SEMICOLON\n\n";
			//logOut << $$->getName() << "\n\n";
		}
		;

variable :
		ID {

			//logOut << "Line " << yylineno << ": variable : ID\n\n";

			SymbolInfo* id = symbolTable->lookup($1->getName());
			if(id == nullptr){
				errorCount++;
				printErr("Undeclared variable " + $1->getName());
				$$ = new SymbolInfo($1->getName(), "ERROR");
				
			}
			else {
				$$ = new SymbolInfo(id->getName(), id->getType(), id->getIdType());
				$$->setSize(id->getSize());
				if(id->isGlobal){
					isGlobal = true;
					logOut << "LEA SI, " << $1->getName() << endl;
				}
				else {
					isGlobal = false;
					logOut << "MOV SI, " << -1 * id->getOffset() << endl;
				}
			}
			//logOut << $$->getName() << "\n\n";
		}
		| ID LTHIRD expression RTHIRD {

			//logOut << "Line " << yylineno << ": variable : ID LTHIRD expression RTHIRD\n\n";

			SymbolInfo* id = symbolTable->lookup($1->getName());

			if(id == nullptr){
				errorCount++;
				printErr("Undeclared variable " + $1->getName());
				$$ = new SymbolInfo($1->getName() + "[" + $3->getName() + "]", "ERROR");
			}
			else if(id->getSize() < 0){
				errorCount++;
				printErr($1->getName() + " not an array");
				$$ = new SymbolInfo(id->getName() + "[" + $3->getName() + "]", "ERROR");
			}
			else {
				if($3->getIdType() != "int"){
					errorCount++;
					printErr("Expression inside third brackets not an integer");
					$$ = new SymbolInfo(id->getName() + "[" + $3->getName() + "]", id->getType(), id->getIdType());
				}
				else{
					if($3->getName().at(0) == '-'){
						errorCount++;
						printErr("Index can't be negative");
						$$ = new SymbolInfo(id->getName() + "[" + $3->getName() + "]", id->getType(), id->getIdType());
					}
					else{
						if(id->isGlobal){
							logOut << "LEA SI, " << $1->getName() << endl;
							logOut << "SHL AX, 1\n";
							logOut << "ADD SI, AX\n";
							isGlobal = true;
						}
						else {
							logOut << "MOV SI, " << -1 * id->getOffset() << endl;
							logOut << "SHL AX, 1\n";
							logOut << "SUB SI, AX\n";
							isGlobal = false;
						}
						$$ = new SymbolInfo(id->getName() + "[" + $3->getName() + "]", id->getType(), id->getIdType());
					}
				}
			}
			//logOut << $$->getName() << "\n\n";

		}
		;

expression :
		logic_expression {
			//logOut << "Line " << yylineno << ": expression : logic_expression\n\n";
			$$ = $1;
			logOut << ";" << $$->getName() << endl;
		}
		| variable {logOut << "PUSH SI\n";} ASSIGNOP logic_expression {

			logOut << "POP SI\n";
			if(isGlobal)
				logOut << "MOV [SI], AX\n";
			else 
				logOut << "MOV [BP + SI], AX\n";
			//logOut << "Line " << yylineno << ": expression : variable ASSIGNOP logic_expression\n\n";


			string left = $1->getIdType();
			string right = $4->getIdType();
			if($1->getSize() > 0){
				errorCount++;
				printErr("Type Mismatch, " + $1->getName() + " is an array");
			}
			else if($4->getSize() > 0){
				errorCount++;
				printErr("Type Mismatch, " + $4->getName() + " is an array");
			}
			else if(left == "int" && right == "float"){
				errorCount++;
				printErr("Type Mismatch");
			}
			else if(right == "void"){
				errorCount++;
				if($4->getType() == "function"){
					printErr("Void function used in expression");
				}
			}
			$$ = new SymbolInfo($1->getName() + "=" + $4->getName(), left);

			logOut << ";" << $$->getName() << endl;
		}
		;


logic_expression :
		rel_expression {
			$$ = $1;
			//logOut << "Line " << yylineno << ": logic_expression : rel_expression\n\n";
			//logOut << $$->getName() << "\n\n";
		}
		| rel_expression LOGICOP {
			lbl1 = makeLabel();
			lbl2 = makeLabel();
			if($2[0] == "&&"){
				logOut << "CMP AX, 0\nJE " << lbl1 << endl;
			}
			else {
				logOut << "CMP AX, 0\nJNE " << lbl1 << endl;
			}
		} 
		rel_expression {

			if($2[0] == "&&"){
				logOut << "CMP AX, 0\nJE " << lbl1 << "\nMOV AX, 1\n";
				logOut << "JMP " << lbl2 << "\n" << lbl1 << ":\nMOV AX, 0\n" << lbl2 << ":\n";
			}
			else {
				logOut << "CMP AX, 0\nJNE " << lbl1 << "\nMOV AX, 0\n";
				logOut << "JMP " << lbl2 << "\n" << lbl1 << ":\nMOV AX, 1\n" << lbl2 << ":\n";
			}

			//logOut << "Line " << yylineno << ": logic_expression : rel_expression LOGICOP rel_expression\n\n";

			string left = $1->getIdType();
			string right = $4->getIdType();
			string resultType = "int";
			if(left != "int" || right != "int"){
				resultType = "ERROR";
				errorCount++;
				printErr("Non int operand in logic_expression");
			}
			$$ = new SymbolInfo($1->getName() + $2[0] + $4->getName(), (left != "int" || right != "int")?"ERROR":"int");
			//logOut << $$->getName() << "\n\n";
		}
		;

rel_expression :
		simple_expression{
			$$ = $1;
			//logOut << "Line " << yylineno << ": rel_expression : simple_expression\n\n";
			//logOut << $$->getName() << "\n\n";
		}
		| simple_expression RELOP {logOut << "PUSH AX\n";} simple_expression {
			//logOut << "Line " << yylineno << ": rel_expression : simple_expression RELOP simple_expression\n\n";
			string jump;
			if($2[0] == "<"){
				jump = "JL";
			}
			else if($2[0] == "<="){
				jump = "JLE";
			}
			else if($2[0] == "=="){
				jump = "JE";
			}
			else if($2[0] == "!="){
				jump = "JNE";
			}
			else if($2[0] == ">="){
				jump = "JGE";
			}
			else if($2[0] == ">"){
				jump = "JG";
			}
			logOut << "POP BX" <<  endl;
			logOut << "CMP BX, AX\n";
			string label1 = makeLabel();
			string label0 = makeLabel();
			logOut << jump << " " << label1 << endl;
			logOut << "MOV AX, 0\n";
			logOut << "JMP " << label0 << endl;
			logOut << label1 << ":\n";
			logOut << "MOV AX, 1\n";
			logOut << label0 << ":\n";

			$$ = new SymbolInfo($1->getName() + $2[0] + $4->getName(), "int");
			//logOut << $$->getName() << "\n\n";
		}
		;

simple_expression :
		term {
			//logOut << "Line " << yylineno << ": simple_expression : term\n\n";
			$$ = $1;
			//logOut << $$->getName() << "\n\n";
		}
		| simple_expression ADDOP {logOut << "PUSH AX\n";} term {
			logOut << "POP BX\n";
			string left = $1->getIdType();
			string right = $4->getIdType();
			if(right == "void"){
				errorCount++;
				printErr("Void function used in expression");
			}
			if($2[0] == "+"){
				logOut << "ADD AX, BX\n";
			}
			else {
				logOut << "SUB BX, AX\n";
				logOut << "MOV AX, BX\n"; 
			}
			//logOut << "Line " << yylineno << ": simple_expression : simple_expression ADDOP term\n\n";
			$$ = new SymbolInfo($1->getName() + $2[0] + $4->getName(), (left == "float" || right == "float")?"float":"int");
			//logOut << $$->getName() << "\n\n";
		}
		| simple_expression ADDOP error term {

			//errors like a + = b;
			//this rule will turn it into a + b

			yyerrok;
			errorCount++;
			string left = $1->getIdType();
			string right = $4->getIdType();
			if(right == "void"){
				errorCount++;
				printErr("Void function used in expression");
			}
			//logOut << "Line " << yylineno << ": simple_expression : simple_expression ADDOP term\n\n";
			$$ = new SymbolInfo($1->getName() + $2[0] + $4->getName(), (left == "float" || right == "float")?"float":"int");
			//logOut << $$->getName() << "\n\n";
		}
		;
term :
		unary_expression{
			$$ = $1;
			//logOut << "Line " << yylineno << ": term : unary_expression\n\n";
			//logOut << $$->getName() << "\n\n";
		}
		| term MULOP {logOut << "PUSH AX" <<  endl;} unary_expression{

			logOut << "POP BX\n";
			logOut << "XCHG   AX, BX\n";

			logOut << "XOR DX, DX\n";

			//logOut << "Line " << yylineno << ": term : term MULOP unary_expression\n\n";

			string left = $1->getIdType();
			string right = $4->getIdType();
			string resultType;

			if(right == "void"){
				errorCount++;
				printErr("Void function used in expression");
			}

			if($2[0] == "%"){
				if(left != "int" || right != "int"){
					errorCount++;
					printErr("Non-Integer operand on modulus operator");
					resultType = "ERROR";
				}
				else{
					if($4->getName() == "0"){
						errorCount++;
						printErr("Modulus by Zero");
						resultType = "ERROR";
					}
					else {
						logOut << "IDIV BX\n";
						logOut << "MOV AX, DX\n";
						resultType = "int";
					}
				}
			}
			else if($2[0] == "/"){
				if($4->getName() == "0"){
					errorCount++;
					printErr("Division by 0");
					resultType = "ERROR";
				}
				else {
					logOut << "IDIV BX\n";
					resultType = (left == "float" || right == "float")?"float":"int";
				}
			}
			else{
				logOut <<  "IMUL BX\n";
				resultType = (left == "float" || right == "float")?"float":"int";
			}



			$$ = new SymbolInfo($1->getName() + $2[0] + $4->getName(), resultType);
			//logOut << $$->getName() << "\n\n";
		}
		| term MULOP error unary_expression{

			//errors like a * = b;
			//this rule will turn it into a * b
			yyerrok;
			errorCount++;
			//logOut << "Line " << yylineno << ": term : term MULOP unary_expression\n\n";

			string left = $1->getIdType();
			string right = $4->getIdType();
			string resultType;

			if(right == "void"){
				errorCount++;
				printErr("Void function used in expression");
			}

			if($2[0] == "%"){
				if(left != "int" || right != "int"){
					errorCount++;
					printErr("Non-Integer operand on modulus operator");
					resultType = "ERROR";
				}
				else{
					if($4->getName() == "0"){
						errorCount++;
						printErr("Modulus by Zero");
						resultType = "ERROR";
					}
					else {
						resultType = "int";
					}
				}
			}
			else if($2[0] == "/"){
				if($4->getName() == "0"){
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


			$$ = new SymbolInfo($1->getName() + $2[0] + $4->getName(), resultType);
			//logOut << $$->getName() << "\n\n";
		}
		;

unary_expression :
		ADDOP unary_expression{
			$$ = new SymbolInfo($1[0] + $2->getName(), $2->getType(), $2->getIdType());
			if($1[0] == "-"){
				logOut << "NEG AX\n";
			}
			//logOut << "Line " << yylineno << ": unary_expression : ADDOP unary_expression\n\n";
			//logOut << $$->getName() << "\n\n";
		}
		| NOT unary_expression{
			$$ = new SymbolInfo("!" + $2->getName(), $2->getType(), $2->getIdType());
			string lbl1 = makeLabel();
			string lbl2 = makeLabel();
			logOut << "CMP AX, 0\nJE " << lbl1 << "\nMOV AX, 0\nJMP " << lbl2 << "\n" << lbl1 << ":\nMOV AX, 1\n" << lbl2 << ":\n";
			//logOut << "Line " << yylineno << ": unary_expression : NOT unary_expression\n\n";
			//logOut << $$->getName() << "\n\n";
		}
		| factor{
			$$ = $1;
			//logOut << "Line " << yylineno << ": unary_expression : factor\n\n";
			//logOut << $$->getName() << "\n\n";
		}
		;

factor : 
		variable{
			$$ = $1;
			if(isGlobal){
				logOut << "MOV AX, [SI]\n";
			}
			else{
				logOut << "MOV AX, [BP + SI]\n";
			}
			//logOut << "Line " << yylineno << ": factor : variable\n\n";
			//logOut << $$->getName() << "\n\n";
		}
		| ID LPAREN {
			logOut << "PUSH BP\n";
		} argument_list RPAREN {
			logOut << "MOV BP, SP\nADD BP, -2\n";
			logOut << "CALL " << $1->getName() << endl;
			//logOut << "Line " << yylineno << ": factor : ID LPAREN argument_list RPAREN \n\n";
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
					if(paramList->size() != $4->size()){
						errorCount++;
						printErr("Total number of arguments mismatch in function " + id->getName());
					}
					else {
						for(int i = 0; i < paramList->size(); i++){
							if(paramList->at(i)->getIdType() != $4->at(i)->getIdType()){
								errorCount++;
								printErr(to_string(i + 1) + "th argument mismatch in function " + id->getName());
							}
							else if($4->at(i)->getSize() != ISVAR){
								if($4->at(i)->getSize() == ISFUNC || $4->at(i)->getSize() == ISFUNCDEF){
									errorCount++;
									printErr("Type Mismatch, " + $4->at(i)->getName() + " is a function");
								}
								else{
									errorCount++;
									printErr("Type Mismatch, " + $4->at(i)->getName() + " is an array");
								}
							}
						}
					}
				}
			}
			for(int i = 0; i < $4->size(); i++){
				logOut << "POP BP\n";
			}
			logOut << "POP BP\n";
			$$ = new SymbolInfo($1->getName() + "(" + makeArgListString($4) + ")", "function", retType);
			//logOut << $$->getName() << "\n\n";
		}
		| LPAREN expression RPAREN {
			$$ = new SymbolInfo("(" + $2->getName() + ")" , $2->getType(), $2->getIdType());
			//logOut << "Line " << yylineno << ": factor : LPAREN expression RPAREN\n\n";
			//logOut << $$->getName() << "\n\n";

		}
		| CONST_INT {
			$$ = $1;
			$$->setIdType("int");
			logOut << "MOV AX, " << stoi($1->getName()) <<  endl;
			//logOut << "Line " << yylineno << ": factor : CONST_INT\n\n";
			//logOut << $$->getName() << "\n\n";
		}
		| CONST_FLOAT {
			$$ = $1;
			$$->setIdType("float");
			logOut << "MOV AX, " << stoi($1->getName()) <<  endl;
			//logOut << "Line " << yylineno << ": factor : CONST_FLOAT\n\n";
			//logOut << $$->getName() << "\n\n";
		}
		| variable INCOP{
			$$ = new SymbolInfo($1->getName() + "++", $1->getType(), $1->getIdType());
			if(isGlobal){
				logOut << "MOV AX, [SI]\nINC [SI]\n";
			} 
			else{ 
				logOut << "MOV AX, [BP + SI]\nINC [BP + SI]\n";
			}
			//logOut << "Line " << yylineno << ": factor : variable INCOP\n\n";
			//logOut << $$->getName() << "\n\n";
		}
		| variable DECOP{
			$$ = new SymbolInfo($1->getName() + "--", $1->getType(), $1->getIdType());
			if(isGlobal){
				logOut << "MOV AX, [SI]\nMOV CX, AX\nDEC CX\nMOV [SI], CX\n";
			} 
			else{ 
				logOut << "MOV AX, [BP + SI]\nMOV CX, AX\nDEC CX\nMOV [BP + SI], CX\n";
			}
			//logOut << "Line " << yylineno << ": factor : variable DECOP\n\n";
			//logOut << $$->getName() << "\n\n";
		}
		;

arguments :
		arguments COMMA logic_expression {
			$$ = $1;
			$$->push_back($3);
			logOut << "PUSH AX\n";
			//logOut << "Line " << yylineno << ": arguments : arguments COMMA logic_expression\n\n";
			//logOut << makeArgListString($$);
			//logOut << "\n\n";
		}
		| logic_expression {
			$$ = new vector<SymbolInfo*>();
			$$->push_back($1);
			logOut << "PUSH AX\n";
			//logOut << "Line " << yylineno << ": arguments : logic_expression\n\n";
			//logOut << makeArgListString($$);
			//logOut << "\n\n";
		}
		;

argument_list :
		arguments {
			$$ = $1;
			//logOut << "Line " << yylineno << ": argument_list : arguments\n\n";
			//logOut << makeArgListString($$);
			//logOut << "\n\n";
		}
		| %empty {
			$$ = new vector<SymbolInfo*>();
			//logOut << "Line " << yylineno << ": argument_list : \n\n";
		}
		;

subroutine:
  		%empty  { 
			endLabel = makeLabel();
			labels.push_back(endLabel + "_" + makeLabel());
			logOut << "CMP AX, 0\n";
			logOut << "JE " <<  endLabel << endl;
		 }
		 ;

%%

int main(int argc,char *argv[]) {

	if((fp=fopen(argv[1],"r"))==NULL)
	{
		printf("Cannot Open Input File.\n");
		exit(1);
	}

	logOut.open("code.asm");
	errOut.open("1805089_error.txt");

	yyin=fp;
	yyparse();

	logOut.flush();
	logOut.close();

	if(isErrEnd){
		fopen("code.asm", "w");
	}

	optimize();
	
	return 0;
}

