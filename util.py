# UTIL
# Various utility and helper functions, as well as standard constants and indexes


import numpy as np
import shutil
from sklearn import preprocessing
from operator import add
from copy import deepcopy
from blox import Schema
from collections import OrderedDict
from itertools import groupby


# Define constants for repeated use and indexing
X_POS = 0
Y_POS = 1
X_SIZE = 2
Y_SIZE = 3
COLOUR = 4
SHAPE = 5
NOTHING = 6
REWARD = 7
NEIGHBOURS = 8
ACTION = 9
LIMIT = 10


# One-hot encode a list of values or categories and return the new list
def oneHot(inputList):
    # Create encoder
    label_encoder = preprocessing.LabelEncoder()
    onehot_encoder = preprocessing.OneHotEncoder(sparse=False)
    # Form inputs and apply encoder
    a = np.array(inputList)
    i = label_encoder.fit_transform(a)
    i = i.reshape(len(i), 1)
    b = onehot_encoder.fit_transform(i)
    # Output result as list
    outputList = b.tolist()
    return outputList


# Given a position return a list of the eight surrounding neighbours and their relative position vectors
def neighbourPositions(pos):
    n1 = [tuple(map(add, pos, (-1, 1))), ["left", "above"]]
    n2 = [tuple(map(add, pos, (0, 1))), ["centre", "above"]]
    n3 = [tuple(map(add, pos, (1, 1))), ["right", "above"]]
    n4 = [tuple(map(add, pos, (1, 0))), ["right", "centre"]]
    n5 = [tuple(map(add, pos, (1, -1))), ["right", "below"]]
    n6 = [tuple(map(add, pos, (0, -1))), ["centre", "below"]]
    n7 = [tuple(map(add, pos, (-1, -1))), ["left", "below"]]
    n8 = [tuple(map(add, pos, (-1, 0))), ["left", "centre"]]
    return [n1, n2, n3, n4, n5, n6, n7, n8]


# Form a vector describing an object and its neighbours for use in learning
def formXvector(objId, state, oldMap):
    # Form primary object vector entry
    objPos = (state[objId][0], state[objId][1])
    vector = [deepcopy(state[objId])]
    vector[0][0] = "centre"
    vector[0][1] = "centre"
    # Form vector entries for neighbours of object
    neighbours = neighbourPositions(objPos)
    for nb in neighbours:
        if nb[0] in oldMap.keys() and len(oldMap[nb[0]]) != 0:

            # print nb[0]
            # print oldMap[nb[0]]
            # print oldMap[nb[0]][0]

            nbVector = deepcopy(state[oldMap[nb[0]][0]])
            nbVector[0] = nb[1][0]
            nbVector[1] = nb[1][1]
            vector.append(nbVector)
        # If there is no neighbour, add a vector with all None entries apart from the position and 'nothing' attributes
        else:
            new = [None for _ in range(NOTHING+1)]
            new[NOTHING] = "yes"
            new[0] = nb[1][0]
            new[1] = nb[1][1]
            vector.append(new)
    return vector


# Form a vector decribing the object relative to its previous state
def formYvector(objId, oldState, newState):
    # Form object vector
    vector = deepcopy(newState[objId])
    # Update position entries to be categorical variables relative to previous position
    oldPos = (oldState[objId][0], oldState[objId][1])
    newPos = (newState[objId][0], newState[objId][1])
    if newPos == oldPos:
        vector[0] = "centre"
        vector[1] = "centre"
    else:
        neighbours = neighbourPositions(oldPos)
        for nb in neighbours:
            if nb[0] == newPos:
                vector[0] = nb[1][0]
                vector[1] = nb[1][1]
    return vector


# Check against previous state and output any object whose attributes have changed
def changes(model):
    changes = []
    if model.prev != None:
        for objId in model.prev.keys():
            if model.prev[objId] != model.curr[objId]:
                changes.append(objId)
    return changes


# Converts a model state into a hashable format for storing in a set
def toHashable(prev, curr):
    #
    prev_state = []
    for key in prev.keys():
        if key != "action" and key != "reward":
            state.append(str(key) + ":(" + ",".join([str(item) for item in prev[key]]) + ")")
    prev_state.sort()

    curr_state = []
    for key in curr.keys():
        if key != "action" and key != "reward":
            state.append(str(key) + ":(" + ",".join([str(item) for item in curr[key]]) + ")")
    curr_state.sort()

    return ", ".join(state)


# Converts a binary vector x to a human-readable data point
def fromBinary(model, x_original):
    x = deepcopy(x_original)
    output = []
    objLengths = [len(obs[1][0]) for obs in model.observations[:NOTHING+1]]
    actionLength = len(model.obsActions[1][0])
    length = (9*sum(objLengths)) + actionLength
    # Check that x is the right length
    if len(x) != length:
        print("Error: Binary vector is not the right length")
        return
    # Iterate over object descriptions
    for i in range(1+NEIGHBOURS):
        objOutput = []
        objVector = x[:sum(objLengths)]
        x[:sum(objLengths)] = []
        # Iterate over attribute vectors
        for j in range(NOTHING+1):
            attVector = objVector[:objLengths[j]]
            objVector[:objLengths[j]] = []
            if attVector == [0 for item in attVector]:
                objOutput.append(None)
            else:
                attVector = tuple(attVector)
                objOutput.append(model.dictionaries[j][1][attVector])
        output.append(objOutput)
    # What remains of x is the action vector
    if x == [0 for item in x]:
        output.append(None)
    else:
        actVector = tuple(x)
        actOutput = model.dictionaries[ACTION][1][actVector]
        output.append(actOutput)
    return output


# Converts a human-readable data point x to a binary vector
def toBinary(model, x_original):
    x = deepcopy(x_original)
    output = []
    sumObjLengths = sum([len(obs[1][0]) for obs in model.observations[:NOTHING+1]])
    # Iterate over object descriptions
    for i in range(1+NEIGHBOURS):
        # # If there is no object in the neighbour position we add a vector of zeros apart from the 'nothing' attribite
        # blank = [None for item in x[i]]
        # blank[NOTHING] = "yes"
        # if x[i] == blank:
        #     new = [0 for k in range(sumObjLengths)]
        #     new[-1] = 1
        #     output = output + new
        #     continue
        # Add binary description of attributes based on one-hot encoding of observations

        for j in range(NOTHING+1):
            if x[i][j] == None:
                output = output + [0 for item in model.observations[j][1][0]]
            else:
                output = output + model.dictionaries[j][0][x[i][j]]

    # Add binary description of action
    # if x[ACTION] == None:
    #     output = output + model.dictionaries[ACTION][0]["none"]
    # else:
    output = output + model.dictionaries[ACTION][0][x[ACTION]]

    return output


# Converts a binary schema x to a human-readable schema
def fromBinarySchema(model, s_original, head):
    s = deepcopy(s_original)
    output = Schema()
    output.head = head
    objLengths = [len(obs[1][0]) for obs in model.observations[:NOTHING+1]]
    actionLength = len(model.obsActions[1][0])
    length = (9*sum(objLengths)) + actionLength
    # Check that s is the right length
    if len(s) != length:
        print("Error: Binary schema is not the right length")
        return
    # Iterate over object descriptions
    for i in range(1+NEIGHBOURS):
        objVector = s[:sum(objLengths)]
        s[:sum(objLengths)] = []
        # Iterate over attribute vectors
        for j in range(NOTHING+1):
            attVector = tuple(objVector[:objLengths[j]])
            objVector[:objLengths[j]] = []
            # If this vector represents an object attribute in the body of the schema
            if list(attVector) != [0 for k in range(len(attVector))]:
                attribute = model.dictionaries[j][1][attVector]
                output.objectBody[(i,j)] = attribute
    # What remains of x is the action vector
    actVector = tuple(s)
    if list(actVector) != [0 for k in range(len(actVector))]:
        action = model.dictionaries[ACTION][1][actVector]
        output.actionBody = action
    return output


# Converts a human-readable schema s to a binary schema
def toBinarySchema(model, s_original):
    s = deepcopy(s_original)
    # Create initial blank schema
    lengths = [len(obs[1][0]) for obs in model.observations[:7]]
    blankObjects = [[[0 for j in range(length)] for length in lengths] for k in range(1+NEIGHBOURS)]
    # Instantiate according to preconditions
    for key in s.objectBody.keys():
        [i,j] = list(key)
        attribute = s.objectBody[key]
        vector = model.dictionaries[j][0][attribute]
        blankObjects[i][j] = vector
    # Form and output final binary schema vector
    objectVector = flatten(flatten(blankObjects))
    action = s.actionBody
    if action == None:
        actionVector = [0 for item in model.obsActions[1][0]]
    else:
        actionVector = model.dictionaries[ACTION][0][action]
    vector = objectVector + actionVector
    return vector


# Flattens list by one level
def flatten(full):
    return [item for sub in full for item in sub]


# Converts list of observations and their one-hot encoded versions to dictionaries
def obsToDicts(obs):
    attributeToBinary = dict(zip(obs[0], obs[1]))
    binaryToAttribute = dict(zip([tuple(vector) for vector in obs[1]], obs[0]))
    return [attributeToBinary, binaryToAttribute]


# Takes a list and removes any duplicate entries, printing how many items were removed
def deDupe(old):
    new = [k for k,v in groupby(sorted(old))]
    numRemoved = len(old) - len(new)
    if numRemoved != 0:
        print("Successfully removed " + str(numRemoved) + " duplicate data")
    return new


# Simplifies a set a of schemas
def simplify(model, old, head, attribute):
    new = []
    # Remove pointless attributes
    counter = 0
    for schema in old:
        toRemove = []
        trimmed = False
        for key in schema.objectBody:
            obj = list(key)
            if obj[0] in range(NEIGHBOURS + 1) and obj[1] in range(Y_POS + 1):
                toRemove.append(key)
                trimmed = True
        if trimmed:
            counter += 1
        for rKey in toRemove:



            # print("REMOVING:")
            # print rKey
            # print schema.objectBody[rKey]
            #
            #


            del schema.objectBody[rKey]



    if counter != 0:
        print("Successfully reduced " + str(counter) + " schemas")

    # Remove duplicate schemas
    toRemove = []
    binary_schema_dict = {}
    old_binary = set([])
    for s in old:
        b = tuple(toBinarySchema(model, s))
        binary_schema_dict[b] = [s.name, s.positive, s.negative, s.failures]
        old_binary.add(b)
    newBinary = [list(item) for item in old_binary]

    # Remove schemas that are more complex/less general
    newBinary.sort(key=sum)
    for i in range(len(newBinary)):
        for j in range(i + 1, len(newBinary)):
            s1 = newBinary[i]
            s2 = newBinary[j]
            if s1 != s2 and np.dot(np.array(s1), np.array(s2)) == sum(s1):
                print("Removed:")
                ds2 = fromBinarySchema(model, s2, head)
                print(attribute + " = " + str(head) + " <- " + ds2.display(no_head=True))
                print("Because of:")
                ds1 = fromBinarySchema(model, s1, head)
                print(attribute + " = " + str(head) + " <- " + ds1.display(no_head=True))
                toRemove.append(s2)

    # Create list of new schemas to be returned
    new = []
    for s in newBinary:
        if s not in toRemove:
            n_s = fromBinarySchema(model, s, head)

            # Restore old schema properties
            n_s.name = binary_schema_dict[tuple(s)][0]
            n_s.positive = binary_schema_dict[tuple(s)][1]
            n_s.negative = binary_schema_dict[tuple(s)][2]
            n_s.failures = binary_schema_dict[tuple(s)][3]
            new.append(n_s)

    # Display notification to user if any schemas were removed
    numRemoved = len(old) - len(new)
    if numRemoved != 0:
        print("Successfully cut " + str(numRemoved) + " schemas")

    return new


# Recursively converts a nested mixture of lists and tuples into a nested tuple
def to_tuple(x):
    
    if type(x) != list and type(x) != tuple:
        return x
    else:
        return tuple([to_tuple(y) for y in x])


# Form a dictionary of constraints from a file
def form_constraints(constraint_list, action_list):

    # Initialise dictionary to return
    constraint_dict = dict(zip(action_list, [[] for _ in action_list]))
    constraint_dict["penalty"] = []

    # Form dictionary entries for each action and penalty constraint
    for line in constraint_list.splitlines():
        if len(line) == 0:
            continue
        elif line[0] == "#":
            continue
        elif line ==  "\n":
            continue
        elif line in constraint_dict.keys():
            curr = line
        else:
            constraint_dict[curr].append(line)

    # Form appropriately formatted strings to return
    for k in constraint_dict.keys():
        if len(constraint_dict[k]) == 0:
            if k == "penalty":
                constraint_dict[k] = "false"
            else:
                constraint_dict[k] = "true"
        elif k != "penalty":
            constraint_dict[k] = ", ".join(constraint_dict[k])

    return constraint_dict


# def to_problog_rule(att, key, schema):
#
#     # Initialise template variables and lists
#     blank_list = ["X_pos", "Y_pos", "X_size", "Y_size", "Colour", "Shape", "Nothing"]
#     change = {"centre": "", "left": " - 1", "right": " + 1", "below": " + 1", "above": " - 1"}
#     neighbours = []
#
#     # Form body of schema
#     body_list = [deepcopy(blank_list) for _ in range(NEIGHBOURS + 1)]
#     for (i,j) in schema.objectBody.keys():
#         if i != 0:
#             body_list[i][0] = "Nb{0}_X_pos".format(i)
#             body_list[i][1] = "Nb{0}_Y_pos".format(i)
#             neighbours.append(i)
#         body_list[i][j] = str(schema.objectBody[(i,j)])
#     head_list = deepcopy(body_list[0])
#     body_list = ["att(Nb{0}, ".format(nb) + ", ".join(body_list[nb]) + ", T0)" for nb in neighbours]
#     body_list.insert(0, "att(Obj, " + ", ".join(head_list) + ", T0)")
#     if att != REWARD:
#         body_list.append("T1 is T0 + 1")
#     if schema.actionBody:
#         body_list.append(schema.actionBody + "(T0)")
#     body = ", ".join(body_list)
#
#     # Form head of schema
#     if att == REWARD:
#         return body
#     elif att == X_POS:
#         head_list[att] = "New_X_pos"
#         body_list.append("New_X_pos is X_pos " + change[key])
#     elif att == Y_POS:
#         head_list[att] = "New_Y_pos"
#         body_list.append("New_Y_pos is Y_pos " + change[key])
#     else:
#         head_list[att] = str(key)
#     head = "att(Obj, " + ", ".join(head_list) + ", T1)"
#
#     return head + " :- " + body + "."


