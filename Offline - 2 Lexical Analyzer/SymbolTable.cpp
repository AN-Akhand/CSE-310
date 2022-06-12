#include<iostream>
#include<fstream>

using namespace std;

class SymbolInfo{
    string name;
    string type;
    SymbolInfo* nextSymbol;
public:
    SymbolInfo(){
        name = "";
        type = "";
        nextSymbol = nullptr;
    }

    SymbolInfo(string name, string type, SymbolInfo* nextSymbol = nullptr){
        this->name = name;
        this->type = type;
        this->nextSymbol = nextSymbol;
    }

    string getName(){
        return name;
    }

    string getType(){
        return type;
    }

    SymbolInfo* getNextSymbol(){
        return nextSymbol;
    }

    void setName(string name){
        this->name = name;
    }

    void setType(string type){
        this->type = type;
    }

    void setNextSymbol(SymbolInfo* nextSymbol){
        this->nextSymbol = nextSymbol;
    }

    ~SymbolInfo(){
        nextSymbol = nullptr;
    }

};

class ScopeTable{

    int size, count;
    string id;
    SymbolInfo** hashTable;
    ScopeTable* parentScope;

public:
    ScopeTable(){
        size = 0;
        count = 0;
        id = "";
        parentScope = nullptr;
        hashTable = nullptr;
    }

    ScopeTable(int size, int id = 1, ScopeTable* parentTable = nullptr){
        this->size = size;
        count = 0;
        this->parentScope = parentTable;

        if(parentTable == nullptr){
            this->id = to_string(id);
        }
        else{
            this->id = getParentScope()->getId() + "." + to_string(id);
        }

        hashTable = new SymbolInfo*[size];
        for(int i = 0; i < size; i++){
            hashTable[i] = new SymbolInfo();
        }

    }

    bool insert(string name, string type){
        int index = hash(name);

        SymbolInfo* root = hashTable[index];

        if(root->getName() == ""){
            root->setName(name);
            root->setType(type);
            return true;
        }
        else{
            SymbolInfo* parent;
            int i = 0;
            do{
                if(root->getName() == name){
                    return false;
                }
                parent = root;
                root = root->getNextSymbol();
                i++;
            }while(root != nullptr);
            root = new SymbolInfo(name, type);
            parent->setNextSymbol(root);

            return true;
        }
    }

    SymbolInfo* lookup(string name){
        int index = hash(name);
        SymbolInfo* root = hashTable[index];
        int i = 0;
        do{
            if(root->getName() == name){

                return root;
            }
            root = root->getNextSymbol();
            i++;
        }while(root != nullptr);

        return nullptr;
    }

    bool deleteSymbol(string name){
        int index = hash(name);
        SymbolInfo* root = hashTable[index];
        int i = 0;
        SymbolInfo* parent;
        if(root->getName() == name){
            if(root->getNextSymbol() == nullptr){
                root->setName("");
                root->setType("");
            }
            else{
                hashTable[index] = root->getNextSymbol();
                delete root;
            }

            return true;

        }
        do{
            if(root->getName() == name){
                parent->setNextSymbol(root->getNextSymbol());
                delete root;

                return true;
            }
            parent = root;
            root = root->getNextSymbol();
            i++;
        }while(root != nullptr);

        return false;
    }

    void print(){
        cout<<"ScopeTable# " << id << endl;

        for(int i = 0; i < size; i++){
            SymbolInfo* root = hashTable[i];
            if(root->getName() == ""){
                continue;
            }
            cout<<i<<"->";

            do{
                cout << "< " << root->getName() << " : " << root->getType() << " >";
                root = root->getNextSymbol();
            }while(root != nullptr);
            cout << endl;
        }
        cout << endl;
    }

    int getSize(){
        return size;
    }

    int getCount(){
        return count;
    }

    string getId(){
        return id;
    }

    ScopeTable* getParentScope(){
        return parentScope;
    }

    void setParentScope(ScopeTable* table){
        parentScope = table;
    }

    void increaseCounter(){
        count++;
    }

    uint32_t hash(string s){

        uint32_t hash = 0;
        int c;

        for(auto c : s)
            hash = c + (hash << 6) + (hash << 16) - hash;

        return hash % size;
    }

    ~ScopeTable(){
        for(int i = 0; i < size; i++){
            SymbolInfo* root = hashTable[i];
            SymbolInfo* temp;
            do{
                temp = root;
                root = root->getNextSymbol();
                delete temp;
            }while(root != nullptr);
        }
        parentScope = nullptr;
        delete[] hashTable;
    }

};

class SymbolTable{

    int bucketSize, count;
    ScopeTable* currentScope;

public:
    SymbolTable(int size){
        bucketSize = size;
        currentScope = new ScopeTable(bucketSize);
        count = 1;
    }

    int getBucketSize(){
        return bucketSize;
    }

    ScopeTable* getCurrentScope(){
        return currentScope;
    }

    void setCurrentScope(ScopeTable* table){
        currentScope = table;
    }

    void enterScope(){
        if(currentScope == nullptr){
            count++;
            currentScope = new ScopeTable(bucketSize, count);
            return;
        }
        currentScope->increaseCounter();
        ScopeTable* newScope = new ScopeTable(bucketSize, currentScope->getCount(), currentScope);
        currentScope = newScope;
    }

    void exitScope(){
        if(currentScope == nullptr){
            return;
        }
        ScopeTable* temp = currentScope;
        currentScope = currentScope->getParentScope();
        delete temp;
    }

    bool insert(string name, string type){
        if(currentScope == nullptr){
            enterScope();
        }
        return currentScope->insert(name, type);
    }

    bool remove(string name){
        return currentScope->deleteSymbol(name);
    }

    SymbolInfo* lookup(string name){
        ScopeTable* temp = currentScope;
        SymbolInfo* item;

        while(temp != nullptr){
            item = temp->lookup(name);
            if(item != nullptr){
                return item;
            }
            temp = temp->getParentScope();
        }
        return nullptr;
    }

    void printCurrentScopeTable(){
        currentScope->print();
    }

    void printAllScopeTable(){
        ScopeTable* temp = currentScope;

        while(temp != nullptr){
            temp->print();
            temp = temp->getParentScope();
        }
    }

    ~SymbolTable(){
        ScopeTable* temp = currentScope;
        while(true){
            if(currentScope == nullptr){
                break;
            }
            ScopeTable* temp = currentScope->getParentScope();
            delete currentScope;
            currentScope = temp;
        }
    }

};

