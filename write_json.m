function write_json(path,value)
folder=fileparts(path);if ~isfolder(folder),mkdir(folder);end
fid=fopen(path,'w');assert(fid>=0,'Cannot write %s',path);
c=onCleanup(@()fclose(fid));fprintf(fid,'%s',jsonencode(value,PrettyPrint=true));
end
