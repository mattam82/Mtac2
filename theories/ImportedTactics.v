From Mtac2 Require Import Base Tactics.
Import M.notations.
Import T.notations.

Require Import Strings.String.
Require Import Mtac2.List.
Import Mtac2.List.ListNotations.

Definition qualify s := String.append "Mtac2.ImportedTactics." s.

Ltac trivial := trivial.
Definition trivial : tactic := T.ltac (qualify "trivial") nil.

Ltac discriminate := discriminate.
Definition discriminate : tactic := T.ltac (qualify "discriminate") nil.

Ltac intuition := intuition.
Definition intuition : tactic := T.ltac (qualify "intuition") nil.

Ltac auto := auto.
Definition auto : tactic := T.ltac (qualify "auto") nil.

Ltac eauto := eauto.
Definition eauto : tactic := T.ltac (qualify "eauto") nil.

Ltac subst := subst.
Definition subst : tactic := T.ltac (qualify "subst") nil.

Ltac contradiction := contradiction.
Definition contradiction : tactic := T.ltac (qualify "contradiction") nil.

Ltac tauto' := tauto.
Definition tauto : tactic := T.ltac (qualify "tauto'") nil.

Ltac unfold x := unfold x.
Definition unfold {A} (x: A) := T.ltac (qualify "unfold") [m:Dyn x].

Ltac rrewrite1 a := rewrite a.
Ltac rrewrite2 a b := rewrite a, b.
Ltac rrewrite3 a b c := rewrite a, b, c.
Ltac rrewrite4 a b c d := rewrite a, b, c, d.
Ltac rrewrite5 a b c d e := rewrite a, b, c, d, e.

Definition compute_terminator {A} (l: list A) : M string :=
  match l with
  | [m:] => M.failwith "At least one required"
  | [m:_ & [m:]] => M.ret "1"
  | [m: _ & [m:_]] => M.ret "2"
  | [m:_ & [m:_ & [m:_]]] => M.ret "3"
  | [m:_ & [m:_ & [m:_ & [m:_]]]] => M.ret "4"
  | [m:_ & [m:_ & [m:_ & [m:_ & [m:_]]]]] => M.ret "5"
  | _ => M.failwith "Unsupported"
  end%string.

Ltac lrewrite1 a := rewrite <- a.
Ltac lrewrite2 a b := rewrite <- a, b.
Ltac lrewrite3 a b c := rewrite <- a, b, c.
Ltac lrewrite4 a b c d := rewrite <- a, b, c, d.
Ltac lrewrite5 a b c d e := rewrite <- a, b, c, d, e.

Inductive RewriteDirection := LeftRewrite | RightRewrite.

Definition trewrite (d : RewriteDirection) (args : list dyn) : tactic := fun g =>
  (ter <- compute_terminator args;
  let prefix := match d with LeftRewrite => "l"%string | RightRewrite => "r"%string end in
  let name := reduce RedNF (qualify (prefix++"rewrite"++ter)) in
  T.ltac name args g)%MC.

Notation "'rewrite' '->' x , .. , z" :=
  (trewrite RightRewrite (cons (Dyn x) .. (cons (Dyn z) nil) ..))
    (at level 0, x at next level, z at next level).
Notation "'rewrite' '<-' x , .. , z" :=
  (trewrite LeftRewrite (cons (Dyn x) .. (cons (Dyn z) nil) ..))
    (at level 0, x at next level, z at next level).
Notation "'rewrite' x , .. , z" :=
  (trewrite RightRewrite (cons (Dyn x) .. (cons (Dyn z) nil) ..))
    (at level 0, x at next level, z at next level).

Ltac elim h := elim h.
Definition elim {A} (x:A) : tactic :=
  T.ltac (qualify "elim") [m: Dyn x].

Ltac induction v := induction v.
Definition induction {A} (x:A) : tactic :=
  T.ltac (qualify "induction") [m: Dyn x].

Definition injection {A} (x: A) : tactic :=
  T.ltac ("Coq.Init.Notations.injection") [m:Dyn x].

Ltac inversion H := inversion H.
Definition inversion {A} (x: A) : tactic :=
  T.ltac (qualify "inversion") [m:Dyn x].

Ltac typeclasses_eauto := typeclasses eauto.
Definition typeclasses_eauto : tactic :=
  T.ltac (qualify "typeclasses_eauto") [m:].

Ltac ltac_apply x := apply x.
Definition ltac_apply {A} (x:A) := T.ltac (qualify "ltac_apply") [m:Dyn x].

Ltac ltac_destruct x := destruct x.
Definition ltac_destruct {A} (x:A) := T.ltac (qualify "ltac_destruct") [m:Dyn x].
