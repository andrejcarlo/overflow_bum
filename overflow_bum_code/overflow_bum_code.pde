import processing.sound.*;

ArrayList<Particle> particles = new ArrayList<Particle>(); // particles following paths
Path[] paths = new Path[0]; // paths to be followed by particles
Boundary metro_boundary = new Boundary(); // POLYGON BOUNDARY
Boundary metro_boundary_collide = new Boundary();
Boundary[] metro_boundary_inside = new Boundary[0]; // POLYGON BOUNDARIES INSIDE
Boundary[] metro_boundary_pilons = new Boundary[0]; // POLYGON BOUNDARIES INSIDE PILONS


// add soundfile
SoundFile sfile;

// sliders and canvas object
Slider congestionSlider, cohesionSlider, separationSlider, speedSlider;;

// preload json variables
PImage img, img_wlines;
JSONObject boundaries_json;
JSONObject boundaries_collide_json;
JSONObject paths_json;
JSONObject inside_boundaries_json;
JSONObject inside_boundaries_pilons_json;

// Helpers From Keyboard or Buttons
boolean draw_boundary = true;
boolean second_viz = false;
boolean helper = false;
boolean draw_metro_lines = true;

// Various Parameters
int maxNumOfParticles = 400;
int text_size_helper = 14;
int text_size_time = 36;
PFont custom_font_title;
PFont custom_font_subtitle;

// Load JSON objects by reading the files
void preload() {
    img_wlines = loadImage("assets/overlays/overlay_sine.png");
    img = loadImage("assets/overlays/overlay_titlu_gri1.png");
    boundaries_json = loadJSONObject("assets/data_from_rhino_bum/rotated/boundary_catacombs.json");
    boundaries_collide_json = loadJSONObject("assets/data_from_rhino_bum/rotated/boundary_catacombs_lowpoly.json");
    inside_boundaries_json = loadJSONObject("assets/data_from_rhino_bum/rotated/boundary_inside_catacombs.json");
    inside_boundaries_pilons_json = loadJSONObject("assets/data_from_rhino_bum/rotated/boundary_inside_pilons.json");
    paths_json = loadJSONObject("assets/data_from_rhino_bum/rotated/paths.json");
}

// Convert saved point data (JSON) into p5 polygon Objects
void loadData() {
    int scale_offset = 150;
    float original_size_x =2427.075;  //2311.76; 
    float original_size_y =1344.240; //1570.776;
    float ratio_boundary = original_size_x/original_size_y;
    
    float scaled_y = height - scale_offset;
    float scaled_x = (height -scale_offset)*ratio_boundary;
    
    float mid_x = scaled_x/2;
    float mid_y = scaled_y/2;
    JSONArray boundariesData = boundaries_json.getJSONArray("0");
    JSONArray boundariesDataCollision = boundaries_collide_json.getJSONArray("0");
    
    JSONObject point;
    JSONArray paths_vertices;
    Path new_path;
    Boundary new_boundary;
    float mapped_correct_size_y;
    float mapped_correct_size_x;
   

    // Load Polygon DIsplay Boundaries
    for (int i = 0; i < boundariesData.size(); i++) {
        // Get each object in the array
        point = boundariesData.getJSONObject(i);
        // Get x,y from position
        mapped_correct_size_y = map(point.getFloat("Y"), 0, original_size_y,  0, scaled_y) + height/2 - mid_y ;
        mapped_correct_size_x = map(point.getFloat("X"), 0, original_size_x, 0, scaled_x) + width/2 - mid_x;
         
        //balls = (Ball[]) append(balls, b);
        metro_boundary.addPoint(mapped_correct_size_x, mapped_correct_size_y);

    }
    
    // Load Polygon Collision Boundaries
    for (int i = 0; i < boundariesDataCollision.size(); i++) {
        // Get each object in the array
        point = boundariesDataCollision.getJSONObject(i);
        // Get x,y from position
        mapped_correct_size_y = map(point.getFloat("Y"), 0, original_size_y,  0, scaled_y) + height/2 - mid_y ;
        mapped_correct_size_x = map(point.getFloat("X"), 0, original_size_x, 0, scaled_x) + width/2 - mid_x;
         
        //balls = (Ball[]) append(balls, b);
        metro_boundary_collide.addPoint(mapped_correct_size_x, mapped_correct_size_y);

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
    
    // Load Inside Pilons Boundaries
    for (int i = 1; i <= inside_boundaries_pilons_json.size(); i++) {
        new_boundary = new Boundary();
        paths_vertices = inside_boundaries_pilons_json.getJSONArray(str(i));
        for (int j = 0; j < paths_vertices.size(); j++) {
            point = paths_vertices.getJSONObject(j);
            mapped_correct_size_y = map(point.getFloat("Y"), 0, original_size_y,  0, scaled_y) + height/2 - mid_y ;
            mapped_correct_size_x = map(point.getFloat("X"), 0, original_size_x, 0, scaled_x) + width/2 - mid_x;
            
            new_boundary.addPoint(mapped_correct_size_x, mapped_correct_size_y);
        }
        metro_boundary_pilons = (Boundary[]) append(metro_boundary_pilons, new_boundary);
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
    
    //size(1600, 1000);
    fullScreen(P3D);
    
    // ------ Slider Setup
    congestionSlider = new Slider(0, maxNumOfParticles, 0, 5, width - 250, 25, 230, 20, "Congestion", width-425, 45);
    cohesionSlider = new Slider(0, 1, 0, 0.1, width - 250, 70, 230, 20, "Cohesion", width-425, 90);
    separationSlider = new Slider(0, 1.1, 0, 0.05, width - 250, 115, 230, 20, "Separation", width-425, 135);
    speedSlider = new Slider(0.1, 2, 1, 0.1, width - 250, 160, 230, 20, "Speed", width-425, 180);
    
    //String[] fontList = PFont.list();
    //printArray(fontList);
  
    custom_font_title = createFont("Futura PT Bold", 70);
    custom_font_subtitle = createFont("Futura PT Bold", 40);
    
    image(img_wlines, 0, 0, width, height);
    background(0, 0, 0);
    
    
    // add sound on loop
    sfile = new SoundFile(this, "assets/sound/background_noise.mpeg");
    sfile.amp(0);
    sfile.loop();
}

// Animate Function
void draw() {
    // Enable Helpers if needed
    if (second_viz == true) {
        //background(0, 0, 0);
        fill(0, 0, 0, 10);
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
    
    // Draw Sliders
    congestionSlider.display();
    cohesionSlider.display();
    separationSlider.display();
    speedSlider.display();
    

    // --------- Generate Particles

    // Build particles until desired length
    if (particles.size() <= congestionSlider.current_value && congestionSlider.current_value != 0) {
        //start a car at a random path then eliminate it when it has reached the end of the path
        Path path = paths[int(random(paths.length))];
        Particle car = new Particle(path.getStart().x, path.getStart().y);
        car.pathToFollow = path;
        particles.add(car);
    }
    
    // --- Adjust sound based on particle number
    sfile.amp(map(congestionSlider.current_value, 0, congestionSlider.maximum, 0.0, 1.0));

    boolean inside_sec = false;
    boolean inside_main = false;

    //--- Path Following Particles
    for (int i = 0; i < particles.size(); i++) {
        // Collision detection
        //inside_main = particles.get(i).boundaries(metro_boundary, false);
        particles.get(i).collide_inside_bd(metro_boundary_collide, 35);
        
        for (Boundary bd: metro_boundary_pilons) {
          particles.get(i).collide_inside_bd(bd, 20);
          //inside_sec = particles.get(i).boundaries(bd,true);
          // if(inside_sec) break;
        }


        // Apply Behaviours of Particles
        boolean eliminate = particles.get(i).applyBehaviors(particles);

        // display
        particles.get(i).update();
        particles.get(i).show();
        
        // Despawn and respawn particles
        if (eliminate || inside_sec || inside_main) {
           particles.remove(i);
        }  
        
    }
    // Draw overlay after particles
    //if (draw_metro_lines)
    //    image(img_wlines, 0, 0, width, height);
    //else
    //    image(img, 0, 0, width, height);

    
    // Draw Title and Subtitle
    strokeWeight(0);
    fill(100);
    textFont(custom_font_title);
    text("Overflow", 20, height-100);
    
    textFont(custom_font_subtitle);
    text("The city and its places", 20, height-50);
    
    
    textFont(custom_font_title,36);
    // white float frameRate
    fill(255);
    text(frameRate,20,20);
    // gray int frameRate display:
    fill(200);
    text(int(frameRate),20,60);

}

// Buttons for Helpers
void keyPressed() {
    if (key == '0') {
        particles = new ArrayList<Particle>();
    } else if (key == '.') {
        second_viz = (!second_viz) ? true : false;
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
