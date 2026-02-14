module uim.database.library.ai.linear;

class LinearModel {
    string name;
    double slope;
    double intercept;

    this(string name, double slope, double intercept) {
        this.name = name;
        this.slope = slope;
        this.intercept = intercept;
    }
}