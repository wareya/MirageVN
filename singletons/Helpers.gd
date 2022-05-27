tool
extends Node

func get_delta_elapsed():
    if Engine.editor_hint:
        return OS.get_ticks_msec()/1000.0
    else:
        return Manager.delta_elapsed

var point = CircleShape2D.new()
func overlaps_point(object : CollisionObject2D, pointer : Node2D, offset : Vector2 = Vector2()):
    point.radius = 0.0
    for owner in object.get_shape_owners():
        if object.is_shape_owner_disabled(owner):
            continue
        for i in range(object.shape_owner_get_shape_count(owner)):
            var shape : Shape2D = object.shape_owner_get_shape(owner, i)
            var transform = object.shape_owner_get_transform(owner)
            if shape.collide(object.global_transform * transform, point, pointer.global_transform.translated(offset)):
                return true
    return false

func overlaps_at_offset(object : CollisionObject2D, object2 : CollisionObject2D, offset : Vector2 = Vector2()):
    for owner in object.get_shape_owners():
        if object.is_shape_owner_disabled(owner):
            continue
        for owner2 in object2.get_shape_owners():
            if object2.is_shape_owner_disabled(owner2):
                continue
            for i in range(object.shape_owner_get_shape_count(owner)):
                var shape : Shape2D = object.shape_owner_get_shape(owner, i)
                var transform = object.shape_owner_get_transform(owner)
                transform = object.global_transform * transform
                for i2 in range(object2.shape_owner_get_shape_count(owner2)):
                    var shape2 : Shape2D = object2.shape_owner_get_shape(owner2, i2)
                    var transform2 = object2.shape_owner_get_transform(owner2)
                    transform2 = object2.global_transform * transform2
                    
                    if shape.collide(transform, shape2, transform2.translated(offset)):
                        return true
    
    return false

func _yield_connections_preprocess(list : Array) -> Array:
    var i = 0
    while i < list.size():
        if list[i] is GDScriptFunctionState:
            list[i] = [list[i], "completed"]
        elif list[i] is Array:
            if list[i].size() != 2 or not list[i][0] is Object or not list[i][1] is String:
                list.remove(i)
                i -= 1
        i += 1
    return list

class YieldAny extends Reference:
    signal completed
    var connections : Array
    static func build(list : Array) -> YieldAny:
        var ret = YieldAny.new()
        for entry in Helpers._yield_connections_preprocess(list):
            ret.attach(entry)
        return ret
    func attach(entry : Array):
        var obj : Object = entry[0]
        var sig : String = entry[1]
        if obj.connect(sig, self, "trigger", [obj, sig]) == OK:
            connections.push_back([obj, sig])
    func trigger():
        for entry in connections:
            var obj : Object = entry[0]
            var sig : String = entry[1]
            if is_instance_valid(obj):
                obj.disconnect(sig, self, "trigger")
        connections = []
        emit_signal("completed")
func yield_any(list : Array):
    return YieldAny.build(list)

class YieldAll extends Reference:
    signal completed
    var connections : Array
    static func build(list : Array) -> YieldAll:
        var ret = YieldAll.new()
        for entry in Helpers._yield_connections_preprocess(list):
            ret.attach(entry)
        return ret
    func attach(entry : Array):
        var obj : Object = entry[0]
        var sig : String = entry[1]
        if obj.connect(sig, self, "trigger", [obj, sig]) == OK:
            connections.push_back([obj, sig])
    func trigger(_obj : Object, _sig : String):
        for i in range(connections.size()):
            var entry = connections[i]
            var obj : Object = entry[0]
            var sig : String = entry[1]
            if _obj == obj and _sig == sig:
                connections.remove(i)
                break
        if connections.size() == 0:
            emit_signal("completed")
func yield_all(list : Array):
    return YieldAll.build(list)

func force_coroutine(ret):
    if ret is GDScriptFunctionState:
        return ret
    else:
        yield(get_tree(), "idle_frame")
        return ret
