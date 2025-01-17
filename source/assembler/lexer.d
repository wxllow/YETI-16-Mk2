module yeti16.assembler.lexer;

import std.conv;
import std.string;
import std.algorithm;

enum TokenType {
	Null,
	Identifier,
	Integer,
	String,
	Label,
	End
}

struct Token {
	TokenType type;
	string    contents;
	string    file;
	size_t    line;
	size_t    col;
}

class Lexer {
	Token[] tokens;
	size_t  i;
	string  file;
	size_t  line;
	size_t  col;
	string  reading;
	string  code;
	bool    inString;

	this() {
		
	}

	void AddToken(TokenType type) {
		tokens  ~= Token(type, reading, file, line, col);
		reading  = "";
	}

	void AddBlank(TokenType type) {
		tokens ~= Token(type, "", file, line, col);
	}

	void AddReading() {
		if (reading.isNumeric()) {
			AddToken(TokenType.Integer);
		}
		else if (reading.startsWith("0x")) {
			reading = reading[2 .. $].to!long(16).text();
			AddToken(TokenType.Integer);
		}
		else if (reading.startsWith("0b")) {
			reading = reading[2 .. $].to!long(2).text();
			AddToken(TokenType.Integer);
		}
		else {
			AddToken(TokenType.Identifier);
		}
	}

	void Lex() {
		for (i = 0; i < code.length; ++ i) {
			if (code[i] == '\n') {
				++ line;
				col = 0;
			}
			else {
				++ col;
			}

			if (inString) {
				switch (code[i]) {
					case '"': {
						inString = false;
						AddToken(TokenType.String);
						break;
					}
					default: reading ~= code[i];
				}
			}
			else {
				switch (code[i]) {
					case ',':
					case ' ':
					case '\t':
					case '\n': {
						if (reading.strip() == "") {
							reading = "";
							goto addLine;
						}
						
						AddReading();

						addLine:
						if (code[i] == '\n') {
							if (
								(tokens.length > 0) &&
								(tokens[$ - 1].type == TokenType.End)
							) {
								break;
							}
							AddBlank(TokenType.End);
						}
						break;
					}
					case '"': {
						inString = true;
						break;
					}
					case '\r': continue;
					case ':': {
						AddToken(TokenType.Label);
						AddToken(TokenType.End);
						break;
					}
					case ';': {
						if (reading.strip() != "") {
							AddReading();
						}

						while (code[i] != '\n') {
							++ i;
							if (i >= code.length) break;
						}

						++ line;
						col = 0;
						AddToken(TokenType.End);
						break;
					}
					default: {
						reading ~= code[i];
					}
				}
			}
		}

		if ((tokens.length == 0) || (tokens[$ - 1].type != TokenType.End)) {
			AddBlank(TokenType.End);
		}
	}
}
