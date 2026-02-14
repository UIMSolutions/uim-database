module uim.database.library.integration;

import std.exception : enforce;
import std.file : write, tempDir;
import std.path : buildPath;
import std.process : execute;
import std.uuid : randomUUID;
import uim.database.library.jsoncompat : JSONValue;

class LanguageBridge {
public:
    Json runPython(string code, Json payload) {
        auto scriptPath = buildPath(tempDir(), "uim_py_" ~ randomUUID().toString() ~ ".py");
        auto program = code ~ "\n";
        write(scriptPath, program);
        auto result = execute(["python3", scriptPath], payload.toString());
        return [
            "exitCode": Json(result.status),
            "stdout": Json(result.output),
            "stderr": Json(result.stderrOutput)
        ].toJson;
    }

    Json runR(string code, Json payload) {
        auto scriptPath = buildPath(tempDir(), "uim_r_" ~ randomUUID().toString() ~ ".R");
        auto program = code ~ "\n";
        write(scriptPath, program);
        auto result = execute(["Rscript", scriptPath], payload.toString());
        return [
            "exitCode": Json(result.status),
            "stdout": Json(result.output),
            "stderr": Json(result.stderrOutput)
        ].toJson;
    }
}
