class Boundary {
  
    
    // An InsideBoundary is an arraylist (boundary) of points (PVector objects)
    ArrayList<PVector> points;
    
    
    Boundary() {
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
        strokeWeight(4);
        stroke(255);
        // Draw Metro Boundary
        beginShape();
        //print(metro_boundary[1]);
        for (PVector v : points) {
            vertex(v.x, v.y);
        }
        endShape(CLOSE);
    }
}
