module uimdb.integration;

import std.exception : enforce;
import std.file : write, tempDir;
import std.path : buildPath;
import std.process : execute;
import std.uuid : randomUUID;
import uimdb.jsoncompat : JSONValue;

class LanguageBridge {
public:
    JSONValue runPython(string code, JSONValue payload) {
        auto scriptPath = buildPath(tempDir(), "uim_py_" ~ randomUUID().toString() ~ ".py");
        auto program = code ~ "\n";
        write(scriptPath, program);
        auto result = execute(["python3", scriptPath], payload.toString());
        return JSONValue([
            "exitCode": JSONValue(result.status),
            "stdout": JSONValue(result.output),
            "stderr": JSONValue(result.stderrOutput)
        ]);
    }

    JSONValue runR(string code, JSONValue payload) {
        auto scriptPath = buildPath(tempDir(), "uim_r_" ~ randomUUID().toString() ~ ".R");
        auto program = code ~ "\n";
        write(scriptPath, program);
        auto result = execute(["Rscript", scriptPath], payload.toString());
        return JSONValue([
            "exitCode": JSONValue(result.status),
            "stdout": JSONValue(result.output),
            "stderr": JSONValue(result.stderrOutput)
        ]);
    }
}
