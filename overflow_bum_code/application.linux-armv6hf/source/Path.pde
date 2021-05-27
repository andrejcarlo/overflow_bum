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
    void addPoint(float x, float y) {
        PVector point = new PVector(x, y);
        points.add(point);
    }

    PVector getStart() {
        return points.get(0);
    }

    PVector getEnd() {
        return points.get(points.size() - 1);
    }

    // Draw the path
    void display() {
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
