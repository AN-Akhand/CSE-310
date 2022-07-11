%option noyywrap yylineno
%x STRING_STATE
%x MUL_COMMENT_STATE
%x COMMENT_STATE
%{
    #include <iostream>
	#include <string>
	#include <fstream>
	#include <algorithm>
	#include "SymbolTable.cpp"
	#include "y.tab.h"
	using namespace std;


	extern YYSTYPE yylval;

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

	int returnSymbolTokens(string s){
		string* symbol = new string[1];
		symbol[0] = s;
		if(symbol[0] == "if"){
			return IF;
		}
		else if(symbol[0] == "else"){
			return ELSE;
		}
		else if(symbol[0] == "for"){
			return FOR;
		}
		else if(symbol[0] == "while"){
			return WHILE;
		}
		else if(symbol[0] == "do"){
			return DO;
		}
		else if(symbol[0] == "int"){
			yylval.type = symbol;
			return INT;
		}
		else if(symbol[0] == "float"){
			yylval.type = symbol;
			return FLOAT;
		}
		else if(symbol[0] == "double"){
			yylval.type = symbol;
			return DOUBLE;
		}
		else if(symbol[0] == "char"){
			yylval.type = symbol;
			return CHAR;
		}
		else if(symbol[0] == "void"){
			yylval.type = symbol;
			return VOID;
		}
		else if(symbol[0] == "switch"){
			return SWITCH;
		}
		else if(symbol[0] == "default"){
			return DEFAULT;
		}
		else if(symbol[0] == "break"){
			return BREAK;
		}
		else if(symbol[0] == "return"){
			return RETURN;
		}
		else if(symbol[0] == "case"){
			return CASE;
		}
		else if(symbol[0] == "continue"){
			return CONTINUE;
		}
		else if(symbol[0] == "printf"){
			return PRINTLN;
		}
	}

	string str;
	string ostr;
	extern int errorCount;
	ofstream tokenout;
	int origLine;

%}

NEWLINE [\r]?[\n]
WHITESPACE [ \t\f\r\v]+ 

LETTER [a-zA-Z]
DIGIT [0-9]
DIGITS {DIGIT}+
IDENTIFIER_INIT {LETTER}|_

KEYWORDS "if"|"for"|"do"|"int"|"float"|"void"|"switch"|"default"|"else"|"while"|"break"|"char"|"double"|"return"|"case"|"continue"|"printf"

ALPHANUM [a-zA-Z0-9]

ADDOP [-+]
MULOP [\*\%\/]
INCOP "++"
DECOP "--"
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

IDENTIFIER {IDENTIFIER_INIT}({ALPHANUM}|_)*
INVALID_IDENTIFIER {DIGITS}{ALPHANUM}*


%%

{KEYWORDS} {
	return returnSymbolTokens(yytext);
}
{MULOP} {
	string* symbol = new string[1];
	symbol[0] = yytext;
	yylval.type = symbol;
	return MULOP;
}
{ADDOP} {
	string* symbol = new string[1];
	symbol[0] = yytext;
	yylval.type = symbol;
	return ADDOP;
}
{INCOP} {
	return INCOP;
}
{DECOP} {
	return DECOP;
}
{RELOP} {
	string* symbol = new string[1];
	symbol[0] = yytext;
	yylval.type = symbol;
	return RELOP;
}
{ASSIGNOP} {
	return ASSIGNOP;
}
{LOGICOP} {
	string* symbol = new string[1];
	symbol[0] = yytext;
	yylval.type = symbol;
	return LOGICOP;
}
{NOT} {
	return NOT;
}
{LPAREN} {
	return LPAREN;
}
{RPAREN} {
	return RPAREN;
}
{LCURL} {
	return LCURL;
}
{RCURL} {
	return RCURL;
}
{LTHIRD} {
	return LTHIRD;
}
{RTHIRD} {
	return RTHIRD;
}
{COMMA} {
	return COMMA;
}
{SEMICOLON} {
	return SEMICOLON;
}
{CONST_INT} {
	SymbolInfo* sInfo = new SymbolInfo(yytext, "int");
	yylval.symbolInfo = sInfo;
	return CONST_INT;
}
{CONST_FLOAT} {
	SymbolInfo* sInfo = new SymbolInfo(yytext, "float");
	yylval.symbolInfo = sInfo;
	return CONST_FLOAT;
}
{TOO_MANY_DEC_POINT_ERROR} {
	//errorCount++;
	//cout << "Error at line no " << yylineno << ": Too many decimal points " << yytext << endl << endl;
}
{ILL_FORMED_NUM_ERROR} {
	//errorCount++;
	//cout << "Error at line no " << yylineno << ": Ill formed number " << yytext << endl << endl;
}
{IDENTIFIER} {
	SymbolInfo* sInfo = new SymbolInfo(yytext, "ID");
	yylval.symbolInfo = sInfo;
	return ID;

}
{INVALID_IDENTIFIER} {
	//errorCount++;
	//cout << "Error at line no " << yylineno << ": Invalid prefix on ID or invalid suffix on Number " << yytext << endl << endl;
}
{CONST_CHAR} {
	char ch = processEscapeSequenceInChar(yytext);
	string temp(1, ch);
	SymbolInfo* sInfo = new SymbolInfo(temp, "char");
	yylval.symbolInfo = sInfo;
	return CONST_CHAR;
}
{EMPTY_CHAR} {
	//errorCount++;
	//cout << "Error at line no " << yylineno << ": Empty character constant error " << yytext << endl << endl;
 }
{MUL_CHAR_CONST} {
	//errorCount++;
	//cout << "Error at line no " << yylineno << ":Multi character constant error " << yytext << endl << endl;
}
{UNFINISHED_CHAR} {
	//errorCount++;
	//cout << "Error at line no " << yylineno << ": Unterminated character " << yytext << endl << endl;
}

\/\/ {
	origLine = yylineno;
	BEGIN COMMENT_STATE;
}

<COMMENT_STATE>([^{NEWLINE}]|\\{NEWLINE})* {
	//cout<<"Line no " << origLine << ": Token <COMMENT> LEXEME //" << yytext << " found"<<endl << endl;
	BEGIN INITIAL;
}

\/\* {
	origLine = yylineno;
	BEGIN MUL_COMMENT_STATE;
}

<MUL_COMMENT_STATE>([^\*]|[\r{NEWLINE}]|(\*+([^\*\/]|[\r{NEWLINE}])))*\*+\/ {
	//cout<<"Line no " << origLine << ": Token <COMMENT> LEXEME /*" << yytext << " found"<<endl << endl;
	BEGIN INITIAL;
}

<MUL_COMMENT_STATE>([^\*]|[\*]+[^*/])* {
	//errorCount++;
	//cout << "Error at line no " << origLine << ": Unterminated Comment " << yytext << endl << endl;
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
	//errorCount++;
	//cout << "Error at line no " << origLine << ": Unknown escape sequence in String " << ostr << endl << endl;
	BEGIN INITIAL;
}
<STRING_STATE><<EOF>> {
	//errorCount++;
	//cout << "Error at line no " << origLine << ": Unterminated String " << ostr << endl << endl;
	BEGIN INITIAL;
	return 0;
}
<STRING_STATE>{NEWLINE} {
	//errorCount++;
	//cout << "Error at line no " << origLine << ": Unterminated String " << ostr << endl << endl;
	BEGIN INITIAL;
}
<STRING_STATE>\" {
	//tokenout << "<" << "STRING, \"" << str << "\"> ";
	//cout<<"Line no " << origLine << ": Token <STRING> LEXEME \"" << ostr << "\" found " << "--> <STRING, \"" << str <<"\">"<< endl << endl;
	BEGIN INITIAL;
}
<STRING_STATE>. {
	str.append(yytext);
	ostr.append(yytext);
}
{NEWLINE} { }

{WHITESPACE} { }

. {
	//errorCount++;
	//cout << "Error at line no " << yylineno << ": Unrecognized character " << yytext << endl << endl;
}

%%