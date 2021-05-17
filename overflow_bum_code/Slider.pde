class Slider {
  
    float minimum;
    float maximum;
    float default_value;
    float step;
    float current_value;
     
    float x_start,y_start;
    float width_slider, height_slider;
    color c = color(random(180, 330), random(30, 100), 100);
    
    Slider () {
      minimum = 0;
      maximum = minimum + 1;
      default_value = 0;
      current_value = default_value;
      step = 0.1;
    }
    
    Slider(float min, float max, float default_val, float stp, int pos_x_start, float pos_y_start, float in_width_slider, float in_height_slider) {
      minimum = min;
      maximum = max;
      default_value = default_val;
      current_value = default_val;
      step = stp;
      
      // position and drawing
      x_start = pos_x_start;
      y_start = pos_y_start;
      width_slider = in_width_slider;
      height_slider = in_height_slider;
      
    }
    
    void increase_slider() {
      if (current_value + step <= maximum) {
        current_value += step;
      }
    }
    
    void decrease_slider() {
      if (current_value - step >= minimum) {
        current_value -= step;
      }
    }
    
    void display() {
      strokeWeight(4);
      noFill();
      stroke(50);
      rect(x_start,y_start,width_slider,height_slider);
      
      float display_value = map(current_value, minimum, maximum, 0, width_slider);
      
      //stroke(50);
      //fill(191, 161, 130);
      fill(c);
      rect(x_start ,y_start, display_value,height_slider);
      
    }
}
