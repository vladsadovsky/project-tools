# Correct git workflow

## Definitions


- _**Working Tree**_ - A local directory containing a working copy of files for git repo, including unstaged changes.
One half (along with the _git dir_) of a _git project_, which is the result of _git clone_, for root projects, or
_git submodule add_, for subprojects.
- _**Git Dir**_ - The directory that contains the index and other state that represents a git repo. On a remote git
server, this is the manifestation of a _bare repo_ with no _working tree_. On a development machine, as part of a
_git project_, this appears as a hidden **.git** subdirectory under the top directory of the _working tree_, for
_root projects_, or as a special subdirectory of the _root project's_ _git dir_, for _subprojects_. 
- _**Git Project**_ - A local _working tree_ on a single development machine, along with its corresponding _git dir_. The
result of _git clone_, for _root projects_, or of _git submodule add_ (or _git submodule update_), for _subprojects_.
A git project is identified by the top-level directory of its _working tree_.
- _**Git Submodule**_ - A somewhat overloaded term. May refer to either:
  1. A _git submodule reference_, which is a special entry in a parent git repo's index that maintains a tuple of
     (local subdirectory name, remote commit point), where "remote commit" is a commit reference into an unspecified
     remote repository. The default and initial URL to this repository is stored in the .gitmodules file, and can
     be resynchronized with "git submodule sync", but the actual URL is kept in gitconfig and is private to each
     instanciated subproject. At "git submodule update --init" time, the indicated local subdirectory in the superproject
     is created if necessary as a clone of the remote, and then the HEAD is hard reset (in a detached state) to the
     indicated remote commit point.
  2. A _git subproject_; i.e., the actual _git project_ instance that is created in a subdirectory of the
     superproject as described in (i.) above.
  
  For the purposes of documentation clarity, we will generally avoid using the bare term "submodule" and instead refer
  to either a _subproject_ or a _submodule reference_.
- _**Superproject**_ - A _git project_ that is the immediate parent project of a _subproject_. May itself be a
_root project_ or a _subproject_.
- _**Subproject**_ - A _git project_ that has a single _superproject_. A subproject is associated with a _git submodule_
reference in the git repo.
- _**Root Project**_ - A _git project_ that has no _superproject_; i.e., is not a _subproject_. Created with _git clone_.
- _**Remote Repository**_ - A (typically _bare_) git repository, typically on a network server, identified by its
_git url_.
- _**Unshared Branch Project**_ - A _git project_ that is in effect the single source of truth for a given
_working branch_. Such a project can freely rebase, hard reset, and squash the _working branch_ at will without concern for
consistency with the same branch on other repos. A developer may, through careful coordination, migrate an _unshared branch
project_ from one location to another (e.g., between a work machine and a home machine), but at any point of time
there is only one project that owns truth for a _working branch_.
- _**Trunk Branch**_ - (Coined term) A git branch that has as its basis a remote repository which is potentially
used by multiple developers and for which merges must be carefully managed. A trunch branch has a single commit
history and is never rebased or pushed with _git push -f_. **master** is the most common trunk branch name, but others
may be created (independently or in a hierarchy) to manage long-lived, multi-developer divergent development efforts
that are only occasionally merged. When one trunk branch is merged into another trunk branch, _git merge_ is generally
used rather than _git rebase_, so that both trunk branches can maintain their linear commit histories. Alternatively,
an intermediate trunk branch can be permanently repurposed as a _working branch_ (thereby invalidating all child
branches), after which it may be rebased on an upstream trunk branch. Generally, development work is never done
directly in a trunk branch; instead, private  _working branches_ are created and used until a stable commit can be
folded into the trunk branch.
- _**Working Branch**_ - (Coined term) A git branch into which changes are directly committed by a developer.
Generally, there is only one developer actively working on a given working branch, and a single _unshared branch project_
represents the current state of the branch. As a result, a working branch can be rebased and squashed at will without
creating problems for other developers. A working branch might only exist locally on a developer's machine, or for backup
purposes it may be periodically pushed (with _git push -f_ to allow for rebases) to a remote repository.
Each working branch is associated with a single upstream _trunk branch_, which is the shared branch from which the
working branch is derived and into which the working branch will eventually be merged. A working branch is
frequently rebased on its trunk branch, and is again rebased just before  merging into the trunk branch,
which allows the trunk to see it as a simple fast-forward merge rather than a multi-base merge; in this way, a simple
linear history of the trunk branch can be preserved..

## Common Tasks

### Global config

```bash
git config --global user.email "<username>@domain.com"
git config --global user.name "<first-name> <last-name>"
git config --global core.editor ("nano" | "vim" | "gedit" ...)
```

### Create a cloned root project from a remote git repo and designate it as the unshared branch project for a new working branch

```bash
mkdir -p ~/xws/git
cd ~/xws/git
git clone <root-project-remote-url> -b <trunk-branch> [<root-project-basename>]
cd <root-project-basename>
git checkout -b <working-branch>           # Generally, should start with "<username>-" for private branches
git config iotboxproj-working-branch.<working-branch>.trunk-branch <trunk-branch>
git config iotboxproj-working-branch.<working-branch>.merge-mode rebase
# Follow instructions for updating subprojects (below)
git push -u origin <working-branch>        # Optional -- If a remote backup/copy of private branch is desired
```

### Update subprojects (only necessary after initial clone or pulling changes from trunk branch)
```bash
# In working tree with <working-branch> checked out:
# <if project has subprojects>
  git submodule update --recursive --init
  # <foreach subproject, recursively>
    # <if subproject has a desired working branch subproject-working-branch>
      cd <subproject-working-tree>
      # <if subproject current branch != subproject-working-branch>
        git fetch . HEAD:<subproject-working-branch>    # attempt to fast-forward working branch to current HEAD
        # <if fetch failed>
          # Reconcile <subproject-working-branch> conflict with HEAD. Should not happen if subproject workflow has been followed.
        # verify HEAD hash == <subproject-working-branch> hash
        git checkout <subproject-working-branch>
  cd <working-tree>
```

### Backup a working branch from its unshared branch project to the "origin" remote repo

```bash
# In working tree with <working-branch> checked out:
git status
# Commit, stash, or discard all dirty or staged files (working tree must be clean)
# Follow instructions for updating subprojects, above
# <if project has subprojects>
  # <foreach subproject, recursively>
    cd <subproject-working-tree>
    git ls-remote --heads --tags 2>/dev/null | sed -n 's/^\('`git rev-parse HEAD`'\)\t\(..*\)$/\1 \2/p'
    # <if no results returned from git ls-remote>
      # <if current head matches a desired local subproject branch head>
        # <if current head is detached or is on an undesirable branch>
          git checkout <subproject-branch-name>
        git push origin <subproject-branch-name>:<subproject-branch-name>    # -f may be needed if this is a private working branch
      # <else>
        git checkout -b <new-subproject-branch-name>
        git push -u origin <new-subproject-branch-name>
  cd <working-tree>
# Verify working-branch is clean and is the version you want to retain
git push -f origin <working-branch>:<working-branch>    # Destructive--overwrites previous origin/<working-branch> HEAD.
                                                        # Necessary for rebase-style branch.
```

### Restore a working branch to its unshared branch project from the "origin" remote repo
```bash
# In working tree with <working-branch> checked out:
git status
# Stash, discard, or commit (to alternate branch) all dirty or staged files (working tree must be clean)
git fetch origin
git reset --hard origin  # Destructive - replaces current <working-branch> HEAD with remote origin/<working-branch> HEAD.
# Follow directions for "Update subprojects", above
# Verify working tree is clean and the desired version
```

### Pull changes from the trunk branch into its unshared branch project (rebase method)
```bash
# In working tree with <working-branch> checked out:
# Follow directions for "Update subprojects", above
git status
# Commit, stash, or discard all dirty or staged files (working tree must be clean)
git fetch origin <trunk-branch>:<trunk-branch>
git rebase <trunk-branch>
# <while rebase-in-progress>:
  # <foreach file conflict>
    # <resolve file conflicts with editor>
    git add <resolved-file>
  # <foreach subproject with conflicts>
    # Follow directions for "Resolve merge conflicts in a submodule reference" below
    git add <resolved-subproject>
  git status
  # verify all conflicts resolved and all changes are staged
  git rebase --continue
  # Follow directions for "Update subprojects", above
  # Abort whole rebase at any time with 'git rebase --abort'
# Follow directions for "Update subprojects"
# Optionally, back up local branch to remote (see above)
```

### Modify or add  files in a working branch's unshared branch project
```bash
# In working tree with <working-branch> checked out:
# Make sure subprojects are in the desired state; use 'git submodule update --recursive --init' if necessary
# Modify or add local, non-subproject files at will
# To modify subprojects, see separate section...
git add <modified-file-or-dir> [<modified-file-or-dir>...]
git status
# Make sure correct files are staged
git commit
# Edit the commit message in the interactive editor
# Save changes; exit editor.
# Optionally, back up local working branch to remote (see above)
```

### Squash multiple commits to a smaller number of commits (typically one) in a working branch's unshared branch project
```bash
# In working tree with <working-branch> checked out:
git status
# Commit, stash, or discard all dirty or staged files (working tree must be clean)
git fetch origin <trunk-branch>:<trunk-branch>
git log HEAD       # view recent commits
git rebase -i $(git merge-base HEAD origin/<trunk-branch>)
# In editor, leave commits you want to keep as "pick"; change others to "s". Leave at least one "pick"
# Save changes; exit editor
# <for each <unsquashed-pick>>:
  # Edit commit message
  git rebase --continue
  # Abort whole rebase at any time with 'git rebase --abort'
# Optionally, back up local working branch to remote (see above)
```

### Push changes from a working branch's unshared branch project to its remote shared trunk branch (rebase method)
```bash
# In working tree with <working-branch> checked out:
mkdir -p <parent-directory-of-subproject>
cd <parent-directory-of-subproject>

# <repeat>
    # <repeat>
        # Follow instructions for "Pull changes from the trunk branch into a private (1-user) branch" (above)
        # Verify/test integration with latest trunk changes
        # <if integration tests failed>
          # Fix integration problems and commit to <working-branch>
      # <until integration tests pass>
    # If desired, follow instructions for "Squash multiple commits to a smaller number of commits (typically one)
    # in a private (1-user) working branch"
    git push origin <working-branch>:<trunk-branch>  # will fail if remote <trunk-branch> changed since above pull...
  # <until push succeeds>
git fetch origin <trunk-branch>:<trunk-branch>
```

### Add a new submodule/subproject in a working branch's unshared branch project
```bash
# In parent project working tree <parent-working-tree> with <parent-working-branch> checked out:
git status
# Commit, stash, or discard all dirty or staged files unless you want submodule add to be part of another commit
mkdir -p <parent-dir-of-subproject-working-tree>
cd <parent-dir-of-subproject-working-tree>
git submodule add <submodule-remote-url> -b <subproject-trunk-branch> [<subproject-basename>]
# <if local editing of the subproject is desired>
  cd <subproject-basename>
  # Follow directions for "Begin local editing of a subproject" below
  cd <parent-working-dir-of-subproject-working-tree>
# <if immediate commit desired>   # generally, submodule adds should be in a separate commit
  git add <submodule-basename>
  # Follow commit directions in "modify or add  files in a private (1-user) working branch"
```

### Begin local editing of a subproject in a working branch's unshared branch project
```bash
# In working tree of the subproject with <subproject-trunk-branch> checked out, and with
# the superproject having <superproject-working-branch> checked out:
# Commit, stash, or discard all dirty or staged files (working tree must be clean)
git checkout -b <subproject-working-branch>     # Generally, should start with "<username>-" for private branches
git config iotboxproj-working-branch.<subproject-working-branch>.trunk-branch <subproject-trunk-branch>
git config iotboxproj-working-branch.<subproject-working-branch>.merge-mode rebase
iotboxproj-superproject-working-branch.<superproject-working-branch>.working-branch=<subproject-working-branch>
git push -u origin <subproject-working-branch>  # Required if <superproject-working-branch> is ever pushed to remote;
                                               # optional otherwise.
```
### Resolve merge conflicts in a submodule reference
This procedure is used when pulling changes from the trunk branch into a superproject results in a merge
conflict in the submodule reference for one of the contained subprojects. This should only happen
if you have created a working branch for the subproject and have locally committed changes to it, and
then committed the resulting change to the submodule reference in the superproject's submodule reference,
prior to rebasing the superproject.

When this happens, there are three "stages" for the submodule reference maintained in the superproject's git index,
until the conflict is resolved. Each stage is associated with a commit point in the subproject,
corresponding to the local working branch commit point (MINE), the current trunk's commit point (THEIRS),
and the common ancestor of the two (BASE). The basic task is to perform a rebase of the subproject's working
branch (MINE) over the subproject's current trunk commit point (THEIRS). Then, the merged submodule reference
can be committed to the working branch of the superproject and rebasing of the superproject can proceed.
```bash
# In working tree of the superproject with <superproject-working-branch> checked out, with a merge or rebase
# in progress, and with an unresolved merge conflict in a submodule reference.
git status
# verify that the submodule list listed as "both modified"
git ls-files --stage --full-name <subproject-working-tree>
# Verify that there are three stages listed, with commit point hashes for each; e.g.,
#
#         160000 dbbd2766fa330fa741ea59bb38689fcc2d283ac5 1       <subproject-relative-path>
#         160000 f174d1dbfe863a59692c3bdae730a36f2a788c51 2       <subproject-relative-path>
#         160000 e6178f3a58b958543952e12824aa2106d560f21d 3       <subproject-relative-path>
#
# Stage 1 is the common ancestor (BASE). Stage 2 is the version that was pulled (THEIRS). Stage 3 is
# our unmerged version (OURS)
BASE_COMMIT=`git ls-files --stage --full-name submodule-child-test | sed -n 's/^160000 \([0-9a-f]\{40\}\) 1\t.*/\1/p'`
THEIR_COMMIT=`git ls-files --stage --full-name submodule-child-test | sed -n 's/^160000 \([0-9a-f]\{40\}\) 2\t.*/\1/p'`
OUR_COMMIT=`git ls-files --stage --full-name submodule-child-test | sed -n 's/^160000 \([0-9a-f]\{40\}\) 3\t.*/\1/p'`
cd <subproject-working-tree>
WORKING_BRANCH_COMMIT=$(git rev-parse <subproject-working-branch>)
# Verify that the $WORKING_BRANCH_COMMIT is equal to "$OUR_COMMIT". If not, you have made changes to <subproject-working-branch>
# or <superproject-working-branch> outside prescribed recipes, and you will have to manually resolve and set
# WORKING_BRANCH_COMMIT to the local version of the subproject that you want to rebase on the trunk changes before
# proceeding.
git checkout $WORKING_BRANCH_COMMIT
git submodule update --recursive --init
git status
# Commit, stash, or discard all dirty or staged files (working tree must be clean)
git fetch origin $THEIR_COMMIT
git rebase $THEIR_COMMIT
# <while rebase-in-progress>:
  # <foreach file conflict>
    # <resolve file conflicts with editor>
    git add <resolved-file>
  # <foreach nested subproject with conflicts>
    # Follow directions for "Resolve merge conflicts in a submodule reference", (i.e., recurse)
    git add <resolved-nested-subproject>
  git status
  # verify all conflicts resolved and all changes are staged
  git rebase --continue
  git submodule update --recursive --init
  # Abort whole rebase at any time with 'git rebase --abort'
# Follow directions for "Update subprojects"
cd <superproject-working-tree>
# Resume merge resolution in superproject (with 'git add' of the subproject, etc.)
```