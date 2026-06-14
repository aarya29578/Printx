import ReactQuill from 'react-quill'

export default function RichTextEditor({ value, onChange }) {
  return <ReactQuill theme="snow" value={value || ''} onChange={onChange} />
}
