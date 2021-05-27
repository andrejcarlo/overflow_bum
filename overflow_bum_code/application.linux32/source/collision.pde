/*
Repo: https://github.com/bmoren/p5.collide2D/
Created by http://benmoren.com
Some functions and code modified version from http://www.jeffreythompson.org/collision-detection
Version v0.7.3 | June 22, 2020
CC BY-NC-SA 4.0
*/


boolean _collideDebug = false;

void collideDebug (boolean debugMode) {
    _collideDebug = debugMode;
}

/*~++~+~+~++~+~++~++~+~+~ 2D ~+~+~++~+~++~+~+~+~+~+~+~+~+~+~+*/


boolean collidePointCircle (float x, float y, float cx, float cy, float d) {
    //2d
    if (dist(x, y, cx, cy) <= d / 2) {
        return true;
    }
    return false;
};

boolean collidePointLine (float px, float py, float x1, float y1, float x2, float y2) {
    // get distance from the point to the two ends of the line
    float d1 = dist(px, py, x1, y1);
    float d2 = dist(px, py, x2, y2);
    float buffer = 0.1;

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

ArrayList collideLineCircle (float x1, float y1, float x2, float y2, float cx, float cy, float diameter) {
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

ArrayList collidePointPoly (float px, float py, ArrayList<PVector> vertices) {
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
ArrayList collideCirclePoly (float cx, float cy, float diameter, ArrayList<PVector> vertices, boolean interior) {

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
