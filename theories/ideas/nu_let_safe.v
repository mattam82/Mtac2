From Mtac2 Require Import Base MTele Logic.
Import M.notations.

Set Universe Polymorphism.
Unset Universe Minimization ToSet.

From Coq Require Import JMeq.

Notation "x =j= y" := (JMeq x y)
                 (at level 70, y at next level, no associativity).
Lemma JMeq_types : forall {A B} {x: A} {y: B} (H: x =j= y), A =m= B.
Proof.
  intros.
  destruct H. reflexivity.
Qed.

Lemma JMeq_meq : forall {A} (x: A) (y: A) (H: x =j= y), x =m= y.
Proof.
  intros.
  rewrite H.
  reflexivity.
Qed.

(** Given a term [t] of type [T], assumed to be of the form [let x : A := y in
    t'], with [T] being [let x : A := y in P] (or its let-expanded version), it
    gets a function [f] and executes [f A x y P meq_refl t' JMeq_refl] under the
    context extended with [x : A := y].  Assuming it returns value [b], it
    returns it after checking no harm is done: [x] is not free in [b]. Note that
    one might tink that it's wrong to return [y] or [P]. However, these terms
    where well-typed in the original context, so there is no problem. [x] is the
    only one being added to the context, and the one to care about. *)
Definition full_nu_let {T} (n: name) (t: T)
  {B : Type}
  (f : forall A (x y: A) P (eqxy: x =m= y) (t': P) (eqP: t =j= t'), M B) :
  M B.
  intros. exact M.mkt.
Qed.

(** Given a variable [x] of type [A], a definition (supposed to be equal) [y],
    and a term [t] of type [P], it returns a [t'] equals to [t]: [let z : A := y
    in t{z/x}]. It won't check if [y] is the actual definition, as long it is
    equal to [x] (that's what [eqxy] says), and assuming [x] is a variable, it
    should be sound to return the let-binding. The reason why the returned term
    has the same type as [P] is because [let z:A := y in t{z/x}] has type
    [P{y/x}] and, since [x =m= y], we get [P{x/x}] which is [P]. *)
Definition full_abs_let : forall {A : Type} {P : Type} (x y : A) (eqxy: x=m=y) (t: P),
    M {t' : P & t =m= t'}.
  intros. exact M.mkt.
Qed.

Definition old_nu_let {A B C : Type} (n: name) (blet: C) (f: A -> C -> M B) : M B :=
  full_nu_let n blet (fun A' x y P eqxy t' eqt'  =>
    eqAA' <- M.unify_or_fail UniCoq A' A;
    let x := reduce (RedWhd [rl:RedMatch]) (match eqAA' with meq_refl => x end) in
    let eqCP := dreduce (@JMeq_types, @meq_sym) (meq_sym (JMeq_types eqt')) in
    let t' := reduce (RedWhd [rl:RedMatch]) (match eqCP with meq_refl => t' end) in
    f x t').


Obligation Tactic := intros.
Program
Definition let_completeness {B} (term: B) : M {blet : B & blet =m= term} :=
  full_nu_let (TheName "m") term (fun A m d P eqmd body eqP=>
    body_let <- full_abs_let (P:=P) m d eqmd body;
    let (blet, jeq) := body_let in
    M.ret (existT _ _ _ : { blet : _ & blet =m= term})).
Next Obligation.
  simpl in *.
  apply JMeq_types in eqP.
  rewrite eqP.
  exact blet.
Defined.
Next Obligation.
  simpl.
  cbv.
  simpl in jeq.
  destruct eqmd.
  destruct (JMeq_types eqP).
  rewrite eqP.
  rewrite jeq.
  reflexivity.
Defined.

Program
Definition let_soundness {A} {P} (x d: A) (term: P) (eqxd : x =m= d) : M {t : P & t =m= term} :=
  letb <- full_abs_let x d eqxd term;
  let (blet, eq) := letb in
  full_nu_let (TheName "m") blet (fun B a b T eqab t' eqblet =>
     _).
Next Obligation.
  refine (M.ret (existT _ _ _)).
  simpl in eq.
  generalize (JMeq_types eqblet).
  intro eqPT.
  generalize t' eqblet.
  clear t' eqblet.
  rewrite <- eqPT.
  intros t' eqblet.
  rewrite eq. rewrite eqblet.
  reflexivity.
Qed.

Print Module M.M.

(** Let [D] equal to [forall x:A, B], it executes [f A (fun x:A=>B) meq_refl] and returs its value (no check needed).
    The reason not to introduce variable [x] is because it can be done later by the user if needed. *)
Definition dest_fun_type (T C: Type): Type.
  refine (forall (t: T), (forall A (x: A) (B: A->Type) (b: B x)
  (eqTB : T =m= (forall z:A, B z)) (eqt: (_ : (forall z, B z)) x =m= b), M C) -> M C).
  rewrite eqTB in t. exact t.
Defined.

Definition dest_fun {T C} : dest_fun_type T C.
  intros; constructor. Qed.

Definition abs_fun: forall{A: Type} {P: A->Type} (x: A) (t: P x),
  M {t': forall x, P x & t' x =m= t}.
  constructor. Qed.


Require Import ssreflect.

Program
Definition fun_completeness {T: Type} (t: T) : M {A:Type & {P:A->Type & {funp : forall x:A, P x & funp =j= t}}} :=
  dest_fun t (fun A x B b eqTB eqt =>
    absf <- abs_fun x b;
    let (t', eqtb') := absf in
      M.ret (existT _ A (existT _ B (existT _ t' _)))).
Next Obligation.
  simpl in *.
  cbv in eqt.
  move: eqTB eqt.
  Fail case.
Admitted.


(* Axiom forall_extensionality : forall (A : Type) (B C : A -> Type), (forall x : A, B x =m= C x) -> (forall x : A, B x) =m= (forall x : A, C x). *)
(* Axiom forall_extensionality_domain : forall (A B: Type) (C: A -> Type) (D: B -> Type), (forall x : A, C x) =m= (forall x : B, D x) -> A =m= B. *)

(* Program *)
(* Definition prod_type_soundness {A: Type} (a: A) (B: Type) : M {P : A -> Type & P a =m= B} := *)
(*   absp <- abs_prod_type a B; *)
(*   let (P, PeqB) := absp in *)
(*   dest_prod_type (forall x:A, P x) (fun A' B' eqBB' => *)
(*      M.ret (existT _ _ _ : { P : _ & P a =m= B})). *)
(* Next Obligation. *)
(*   simpl in *. *)
(*   generalize x; clear x. *)
(*   apply forall_extensionality_domain in eqBB'. *)
(*   rewrite eqBB'. *)
(*   exact B'. *)
(* Defined. *)
(* Next Obligation. *)
(*   simpl in *. *)
(*   unfold prod_type_soundness_obligation_1. *)
(*   rewrite -PeqB. *)
(* Admitted. *)