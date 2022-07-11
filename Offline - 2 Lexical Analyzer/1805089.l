%option noyywrap yylineno
%x STRING_STATE
%x MUL_COMMENT_STATE
%x COMMENT_STATE
%{
    #include <iostream>
    #include "SymbolTable.cpp"
	#include <string>
	#include <fstream>
	#include <algorithm>

	char processEscapeSequence(string str){
		if(str == "\\n"){
			return '\n';
		}
		else if(str == "\\r"){
			return '\r';
		}
		else if(str == "\\t"){
			return '\t';
		}
		else if(str == "\\a"){
			return '\a';
		}
		else if(str == "\\f"){
			cout << "BLEHf" << endl << endl;
			return '\f';
		}
		else if(str == "\\b"){
			return '\b';
		}
		else if(str == "\\v"){
			return '\v';
		}
		else if(str == "\\0"){
			return '\0';
		}
		else if(str == "\\\\"){
			return '\\';
		}
		else if(str == "\\\'"){
			return '\'';
		}
		else if(str == "\\\""){
			return '\"';
		}
		return '\0';
	}

	char processEscapeSequenceInChar(string str){
		if(str[1] == '\\'){
			if(str == "\'\\n\'"){
				return '\n';
			}
			else if(str == "\'\\r\'"){
				return '\r';
			}
			else if(str == "\'\\t\'"){
				return '\t';
			}
			else if(str == "\'\\a\'"){
				return '\a';
			}
			else if(str == "\'\\f\'"){
				return '\f';
			}
			else if(str == "\'\\b\'"){
				return '\b';
			}
			else if(str == "\'\\v\'"){
				return '\v';
			}
			else if(str == "\'\\0\'"){
				return '\0';
			}
			else if(str == "\'\\\\\'"){
				return '\\';
			}
			else if(str == "\'\\\'\'"){
				return '\'';
			}
			else if(str == "\'\\\"\'"){
				return '\"';
			}
		}
		else{
			return str[1];
		}
		return '\0';
	}

    SymbolTable *symbolTable = new SymbolTable(7);
	string str;
	string ostr;
	int errorCount = 0;
	ofstream tokenout;
	int origLine;

%}

NEWLINE [\r]?[\n]
WHITESPACE [ \t\f\r\v]+ 

LETTER [a-zA-Z]
DIGIT [0-9]
DIGITS {DIGIT}+
IDENTIFIER_INIT {LETTER}|_

KEYWORDS "if"|"for"|"do"|"int"|"float"|"void"|"switch"|"default"|"else"|"while"|"break"|"char"|"double"|"return"|"case"|"continue"

ALPHANUM [a-zA-Z0-9]

ADDOP [-+]
MULOP [\*\%\/]
INCOP "++"|"--"
RELOP "<"|"<="|"=="|"!="|">="|">"
ASSIGNOP "="
LOGICOP "||"|"&&"
NOT "!"


LPAREN "("
RPAREN ")"
LCURL "{"
RCURL "}"
LTHIRD "["
RTHIRD "]"

COMMA ","
SEMICOLON ";"

CONST_INT {DIGITS}
DECIMAL ({DIGIT}*[\.]{DIGIT}+)
CONST_FLOAT {DECIMAL}|(({DECIMAL}|{DIGITS})[Ee][+-]?{DIGITS})
ILL_FORMED_NUM_ERROR (({DECIMAL}|{DIGITS})[Ee][+-]?{DECIMAL})
TOO_MANY_DEC_POINT_ERROR ({DECIMAL}[\.]+({DECIMAL}|{DIGITS}))+

ESCAPE_SEQUENCE \\[nt\\\'\"afrbv0]
ESCAPE_SEQUENCE_CHAR [nt\\\'\"afrbv0]

CONST_CHAR \'{ESCAPE_SEQUENCE}\'|\'[^\\\'{NEWLINE}]\'
UNFINISHED_CHAR \'[^\'{NEWLINE}]*|\'\\\'
EMPTY_CHAR \'\'
MUL_CHAR_CONST \'({ESCAPE_SEQUENCE}|[^\\\'{NEWLINE}])+\'

IDENTIFIER {IDENTIFIER_INIT}{ALPHANUM}*
INVALID_IDENTIFIER {DIGITS}{ALPHANUM}*


%%

{KEYWORDS} {
	string s(yytext);
	transform(s.begin(), s.end(), s.begin(), ::toupper);
	tokenout << "<" << s << "> ";
	cout<<"Line no " << yylineno << ": Token <"<< s <<"> LEXEME " << yytext << " found"<<endl << endl;
	}
{MULOP} {
	tokenout << "<" << "MULOP, " << yytext << "> "; 
	cout<<"Line no " << yylineno << ": Token <MULOP> LEXEME " << yytext << " found"<<endl << endl;
}
{ADDOP} {
	tokenout << "<" << "ADDOP, " << yytext << "> "; 
	cout<<"Line no " << yylineno << ": Token <ADDOP> LEXEME " << yytext << " found"<<endl << endl;
}
{INCOP} {
	tokenout << "<" << "INCOP, " << yytext << "> "; 
	cout<<"Line no " << yylineno << ": Token <INCOP> LEXEME " << yytext << " found"<<endl << endl;
}
{RELOP} {
	tokenout << "<" << "RELOP, " << yytext << "> ";
	cout<<"Line no " << yylineno << ": Token <RELOP> LEXEME " << yytext << " found"<<endl << endl;
}
{ASSIGNOP} {
	tokenout << "<" << "ASSIGNOP, " << yytext << "> ";
	cout<<"Line no " << yylineno << ": Token <ASSIGNOP> LEXEME " << yytext << " found"<<endl << endl;
}
{LOGICOP} {
	tokenout << "<" << "LOGICOP, " << yytext << "> ";
	cout<<"Line no " << yylineno << ": Token <LOGICOP> LEXEME " << yytext << " found"<<endl << endl;
}
{NOT} {
	tokenout << "<" << "NOT, " << yytext << "> ";
	cout<<"Line no " << yylineno << ": Token <LOGIC> LEXEME " << yytext << " found"<<endl << endl;
}
{LPAREN} {
	tokenout << "<" << "LPAREN, " << yytext << "> ";
	cout<<"Line no " << yylineno << ": Token <LPAREN> LEXEME " << yytext << " found"<<endl << endl;
}
{RPAREN} {
	tokenout << "<" << "RPAREN, " << yytext << "> ";
	cout<<"Line no " << yylineno << ": Token <RPAREN> LEXEME " << yytext << " found"<<endl << endl;
}
{LCURL} {
	tokenout << "<" << "LCURL, " << yytext << "> ";
	cout<<"Line no " << yylineno << ": Token <LCURL> LEXEME " << yytext << " found"<<endl << endl;
	symbolTable->enterScope();
}
{RCURL} {
	tokenout << "<" << "RCURL, " << yytext << "> ";
	cout<<"Line no " << yylineno << ": Token <RCURL> LEXEME " << yytext << " found"<<endl << endl;
	symbolTable->exitScope();
}
{LTHIRD} {
	tokenout << "<" << "LTHIRD, " << yytext << "> ";
	cout<<"Line no " << yylineno << ": Token <LTHIRD> LEXEME " << yytext << " found"<<endl << endl;
}
{RTHIRD} {
	tokenout << "<" << "RTHIRD, " << yytext << "> ";
	cout<<"Line no " << yylineno << ": Token <RTHIRD> LEXEME " << yytext << " found"<<endl << endl;
}
{COMMA} {
	tokenout << "<" << "COMMA, " << yytext << "> ";
	cout<<"Line no " << yylineno << ": Token <COMMA> LEXEME " << yytext << " found"<<endl << endl;
}
{SEMICOLON} {
	tokenout << "<" << "SEMICOLON, " << yytext << "> ";
	cout<<"Line no " << yylineno << ": Token <SEMICOLON> LEXEME " << yytext << " found"<<endl << endl;
}
{CONST_INT} {
	tokenout << "<" << "CONST_INT, " << yytext << "> ";
	cout<<"Line no " << yylineno << ": Token <CONST_INT> LEXEME " << yytext << " found"<<endl << endl;
	if(symbolTable->insert(yytext, "CONST_INT")){
		symbolTable->printAllScopeTable();
	}
	else{
		cout << yytext << " already exists in scopetable"<< endl << endl;
	}
}
{CONST_FLOAT} {
	tokenout << "<" << "CONST_FLOAT, " << yytext << "> ";
	cout<<"Line no " << yylineno << ": Token <CONST_FLOAT> LEXEME " << yytext << " found"<<endl << endl;
	if(symbolTable->insert(yytext, "CONST_FLOAT")){
		symbolTable->printAllScopeTable();
	}
	else{
		cout << yytext << " already exists in scopetable"<< endl << endl;
	}
}
{TOO_MANY_DEC_POINT_ERROR} {
	errorCount++;
	cout << "Error at line no " << yylineno << ": Too many decimal points " << yytext << endl << endl;
}
{ILL_FORMED_NUM_ERROR} {
	errorCount++;
	cout << "Error at line no " << yylineno << ": Ill formed number " << yytext << endl << endl;
}
{IDENTIFIER} {
	tokenout << "<" << "ID, " << yytext << "> ";
	cout<<"Line no " << yylineno << ": Token <ID> LEXEME " << yytext << " found"<<endl << endl;
	if(symbolTable->insert(yytext, "ID")){
		symbolTable->printAllScopeTable();
	}
	else{
		cout << yytext << " already exists in scopetable"<< endl << endl;
	}

}
{INVALID_IDENTIFIER} {
	errorCount++;
	cout << "Error at line no " << yylineno << ": Invalid prefix on ID or invalid suffix on Number " << yytext << endl << endl;
}
{CONST_CHAR} {
	char ch = processEscapeSequenceInChar(yytext);
	tokenout << "<" << "CONST_CHAR, " << ch << "> ";
	cout<<"Line no " << yylineno << ": Token <CONST_CHAR> LEXEME " << yytext << " found -->" << "<CHAR_CONST, " << ch << ">" <<endl << endl;
	string temp(1, ch);
	if(symbolTable->insert(yytext, "CONST_CHAR")){
		symbolTable->printAllScopeTable();
	}
	else{
		cout << yytext << " already exists in scopetable"<< endl << endl;
	}
}
{EMPTY_CHAR} {
	errorCount++;
	cout << "Error at line no " << yylineno << ": Empty character constant error " << yytext << endl << endl;
 }
{MUL_CHAR_CONST} {
	errorCount++;
	cout << "Error at line no " << yylineno << ":Multi character constant error " << yytext << endl << endl;
}
{UNFINISHED_CHAR} {
	errorCount++;
	cout << "Error at line no " << yylineno << ": Unterminated character " << yytext << endl << endl;
}

\/\/ {
	origLine = yylineno;
	BEGIN COMMENT_STATE;
}

<COMMENT_STATE>([^{NEWLINE}]|\\{NEWLINE})* {
	cout<<"Line no " << origLine << ": Token <COMMENT> LEXEME //" << yytext << " found"<<endl << endl;
	BEGIN INITIAL;
}

\/\* {
	origLine = yylineno;
	BEGIN MUL_COMMENT_STATE;
}

<MUL_COMMENT_STATE>([^\*]|[\r{NEWLINE}]|(\*+([^\*\/]|[\r{NEWLINE}])))*\*+\/ {
	cout<<"Line no " << origLine << ": Token <COMMENT> LEXEME /*" << yytext << " found"<<endl << endl;
	BEGIN INITIAL;
}

<MUL_COMMENT_STATE>([^\*]|[\*]+[^*/])* {
	errorCount++;
	cout << "Error at line no " << origLine << ": Unterminated Comment " << yytext << endl << endl;
	BEGIN INITIAL;
	return 0;
}

\" {
	str = "";
	ostr = "";
	origLine = yylineno;
	BEGIN STRING_STATE;
}
<STRING_STATE>{ESCAPE_SEQUENCE} {
	str.push_back(processEscapeSequence(yytext));
	ostr.append(yytext);
}
<STRING_STATE>\\{NEWLINE} {
	ostr.append(yytext);
}
<STRING_STATE>\\[^{ESCAPE_SEQUENCE_CHAR}] {
	ostr.append(yytext);
	errorCount++;
	cout << "Error at line no " << origLine << ": Unknown escape sequence in String " << ostr << endl << endl;
	BEGIN INITIAL;
}
<STRING_STATE><<EOF>> {
	errorCount++;
	cout << "Error at line no " << origLine << ": Unterminated String " << ostr << endl << endl;
	BEGIN INITIAL;
	return 0;
}
<STRING_STATE>{NEWLINE} {
	errorCount++;
	cout << "Error at line no " << origLine << ": Unterminated String " << ostr << endl << endl;
	BEGIN INITIAL;
}
<STRING_STATE>\" {
	tokenout << "<" << "STRING, \"" << str << "\"> ";
	cout<<"Line no " << origLine << ": Token <STRING> LEXEME \"" << ostr << "\" found " << "--> <STRING, \"" << str <<"\">"<< endl << endl;
	BEGIN INITIAL;
}
<STRING_STATE>. {
	str.append(yytext);
	ostr.append(yytext);
}
{NEWLINE} { }

{WHITESPACE} { }

. {
	errorCount++;
	cout << "Error at line no " << yylineno << ": Unrecognized character " << yytext << endl << endl;
}

%%

int main(int argc,char *argv[]){
	
	if(argc!=2){
		printf("Please provide input file name and try again\n");
		return 0;
	}
	
	FILE *fin=fopen(argv[1],"r");
	if(fin==NULL){
		printf("Cannot open specified file\n");
		return 0;
	}
	
	tokenout.open("1805089_token.txt");
	freopen("1805089_log.txt", "w", stdout);
	cout<<endl;
	yyin= fin;
	yylex();
	fclose(yyin);
	symbolTable->printAllScopeTable();
	delete symbolTable;
	cout << "Total lines: " << yylineno << endl;
	cout << "Total errors: " << errorCount << endl;
	tokenout.close();
	return 0;
}