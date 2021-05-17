ArrayList<Particle> particles = new ArrayList<Particle>(); // particles following paths
Path[] paths = new Path[0]; // paths to be followed by particles
Boundary metro_boundary = new Boundary(); // POLYGON BOUNDARY
Boundary[] metro_boundary_inside = new Boundary[0]; // POLYGON BOUNDARIES INSIDE


// sliders and canvas object
Slider congestionSlider, cohesionSlider, separationSlider, speedSlider;;

// preload json variables
PImage img, img_wlines;
JSONObject boundaries_json;
JSONObject paths_json;
JSONObject inside_boundaries_json;

// Helpers From Keyboard or Buttons
boolean draw_boundary = true;
boolean second_viz = false;
boolean helper = false;
boolean draw_metro_lines = true;

// Various Parameters
int maxNumOfParticles = 400;
int text_size_helper = 14;
int text_size_time = 36;

// Load JSON objects by reading the files
void preload() {
    img_wlines = loadImage("assets/overlays/overlay_sine.png");
    img = loadImage("assets/overlays/overlay_titlu_gri1.png");
    boundaries_json = loadJSONObject("assets/data_from_rhino_bum/boundary_catacombs.json");
    inside_boundaries_json = loadJSONObject("assets/data_from_rhino_bum/boundary_inside_catacombs.json");
    paths_json = loadJSONObject("assets/data_from_rhino_bum/paths.json");
}

// Convert saved point data (JSON) into p5 polygon Objects
void loadData() {
    int scale_offset = 150;
    float original_size_x = 2311.76;
    float original_size_y = 1570.776;
    float ratio_boundary = original_size_x/original_size_y;
    
    float scaled_y = height - scale_offset;
    float scaled_x = (height -scale_offset)*ratio_boundary;
    
    float mid_x = scaled_x/2;
    float mid_y = scaled_y/2;
    JSONArray boundariesData = boundaries_json.getJSONArray("0");
    
    JSONObject point;
    JSONArray paths_vertices;
    Path new_path;
    Boundary new_boundary;
    float mapped_correct_size_y;
    float mapped_correct_size_x;

    // Load Polygon Boundaries
    for (int i = 0; i < boundariesData.size(); i++) {
        // Get each object in the array
        point = boundariesData.getJSONObject(i);
        // Get x,y from position
        mapped_correct_size_y = map(point.getFloat("Y"), 0, original_size_y,  0, scaled_y) + height/2 - mid_y ;
        mapped_correct_size_x = map(point.getFloat("X"), 0, original_size_x, 0, scaled_x) + width/2 - mid_x;
         
        //balls = (Ball[]) append(balls, b);
        metro_boundary.addPoint(mapped_correct_size_x, mapped_correct_size_y);

    }
    
    // Load Inside Boundaries
    for (int i = 1; i <= inside_boundaries_json.size(); i++) {
        new_boundary = new Boundary();
        paths_vertices = inside_boundaries_json.getJSONArray(str(i));
        for (int j = 0; j < paths_vertices.size(); j++) {
            point = paths_vertices.getJSONObject(j);
            mapped_correct_size_y = map(point.getFloat("Y"), 0, original_size_y,  0, scaled_y) + height/2 - mid_y ;
            mapped_correct_size_x = map(point.getFloat("X"), 0, original_size_x, 0, scaled_x) + width/2 - mid_x;
            
            new_boundary.addPoint(mapped_correct_size_x, mapped_correct_size_y);
        }
        metro_boundary_inside = (Boundary[]) append(metro_boundary_inside, new_boundary);
    }
    
    // Load Paths that the particles are going to f_ollow

    for (int i = 1; i <= paths_json.size(); i++) {
        new_path = new Path();
        paths_vertices = paths_json.getJSONArray(str(i));
        for (int j = 0; j < paths_vertices.size(); j++) {
            point = paths_vertices.getJSONObject(j);
            new_path.addPoint(map(point.getFloat("X"), 0, original_size_x, 0, scaled_x) + width/2 - mid_x, 
                map(point.getFloat("Y"), 0, original_size_y,  0, scaled_y) + height/2 - mid_y);
        }
        paths = (Path[]) append(paths, new_path);
    }

    // Load Inverse Paths  (particle move in opposite direction on the same path)

    for (int i = 1; i <= paths_json.size(); i++) {
        new_path = new Path();
        paths_vertices = paths_json.getJSONArray(str(i));
        for (int j = paths_vertices.size() - 1; j >= 0; j--) {
            point = paths_vertices.getJSONObject(j);
            new_path.addPoint(map(point.getFloat("X"), 0, original_size_x, 0, scaled_x) + width/2 - mid_x, 
                map(point.getFloat("Y"), 0, original_size_y,  0, scaled_y) + height/2 - mid_y);
        }
        paths = (Path[]) append(paths, new_path);
    }

}

// Setup canvas to draw anything
void setup() {
    // load assets
    preload();
    loadData();
    
    print("Made with love in Delft/Bucharest by @andrejcarlo and @alxmuller");
    print("VERSION BUM_01");
    
    size(1600, 1000);
    //fullScreen();
    
    // ------ Slider Setup
    congestionSlider = new Slider(0, maxNumOfParticles, 0, 5, width - 250, 25, 230, 20);
    cohesionSlider = new Slider(0, 1, 0, 0.1, width - 250, 70, 230, 20);
    separationSlider = new Slider(0, 1.1, 0, 0.05, width - 250, 115, 230, 20);
    speedSlider = new Slider(0.1, 2, 1, 0.1, width - 250, 160, 230, 20);
    
    image(img_wlines, 0, 0, width, height);
    background(0, 0, 0);

}

// Animate Function
void draw() {
    // Enable Helpers if needed
    if (second_viz == true) {
        //background(0, 0, 0);
        fill(0, 0, 0, 15);
        noStroke();
    } else {
        background(0);

        fill(0, 2);
        stroke(51);
    }
    rect(0, 0, width, height);
    //fill(0, 0, 0, 15);
    //noStroke();
    
    
    // Draw Boundaries
    if (draw_boundary) {
      metro_boundary.display();
      for (Boundary inside: metro_boundary_inside) {
        inside.display();
      }
    }
    
    congestionSlider.display();
    cohesionSlider.display();
    separationSlider.display();
    speedSlider.display();
    

    // --------- Generate Particles

    //start a car at a random path then eliminate it when it has reached the end of the path
    Path path = paths[int(random(paths.length))];
    Particle car = new Particle(path.getStart().x, path.getStart().y);
    car.pathToFollow = path;

    // Build particles until desired length
    if (particles.size() <= congestionSlider.current_value && congestionSlider.current_value != 0) {
        particles.add(car);
    }

    //--- Path Following Particles
    for (int i = 0; i < particles.size(); i++) {
        // Collision detection
        boolean inside = particles.get(i).boundaries();

        // Apply Behaviours of Particles
        boolean eliminate = particles.get(i).applyBehaviors(particles);

        // display
        particles.get(i).update();
        particles.get(i).show();

        // Respawn
        elimination(inside, eliminate, i);
    }
    // Draw overlay after particles
    //if (draw_metro_lines)
    //    image(img_wlines, 0, 0, width, height);
    //else
    //    image(img, 0, 0, width, height);

    //Draw Helpers and clock after image
    if (helper == true) {
        textSize(text_size_helper);
        strokeWeight(0);
        fill(100);
        int distance_between = 14;
        text("move congestion slider to start", 40, height - 20 - distance_between * 5);
        text("b to hide metro plan", 40, height - 20 - distance_between * 4);
        text("r to reset particles", 40, height - 20 - distance_between * 3);
        text("v to change visualization", 40, height - 20 - distance_between * 2);
        text("i to hide metro lines", 40, height - 20 - distance_between);
        text("space to hide these instructions", 40, height - 20);


    }
    

}

// Buttons for Helpers
void keyPressed() {
    if (key == '0') {
        particles = new ArrayList<Particle>();
    } else if (key == '.') {
        second_viz = (!second_viz) ? true : false;
    } else if (key == ' ') {
        helper = (!helper) ? true : false;
    } else if (key == '1') {
        draw_boundary = (!draw_boundary) ? true : false;
    } else if (key == 'q') {
        draw_metro_lines = (!draw_metro_lines) ? true : false;
    } else if (key == '*') {
        congestionSlider.increase_slider();
    } else if (key == '/') {
        congestionSlider.decrease_slider();
    } else if (key == '9') {
        cohesionSlider.increase_slider();
    } else if (key == '8') {
        cohesionSlider.decrease_slider();
    } else if (key == '6') {
        separationSlider.increase_slider();
    } else if (key == '5') {
        separationSlider.decrease_slider();
    }  else if (key == '3') {
        speedSlider.increase_slider();
    } else if (key == '2') {
        speedSlider.decrease_slider();
    }
}

// Despawn and respawn particles
void elimination(boolean inside, boolean eliminate, int index) {
    if (inside || eliminate) {
        particles.remove(index);
    }
}

// also change here dimensions for resizing window
// whenever you resize, the canvas changes dimensions according to these values
// function windowResized() {
//     resizeCanvas(sketchHeight, sketchWidth);
// }
