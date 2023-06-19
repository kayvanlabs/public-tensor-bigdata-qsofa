Npos=200;
Nneg=500;
SDpos=.3;
SDneg=.7;
MEANpos=1;
MEANneg=0;
pos=randn(Npos,1)*SDpos+MEANpos;
neg=randn(Nneg,1)*SDneg+MEANneg;
perm=randperm(Npos+Nneg);
v=[pos;neg];
w=[ones(Npos,1);zeros(Nneg,1)];
score=v(perm,1);
class=w(perm,1);
AUC(class,score);