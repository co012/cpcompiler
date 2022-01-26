#include <stdio.h>

class Rectangle {
    int width;
    int height;

    void init(int width, int height){
        this.width = width;
        this.height = height;
    }

    void toString(void){
        printf("Rectangle %dx%d\n", this.width, this.height);
    }

    int getArea(void){
        this.toString();
        int area = this.width * this.height;
        return area;
    }


}

class Circle {
    int radius;

    void init(int radius){
        this.radius = radius;
    }

    void toString(void){
        printf("Circle r=%d\n", this.radius);
    }

    int getArea(void){
        this.toString();
        int area = this.radius * this.radius * 3;
        return area;
    }


}

int main(void){
    printf("Hello world\n");
    class Rectangle rect;
    rect.init(2,3);
    class Circle circ;
    circ.init(5);

    printf("Area: %d\n", rect.getArea());
    printf("Area: %d\n", circ.getArea());
    return 0;
}