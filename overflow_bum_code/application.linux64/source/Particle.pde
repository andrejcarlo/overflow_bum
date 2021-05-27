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
    color c[] = {color(150,52,132), color(45,102,190), color(96,175,255), color(40,194,255),color(42,245,255)};
    Path pathToFollow;
    color color_assigned = c[int(random(c.length))];
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
    boolean borders(Path path) {
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
    PVector align(ArrayList<Particle> particles) {
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
    ArrayList<PVector> separation_cohesion(ArrayList<Particle> particles) {
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
    void collide_inside_bd(Boundary metro_bd, float pilonSize) {
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
    boolean boundaries (Boundary metro_bd, boolean inside) {
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
    PVector follow(Path path) {

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
    PVector seek(PVector target) {
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
    boolean applyBehaviors(ArrayList vehicles) {
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
        velocity.setMag(map(50, 0, 100, 4, 0.1));
        // apply speed factor to velocity
        velocity.mult(speedSlider.current_value);
        return eliminate;
    }
    // apply a force (if mass is 1 then add it to acceleration)
    void applyForce(PVector force) {
        // We could add mass here if we want A = F / M
        acceleration.add(force);
    }
    // update position, velocity of the particle (animate the particle)
    void update() {
        position.add(velocity);
        velocity.add(acceleration);
        velocity.limit(maxSpeed);
        acceleration.mult(0);
    }
    // Draw the particle on screen
    void show() {
        fill(color_assigned);
        noStroke();
        circle(position.x, position.y, 3);
    }

}
// A function to get the normal point from a point (p) to a line segment (a-b)
// This function could be optimized to make fewer new Vector objects
PVector getNormalPoint(PVector p, PVector a, PVector b) {
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
