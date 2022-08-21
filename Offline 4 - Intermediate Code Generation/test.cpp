#include<iostream>
#include<cstdlib>
#include<cstring>
#include<cmath>
#include<vector>
#include<fstream>
#include<iterator>

using namespace std;
void optimize(){
ifstream oin;
	oin.open("test.txt");
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
					((j - 1)[0].rfind("LEA SI", 0) == 0)) {
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
		if(oin.eof()){
			break;
		}
        getline(oin, s);
        code.push_back(s);
        if(s == "END MAIN"){
            break;
        }
    }
    ofstream output_file("./1805089_optimized.asm");
    ostream_iterator<string> output_iterator(output_file, "\n");
    copy(code.begin(), code.end(), output_iterator);
}

int main(){
    optimize();
}