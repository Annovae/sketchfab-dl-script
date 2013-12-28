// ==UserScript==
// @name           Sketchfab download script
// @description    lets you download Sketchfab models
// @author         Reinitialized
//
//Version Number
// @version        1.0
//
// Urls process this user script on
// @include        https://sketchfab.com/show/*
// ==/UserScript==
 
function getElementByXpath(path) {
    return document.evaluate(path, document, null, 9, null).singleNodeValue;
};

function InfoForGeometry(geom) {
    try {
        info = {
            'name' : geom._name,
            'vertices' : geom.attributes.Vertex._elements,
            'primitives' : []
        };
        for (i = 0; i < geom.primitives.length; ++i) {
            var primitive = geom.primitives[i];
            if (primitive.mode == 1)
                return null;
            info.primitives.push({
                'mode' : primitive.mode,
                'indices' : primitive.indices._elements
            });
        }
        return info;
    }
    catch (err) {
        console.log(err.message);
        console.log(geom);
    }
};

function OBJforGeometry(geom) {
    return OBJforGeometryInfo(InfoForGeometry(geom));
};

var vertexOffset = 0;
function OBJforGeometryInfo(info) {
    if (!info)
        return;
    var obj = '#name: ' + info.name + '\n';
    for (var i = 0; i < info.vertices.length; i += 3) {
        obj += 'v ';
        for (j = 0; j < 3; ++j) {
            obj += info.vertices[i + j] + ' ';
        }
        obj += '\n';
    }
    for (var i = 0; i < info.primitives.length; ++i) {
        var primitive = info.primitives[i];
        if (primitive.mode == gl.TRIANGLES || primitive.mode == gl.TRIANGLE_STRIP) {
            for (j = 0; j + 2 < primitive.indices.length; primitive.mode == gl.TRIANGLES ? j += 3 : ++j) {
                obj += 'f ';
                for (k = 0; k < 3; ++k) {
                    obj += (primitive.indices[j + k] + vertexOffset + 1) + ' ';
                }
                obj += '\n';
            }
        }
        else {
            console.log('Primitive mode not implemented');
        }
    }
    vertexOffset += info.vertices.length / 3;
    return obj;
};

var computedIDs = new Array();
var combinedOBJ = '';
function recurse(node) {
    if (node.className() == 'Geometry') {
        var computeOBJ = true;
        var useID = '_uniqueID' in node;
        for (var i = 0; i < computedIDs.length; ++i) {
            if (computedIDs[i] == (useID ? node._uniqueID : node._name)) {
                computeOBJ = false; 
                break;
            }
        }
        if (computeOBJ) {
            computedIDs.push(useID ? node._uniqueID : node._name);
            combinedOBJ += OBJforGeometry(node);
        }
    }
    if (node.children.length) {
        for (var i = 0; i < node.children.length; ++i) {
            recurse(node.children[i]);
        }
    }
};
window.dlOBJ = function() {
    recurse(view3D._scene); 
    // Credit: http://thiscouldbebetter.wordpress.com/2012/12/18/loading-editing-and-saving-a-text-file-in-html5-using-javascrip/
    function destroyClickedElement(event)
    {
        document.body.removeChild(event.target);
    }
    var textToWrite = combinedOBJ;
    var textFileAsBlob = new Blob([textToWrite], {type:'text/plain'});
    
    // Credit: http://phpjs.org/functions
    function basename (path, suffix) {
        var b = path.replace(/^.*[\/\\]/g, '');
        
        if (typeof suffix === 'string' && b.substr(b.length - suffix.length) == suffix) {
            b = b.substr(0, b.length - suffix.length);
        }
        
        return b;
    }
    var fileNameToSaveAs = basename(document.URL) + ".obj";
    
    var downloadLink = document.createElement("a");
    downloadLink.download = fileNameToSaveAs;
    downloadLink.innerHTML = "Download File";
    if (window.webkitURL != null)
    {
        // Chrome allows the link to be clicked
        // without actually adding it to the DOM.
        downloadLink.href = window.webkitURL.createObjectURL(textFileAsBlob);
    }
    else
    {
        // Firefox requires the link to be added to the DOM
        // before it can be clicked.
        downloadLink.href = window.URL.createObjectURL(textFileAsBlob);
        downloadLink.onclick = destroyClickedElement;
        downloadLink.style.display = "none";
        document.body.appendChild(downloadLink);
    }
    downloadLink.click();
};

var ul = getElementByXpath('//*[@id="main-menu"]/ul');
var li=document.createElement("li");
li.innerHTML='<a class="order-model" id="downloadOBJ"><span>Download .OBJ</span></a>';
li.addEventListener ("click", dlOBJ , false);
ul.appendChild(li);