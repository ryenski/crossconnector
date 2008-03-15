
function togglePeople(master, className) {
  var people = getElementsByClassName(className);
  if (master.checked) {
    for (i = 0; i < people.length; i++) { people[i].checked = true; }
  } else {
    for (i = 0; i < people.length; i++) { people[i].checked = false; }
  }
}

function toggleMaster(master){
  master = document.getElementById(master)
  if (master.checked) {
     master.checked = false;  }
}
  
  
function toggleAdminResources(className){
  var element = getElementsByClassName(className);
  for (i = 0; i < element.length; i++) { element[i].style.display=='none'; } 
}


/* Thanks to http://www.snook.ca/archives/000370.php */
function getElementsByClassName(classname) {
    var a = [];
    var re = new RegExp('\\b' + classname + '\\b');
    var els = document.all?document.all:document.getElementsByTagName("*");
    for(var i=0,j=els.length; i<j; i++)
        if(re.test(els[i].className))a.push(els[i]);
    return a;
}


function togglePrivateForm(box, elem){
  var elem = document.getElementById(elem);
  var box = document.getElementById(box);
  if (box.checked) {
    elem.style.display = 'block';
  }
  else{
    elem.style.display = 'none';
  }
}








