#include <stdio.h>

class Rectangle {
    int width;
    int height;

    void toString(void){
        printf("Rectangle %dx%d\n", this.width, this.height);
    }

    int getArea(void){
        this.toString();
        int area = this.width * this.height;
        return area;
    }

    int getVolumeWithDimension(int deepness){
        return this.width * this.height * deepness;
    }

}

class Rectangle ala;

int main(void){
    printf("Hello world\n");
    class Rectangle rect;
    rect.width = 2;
    rect.height = 3;
    int area = rect.getArea();
    int volume = rect.getVolumeWithDimension(12);
    rect.width++;
    rect.toString();
    ala.toString();
    printf("Area: %d, Volume: %d\n", area, volume);
    return 0;
}