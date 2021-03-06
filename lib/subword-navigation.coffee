_ = require 'underscore-plus'
{Point} = require 'atom'

module.exports =
class SubwordNavigation
  constructor: ->

  destroy: ->

  editor: ->
    atom.workspace.getActiveTextEditor()

  moveToNextSubwordBoundary: ->
    for cursor in @cursors()
      if position = cursor.getNextWordBoundaryBufferPosition(@cursorOptions())
        cursor.setBufferPosition(position)

  moveToPreviousSubwordBoundary: ->
    for cursor in @cursors()
      if position = cursor.getPreviousWordBoundaryBufferPosition(@cursorOptions(backwards: true))
        # FIXME: hack to fix going left on first line
        if position.isEqual(cursor.getBufferPosition())
          position = new Point(position.row, 0)
        cursor.setBufferPosition(position)

  selectToNextSubwordBoundary: ->
    for selection in @selections()
      cursor = selection.cursor
      position = cursor.getNextWordBoundaryBufferPosition(@cursorOptions())
      if cursor and position
        selection.modifySelection ->
          cursor.setBufferPosition(position)

  selectToPreviousSubwordBoundary: ->
    for selection in @selections()
      cursor = selection.cursor
      position = cursor.getPreviousWordBoundaryBufferPosition(@cursorOptions(backwards: true))
      if cursor and position
        # FIXME: hack to fix going left on first line
        if position.isEqual(cursor.getBufferPosition())
          position = new Point(position.row, 0)
        selection.modifySelection ->
          cursor.setBufferPosition(position)

  deleteToNextSubwordBoundary: ->
    @editor().transact =>
      @selectToNextSubwordBoundary()
      for selection in @selections()
        selection.deleteSelectedText()

  deleteToPreviousSubwordBoundary: ->
    @editor().transact =>
      @selectToPreviousSubwordBoundary()
      for selection in @selections()
        selection.deleteSelectedText()

  subwordRegExp: (options={}) ->
    nonWordCharacters = atom.config.get('editor.nonWordCharacters')
    segments = ["^[\t ]*$"]
    segments.push("[A-Z]?[a-z]+")
    segments.push("[A-Z]+(?![a-z])")
    segments.push("\\d+")
    if options.backwards
      segments.push("[#{_.escapeRegExp(nonWordCharacters)}]+\\s*")
    else
      segments.push("\\s*[#{_.escapeRegExp(nonWordCharacters)}]+")
    new RegExp(segments.join("|"), "g")

  cursors: ->
    if @editor() then @editor().getCursors() else []

  selections: ->
    if @editor() then @editor().getSelections() else []

  cursorOptions: (options={}) ->
    {wordRegex: @subwordRegExp(options)}
