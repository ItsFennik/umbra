.pragma library

// Small calculator for the launcher. A recursive-descent parser, so nothing is ever eval'd.
//   + - * / % ^ (power), parentheses, unary minus, "x" "×" "÷" as operators,
//   constants pi tau e, functions sqrt cbrt abs round floor ceil exp ln log log2 sin cos tan asin acos atan.
// evaluate() returns a finite number, or throws an Error with a short message.

var constants = { pi: Math.PI, tau: 2 * Math.PI, e: Math.E };
var functions = {
    sqrt: Math.sqrt, cbrt: Math.cbrt, abs: Math.abs, round: Math.round, floor: Math.floor, ceil: Math.ceil,
    exp: Math.exp, ln: Math.log, log: Math.log10, log2: Math.log2,
    sin: Math.sin, cos: Math.cos, tan: Math.tan, asin: Math.asin, acos: Math.acos, atan: Math.atan
};

function tokenize(text) {
    var tokens = [];
    var i = 0;
    while (i < text.length) {
        var c = text[i];
        if (/\s/.test(c)) {
            i++;
        } else if (/[0-9.]/.test(c)) {
            var m = /^(\d+\.?\d*|\.\d+)(e[+-]?\d+)?/i.exec(text.slice(i));
            if (!m)
                throw new Error("Unexpected “" + c + "”");
            tokens.push({ type: "num", value: parseFloat(m[0]) });
            i += m[0].length;
        } else if ((c === "x" || c === "X") && /^[\s\d.(]/.test(text[i + 1] || "")) {
            // "2x3" and "2 x (1+1)" read as multiplication.
            tokens.push({ type: "op", value: "*" });
            i++;
        } else if (/[a-z]/i.test(c)) {
            var w = /^[a-z][a-z0-9]*/i.exec(text.slice(i))[0].toLowerCase();
            tokens.push({ type: "name", value: w });
            i += w.length;
        } else if ("+-*/%^()×÷−".indexOf(c) >= 0) {
            tokens.push({ type: "op", value: c === "×" ? "*" : c === "÷" ? "/" : c === "−" ? "-" : c });
            i++;
        } else {
            throw new Error("Unexpected “" + c + "”");
        }
    }
    return tokens;
}

function evaluate(text) {
    var tokens = tokenize(text);
    var pos = 0;

    function peek() { return tokens[pos]; }
    function isOp(v) { var t = tokens[pos]; return t && t.type === "op" && t.value === v; }
    function expect(v) {
        if (!isOp(v))
            throw new Error("Expected “" + v + "”");
        pos++;
    }

    // expression := term (("+" | "-") term)*
    function expression() {
        var v = term();
        while (isOp("+") || isOp("-"))
            v = tokens[pos++].value === "+" ? v + term() : v - term();
        return v;
    }
    // term := unary (("*" | "/" | "%") unary)*
    function term() {
        var v = unary();
        while (isOp("*") || isOp("/") || isOp("%")) {
            var op = tokens[pos++].value;
            var r = unary();
            v = op === "*" ? v * r : op === "/" ? v / r : v % r;
        }
        return v;
    }
    // unary := "-" unary | "+" unary | power
    function unary() {
        if (isOp("-")) { pos++; return -unary(); }
        if (isOp("+")) { pos++; return unary(); }
        return power();
    }
    // power := primary ("^" unary)?   (right-associative)
    function power() {
        var base = primary();
        if (isOp("^")) { pos++; return Math.pow(base, unary()); }
        return base;
    }
    function primary() {
        var t = peek();
        if (!t)
            throw new Error("Incomplete expression");
        if (t.type === "num") { pos++; return t.value; }
        if (isOp("(")) {
            pos++;
            var v = expression();
            expect(")");
            return v;
        }
        if (t.type === "name") {
            pos++;
            if (constants.hasOwnProperty(t.value))
                return constants[t.value];
            if (functions.hasOwnProperty(t.value)) {
                expect("(");
                var arg = expression();
                expect(")");
                return functions[t.value](arg);
            }
            throw new Error("Unknown name “" + t.value + "”");
        }
        throw new Error("Unexpected “" + t.value + "”");
    }

    if (tokens.length === 0)
        throw new Error("Type an expression");
    var result = expression();
    if (pos < tokens.length)
        throw new Error("Unexpected “" + tokens[pos].value + "”");
    if (!isFinite(result))
        throw new Error(isNaN(result) ? "Not a number" : "Infinity");
    return result;
}

// Whether a plain search looks like arithmetic rather than a name, e.g. "2+2" or "sqrt(2)" but not "2048".
function looksLikeMath(text) {
    var t = text.trim();
    if (!/\d|pi|tau/.test(t))
        return false;
    if (!/^[\d\s.+\-*/%^()×÷−a-z]+$/i.test(t))
        return false;
    return /[+\-*/%^×÷−]/.test(t.replace(/^[-+]/, "")) || /[\d)]\s*x\s*[\d.(]/i.test(t) || /^[a-z0-9]+\(/i.test(t);
}

function format(value) {
    if (Number.isInteger(value) && Math.abs(value) < 1e21)
        return String(value);
    var s = Math.abs(value) >= 1e15 || Math.abs(value) < 1e-9 ? value.toExponential(10) : value.toPrecision(12);
    // Drop trailing zeros, in both plain and exponential notation.
    return s.replace(/(\.\d*?)0+(e|$)/, "$1$2").replace(/\.(e|$)/, "$1");
}
