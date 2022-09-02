int a[10]; 

int main(){
    int i;
    int b;
    for(i = 0; i < 10; i++){
        a[i] = i;
    }
    for(i = 0; i < 10; i++){
        b = a[i];
        printf(b);
    }
}