extends Node
class_name CutsceneParser

# description of cutscene text preprocessing logic
# (i.e. lines that go `"narration text"` or `"name" > "dialogue text"`)
# ----
# 1) split the line into: indentation; list of character sequences that are either string literals or not string literals
# 1.a) i.e. `    "asdf" > func() > "gigawer"  ` will be split into:
#       `    `
#       `"asdf"`
#       ` > func() > `
#       `"gigawer"`
#       `  `
# 2) if the first non-indentation character is not " or ',
#    or there are too few items, skip the line and re-emit it as-is
# 3) check if the third item is ">" after being whites-space-stripped.
#    if it is, treat the line as dialogue
# 4) otherwise treat the line as narration
# 5) in dialogue, the second item is used as the name/identity,
#    and the fourth-and-later tokens are combined and emitted as an expression.
#    this expression should evaluate to a string containing the bbcode you want to display.
# 6) in narration, the second-and-later tokens are combined and emitted as an expression.
#    this expression should evaluate to a string containing the bbcode you want to display.

# yield statements are parsed more properly, but must still only be a single line, and cannot be overly complex.
# (e.g. they will break if you stick a (){}[] or # in a string inside of them)
# (if you need to do this, assign the string to a variable first, then use that variable)

static func parse_yield(line : String):
    #var obj = ""
    #var sig = ""
    
    var end = line.length()
    
    var yield_start = line.find("yield")
    if yield_start < 0:
        return null
    
    var indent_end = -1
    for i in range(0, yield_start+1):
        var c = line[i]
        if c == "#":
            return null
        if c != " " and c != "\t":
            indent_end = i
            break
    
    var obj_start = -1
    var obj_end = -1
    var sig_start = -1
    var sig_end = -1
    var depth = 0
    for i in range(yield_start, end):
        var c = line[i]
        if obj_start < 0:
            if c == "(":
                obj_start = i + 1
        else:
            if c in "({[":
                depth += 1
            elif c in ")}]":
                depth -= 1
            
            if obj_end < 0:
                if c == "," and depth == 0:
                    obj_end = i
                    sig_start = i+1
            if sig_start >= 0 and sig_end < 0:
                if c == ")" and depth == -1:
                    sig_end = i
    
    var ret = \
        { "indent" : line.substr(0, indent_end),
          "prefix" : line.substr(indent_end, yield_start - indent_end),
          "obj" : line.substr(obj_start, obj_end - obj_start),
          "sig" : line.substr(sig_start, sig_end - sig_start),
        }
    #print(ret)
    #print(sig_start)
    #print(sig_end)
    
    if sig_end >= 0:
        return ret
    else:
        return null

static func parse_text(line : String, linenum : int):
    var stuff = [""]
    var in_indentation = true
    var in_string = false
    var in_escape = false
    var in_comment = false
    var string_type = ""
    var i = 0
    while i < line.length():
        var c : String = line[i]
        if in_indentation and not c in " \t\n\r":
            in_indentation = false
            stuff.push_back("")
        if in_comment:
            stuff[stuff.size()-1] += c  
        elif !in_string:
            if c == '"' or c == "'":
                # handle transfer into string mode
                stuff.push_back("")
                in_string = true
                if c == '"' and i+2 < line.length() and line[i+1] == '"' and line[i+2] == '"':
                    string_type = '"""'
                    i += 2
                else:
                    string_type = c
                stuff[stuff.size()-1] += string_type
            elif c == "#":
                # move into comment mode
                stuff.push_back("")
                stuff[stuff.size()-1] += c
                in_comment = true
            else:
                stuff[stuff.size()-1] += c
        else: # in string
            # in an escape sequence, or at the escape prefix itself
            if in_escape or c == "\\":
                stuff[stuff.size()-1] += c
                in_escape = !in_escape
            # end of string
            elif line.find(string_type, i) == i:
                stuff[stuff.size()-1] += string_type
                stuff.push_back("")
                i += string_type.length()-1
                string_type = ""
                in_string = false
            # continuation of string
            else:
                stuff[stuff.size()-1] += c
        i += 1
    
    if in_string:
        assert(false, "multi-line strings are not supported by the cutscene parser (line %s)" % [linenum])
    
    i = 0
    while i < stuff.size():
        if stuff[i] == "":
            stuff.remove(i)
        else:
            i += 1
    
    return stuff

static func array_join(array : Array, from : int, to_exclusive : int = -1):
    if to_exclusive < 0:
        to_exclusive = array.size()
    var ret = ""
    for i in range(from, to_exclusive):
        ret += array[i]
    return ret

static func parsify(script : GDScript):
    var code : String = script.source_code
    var new_code : Array = []
    var LINE_NUM = 0 # in terms of content text
    var code_linenum = 1
    var force_next_line_num = -1
    for _line in code.split("\n"):
        var line : String = _line
        var parse_data = parse_text(line, code_linenum)
        code_linenum += 1
        
        # don't read root-level or blank lines
        if parse_data.size() < 1:
            continue
        
        var indentation = parse_data[0]
        
        var stripped = line.strip_edges()
        if stripped == "#### LINE_DELETED_HERE":
            new_code.push_back("%sManager.set_load_line(%s)"
                % [indentation, LINE_NUM])
            new_code.push_back("%sif Manager.LOAD_SKIP and Manager.SAVED_LINE == %s: Manager.notify_load_finished()"
                % [indentation, LINE_NUM])
            
            new_code.push_back(line)
            
            LINE_NUM += 1
            continue
        
        if stripped.begins_with("#### LINE_ADDED_FORCE_NEXT_LINE_NUM "):
            var next = stripped.split("#### LINE_ADDED_FORCE_NEXT_LINE_NUM ", true, 1)
            force_next_line_num = int(next[1])
            
            new_code.push_back(line)
            continue
        
        if stripped.begins_with("#### LINE_DELETED_FORCE_LINE_NUM "):
            var next = stripped.split("#### LINE_DELETED_FORCE_LINE_NUM ", true, 1)
            var num = int(next[1])
            
            # FIXME: do we need the first one of these two statements?
            new_code.push_back("%sManager.set_load_line(%s)"
                % [indentation, num])
            new_code.push_back("%sif Manager.LOAD_SKIP and Manager.SAVED_LINE == %s: Manager.notify_load_finished()"
                % [indentation, num])
            
            new_code.push_back(line)
            continue
        
        # skip if only indentation, or if first non-indentation isn't a string
        if parse_data.size() < 2 or not parse_data[0][0] in " \t\r\n" or not parse_data[1][0] in ["'", '"']:
            new_code.push_back(line)
            continue
        
        var is_dialogue = parse_data.size() >= 4 and parse_data[2].strip_edges() == ">"
        
        var line_num_stash = -1
        
        if force_next_line_num >= 0:
            line_num_stash = LINE_NUM
            LINE_NUM = force_next_line_num
            force_next_line_num = -1
        
        new_code.push_back("%sManager.set_load_line(%s)"
            % [indentation, LINE_NUM])
        new_code.push_back("%sif Manager.LOAD_SKIP and Manager.SAVED_LINE == %s: Manager.notify_load_finished()"
            % [indentation, LINE_NUM])
        
        if !is_dialogue:
            new_code.push_back("%sManager.textbox_set_identity()" % [indentation])
            new_code.push_back("%sManager.textbox_set_bbcode(%s)" % [indentation, array_join(parse_data, 1)])
            new_code.push_back("%sManager.textbox_set_continue_icon('next')" % [indentation])
            new_code.push_back("%syield(Manager, 'cutscene_continue')" % [indentation])
            new_code.push_back("")
        else:
            new_code.push_back("%sManager.textbox_set_identity(%s)"
                    % [indentation, parse_data[1]])
            new_code.push_back("%sManager.textbox_set_bbcode(%s)" % [indentation, array_join(parse_data, 3)])
            new_code.push_back("%sManager.textbox_set_continue_icon('next')" % [indentation])
            new_code.push_back("%syield(Manager, 'cutscene_continue')" % [indentation])
            new_code.push_back("")
        
        if line_num_stash >= 0:
            LINE_NUM = line_num_stash
        else:
            LINE_NUM += 1
    
    var _i = 0
    while _i < new_code.size():
        var data = parse_yield(new_code[_i])
        if data:
            var a = "%sif true:" % [data.indent]
            var b = "%s    var ___yield_expr_kfau234uf2eud_a = %s" % [data.indent, data.obj]
            var c = "%s    var ___yield_expr_kfau234uf2eud_b = %s" % [data.indent, data.sig]
            var d = "%s    if !Manager.LOAD_SKIP: print('yielding for... ', \"\"\" %s, %s \"\"\")" % [data.indent, data.obj, data.sig]
            var e = "%s    if !Manager.LOAD_SKIP: %syield(___yield_expr_kfau234uf2eud_a, ___yield_expr_kfau234uf2eud_b)" % [data.indent, data.prefix]
            new_code[_i] = a
            _i += 1
            new_code.insert(_i, b)
            _i += 1
            new_code.insert(_i, c)
            _i += 1
            new_code.insert(_i, d)
            _i += 1
            new_code.insert(_i, e)
            
            #print("post-parse ---------")
            #print(a)
            #print(b)
            #print(c)
            #print(d)
            #print(e)
        _i += 1
    
    new_code.append_array(Array("""
func kill():
    queue_free()
    """.split("\n")))
    
    var new_source_code = PoolStringArray(new_code).join("\n")
    #print(new_source_code)
    var f = File.new()
    f.open("user://_cutscene_parser_output.gd", File.WRITE)
    f.store_string(new_source_code)
    f.flush()
    f.close()
    
    var old_path = script.resource_path
    script = GDScript.new()
    script.set_source_code(new_source_code)
    #warning-ignore:return_value_discarded
    script.reload()
    #script.resource_path = old_path
    return script
