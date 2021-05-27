import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import processing.sound.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class overflow_bum_code extends PApplet {



ArrayList<Particle> particles = new ArrayList<Particle>(); // particles following paths
Path[] paths = new Path[0]; // paths to be followed by particles
Boundary metro_boundary = new Boundary(); // POLYGON BOUNDARY
Boundary metro_boundary_collide = new Boundary();
Boundary[] metro_boundary_inside = new Boundary[0]; // POLYGON BOUNDARIES INSIDE
Boundary[] metro_boundary_pilons = new Boundary[0]; // POLYGON BOUNDARIES INSIDE PILONS
PVector[] icon = new PVector[0];

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
JSONObject icon_json;

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
PFont acumin_font;


// Key Hack for P3d Button Presses
boolean reset_particles = false;
boolean activate_viz = false;
boolean enable_boundary = false;  
boolean congestion_increase = false;
boolean congestion_decrease = false;
boolean cohesion_increase = false;
boolean cohesion_decrease= false;
boolean separation_increase = false;
boolean separation_decrease = false;
boolean speed_increase = false;
boolean speed_decrease = false;

// Load JSON objects by reading the files
public void preload() {
    img_wlines = loadImage("assets/overlays/overlay_sine.png");
    img = loadImage("assets/overlays/overlay_titlu_gri1.png");
    boundaries_json = loadJSONObject("assets/data_from_rhino_bum/rotated/boundary_catacombs.json");
    boundaries_collide_json = loadJSONObject("assets/data_from_rhino_bum/rotated/boundary_catacombs_lowpoly.json");
    inside_boundaries_json = loadJSONObject("assets/data_from_rhino_bum/rotated/boundary_inside_catacombs.json");
    inside_boundaries_pilons_json = loadJSONObject("assets/data_from_rhino_bum/rotated/boundary_inside_pilons.json");
    paths_json = loadJSONObject("assets/data_from_rhino_bum/rotated/paths.json");
    icon_json = loadJSONObject("assets/data_from_rhino_bum/rotated/icon.json");
}

// Convert saved point data (JSON) into p5 polygon Objects
public void loadData() {
    int scale_offset = 85;
    float original_size_x =2427.075f;  //2311.76; 
    float original_size_y =1344.240f; //1570.776;
    float ratio_boundary = original_size_x/original_size_y;
    
    float scaled_y = height - scale_offset;
    float scaled_x = (height -scale_offset)*ratio_boundary;
    
    float mid_x = scaled_x/2;
    float mid_y = scaled_y/2;
    JSONArray boundariesData = boundaries_json.getJSONArray("0");
    JSONArray boundariesDataCollision = boundaries_collide_json.getJSONArray("0");
    JSONArray iconData = icon_json.getJSONArray("0");
    
    JSONObject point;
    JSONArray paths_vertices;
    Path new_path;
    Boundary new_boundary;
    float mapped_correct_size_y;
    float mapped_correct_size_x;
    
    // Load Polygon DIsplay Boundaries
    for (int i = 0; i < iconData.size(); i++) {
        // Get each object in the array
        point = iconData.getJSONObject(i);
        // Get x,y from position
        mapped_correct_size_y = map(point.getFloat("Y"), 0, original_size_y,  0, scaled_y) + height/2 - mid_y ;
        mapped_correct_size_x = map(point.getFloat("X"), 0, original_size_x, 0, scaled_x) + width/2 - mid_x;
         
        //balls = (Ball[]) append(balls, b);
        icon = (PVector[]) append(icon, new PVector(mapped_correct_size_x, mapped_correct_size_y));
       
    }
    
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
public void setup() {
    // load assets
    preload();
    loadData();
    
    print("Made with love in Delft/Bucharest by @andrejcarlo and @alxmuller");
    print("VERSION BUM_100");
    
    //size(1280, 720, P3D);
    
    
    // ------ Slider Setup
    congestionSlider = new Slider(0, maxNumOfParticles, 0, 20, width - 280, 38.5f, 230, 8, "CONGESTION", width-310, 47.5f);
    cohesionSlider = new Slider(0, 1.0f, 0, 0.1f, width - 280, 74.5f, 230, 8, "COHESION", width-310, 84.5f);
    separationSlider = new Slider(0, 1.1f, 0, 0.073f, width - 280, 109.5f, 230, 8, "SPREAD", width-310, 119.5f);
    speedSlider = new Slider(0.1f, 2, 1, 0.13f, width - 280, 146.5f, 230, 8, "SPEED", width-310, 154.5f);
    
    //String[] fontList = PFont.list();
    //printArray(fontList);
    acumin_font = loadFont("Montserrat-Black-48.vlw");
    custom_font_title = loadFont("Swiss721BT-BlackExtended-48.vlw");
    custom_font_subtitle = loadFont("Swiss721BT-BoldExtended-48.vlw");
    
    
    // add sound on loop
    sfile = new SoundFile(this, "assets/sound/ambience_aif.aif");
    sfile.amp(0.01f);
    sfile.loop();
}

// Animate Function
public void draw() {
    // Enable Helpers if needed
    if (second_viz == true) {
        //background(0, 0, 0);
        fill(0, 0, 0, 10);
        noStroke();
    } else {
        background(0);

        fill(0, 2);
        //stroke(51);
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
      displayIcon();
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
        Path path = paths[PApplet.parseInt(random(paths.length))];
        Particle car = new Particle(path.getStart().x, path.getStart().y);
        car.pathToFollow = path;
        particles.add(car);
    }
    
    // --- Adjust sound based on particle number
    sfile.amp(map(congestionSlider.current_value, 0.01f, congestionSlider.maximum, 0.01f, 1.0f));

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
    textAlign(LEFT);
    strokeWeight(0);
    fill(100);
    textFont(custom_font_title,41);
    text("OVERFLOW", 40, height-65);
    
    textFont(custom_font_subtitle,20);
    text("The city and its places", 48, height-40);
    
    
    //textFont(acumin_font,36);
    //// gray int frameRate display:
    //fill(200);
    //text(int(frameRate),20,60);
    
    
    //keyActions();

}


public void displayIcon() {
    //strokeWeight(2);
    fill(100);
    noStroke();
    // Draw Metro Boundary
    beginShape();
    //print(metro_boundary[1]);
    for (PVector v : icon) {
        vertex(v.x, v.y);
    }
    endShape(CLOSE);
}



public void keyPressed(){ 
  if (key == '0') {
        particles = new ArrayList<Particle>();
    } else if (key == '.') {
        second_viz = (!second_viz) ? true : false;
    } else if (key == '1') {
        draw_boundary = (!draw_boundary) ? true : false;
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
    //println("pressed");
}

//void keyTyped() {
//   println("typed"); 
//}
class Boundary {
  
    
    // An InsideBoundary is an arraylist (boundary) of points (PVector objects)
    ArrayList<PVector> points;
    
    
    Boundary() {
       points = new ArrayList<PVector>();

    }

    // Add a point to the path
    public void addPoint(float x, float y) {
        PVector point = new PVector(x, y);
        points.add(point);
    }

    public PVector getStart() {
        return points.get(0);
    }

    public PVector getEnd() {
        return points.get(points.size() - 1);
    }

    // Draw the path
    public void display() {
        strokeWeight(1);
        stroke(100);
        // Draw Metro Boundary
        beginShape();
        //print(metro_boundary[1]);
        for (PVector v : points) {
            vertex(v.x, v.y);
        }
        endShape(CLOSE);
    }
}
class Particle {
    PVector position;
    PVector velocity;
    PVector acceleration;
    float maxForce;
    float maxForceCohesion;
    float maxSpeed;
    float size;
    boolean[] infectionState;
    boolean infected;
    int stuck;
    int c[] = {color(150,52,132), color(45,102,190), color(96,175,255), color(40,194,255),color(42,245,255)};
    Path pathToFollow;
    int color_assigned = c[PApplet.parseInt(random(c.length))];
    float pilonSize;
  
    Particle (float x, float y) {
        position = new PVector(x, y);
        velocity = PVector.random2D();
        velocity.setMag(random(1, 3));
        acceleration = new PVector();
        maxForce = 2;
        maxForceCohesion = 4;
        maxSpeed = 4;
        size = 10;
        stuck = 0;
        //pilonSize = 20;

        //int r = int(random(255)); // r is a random number between 0 - 255
        //int g = int(random(100, 200)); // g is a random number betwen 100 - 200
        //int b = int(random(100)); // b is a random number between 0 - 100
        //int a = 255; // a is a random number between 200 - 255

        
    }
    
    // Despawn Particles once they reach the end of a path
    public boolean borders(Path path) {
        int perceptionRadius = 10;
        float d = dist(
            position.x,
            position.y,
            path.getEnd().x,
            path.getEnd().y
        );
        if (d < perceptionRadius) {
            return true;
            //position.x = path.getStart().x;
            //position.y = path.getStart().y;
            //velocity = new PVector(0, 0);
            //velocity.mult(maxSpeed);

        } else {
          return false;
            
        }
    }
    // Align Behaviour
    public PVector align(ArrayList<Particle> particles) {
        int perceptionRadius = 50;
        PVector steering = new PVector();
        int total = 0;
        for (Particle other : particles ) {
            float d = dist(
                position.x,
                position.y,
                other.position.x,
                other.position.y
            );
            if (other != this && d < perceptionRadius) {
                steering.add(other.velocity);
                total++;
            }
        }
        if (total > 0) {
            steering.div(total);
            steering.setMag(maxSpeed);
            steering.sub(velocity);
            steering.limit(maxForce);
        }
        return steering;
    }
    // Separation and Cohesion Behaviour
    public ArrayList<PVector> separation_cohesion(ArrayList<Particle> particles) {
        int perceptionRadius = 50;
        PVector steering_separation = new PVector();
        PVector steering_cohesion = new PVector();
        int total = 0;
        ArrayList<PVector> result = new ArrayList<PVector>();
        for (Particle other : particles ) {
            float d = dist(
                position.x,
                position.y,
                other.position.x,
                other.position.y
            );
            if (other != this && d < perceptionRadius && d != 0) {
                PVector diff = PVector.sub(position, other.position);
                diff.div(d * d);
                steering_separation.add(diff);
                steering_cohesion.add(other.velocity);
                total++;
                
            }
        }
        if (total > 0) {
            steering_separation.div(total);
            steering_separation.setMag(maxSpeed);
            steering_separation.sub(velocity);
            steering_separation.limit(maxForce);
            
            steering_cohesion.div(total);
            steering_cohesion.setMag(maxSpeed);
            steering_cohesion.sub(velocity);
            steering_cohesion.limit(maxForce);
        }
        result.add(steering_separation);
        result.add(steering_cohesion);
        return result;
        
    }
    
    // Collision Detection with Structural Pilons
    public void collide_inside_bd(Boundary metro_bd, float pilonSize) {
        int spring = 1;
        float minDist = pilonSize / 2 + size / 2;
        float dx,dy, distance = 0;
        
        for (PVector pilon: metro_bd.points) {
            // console.log(others[i]);
              dx = pilon.x - position.x;
              dy = pilon.y - position.y;
              distance = sqrt(dx * dx + dy * dy);
              //   console.log(distance);
              //console.log(minDist);
              if (distance < minDist) {
                  //console.log("2");
                  float angle = atan2(dy, dx);
                  float targetX = position.x + cos(angle) * minDist;
                  float targetY = position.y + sin(angle) * minDist;
                  float ax = (targetX - pilon.x) * spring;
                  float ay = (targetY - pilon.y) * spring;
  
                  velocity.x -= ax;
                  velocity.y -= ay;
              }
        }
    }


    // Collision Detection with the metro walls
    public boolean boundaries (Boundary metro_bd, boolean inside) {
        // boundary hits
        ArrayList hit_wall_detect = collideCirclePoly(position.x, position.y, size, metro_bd.points, false);
        ArrayList outside_wall_detect = collideCirclePoly(position.x, position.y, size, metro_bd.points, true);

        int spring = 1;
        float minDist = size / 2;
        boolean redirected = false;
        boolean inside_check;
        
        if (inside) inside_check = false;
        else inside_check = (boolean) outside_wall_detect.get(0);
        
        float dx,dy, distance = 0;
        
        if (hit_wall_detect.size() >= 3 && inside_check) {
            if ((float) hit_wall_detect.get(1) > 0 && (float) hit_wall_detect.get(2) > 0) {
            
              // console.log(others[i]);
              dx = (float) hit_wall_detect.get(1) - position.x;
              dy = (float) hit_wall_detect.get(2) - position.y;
              distance = sqrt(dx * dx + dy * dy);
              //   console.log(distance);
              //console.log(minDist);
              if (distance < minDist) {
                  //console.log("2");
                  float angle = atan2(dy, dx);
                  float targetX = position.x + cos(angle) * minDist;
                  float targetY = position.y + sin(angle) * minDist;
                  float ax = (targetX - (float) hit_wall_detect.get(1)) * spring;
                  float ay = (targetY - (float) hit_wall_detect.get(2)) * spring;
  
                  velocity.x -= ax;
                  velocity.y -= ay;
                  //lastPosition = position
                  redirected = true;
              }
              stuck = 0;
            }
        }
        if (inside) {
          if ((boolean) outside_wall_detect.get(0)){ 
            print("Ejected"); 
            return true;
          }       
          
        } else {
          if (!(boolean) outside_wall_detect.get(0)) return true;
        }
        
        return false;
    }
    
    // This function implements Craig Reynolds' path following algorithm
    // http://www.red3d.com/cwr/steer/PathFollow.html
    public PVector follow(Path path) {

        // Predict position 25 (arbitrary choice) frames ahead
        PVector predict = velocity.copy();
        predict.normalize();
        predict.mult(15); //25
        PVector predictpos = PVector.add(position, predict);

        // Now we must find the normal to the path from the predicted position
        // We look at the normal for each line segment and pick out the closest one
        PVector normal = null;
        PVector target = null;
        float worldRecord = 1000000; // Start with a very high worldRecord distance that can easily be beaten

        // Loop through all points of the path
        for (int i = 0; i < path.points.size() - 1; i++) {

            // Look at a line segment
            PVector a = path.points.get(i);
            PVector b = path.points.get(i+1);// % path.points.length]; // Note Path has to wraparound

            // Get the normal point to that line
            PVector normalPoint = getNormalPoint(predictpos, a, b);

            // Check if normal is on line segment
            PVector dir = PVector.sub(b, a);
            // If it's not within the line segment, consider the normal to just be the end of the line segment (point b)
            //if (da + db > line.mag()+1) {
            if (normalPoint.x < min(a.x, b.x) || normalPoint.x > max(a.x, b.x) || normalPoint.y < min(a.y, b.y) || normalPoint.y > max(a.y, b.y)) {
                normalPoint = b.copy();
                // If we're at the end we really want the next line segment for looking ahead
                a = path.points.get((i+1)%path.points.size());// % path.points.length];
                b = path.points.get((i+2)%path.points.size());// % path.points.length]; // Path wraps around
                dir = PVector.sub(b, a);
            }

            // How far away are we from the path?
            float d = PVector.dist(predictpos, normalPoint);
            // Did we beat the worldRecord and find the closest line segment?
            if (d < worldRecord) {
                worldRecord = d;
                normal = normalPoint;

                // Look at the direction of the line segment so we can seek a little bit ahead of the normal
                dir.normalize();
                // This is an oversimplification
                // Should be based on distance to path & velocity
                dir.mult(15); //25
                target = normal.copy();
                target.add(dir);
            }
        }


        boolean debug = false;
        // Draw the debugging stuff
        if (debug) {
            // Draw predicted future position
            stroke(0);
            fill(0);
            line(position.x, position.y, predictpos.x, predictpos.y);
            ellipse(predictpos.x, predictpos.y, 4, 4);

            // Draw normal position
            stroke(0);
            fill(0);
            ellipse(normal.x, normal.y, 4, 4);
            // Draw actual target (red if steering towards it)
            line(predictpos.x, predictpos.y, target.x, target.y);
            if (worldRecord > path.radius) fill(255, 0, 0);
            noStroke();
            ellipse(target.x, target.y, 8, 8);
        }

        // Only if the distance is greater than the path's radius do we bother to steer
        if (worldRecord > path.radius) {
            return seek(target);
        } else {
            return new PVector(0, 0);
        }
    }
    // A method that calculates and applies a steering force towards a target
    // STEER = DESIRED MINUS VELOCITY
    public PVector seek(PVector target) {
        PVector desired = PVector.sub(target, position); // A vector pointing from the position to the target

        // Normalize desired and scale to maximum speed
        desired.normalize();
        desired.mult(maxSpeed);
        // Steering = Desired minus Vepositionity
        PVector steer = PVector.sub(desired, velocity);
        steer.limit(maxForce); // Limit to maximum steering force

        return steer;
    }
    // apply all desired behaviours of the particle
    public boolean applyBehaviors(ArrayList vehicles) {
        // Follow path force (only for car particles)
        // TODO: apply only for car particles
        PVector steerForce = this.follow(pathToFollow);
        // Separate from other boids force
        ArrayList<PVector> sep_cohesion = this.separation_cohesion(vehicles);
        sep_cohesion.get(0).mult(separationSlider.current_value);
        sep_cohesion.get(1).mult(cohesionSlider.current_value);
        //PVector cohesionForce = this.align(vehicles);
        //cohesionForce.mult(cohesionSlider.current_value);

        this.applyForce(steerForce);
        this.applyForce(sep_cohesion.get(0));
        this.applyForce(sep_cohesion.get(1));
        boolean eliminate = this.borders(this.pathToFollow);
        velocity.setMag(map(50, 0, 100, 4, 0.1f));
        // apply speed factor to velocity
        velocity.mult(speedSlider.current_value);
        return eliminate;
    }
    // apply a force (if mass is 1 then add it to acceleration)
    public void applyForce(PVector force) {
        // We could add mass here if we want A = F / M
        acceleration.add(force);
    }
    // update position, velocity of the particle (animate the particle)
    public void update() {
        position.add(velocity);
        velocity.add(acceleration);
        velocity.limit(maxSpeed);
        acceleration.mult(0);
    }
    // Draw the particle on screen
    public void show() {
        fill(color_assigned);
        noStroke();
        circle(position.x, position.y, 3);
    }

}
// A function to get the normal point from a point (p) to a line segment (a-b)
// This function could be optimized to make fewer new Vector objects
public PVector getNormalPoint(PVector p, PVector a, PVector b) {
    // Vector from a to p
    PVector ap = PVector.sub(p, a);
    // Vector from a to b
    PVector ab = PVector.sub(b, a);
    ab.normalize(); // Normalize the line
    // Project vector "diff" onto line by using the dot product
    ab.mult(ap.dot(ab));
    PVector normalPoint = PVector.add(a, ab);
    return normalPoint;
}
class Path {
  
    float radius;
    // A Path is an arraylist of points (PVector objects)
    ArrayList<PVector> points;
    
    
    Path() {
        // Arbitrary radius of 5
        // A path has a radius, i.e how far is it ok for the boid to wander off
       radius = 5;
       points = new ArrayList<PVector>();

    }

    // Add a point to the path
    public void addPoint(float x, float y) {
        PVector point = new PVector(x, y);
        points.add(point);
    }

    public PVector getStart() {
        return points.get(0);
    }

    public PVector getEnd() {
        return points.get(points.size() - 1);
    }

    // Draw the path
    public void display() {
        strokeJoin(ROUND);

        // Draw thick line for radius
        stroke(175, 0);
        strokeWeight(radius * 2);
        noFill();
        beginShape();
        for (PVector v : points) {
            vertex(v.x, v.y);
        }
        endShape();
        // Draw thin line for center of path
        stroke(51);
        strokeWeight(3);
        noFill();
        //fill(51)
        beginShape();
        for (PVector v : points) {
            vertex(v.x, v.y);
        }
        endShape();
    }
}
class Slider {
  
    float minimum;
    float maximum;
    float default_value;
    float step;
    float current_value;
     
    float x_start,y_start;
    float width_slider, height_slider;
    int c = color(random(180, 330), random(30, 100), 100);
    
    float x_text, y_text;
    float text_size = 15;
    String text_str;
    
    Slider () {
      minimum = 0;
      maximum = minimum + 1;
      default_value = 0;
      current_value = default_value;
      step = 0.1f;
    }
    
    Slider(float min, float max, float default_val, float stp, int pos_x_start, float pos_y_start, float in_width_slider, float in_height_slider,String txt,  float pos_x_text, float pos_y_text) {
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
      
      text_str = txt;
      x_text = pos_x_text;
      y_text = pos_y_text;
      
    }
    
    public void increase_slider() {
      if (current_value + step <= maximum) {
        current_value += step;
      }else {
         current_value = maximum; 
      }
    }
    
    public void decrease_slider() {
      if (current_value - step >= minimum) {
        current_value -= step;
      } else {
       current_value = minimum; 
      }
    }  
    
    public void display() {
      textFont(custom_font_subtitle,text_size);
      textAlign(RIGHT);
      strokeWeight(0);
      fill(100);
      text(text_str, x_text,y_text);
      
      strokeWeight(0.5f);
      fill(100);
      //stroke(255);
      rect(x_start,y_start,width_slider,height_slider);
      
      float display_value = map(current_value, minimum, maximum, 0, width_slider);
      
      //stroke(50);
      //fill(191, 161, 130);
      fill(255);
      rect(x_start ,y_start, display_value,height_slider);
      
      
      
    }
}
/*
Repo: https://github.com/bmoren/p5.collide2D/
Created by http://benmoren.com
Some functions and code modified version from http://www.jeffreythompson.org/collision-detection
Version v0.7.3 | June 22, 2020
CC BY-NC-SA 4.0
*/


boolean _collideDebug = false;

public void collideDebug (boolean debugMode) {
    _collideDebug = debugMode;
}

/*~++~+~+~++~+~++~++~+~+~ 2D ~+~+~++~+~++~+~+~+~+~+~+~+~+~+~+*/


public boolean collidePointCircle (float x, float y, float cx, float cy, float d) {
    //2d
    if (dist(x, y, cx, cy) <= d / 2) {
        return true;
    }
    return false;
};

public boolean collidePointLine (float px, float py, float x1, float y1, float x2, float y2) {
    // get distance from the point to the two ends of the line
    float d1 = dist(px, py, x1, y1);
    float d2 = dist(px, py, x2, y2);
    float buffer = 0.1f;

    // get the length of the line
    float lineLen = dist(x1, y1, x2, y2);

    //// since floats are so minutely accurate, add a little buffer zone that will give collision
    //if (buffer == null) { buffer = 0.1; }   // higher # = less accurate

    // if the two distances are equal to the line's length, the point is on the line!
    // note we use the buffer here to give a range, rather than one #
    if (d1 + d2 >= lineLen - buffer && d1 + d2 <= lineLen + buffer) {
        return true;
    }
    return false;
}

public ArrayList collideLineCircle (float x1, float y1, float x2, float y2, float cx, float cy, float diameter) {
    // is either end INSIDE the circle?
    // if so, return true immediately
    boolean inside1 = collidePointCircle(x1, y1, cx, cy, diameter);
    boolean inside2 = collidePointCircle(x2, y2, cx, cy, diameter);
    if (inside1) {
        return new ArrayList(java.util.Arrays.asList(true,x1,y1));
    } else if (inside2) {
        return new ArrayList(java.util.Arrays.asList(true,x2,y2));
    }

    // get length of the line
    float distX = x1 - x2;
    float distY = y1 - y2;
    float len = sqrt((distX * distX) + (distY * distY));

    // get dot product of the line and circle
    float dot = (((cx - x1) * (x2 - x1)) + ((cy - y1) * (y2 - y1))) / pow(len, 2);

    // find the closest point on the line
    float closestX = x1 + (dot * (x2 - x1));
    float closestY = y1 + (dot * (y2 - y1));

    // is this point actually on the line segment?
    // if so keep going, but if not, return false
    boolean onSegment = collidePointLine(closestX, closestY, x1, y1, x2, y2);
    if (!onSegment) return new ArrayList(java.util.Arrays.asList(false));

    // draw a debug circle at the closest point on the line
    if (_collideDebug) {
        ellipse(closestX, closestY, 10, 10);
    }

    // get distance to closest point
    distX = closestX - cx;
    distY = closestY - cy;
    float distance = sqrt((distX * distX) + (distY * distY));

    if (distance <= diameter / 2) {
        return new ArrayList(java.util.Arrays.asList(true,closestX,closestY));
    }
    return new ArrayList(java.util.Arrays.asList(false));
}

public ArrayList collidePointPoly (float px, float py, ArrayList<PVector> vertices) {
    boolean collision = false;

    // go through each of the vertices, plus the next vertex in the list
    int next = 0;
    for (int current = 0; current < vertices.size(); current++) {

        // get next vertex in list if we've hit the end, wrap around to 0
        next = current + 1;
        if (next == vertices.size()) next = 0;

        // get the PVectors at our current position this makes our if statement a little cleaner
        PVector vc = vertices.get(current);    // c for "current"
        PVector vn = vertices.get(next);       // n for "next"

        // compare position, flip 'collision' variable back and forth
        if (((vc.y >= py && vn.y < py) || (vc.y < py && vn.y >= py)) &&
            (px < (vn.x - vc.x) * (py - vc.y) / (vn.y - vc.y) + vc.x)) {
            collision = !collision;
        }
    }
    return new ArrayList(java.util.Arrays.asList(collision));
}


// POLYGON/CIRCLE
public ArrayList collideCirclePoly (float cx, float cy, float diameter, ArrayList<PVector> vertices, boolean interior) {

    // go through each of the vertices, plus the next vertex in the list
    int next = 0;
    for (int current = 0; current < vertices.size(); current++) {

        // get next vertex in list if we've hit the end, wrap around to 0
        next = current + 1;
        if (next == vertices.size()) next = 0;

        // get the PVectors at our current position this makes our if statement a little cleaner
        PVector vc = vertices.get(current);    // c for "current"
        PVector vn = vertices.get(next);       // n for "next"

        // check for collision between the circle and a line formed between the two vertices
        ArrayList collision = collideLineCircle(vc.x, vc.y, vn.x, vn.y, cx, cy, diameter);
        if ((boolean)collision.get(0)) return collision;
    }

    // test if the center of the circle is inside the polygon
    if (interior == true) {
        ArrayList centerInside = collidePointPoly(cx, cy, vertices);
        if ((boolean) centerInside.get(0)) return centerInside;
    }

    // otherwise, after all that, return false
    return new ArrayList(java.util.Arrays.asList(false));
}
  public void settings() {  fullScreen(P3D); }
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "overflow_bum_code" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
