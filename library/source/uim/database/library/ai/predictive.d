module uim.database.library.ml;

import core.sync.mutex : Mutex;
import std.exception : enforce;
import uim.database.library.jsoncompat : JSONValue;


class PredictiveLibrary {
private:
    Mutex _mutex;
    LinearModel[string] _models;

public:
    this() {
        _mutex = new Mutex;
    }

    JSONValue trainLinear(string modelName, double[] x, double[] y) {
        enforce(x.length == y.length, "x and y length mismatch");
        enforce(x.length > 1, "at least 2 samples required");

        auto meanX = avg(x);
        auto meanY = avg(y);

        double num = 0;
        double den = 0;
        foreach (idx; 0 .. x.length) {
            auto dx = x[idx] - meanX;
            num += dx * (y[idx] - meanY);
            den += dx * dx;
        }

        enforce(den != 0, "cannot fit model with zero variance in x");

        auto slope = num / den;
        auto intercept = meanY - slope * meanX;

        synchronized (_mutex) {
            _models[modelName] = LinearModel(modelName, slope, intercept);
        }

        return JSONValue([
            "model": JSONValue(modelName),
            "slope": JSONValue(slope),
            "intercept": JSONValue(intercept)
        ]);
    }

    JSONValue predictLinear(string modelName, double x) {
        synchronized (_mutex) {
            enforce(modelName in _models, "unknown model");
            auto m = _models[modelName];
            auto y = m.slope * x + m.intercept;
            return JSONValue([
                "model": JSONValue(modelName),
                "x": JSONValue(x),
                "prediction": JSONValue(y)
            ]);
        }
    }

private:
    double avg(const double[] v) {
        double s = 0;
        foreach (x; v) {
            s += x;
        }
        return s / v.length;
    }
}
